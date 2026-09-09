#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
    report-room: deterministic, zero-inference offline HTML reading room over
    reports/README.md joined with a read-only Beads snapshot.

.DESCRIPTION
    Usage:
      scripts/report-room.ps1 open  [-NoLaunch] [-Output <path>] [-RepoRoot <path>]
      scripts/report-room.ps1 check [-Json] [-RepoRoot <path>]

    open   Renders reports/README.md plus embedded bead detail cards to a
           self-contained temporary HTML file and launches the default browser
           (unless -NoLaunch). Prints the output path either way.
    check  Validates the source: thread structure, report links, bead IDs,
           age facts, prerequisites. -Json emits a stable machine schema.

    Boundaries: no model/API call, no network, no standing service, no Beads
    mutation. Beads is read through a single batched `bd show <ids...> --json`
    (with a bounded per-ID fallback). Generated HTML goes under the OS temp
    directory by default and is never written under reports/.

    Test seams (documented in scripts/README.md):
      -BdJsonPath <file>            read bead JSON from a fixture file instead of bd
      REPORT_ROOM_BD_EXE            override the bd executable name/path
      REPORT_ROOM_TEST_FAIL_RENDER  =1 forces a renderer failure after the output
                                    file exists (exercises temp-output cleanup)

    Exit codes: 0 success (warnings allowed), 1 error (missing prerequisites,
    malformed source, missing/out-of-repo links, invalid bead JSON, renderer
    failure), 2 usage error.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [switch]$NoLaunch,
    [string]$Output,
    [string]$RepoRoot,
    [switch]$Json,

    # Test seam: path to a JSON file used as the bd snapshot instead of calling bd.
    [string]$BdJsonPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- constants --
# Age thresholds add neutral visual emphasis only; age never claims priority,
# neglect, or misunderstanding. Named constants per design.
$script:AGE_EMPHASIS_SOFT_DAYS   = 30
$script:AGE_EMPHASIS_STRONG_DAYS = 90
# Bounded fallback: max individual `bd show <id> --json` calls if the batched
# call is unsupported by the installed CLI.
$script:MAX_FALLBACK_BD_CALLS    = 32

$script:BEAD_ID_REGEX   = 'mybd-[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*'
$script:MD_LINK_REGEX   = '\[(?<text>[^\]]+)\]\((?<target>[^)\s]+)\)'
$script:ACTIVE_HEADING  = '^##\s+Active threads\s*$'
$script:RENDERER_NAME   = 'internal-subset'   # minimal converter, no dependency

# ---------------------------------------------------------------- utilities --
function HtmlEnc([string]$s) {
    if ($null -eq $s) { return '' }
    return [System.Net.WebUtility]::HtmlEncode($s)
}

function Get-Field($obj, [string]$name, $default = $null) {
    if ($null -eq $obj) { return $default }
    $p = $obj.PSObject.Properties[$name]
    if ($null -ne $p -and $null -ne $p.Value) { return $p.Value }
    return $default
}

function Parse-BdTimestamp($v) {
    # ConvertFrom-Json may hand back a [datetime] already (PS 7 converts ISO
    # strings); bd timestamps are UTC, so Unspecified kind means UTC here.
    if ($null -eq $v) { return $null }
    if ($v -is [datetime]) {
        switch ($v.Kind) {
            'Utc'   { return $v }
            'Local' { return $v.ToUniversalTime() }
            default { return [datetime]::SpecifyKind($v, [System.DateTimeKind]::Utc) }
        }
    }
    $s = [string]$v
    if ([string]::IsNullOrWhiteSpace($s)) { return $null }
    try {
        return [datetime]::Parse($s,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
            [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    } catch { return $null }
}

function Get-ReportDateFromName([string]$fileName) {
    # Leading YYYY-MM-DD filename prefix, else $null ("unknown"). Never invent.
    if ($fileName -match '^(\d{4}-\d{2}-\d{2})') {
        try {
            return [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd',
                [System.Globalization.CultureInfo]::InvariantCulture)
        } catch { return $null }
    }
    return $null
}

# ------------------------------------------------------------------ parsing --
function Get-UniqueOrdered([string[]]$items) {
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($i in $items) { if ($seen.Add($i)) { $out.Add($i) } }
    return @($out)
}

function Find-MdLinks([string]$text) {
    # Relative .md links only; external and anchor-only links are ignored.
    $links = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($text, $script:MD_LINK_REGEX)) {
        $t = $m.Groups['target'].Value
        if ($t -match '^[a-z][a-z0-9+.-]*://') { continue }   # scheme -> external
        if ($t.StartsWith('#')) { continue }
        $t = ($t -split '#', 2)[0]
        if ($t -notmatch '\.md$') { continue }
        $links.Add($t)
    }
    return @($links)
}

function Find-BeadIds([string]$text) {
    $ids = foreach ($m in [regex]::Matches($text, $script:BEAD_ID_REGEX)) { $m.Value }
    return @(Get-UniqueOrdered @($ids))
}

function Parse-ActiveThreads([string[]]$lines) {
    # Each H3 beneath '## Active threads' is one authored thread, ending at the
    # next H3 or H2. Returns @() on malformed structure (caller decides fate).
    $threads = [System.Collections.Generic.List[object]]::new()
    $inSection = $false
    $current = $null
    $inFence = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^```') { $inFence = -not $inFence }
        if (-not $inFence) {
            if ($line -match $script:ACTIVE_HEADING) { $inSection = $true; continue }
            if (-not $inSection) { continue }
            if ($line -match '^##\s' -and $line -notmatch '^###') { break }  # next H2 ends section
            if ($line -match '^###\s+(.+?)\s*$') {
                $current = [pscustomobject]@{
                    Title = $Matches[1]
                    Lines = [System.Collections.Generic.List[string]]::new()
                }
                $threads.Add($current)
                continue
            }
        } elseif (-not $inSection) { continue }
        if ($null -ne $current) { $current.Lines.Add($line) }
    }
    return @($threads)
}

function Resolve-ReportLink {
    # Validate a relative report link without following paths outside the repo.
    param([string]$target, [string]$baseDir, [string]$repoRootFull)
    $result = [ordered]@{ target = $target; in_repo = $false; resolved = $false; full = $null }
    if ([System.IO.Path]::IsPathRooted($target) -or $target -match '^[A-Za-z]:') {
        return [pscustomobject]$result   # absolute paths are out-of-contract
    }
    try {
        $full = [System.IO.Path]::GetFullPath((Join-Path $baseDir $target))
    } catch { return [pscustomobject]$result }
    $rootWithSep = $repoRootFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar) +
                   [System.IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($rootWithSep, [System.StringComparison]::Ordinal)) {
        return [pscustomobject]$result   # traversal outside the repo: rejected
    }
    $result.in_repo = $true
    $result.full = $full
    $result.resolved = (Test-Path -LiteralPath $full -PathType Leaf)
    return [pscustomobject]$result
}

# ---------------------------------------------------------------- bd access --
function Get-BeadSnapshot {
    <#
        Hydrate unique bead IDs. Read-only, single batched call where
        supported; bounded per-ID fallback otherwise. Never mutates.
        Returns @{ Beads = <id->object map>; Errors = @(strings) }.
    #>
    param([string[]]$ids, [string]$bdJsonPath)

    $map = [ordered]@{}
    $errors = @()
    if ($ids.Count -eq 0) { return @{ Beads = $map; Errors = $errors } }

    $raw = $null
    if ($bdJsonPath) {
        if (-not (Test-Path -LiteralPath $bdJsonPath -PathType Leaf)) {
            return @{ Beads = $map; Errors = @("bd fixture not found: $bdJsonPath") }
        }
        $raw = Get-Content -LiteralPath $bdJsonPath -Raw
    } else {
        $bdExe = if ($env:REPORT_ROOM_BD_EXE) { $env:REPORT_ROOM_BD_EXE } else { 'bd' }
        if (-not (Get-Command $bdExe -ErrorAction SilentlyContinue)) {
            return @{ Beads = $map; Errors = @("required command '$bdExe' is not available on PATH; install beads or pass -BdJsonPath") }
        }
        # Single batched read-only call (never a mutating command, never bd serve).
        $stdout = & $bdExe show @ids --json 2>$null
        $exit = $LASTEXITCODE
        $raw = ($stdout | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($raw) -and $exit -ne 0) {
            # Batched form failed outright: bounded per-ID fallback.
            if ($ids.Count -gt $script:MAX_FALLBACK_BD_CALLS) {
                return @{ Beads = $map; Errors = @("batched 'bd show --json' failed and $($ids.Count) IDs exceed the fallback cap of $($script:MAX_FALLBACK_BD_CALLS)") }
            }
            $parts = [System.Collections.Generic.List[string]]::new()
            foreach ($id in $ids) {
                $one = (& $bdExe show $id --json 2>$null | Out-String).Trim()
                if ($LASTEXITCODE -eq 0 -and $one) { $parts.Add($one) }
            }
            if ($parts.Count -eq 0) { return @{ Beads = $map; Errors = $errors } }
            $raw = '[' + (($parts | ForEach-Object { $_.TrimStart('[').TrimEnd(']') }) -join ',') + ']'
        }
    }

    if ([string]::IsNullOrWhiteSpace($raw)) { return @{ Beads = $map; Errors = $errors } }
    try {
        $parsed = ConvertFrom-Json -InputObject $raw
    } catch {
        return @{ Beads = $map; Errors = @("bead JSON is invalid: $($_.Exception.Message)") }
    }
    if ($parsed -is [pscustomobject] -and (Get-Field $parsed 'error')) {
        # bd's "no issues found" object: every requested ID is unresolved.
        return @{ Beads = $map; Errors = $errors }
    }
    foreach ($b in @($parsed)) {
        $id = Get-Field $b 'id'
        if ($id) { $map[$id] = $b }
    }
    return @{ Beads = $map; Errors = $errors }
}

# ---------------------------------------------------------------- age facts --
function Get-ThreadAgeFacts {
    # Exact, labeled facts. 'unknown' rather than an invented date.
    param($thread, $linkInfoByTarget, $beadMap, [datetime]$nowUtc)

    $dates = @()
    foreach ($t in $thread.ReportLinks) {
        $d = Get-ReportDateFromName ([System.IO.Path]::GetFileName($t))
        if ($null -ne $d) { $dates += $d }
    }
    $oldestReport = if ($dates.Count) { ($dates | Sort-Object)[0] } else { $null }
    $newestReport = if ($dates.Count) { ($dates | Sort-Object)[-1] } else { $null }
    $span = if ($null -ne $oldestReport -and $null -ne $newestReport) {
        [int]($newestReport - $oldestReport).TotalDays
    } else { $null }

    $activeStatuses = @('open', 'in_progress', 'deferred')
    $oldestActive = $null; $oldestActiveCreated = $null
    $stalest = $null;      $stalestUpdated = $null
    foreach ($id in $thread.BeadIds) {
        if (-not $beadMap.Contains($id)) { continue }
        $b = $beadMap[$id]
        $status = [string](Get-Field $b 'status' '')
        $created = Parse-BdTimestamp (Get-Field $b 'created_at')
        $updated = Parse-BdTimestamp (Get-Field $b 'updated_at')
        if ($activeStatuses -contains $status -and $null -ne $created) {
            if ($null -eq $oldestActiveCreated -or $created -lt $oldestActiveCreated) {
                $oldestActiveCreated = $created; $oldestActive = $id
            }
        }
        if ($status -ne 'closed' -and $null -ne $updated) {
            if ($null -eq $stalestUpdated -or $updated -lt $stalestUpdated) {
                $stalestUpdated = $updated; $stalest = $id
            }
        }
    }

    return [ordered]@{
        oldest_report_date = if ($oldestReport) { $oldestReport.ToString('yyyy-MM-dd') } else { 'unknown' }
        newest_report_date = if ($newestReport) { $newestReport.ToString('yyyy-MM-dd') } else { 'unknown' }
        report_span_days   = if ($null -ne $span) { $span } else { 'unknown' }
        oldest_active_bead = if ($oldestActive) {
            [ordered]@{
                id         = $oldestActive
                created_at = $oldestActiveCreated.ToString('yyyy-MM-ddTHH:mm:ssZ')
                age_days   = [int][math]::Floor(($nowUtc - $oldestActiveCreated).TotalDays)
            }
        } else { $null }
        stalest_bead = if ($stalest) {
            [ordered]@{
                id                = $stalest
                updated_at        = $stalestUpdated.ToString('yyyy-MM-ddTHH:mm:ssZ')
                days_since_update = [int][math]::Floor(($nowUtc - $stalestUpdated).TotalDays)
            }
        } else { $null }
    }
}

function Get-AgeEmphasisClass($days) {
    if ($days -isnot [int]) { return '' }
    if ($days -ge $script:AGE_EMPHASIS_STRONG_DAYS) { return 'age-strong' }
    if ($days -ge $script:AGE_EMPHASIS_SOFT_DAYS)   { return 'age-soft' }
    return ''
}

# ------------------------------------------------------------ core analysis --
function Get-Analysis {
    <#
        Shared by open and check. Parses the source, validates links, hydrates
        beads, computes age facts. Returns a rich state object; never mutates
        reports or Beads.
    #>
    param([string]$repoRootFull, [string]$bdJsonPath)

    $state = [ordered]@{
        SourcePath = Join-Path $repoRootFull 'reports/README.md'
        Lines = $null; Threads = @(); AllLinks = @(); LinkInfo = [ordered]@{}
        BeadIds = @(); BeadMap = [ordered]@{}; BeadSource = $null
        UnthreadedSinceLatest = @()
        Errors = [System.Collections.Generic.List[object]]::new()
        Warnings = [System.Collections.Generic.List[object]]::new()
        NowUtc = [datetime]::UtcNow
    }

    if (-not (Test-Path -LiteralPath $state.SourcePath -PathType Leaf)) {
        $state.Errors.Add([ordered]@{ code = 'source_missing'; message = "source not found: $($state.SourcePath)" })
        return $state
    }
    $state.Lines = @([string[]](Get-Content -LiteralPath $state.SourcePath))

    # Threads
    $threadsRaw = @(Parse-ActiveThreads $state.Lines)
    if ($threadsRaw.Count -eq 0) {
        $state.Errors.Add([ordered]@{ code = 'malformed_source'; message = "no H3 threads found under '## Active threads' in $($state.SourcePath)" })
        return $state
    }
    $threads = foreach ($t in $threadsRaw) {
        $body = ($t.Lines -join "`n")
        [pscustomobject]@{
            Title       = $t.Title
            ReportLinks = @(Get-UniqueOrdered (Find-MdLinks $body))
            BeadIds     = @(Find-BeadIds $body)
        }
    }
    $state.Threads = @($threads)

    # Whole-file link validation (threads plus every other section)
    $reportsDir = Join-Path $repoRootFull 'reports'
    $allTargets = @(Get-UniqueOrdered (Find-MdLinks ($state.Lines -join "`n")))
    $state.AllLinks = $allTargets
    foreach ($t in $allTargets) {
        $info = Resolve-ReportLink -target $t -baseDir $reportsDir -repoRootFull $repoRootFull
        $state.LinkInfo[$t] = $info
        if (-not $info.in_repo) {
            $state.Errors.Add([ordered]@{ code = 'link_outside_repo'; message = "link traverses outside the repo: $t" })
        } elseif (-not $info.resolved) {
            $state.Errors.Add([ordered]@{ code = 'link_missing'; message = "linked report not found: $t" })
        }
    }

    # Beads: unique IDs across all threads, one batched read
    $state.BeadIds = @(Get-UniqueOrdered @($threads | ForEach-Object { $_.BeadIds }))
    $state.BeadSource = if ($bdJsonPath) { 'fixture' } else { 'bd' }
    $snap = Get-BeadSnapshot -ids $state.BeadIds -bdJsonPath $bdJsonPath
    $state.BeadMap = $snap.Beads
    foreach ($e in $snap.Errors) {
        $code = if ($e -match 'invalid') { 'bd_json_invalid' } else { 'bd_unavailable' }
        $state.Errors.Add([ordered]@{ code = $code; message = $e })
    }
    foreach ($id in $state.BeadIds) {
        if (-not $state.BeadMap.Contains($id)) {
            $state.Warnings.Add([ordered]@{ code = 'bead_unresolved'; message = "bead ID not found in Beads: $id" })
        } elseif ((Get-Field $state.BeadMap[$id] 'status') -eq 'closed') {
            $state.Warnings.Add([ordered]@{ code = 'bead_closed'; message = "referenced bead is closed: $id" })
        }
    }

    # Reports newer than the newest thread-linked report (informational)
    $threadDates = @()
    foreach ($t in $threads) {
        foreach ($l in $t.ReportLinks) {
            $d = Get-ReportDateFromName ([System.IO.Path]::GetFileName($l))
            if ($null -ne $d) { $threadDates += $d }
        }
    }
    if ($threadDates.Count -and (Test-Path -LiteralPath $reportsDir)) {
        $newest = ($threadDates | Sort-Object)[-1]
        $unthreaded = foreach ($f in (Get-ChildItem -LiteralPath $reportsDir -Filter '*.md' -File)) {
            if ($f.Name -eq 'README.md') { continue }
            $d = Get-ReportDateFromName $f.Name
            if ($null -ne $d -and $d -gt $newest) { $f.Name }
        }
        $state.UnthreadedSinceLatest = @($unthreaded | Sort-Object)
    }

    return $state
}

# ---------------------------------------------------------------- rendering --
function Convert-InlineMd {
    <#
        Minimal inline converter for the constrained subset present in the
        source: HTML-escape first, then markdown links (placeholder-protected),
        bead-ID same-page links, code spans, bold, italic. Not a general
        Markdown parser.

        Markdown links run before bead-ID linkification, and each generated
        <a> is swapped for an opaque placeholder until the very end, so a
        link whose target or label happens to contain a bead ID never has its
        syntax mangled by the bead-ID pass.
    #>
    param([string]$text, $linkInfo, $cardIds)

    $t = HtmlEnc $text

    # Markdown links; relative .md links become absolute file:// URIs. Only
    # '#'-anchors and resolved file:// hrefs are emitted; any other target
    # (javascript:, unresolved traversal, etc.) renders as plain text.
    $linkPlaceholders = [System.Collections.Generic.List[string]]::new()
    $t = [regex]::Replace($t, $script:MD_LINK_REGEX, {
        param($m)
        $target = $m.Groups['target'].Value
        $label = $m.Groups['text'].Value
        $bare = ($target -split '#', 2)[0]
        $href = $null
        if ($target.StartsWith('#')) {
            $href = $target
        } elseif ($linkInfo.Contains($bare)) {
            $info = $linkInfo[$bare]
            # [uri]::new, not a [uri] cast: the cast yields a relative URI for
            # Unix absolute paths, whose AbsoluteUri silently evaluates empty.
            if ($info.in_repo -and $info.resolved) { $href = [uri]::new($info.full).AbsoluteUri }
        }
        $rendered = if ($null -ne $href) { "<a href=""$href"">$label</a>" } else { $label }
        $idx = $linkPlaceholders.Count
        $linkPlaceholders.Add($rendered)
        "`0LINK$idx`0"
    })

    # Same-page bead links (only IDs that have an embedded card)
    $t = [regex]::Replace($t, $script:BEAD_ID_REGEX, {
        param($m)
        if ($cardIds.Contains($m.Value)) {
            "<a class=""bead-ref"" href=""#bead-$($m.Value)"">$($m.Value)</a>"
        } else { $m.Value }
    })
    # Code spans
    $t = [regex]::Replace($t, '`([^`]+)`', '<code>$1</code>')
    $t = [regex]::Replace($t, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    $t = [regex]::Replace($t, '(?<![\w*])\*([^*\r\n]+?)\*(?![\w*])', '<em>$1</em>')

    # Restore protected links last so nothing above can touch their markup.
    $t = [regex]::Replace($t, "`0LINK(\d+)`0", {
        param($m)
        $linkPlaceholders[[int]$m.Groups[1].Value]
    })
    return $t
}

function Convert-SourceToHtmlBody {
    # Line-oriented converter for the source's constrained block subset:
    # headings, blockquotes, tables, ul/ol lists with continuations, code
    # fences, paragraphs. Unknown constructs degrade to escaped paragraphs.
    param([string[]]$lines, $linkInfo, $cardIds, $ageBlocks)

    $out = [System.Text.StringBuilder]::new()
    $para = [System.Collections.Generic.List[string]]::new()
    $inActive = $false
    $activeH3Index = 0

    $flushPara = {
        if ($para.Count) {
            [void]$out.AppendLine('<p>' + (Convert-InlineMd ($para -join ' ') $linkInfo $cardIds) + '</p>')
            $para.Clear()
        }
    }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^```') {                       # code fence
            & $flushPara
            $code = [System.Collections.Generic.List[string]]::new()
            $i++
            while ($i -lt $lines.Count -and $lines[$i] -notmatch '^```') { $code.Add($lines[$i]); $i++ }
            [void]$out.AppendLine('<pre><code>' + (HtmlEnc ($code -join "`n")) + '</code></pre>')
            continue
        }
        if ($line -match '^(#{1,3})\s+(.+?)\s*$') {      # headings
            & $flushPara
            $level = $Matches[1].Length
            $title = $Matches[2]
            if ($level -eq 2) { $inActive = ($line -match $script:ACTIVE_HEADING) }
            [void]$out.AppendLine("<h$level>" + (Convert-InlineMd $title $linkInfo $cardIds) + "</h$level>")
            if ($level -eq 3 -and $inActive) {
                # Indexed by ordinal (thread order), not title: duplicate H3
                # titles must not collide in the age-facts lookup.
                if ($activeH3Index -lt $ageBlocks.Count) {
                    [void]$out.AppendLine($ageBlocks[$activeH3Index])
                }
                $activeH3Index++
            }
            continue
        }
        if ($line -match '^>\s?(.*)$') {                 # blockquote
            & $flushPara
            $quote = [System.Collections.Generic.List[string]]::new()
            while ($i -lt $lines.Count -and $lines[$i] -match '^>\s?(.*)$') {
                $quote.Add($Matches[1]); $i++
            }
            $i--
            [void]$out.AppendLine('<blockquote><p>' + (Convert-InlineMd (($quote | Where-Object { $_ }) -join ' ') $linkInfo $cardIds) + '</p></blockquote>')
            continue
        }
        if ($line -match '^\|') {                        # table
            & $flushPara
            $rows = [System.Collections.Generic.List[string]]::new()
            while ($i -lt $lines.Count -and $lines[$i] -match '^\|') { $rows.Add($lines[$i]); $i++ }
            $i--
            [void]$out.AppendLine('<div class="tablewrap"><table>')
            $rowIdx = 0
            foreach ($row in $rows) {
                if ($row -match '^\|[\s\-:|]+\|$') { continue }   # separator
                $cells = @(($row.Trim('|') -split '\|') | ForEach-Object { $_.Trim() })
                $tag = if ($rowIdx -eq 0) { 'th' } else { 'td' }
                $tr = ($cells | ForEach-Object { "<$tag>" + (Convert-InlineMd $_ $linkInfo $cardIds) + "</$tag>" }) -join ''
                [void]$out.AppendLine("<tr>$tr</tr>")
                $rowIdx++
            }
            [void]$out.AppendLine('</table></div>')
            continue
        }
        if ($line -match '^(\s*)([-*]|\d+\.)\s+(.+)$') { # list (ul or ol)
            & $flushPara
            $ordered = $Matches[2] -match '^\d'
            $tag = if ($ordered) { 'ol' } else { 'ul' }
            $items = [System.Collections.Generic.List[string]]::new()
            $current = $Matches[3]
            $i++
            while ($i -lt $lines.Count) {
                $l = $lines[$i]
                if ($l -match '^(\s*)([-*]|\d+\.)\s+(.+)$') { $items.Add($current); $current = $Matches[3]; $i++ }
                elseif ($l -match '^\s+\S') { $current += ' ' + $l.Trim(); $i++ }   # continuation
                else { break }
            }
            $i--
            $items.Add($current)
            [void]$out.AppendLine("<$tag>")
            foreach ($it in $items) {
                [void]$out.AppendLine('<li>' + (Convert-InlineMd $it $linkInfo $cardIds) + '</li>')
            }
            [void]$out.AppendLine("</$tag>")
            continue
        }
        if ([string]::IsNullOrWhiteSpace($line)) { & $flushPara; continue }
        $para.Add($line.Trim())
    }
    & $flushPara
    return $out.ToString()
}

function New-AgeFactsHtml {
    param($age)
    $rows = [System.Text.StringBuilder]::new()
    [void]$rows.Append("<span class=""fact""><b>oldest report</b> $(HtmlEnc $age.oldest_report_date)</span>")
    [void]$rows.Append("<span class=""fact""><b>newest report</b> $(HtmlEnc $age.newest_report_date)</span>")
    $spanCls = Get-AgeEmphasisClass $age.report_span_days
    [void]$rows.Append("<span class=""fact $spanCls""><b>span</b> $(HtmlEnc ([string]$age.report_span_days)) days</span>")
    if ($age.oldest_active_bead) {
        $b = $age.oldest_active_bead
        $cls = Get-AgeEmphasisClass $b.age_days
        [void]$rows.Append("<span class=""fact $cls""><b>oldest active bead</b> <a class=""bead-ref"" href=""#bead-$($b.id)"">$($b.id)</a> $($b.age_days) days old</span>")
    } else {
        [void]$rows.Append('<span class="fact"><b>oldest active bead</b> none resolved</span>')
    }
    if ($age.stalest_bead) {
        $b = $age.stalest_bead
        $cls = Get-AgeEmphasisClass $b.days_since_update
        [void]$rows.Append("<span class=""fact $cls""><b>stalest bead</b> <a class=""bead-ref"" href=""#bead-$($b.id)"">$($b.id)</a> updated $($b.days_since_update) days ago</span>")
    } else {
        [void]$rows.Append('<span class="fact"><b>stalest bead</b> none resolved</span>')
    }
    return '<div class="agefacts" title="Exact facts from filenames and Beads timestamps. Age does not claim priority, neglect, or misunderstanding.">' +
           $rows.ToString() + '</div>'
}

function New-BeadCardHtml {
    param([string]$id, $bead, $cardIds, [string]$snapshotStamp)

    if ($null -eq $bead) {
        return @"
<section class="bead-card status-missing" id="bead-$id">
<h3><code>$(HtmlEnc $id)</code> <span class="badge badge-missing">not found</span></h3>
<p>Not found in Beads at snapshot time ($(HtmlEnc $snapshotStamp)). It may be renamed, deleted, or from another database.</p>
</section>
"@
    }

    $status = [string](Get-Field $bead 'status' 'unknown')
    $fields = [ordered]@{
        status   = $status
        priority = [string](Get-Field $bead 'priority' '')
        type     = [string](Get-Field $bead 'issue_type' '')
        assignee = [string](Get-Field $bead 'assignee' '')
        created  = & { $d = Parse-BdTimestamp (Get-Field $bead 'created_at')
                       if ($d) { $d.ToString('yyyy-MM-ddTHH:mm:ssZ') } else { '' } }
        updated  = & { $d = Parse-BdTimestamp (Get-Field $bead 'updated_at')
                       if ($d) { $d.ToString('yyyy-MM-ddTHH:mm:ssZ') } else { '' } }
        labels   = (@(Get-Field $bead 'labels' @()) -join ', ')
    }
    $dl = ($fields.GetEnumerator() | ForEach-Object {
        "<dt>$(HtmlEnc $_.Key)</dt><dd>$(HtmlEnc $_.Value)</dd>"
    }) -join ''

    $longs = [System.Text.StringBuilder]::new()
    $longMap = [ordered]@{
        'Description'         = Get-Field $bead 'description'
        'Acceptance criteria' = Get-Field $bead 'acceptance_criteria'
        'Design'              = Get-Field $bead 'design'
        'Notes'               = Get-Field $bead 'notes'
    }
    $first = $true
    foreach ($k in $longMap.Keys) {
        $v = $longMap[$k]
        if ([string]::IsNullOrWhiteSpace([string]$v)) { continue }
        $open = if ($first) { ' open' } else { '' }
        $first = $false
        [void]$longs.AppendLine("<details$open><summary>$(HtmlEnc $k)</summary><pre class=""field"">$(HtmlEnc ([string]$v))</pre></details>")
    }

    # Dependency identities from the payload; dependents/children reconstructed
    # within this snapshot (counts shown for anything outside it).
    $deps = @(Get-Field $bead 'dependencies' @())
    $depHtml = if ($deps.Count) {
        ($deps | ForEach-Object {
            $did = [string](Get-Field $_ 'id' '?')
            if ($cardIds.Contains($did)) { "<a class=""bead-ref"" href=""#bead-$did"">$(HtmlEnc $did)</a>" }
            else { "<code>$(HtmlEnc $did)</code>" }
        }) -join ', '
    } else { 'none' }
    $depCount = [string](Get-Field $bead 'dependency_count' '0')
    $dependentCount = [string](Get-Field $bead 'dependent_count' '0')
    $children = @($cardIds | Where-Object { $_ -like "$id.*" })
    $childHtml = if ($children.Count) {
        ($children | ForEach-Object { "<a class=""bead-ref"" href=""#bead-$_"">$(HtmlEnc $_)</a>" }) -join ', '
    } else { 'none in snapshot' }

    $badgeCls = switch ($status) {
        'closed' { 'badge-closed' } 'in_progress' { 'badge-active' } default { 'badge-open' }
    }
    return @"
<section class="bead-card status-$(HtmlEnc $status)" id="bead-$id">
<h3><code>$(HtmlEnc $id)</code> $(HtmlEnc ([string](Get-Field $bead 'title' ''))) <span class="badge $badgeCls">$(HtmlEnc $status)</span></h3>
<dl>$dl</dl>
$($longs.ToString())
<p class="rel"><b>dependencies</b> ($(HtmlEnc $depCount)): $depHtml<br>
<b>dependents</b>: $(HtmlEnc $dependentCount) recorded<br>
<b>children</b>: $childHtml</p>
<p class="stamp">snapshot $(HtmlEnc $snapshotStamp)</p>
</section>
"@
}

function New-ReportRoomHtml {
    param($state)

    $snapshotStamp = $state.NowUtc.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $cardIds = [System.Collections.Generic.HashSet[string]]::new([string[]]$state.BeadIds)

    # Indexed by ordinal (thread order), not title: two threads may share an
    # authored H3 title and must not collide in the age-facts lookup. A plain
    # list (not a dictionary keyed by int) avoids OrderedDictionary's
    # positional-indexer ambiguity with integer keys.
    $ageBlocks = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $state.Threads) {
        $age = Get-ThreadAgeFacts -thread $t -linkInfoByTarget $state.LinkInfo -beadMap $state.BeadMap -nowUtc $state.NowUtc
        $ageBlocks.Add((New-AgeFactsHtml $age))
    }

    $body = Convert-SourceToHtmlBody -lines $state.Lines -linkInfo $state.LinkInfo -cardIds $cardIds -ageBlocks $ageBlocks

    $cards = [System.Text.StringBuilder]::new()
    foreach ($id in $state.BeadIds) {
        $bead = if ($state.BeadMap.Contains($id)) { $state.BeadMap[$id] } else { $null }
        [void]$cards.AppendLine((New-BeadCardHtml -id $id -bead $bead -cardIds $cardIds -snapshotStamp $snapshotStamp))
    }

    # Self-contained and offline: inline CSS only, no scripts, no remote assets,
    # no telemetry. Bead links are same-page anchors; :target does the focus.
    return @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>report reading room — snapshot $(HtmlEnc $snapshotStamp)</title>
<style>
:root { --fg:#1a1a1a; --bg:#ffffff; --muted:#666; --line:#ddd; --accent:#0b5394;
        --soft:#fff3cd; --strong:#f8d7da; --card:#f8f9fa; }
@media (prefers-color-scheme: dark) {
  :root { --fg:#e6e6e6; --bg:#1e1e1e; --muted:#9a9a9a; --line:#444; --accent:#7ab3e0;
          --soft:#4a3f1e; --strong:#5a2a2e; --card:#2a2a2a; }
}
body { color:var(--fg); background:var(--bg); font:16px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif;
       max-width:56rem; margin:2rem auto; padding:0 1rem; }
h1,h2,h3 { line-height:1.25; } h2 { border-bottom:1px solid var(--line); padding-bottom:.3rem; margin-top:2.2rem; }
a { color:var(--accent); } code { background:var(--card); padding:.1em .3em; border-radius:3px; font-size:.92em; }
pre { background:var(--card); padding: .8em; border-radius:6px; overflow-x:auto; }
pre.field { white-space:pre-wrap; word-break:break-word; }
blockquote { border-left:4px solid var(--line); margin:1em 0; padding:.2em 1em; color:var(--muted); }
.tablewrap { overflow-x:auto; } table { border-collapse:collapse; width:100%; }
th,td { border:1px solid var(--line); padding:.4em .6em; text-align:left; vertical-align:top; }
.agefacts { background:var(--card); border:1px solid var(--line); border-radius:6px;
            padding:.5em .8em; margin:.5em 0 1em; font-size:.86em; display:flex; flex-wrap:wrap; gap:.4em 1.2em; }
.agefacts b { color:var(--muted); font-weight:600; margin-right:.35em; }
.fact.age-soft { background:var(--soft); border-radius:4px; padding:0 .35em; }
.fact.age-strong { background:var(--strong); border-radius:4px; padding:0 .35em; }
a.bead-ref { text-decoration:none; border-bottom:1px dashed var(--accent); }
.bead-card { border:1px solid var(--line); border-radius:8px; background:var(--card);
             padding: .2rem 1rem .8rem; margin:1rem 0; }
.bead-card:target { outline:3px solid var(--accent); }
.bead-card h3 { margin:.6rem 0; } .bead-card dl { display:grid; grid-template-columns:max-content 1fr;
             gap:.15em .8em; font-size:.9em; margin:.4rem 0; }
.bead-card dt { color:var(--muted); } .bead-card dd { margin:0; }
.badge { font-size:.72em; border-radius:999px; padding:.15em .6em; vertical-align:middle; }
.badge-open { background:#d4edda; color:#155724; } .badge-active { background:#cce5ff; color:#004085; }
.badge-closed { background:#e2e3e5; color:#383d41; } .badge-missing { background:var(--strong); }
.status-closed h3, .status-missing h3 { opacity:.75; }
.stamp { color:var(--muted); font-size:.8em; margin-bottom:0; }
.rel { font-size:.9em; }
.roomhdr { color:var(--muted); font-size:.85em; border-bottom:1px solid var(--line); padding-bottom:.5rem; }
</style>
</head>
<body>
<p class="roomhdr">report-room snapshot generated $(HtmlEnc $snapshotStamp) from
<code>$(HtmlEnc $state.SourcePath)</code> — disposable joined view; the Markdown source and Beads stay canonical.
Age emphasis thresholds: soft ≥ $($script:AGE_EMPHASIS_SOFT_DAYS) days, strong ≥ $($script:AGE_EMPHASIS_STRONG_DAYS) days (neutral emphasis only).</p>
$body
<h2 id="bead-snapshot">Bead snapshot</h2>
<p>Current read-only detail for every bead referenced by the active threads, captured at $(HtmlEnc $snapshotStamp). Closed and missing beads stay visible and marked.</p>
$($cards.ToString())
</body>
</html>
"@
}

# ----------------------------------------------------------------- commands --
function Invoke-Open {
    param([string]$repoRootFull, [string]$outputOverride, [switch]$noLaunch, [string]$bdJsonPath)

    $state = Get-Analysis -repoRootFull $repoRootFull -bdJsonPath $bdJsonPath
    if ($state.Errors.Count) {
        foreach ($e in $state.Errors) { Write-Error -ErrorAction Continue "report-room: [$($e.code)] $($e.message)" }
        exit 1
    }
    foreach ($w in $state.Warnings) { Write-Warning "report-room: [$($w.code)] $($w.message)" }

    # Output path: OS temp by default, never under reports/.
    $outPath = $null
    if ($outputOverride) {
        $outPath = [System.IO.Path]::GetFullPath($outputOverride)
        $reportsDir = [System.IO.Path]::GetFullPath((Join-Path $repoRootFull 'reports')) +
                      [System.IO.Path]::DirectorySeparatorChar
        if ($outPath.StartsWith($reportsDir, [System.StringComparison]::Ordinal)) {
            Write-Error -ErrorAction Continue "report-room: refusing to write generated HTML under reports/ ($outPath)"
            exit 1
        }
    } else {
        $stamp = [datetime]::UtcNow.ToString('yyyyMMdd-HHmmss')
        $rand = [System.IO.Path]::GetRandomFileName().Split('.')[0]
        $outPath = Join-Path ([System.IO.Path]::GetTempPath()) "report-room-$stamp-$rand.html"
    }

    $wrote = $false
    try {
        $html = New-ReportRoomHtml -state $state
        Set-Content -LiteralPath $outPath -Value $html -Encoding utf8 -NoNewline
        $wrote = $true
        if ($env:REPORT_ROOM_TEST_FAIL_RENDER -eq '1') {
            throw 'test-induced renderer failure (REPORT_ROOM_TEST_FAIL_RENDER=1)'
        }
    } catch {
        # Clean up partial temp output on failure.
        if ($wrote -and (Test-Path -LiteralPath $outPath)) {
            Remove-Item -LiteralPath $outPath -Force -ErrorAction SilentlyContinue
        }
        Write-Error -ErrorAction Continue "report-room: renderer failed: $($_.Exception.Message)"
        exit 1
    }

    if (-not $noLaunch) {
        try {
            Start-Process -FilePath $outPath   # default browser, cross-platform
        } catch {
            Write-Warning "report-room: could not launch a browser ($($_.Exception.Message)); open the file manually."
        }
    }
    Write-Output $outPath
    exit 0
}

function Invoke-Check {
    param([string]$repoRootFull, [switch]$asJson, [string]$bdJsonPath)

    $state = Get-Analysis -repoRootFull $repoRootFull -bdJsonPath $bdJsonPath

    $bdExe = if ($env:REPORT_ROOM_BD_EXE) { $env:REPORT_ROOM_BD_EXE } else { 'bd' }
    $bdAvailable = [bool](Get-Command $bdExe -ErrorAction SilentlyContinue)
    if (-not $bdAvailable -and -not $bdJsonPath -and
        -not ($state.Errors | Where-Object { $_.code -eq 'bd_unavailable' })) {
        $state.Errors.Add([ordered]@{ code = 'bd_unavailable'; message = "required command '$bdExe' is not available on PATH" })
    }

    $threadReports = foreach ($t in $state.Threads) {
        $age = Get-ThreadAgeFacts -thread $t -linkInfoByTarget $state.LinkInfo -beadMap $state.BeadMap -nowUtc $state.NowUtc
        $links = foreach ($l in $t.ReportLinks) {
            $info = if ($state.LinkInfo.Contains($l)) { $state.LinkInfo[$l] } else { $null }
            $d = Get-ReportDateFromName ([System.IO.Path]::GetFileName($l))
            [ordered]@{
                target   = $l
                date     = if ($d) { $d.ToString('yyyy-MM-dd') } else { 'unknown' }
                in_repo  = if ($info) { [bool]$info.in_repo } else { $false }
                resolved = if ($info) { [bool]$info.resolved } else { $false }
            }
        }
        [ordered]@{
            title               = $t.Title
            report_count        = $t.ReportLinks.Count
            report_links        = @($links)
            bead_count          = $t.BeadIds.Count
            bead_ids            = @($t.BeadIds)
            unresolved_bead_ids = @($t.BeadIds | Where-Object { -not $state.BeadMap.Contains($_) })
            closed_bead_ids     = @($t.BeadIds | Where-Object {
                $state.BeadMap.Contains($_) -and (Get-Field $state.BeadMap[$_] 'status') -eq 'closed' })
            age                 = $age
        }
    }

    $doc = [ordered]@{
        schema_version = 1
        generated_at   = $state.NowUtc.ToString('yyyy-MM-ddTHH:mm:ssZ')
        source         = $state.SourcePath
        repo_root      = $repoRootFull
        prerequisites  = [ordered]@{
            pwsh         = $PSVersionTable.PSVersion.ToString()
            bd_available = $bdAvailable
            bead_source  = if ($state.BeadSource) { $state.BeadSource } else { 'bd' }
            renderer     = $script:RENDERER_NAME
        }
        age_thresholds = [ordered]@{
            soft_days   = $script:AGE_EMPHASIS_SOFT_DAYS
            strong_days = $script:AGE_EMPHASIS_STRONG_DAYS
        }
        counts = [ordered]@{
            threads             = $state.Threads.Count
            unique_report_links = $state.AllLinks.Count
            unique_bead_ids     = $state.BeadIds.Count
        }
        threads                 = @($threadReports)
        unthreaded_since_latest = @($state.UnthreadedSinceLatest)
        errors                  = @($state.Errors)
        warnings                = @($state.Warnings)
    }

    if ($asJson) {
        Write-Output (ConvertTo-Json -InputObject $doc -Depth 10)
    } else {
        Write-Output "report-room check: $($state.SourcePath)"
        Write-Output ("  threads: {0}; unique report links: {1}; unique bead ids: {2}" -f
            $doc.counts.threads, $doc.counts.unique_report_links, $doc.counts.unique_bead_ids)
        foreach ($t in $threadReports) {
            $ageBits = "reports $($t.age.oldest_report_date)..$($t.age.newest_report_date) (span $($t.age.report_span_days)d)"
            if ($t.age.oldest_active_bead) { $ageBits += "; oldest active bead $($t.age.oldest_active_bead.id) $($t.age.oldest_active_bead.age_days)d" }
            if ($t.age.stalest_bead) { $ageBits += "; stalest $($t.age.stalest_bead.id) $($t.age.stalest_bead.days_since_update)d since update" }
            Write-Output ("  - {0}: {1} reports, {2} beads ({3} closed, {4} unresolved); {5}" -f
                $t.title, $t.report_count, $t.bead_count, $t.closed_bead_ids.Count, $t.unresolved_bead_ids.Count, $ageBits)
        }
        Write-Output ("  unthreaded since latest thread-linked report: {0}" -f $doc.unthreaded_since_latest.Count)
        foreach ($w in $state.Warnings) { Write-Output "  warning [$($w.code)] $($w.message)" }
        foreach ($e in $state.Errors)   { Write-Output "  error [$($e.code)] $($e.message)" }
        Write-Output ("  result: {0} error(s), {1} warning(s)" -f $state.Errors.Count, $state.Warnings.Count)
    }

    if ($state.Errors.Count) { exit 1 }
    exit 0
}

# ----------------------------------------------------------------- dispatch --
$usage = @'
usage: report-room.ps1 open  [-NoLaunch] [-Output <path>] [-RepoRoot <path>]
       report-room.ps1 check [-Json] [-RepoRoot <path>]
'@

if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }
try {
    $repoRootFull = (Resolve-Path -LiteralPath $RepoRoot).Path
} catch {
    Write-Error -ErrorAction Continue "report-room: repo root not found: $RepoRoot"
    exit 1
}

switch ($Command) {
    'open' {
        if ($Json) { Write-Error -ErrorAction Continue "report-room: -Json is only valid with 'check'`n$usage"; exit 2 }
        Invoke-Open -repoRootFull $repoRootFull -outputOverride $Output -noLaunch:$NoLaunch -bdJsonPath $BdJsonPath
    }
    'check' {
        if ($NoLaunch -or $Output) { Write-Error -ErrorAction Continue "report-room: -NoLaunch/-Output are only valid with 'open'`n$usage"; exit 2 }
        Invoke-Check -repoRootFull $repoRootFull -asJson:$Json -bdJsonPath $BdJsonPath
    }
    default {
        Write-Error -ErrorAction Continue "report-room: unknown or missing command '$Command'`n$usage"
        exit 2
    }
}
