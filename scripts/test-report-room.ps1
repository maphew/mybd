#!/usr/bin/env pwsh
#requires -Version 7.0
<#
.SYNOPSIS
    Plain-PowerShell test harness for scripts/report-room.ps1 (Pester is not
    available on this machine). Assert-style tests with a summary and nonzero
    exit on failure.

.DESCRIPTION
    Every test runs report-room.ps1 in a child pwsh process against fixture
    Markdown (a throwaway repo layout under the OS temp dir) and fixture bead
    JSON injected through the -BdJsonPath seam or a fake bd executable via
    REPORT_ROOM_BD_EXE. No test touches the live Beads database, mutates
    anything, or launches a browser (-NoLaunch everywhere).
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Pass = 0
$script:Fail = 0
$script:Failures = [System.Collections.Generic.List[string]]::new()

function Assert-True([bool]$cond, [string]$name) {
    if ($cond) { $script:Pass++; Write-Host "  ok  $name" }
    else {
        $script:Fail++; $script:Failures.Add($name)
        Write-Host "FAIL  $name" -ForegroundColor Red
    }
}
function Assert-Eq($actual, $expected, [string]$name) {
    $ok = ([string]$actual) -eq ([string]$expected)
    if (-not $ok) { $name += " (expected '$expected', got '$actual')" }
    Assert-True $ok $name
}

# ------------------------------------------------------------------- set up --
$pwshExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$scriptUnderTest = Join-Path $PSScriptRoot 'report-room.ps1'
$work = Join-Path ([System.IO.Path]::GetTempPath()) ('report-room-tests-' + [System.IO.Path]::GetRandomFileName().Split('.')[0])
New-Item -ItemType Directory -Path $work -Force | Out-Null

function Invoke-RR {
    # Run report-room.ps1 in a child process (its `exit` must not kill us).
    param([string[]]$Arguments, [hashtable]$EnvVars = @{})
    $saved = @{}
    foreach ($k in $EnvVars.Keys) {
        $saved[$k] = [Environment]::GetEnvironmentVariable($k)
        [Environment]::SetEnvironmentVariable($k, $EnvVars[$k])
    }
    try {
        $stderr = Join-Path $work 'last-stderr.txt'
        $out = & $pwshExe -NoProfile -File $scriptUnderTest @Arguments 2>$stderr
        return @{ Out = @($out); Exit = $LASTEXITCODE; Err = (Get-Content -Raw $stderr -ErrorAction SilentlyContinue) }
    } finally {
        foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) }
    }
}

function New-FixtureRepo {
    param([string]$name, [string]$readme, [string[]]$reportFiles = @())
    $root = Join-Path $work $name
    $reports = Join-Path $root 'reports'
    New-Item -ItemType Directory -Path $reports -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $reports 'README.md') -Value $readme -Encoding utf8
    foreach ($f in $reportFiles) {
        Set-Content -LiteralPath (Join-Path $reports $f) -Value "# $f" -Encoding utf8
    }
    return $root
}

# Main fixture: two threads, duplicate IDs, dated + undated links, injection
# attempts in both the Markdown source and (via JSON) bead fields.
$mainReadme = @'
# Fixture room

## Start here

Intro paragraph linking [the old report](2026-01-01-old.md).

## Active threads

### Thread one

**Read:**

- [Old report](2026-01-01-old.md)
- [New report](2026-03-01-new.md)

**Questions now:** something about `mybd-aaa` and mybd-aaa again (dedupe test).

**Live Beads context:** `mybd-aaa`, `mybd-bbb` and `mybd-ccc`.

### Thread two <script>alert('md')</script>

Prose with [undated notes](undated-notes.md) and injection <img src=x onerror=alert(1)>.

**Live Beads context:** `mybd-bbb`.

## Not a thread

This H2 section mentions mybd-zzz and must not become a thread.
'@
$mainRoot = New-FixtureRepo 'main' $mainReadme @(
    '2026-01-01-old.md', '2026-03-01-new.md', 'undated-notes.md', '2026-05-05-unthreaded.md')

$fixtureJson = Join-Path $work 'beads.json'
@'
[
  {"id":"mybd-aaa","title":"Fixture A <script>alert('bd')</script>","status":"open",
   "priority":1,"issue_type":"task","assignee":"maphew",
   "created_at":"2026-01-10T00:00:00Z","updated_at":"2026-02-01T00:00:00Z",
   "labels":["x"],"description":"Desc with <b>html</b> & ampersand",
   "acceptance_criteria":"ac","notes":"n",
   "dependencies":[{"id":"mybd-bbb","title":"Fixture B"}],
   "dependency_count":1,"dependent_count":0},
  {"id":"mybd-bbb","title":"Fixture B","status":"closed","priority":2,
   "issue_type":"bug","created_at":"2026-01-05T00:00:00Z","updated_at":"2026-01-20T00:00:00Z"}
]
'@ | Set-Content -LiteralPath $fixtureJson -Encoding utf8

# ================================================================== check ====
Write-Host "== check -Json: thread parsing, dedupe, ages, closed/missing =="
$r = Invoke-RR @('check', '-Json', '-RepoRoot', $mainRoot, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 0 'check -Json exits 0 on healthy fixture'
$doc = $null
try { $doc = ($r.Out -join "`n") | ConvertFrom-Json } catch { }
Assert-True ($null -ne $doc) 'check -Json emits parseable JSON'

if ($null -ne $doc) {
    foreach ($k in 'schema_version','generated_at','source','prerequisites','threads','errors','warnings') {
        Assert-True ($null -ne $doc.PSObject.Properties[$k]) "schema contains '$k'"
    }
    Assert-Eq $doc.threads.Count 2 'exactly two threads parsed (H2 ends the section)'
    $t1 = $doc.threads[0]; $t2 = $doc.threads[1]
    Assert-Eq $t1.title 'Thread one' 'thread 1 title preserved'
    Assert-Eq ($t1.bead_ids -join ',') 'mybd-aaa,mybd-bbb,mybd-ccc' 'thread 1 bead IDs de-duplicated in authored order'
    Assert-Eq ($t2.bead_ids -join ',') 'mybd-bbb' 'thread 2 bead IDs'
    Assert-True ($doc.threads.title -notcontains 'Not a thread') 'H2 sections never become threads'
    Assert-Eq $t1.report_count 2 'thread 1 report link count'
    Assert-Eq $doc.counts.unique_report_links 3 'whole-file unique report link count'

    # age facts
    Assert-Eq $t1.age.oldest_report_date '2026-01-01' 'oldest report date from filename'
    Assert-Eq $t1.age.newest_report_date '2026-03-01' 'newest report date from filename'
    Assert-Eq $t1.age.report_span_days 59 'report span in days'
    Assert-Eq $t2.age.oldest_report_date 'unknown' 'undated filename yields unknown, never invented'
    Assert-Eq $t2.age.report_span_days 'unknown' 'span unknown without dated reports'
    Assert-Eq $t1.age.oldest_active_bead.id 'mybd-aaa' 'oldest active bead (closed bbb excluded)'
    $expectedAge = [int][math]::Floor(([datetime]::UtcNow - [datetime]::Parse('2026-01-10T00:00:00Z').ToUniversalTime()).TotalDays)
    Assert-True ([math]::Abs($t1.age.oldest_active_bead.age_days - $expectedAge) -le 1) 'oldest active bead age in days is exact'
    Assert-Eq $t1.age.stalest_bead.id 'mybd-aaa' 'stalest non-closed bead'
    $reported = [datetime]::Parse([string]$t1.age.oldest_active_bead.created_at,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
        [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    $expectedUtc = [datetime]::new(2026, 1, 10, 0, 0, 0, [System.DateTimeKind]::Utc)
    Assert-Eq $reported.Ticks $expectedUtc.Ticks 'bead timestamps stay UTC (no local-time drift)'

    # closed / missing beads
    Assert-Eq ($t1.closed_bead_ids -join ',') 'mybd-bbb' 'closed bead reported'
    Assert-Eq ($t1.unresolved_bead_ids -join ',') 'mybd-ccc' 'missing bead reported as unresolved'
    Assert-True (@($doc.warnings | Where-Object code -eq 'bead_unresolved').Count -ge 1) 'unresolved bead is a warning, not an error'
    Assert-True (@($doc.warnings | Where-Object code -eq 'bead_closed').Count -ge 1) 'closed bead is a warning'
    Assert-Eq $doc.errors.Count 0 'healthy fixture has zero errors'
    Assert-Eq ($doc.unthreaded_since_latest -join ',') '2026-05-05-unthreaded.md' 'unthreaded_since_latest lists newer report (informational)'
    Assert-Eq $doc.prerequisites.bead_source 'fixture' 'prerequisites record the fixture bead source'
}

Write-Host "== check: link failures are errors and exit nonzero =="
$badLinks = New-FixtureRepo 'badlinks' @'
## Active threads

### T

[gone](nope.md) and [escape](../../outside.md) with `mybd-aaa`.
'@
Set-Content -LiteralPath (Join-Path $work 'outside.md') -Value 'outside' -Encoding utf8
$r = Invoke-RR @('check', '-Json', '-RepoRoot', $badLinks, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 1 'missing/traversing links exit 1'
$doc = ($r.Out -join "`n") | ConvertFrom-Json
Assert-True (@($doc.errors | Where-Object code -eq 'link_missing').Count -eq 1) 'missing link reported as error'
Assert-True (@($doc.errors | Where-Object code -eq 'link_outside_repo').Count -eq 1) 'out-of-repo traversal rejected even though the file exists'

Write-Host "== check: malformed source and missing prerequisites =="
$noThreads = New-FixtureRepo 'nothreads' "# Just prose`n`nNo active threads heading."
$r = Invoke-RR @('check', '-Json', '-RepoRoot', $noThreads, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 1 'source without threads is malformed: exit 1'
$doc = $null
try { $doc = ($r.Out -join "`n") | ConvertFrom-Json } catch { }
Assert-True ($null -ne $doc) 'malformed_source (missing heading) still emits parseable JSON, does not crash'
if ($null -ne $doc) {
    Assert-True (@($doc.errors | Where-Object code -eq 'malformed_source').Count -eq 1) 'malformed source (missing heading) reports code malformed_source'
}

$emptyReadme = New-FixtureRepo 'emptyreadme' ''
$r = Invoke-RR @('check', '-Json', '-RepoRoot', $emptyReadme, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 1 'empty README.md exits 1 (malformed), not a crash'
$doc = $null
try { $doc = ($r.Out -join "`n") | ConvertFrom-Json } catch { }
Assert-True ($null -ne $doc) 'empty README.md still emits parseable JSON, does not crash'
if ($null -ne $doc) {
    Assert-True (@($doc.errors | Where-Object code -eq 'malformed_source').Count -eq 1) 'empty README.md reports code malformed_source'
}

$r = Invoke-RR @('check', '-RepoRoot', (Join-Path $work 'does-not-exist-root'))
Assert-Eq $r.Exit 1 'nonexistent repo root exits 1'
$emptyRoot = Join-Path $work 'emptyroot'
New-Item -ItemType Directory -Path $emptyRoot -Force | Out-Null
$r = Invoke-RR @('check', '-RepoRoot', $emptyRoot, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 1 'missing reports/README.md exits 1'
$r = Invoke-RR @('check', '-Json', '-RepoRoot', $mainRoot) @{ REPORT_ROOM_BD_EXE = 'report-room-no-such-bd' }
Assert-Eq $r.Exit 1 'unavailable bd is a failed prerequisite: exit 1'
$doc = ($r.Out -join "`n") | ConvertFrom-Json
Assert-True (@($doc.errors | Where-Object code -eq 'bd_unavailable').Count -ge 1) 'bd unavailability reported in errors'
Assert-Eq $doc.prerequisites.bd_available 'False' 'prerequisites.bd_available is false'

Write-Host "== check: malformed bead JSON =="
$badJson = Join-Path $work 'bad.json'
Set-Content -LiteralPath $badJson -Value '{"this is": not json' -Encoding utf8
$r = Invoke-RR @('check', '-Json', '-RepoRoot', $mainRoot, '-BdJsonPath', $badJson)
Assert-Eq $r.Exit 1 'malformed bead JSON exits 1'
$doc = ($r.Out -join "`n") | ConvertFrom-Json
Assert-True (@($doc.errors | Where-Object code -eq 'bd_json_invalid').Count -ge 1) 'invalid JSON reported as bd_json_invalid'

Write-Host "== check: code fences protect '## '/'### ' from heading interpretation =="
$fencedH2 = New-FixtureRepo 'fencedh2' @'
## Active threads

### Thread one

```
code block
## not a real heading
```

**Live Beads context:** `mybd-fence1`.

### Thread two

**Live Beads context:** `mybd-fence2`.
'@
$r = Invoke-RR @('check', '-Json', '-RepoRoot', $fencedH2, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 0 'fenced fixture (## inside fence) exits 0'
$doc = ($r.Out -join "`n") | ConvertFrom-Json
Assert-Eq $doc.threads.Count 2 "a '## ' line inside a code fence does not end the Active threads section"
Assert-Eq ($doc.threads[0].bead_ids -join ',') 'mybd-fence1' 'thread one bead id captured past the fence'
Assert-Eq ($doc.threads[1].bead_ids -join ',') 'mybd-fence2' 'thread two survives (section was not falsely ended)'

$fencedH3 = New-FixtureRepo 'fencedh3' @'
## Active threads

### Thread one

```
### not a real thread
```

**Live Beads context:** `mybd-real`.
'@
$r = Invoke-RR @('check', '-Json', '-RepoRoot', $fencedH3, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 0 'fenced fixture (### inside fence) exits 0'
$doc = ($r.Out -join "`n") | ConvertFrom-Json
Assert-Eq $doc.threads.Count 1 "a '### ' line inside a code fence does not create a phantom thread"
Assert-Eq $doc.threads[0].title 'Thread one' 'only the real H3 becomes a thread'
Assert-True ($doc.threads.title -notcontains 'not a real thread') 'fenced ### text never becomes a thread title'
Assert-Eq ($doc.threads[0].bead_ids -join ',') 'mybd-real' 'thread one bead id integrity preserved across the fence'

# =================================================================== open ====
Write-Host "== open: -NoLaunch, output location, embedded cards, escaping =="
$r = Invoke-RR @('open', '-NoLaunch', '-RepoRoot', $mainRoot, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 0 'open -NoLaunch exits 0'
$outPath = [string]$r.Out[-1]
Assert-True (Test-Path -LiteralPath $outPath) 'open prints an existing output path'
$tempRoot = [System.IO.Path]::GetTempPath()
Assert-True ($outPath.StartsWith($tempRoot)) 'default output lands under the OS temp dir'
Assert-True (-not $outPath.Contains([System.IO.Path]::DirectorySeparatorChar + 'reports' + [System.IO.Path]::DirectorySeparatorChar)) 'default output is not under reports/'

$html = Get-Content -LiteralPath $outPath -Raw
Assert-True ($html.Contains('href="#bead-mybd-aaa"')) 'bead ID rewritten to same-page link'
Assert-True ($html.Contains('id="bead-mybd-aaa"')) 'embedded detail card anchor exists'
Assert-True ($html.Contains('id="bead-mybd-ccc"')) 'missing bead still gets a visible card'
Assert-True ($html -match 'status-missing') 'missing bead card clearly marked'
Assert-True ($html -match 'badge-closed') 'closed bead clearly marked'
Assert-True (-not ($html -match '<script')) 'no script element anywhere (bd + md injection escaped)'
Assert-True ($html.Contains('&lt;script&gt;')) 'injection attempts visible but escaped'
Assert-True (-not ($html -match '<img src=x')) 'markdown-sourced HTML injection escaped'
Assert-True (-not ($html -match '(?i)(src|href)="https?://')) 'no remote assets or telemetry'
Assert-True ($html.Contains('class="agefacts"')) 'age facts rendered per thread'
Remove-Item -LiteralPath $outPath -Force

Write-Host "== open: link syntax survives bead-ID-bearing targets/labels; unsafe hrefs suppressed =="
$linkBead = New-FixtureRepo 'linkbead' @'
## Active threads

### T

- [id in target](2026-01-01-mybd-aaa-notes.md)
- [label mybd-bbb](x.md)
- [js](javascript:alert(1))
'@ @('2026-01-01-mybd-aaa-notes.md', 'x.md')
$r = Invoke-RR @('open', '-NoLaunch', '-RepoRoot', $linkBead, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 0 'open on link/bead-id fixture exits 0'
$outPath2 = [string]$r.Out[-1]
$html2 = Get-Content -LiteralPath $outPath2 -Raw
$expectedHref1 = [uri]::new([System.IO.Path]::GetFullPath((Join-Path $linkBead 'reports/2026-01-01-mybd-aaa-notes.md'))).AbsoluteUri
$expectedHref2 = [uri]::new([System.IO.Path]::GetFullPath((Join-Path $linkBead 'reports/x.md'))).AbsoluteUri
Assert-True ($html2.Contains("<a href=""$expectedHref1"">id in target</a>")) 'bead ID embedded in a link target does not destroy the link'
Assert-True ($html2.Contains("<a href=""$expectedHref2"">label mybd-bbb</a>")) 'bead ID embedded in a link label does not destroy the link'
Assert-Eq (@([regex]::Matches($html2, [regex]::Escape("href=""$expectedHref1"""))).Count) 1 'the bead-ID-in-target link renders as exactly one <a>'
Assert-True (-not ($html2 -match '(?i)javascript:')) 'javascript: scheme never appears as an href'
Assert-True (-not ($html2 -match '<a[^>]*>js')) 'unsafe-target link renders as plain label text only, not a live link'
Remove-Item -LiteralPath $outPath2 -Force

Write-Host "== open: duplicate H3 titles get independent age facts (keyed by ordinal, not title) =="
$dupJson = Join-Path $work 'dup-beads.json'
@'
[
  {"id":"mybd-dupa","title":"Dup A","status":"open","created_at":"2020-01-01T00:00:00Z","updated_at":"2020-01-01T00:00:00Z"},
  {"id":"mybd-dupb","title":"Dup B","status":"open","created_at":"2022-02-02T00:00:00Z","updated_at":"2022-02-02T00:00:00Z"}
]
'@ | Set-Content -LiteralPath $dupJson -Encoding utf8
$dupTitles = New-FixtureRepo 'duptitles' @'
## Active threads

### Same title

- [A](2026-01-01-a.md)

**Live Beads context:** `mybd-dupa`.

### Same title

- [B](2026-06-01-b.md)

**Live Beads context:** `mybd-dupb`.
'@ @('2026-01-01-a.md', '2026-06-01-b.md')
$r = Invoke-RR @('open', '-NoLaunch', '-RepoRoot', $dupTitles, '-BdJsonPath', $dupJson)
Assert-Eq $r.Exit 0 'open on duplicate-title fixture exits 0'
$outPath3 = [string]$r.Out[-1]
$html3 = Get-Content -LiteralPath $outPath3 -Raw
$ageDivs = @([regex]::Matches($html3, '(?s)<div class="agefacts".*?</div>') | ForEach-Object { $_.Value })
Assert-Eq $ageDivs.Count 2 'two agefacts blocks render, one per thread, despite the shared title'
if ($ageDivs.Count -eq 2) {
    Assert-True ($ageDivs[0].Contains('2026-01-01') -and $ageDivs[0].Contains('#bead-mybd-dupa')) 'first "Same title" thread shows its own report date and bead'
    Assert-True (-not $ageDivs[0].Contains('#bead-mybd-dupb')) 'first "Same title" thread does not leak the second thread''s bead'
    Assert-True ($ageDivs[1].Contains('2026-06-01') -and $ageDivs[1].Contains('#bead-mybd-dupb')) 'second "Same title" thread shows its own report date and bead'
    Assert-True (-not $ageDivs[1].Contains('#bead-mybd-dupa')) 'second "Same title" thread does not leak the first thread''s bead'
}
Remove-Item -LiteralPath $outPath3 -Force

Write-Host "== open: explicit -Output, reports/ refusal, cleanup on failure =="
$explicit = Join-Path $work 'explicit-out.html'
$r = Invoke-RR @('open', '-NoLaunch', '-Output', $explicit, '-RepoRoot', $mainRoot, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 0 'open honors -Output'
Assert-True (Test-Path -LiteralPath $explicit) '-Output file written'
Remove-Item -LiteralPath $explicit -Force

$r = Invoke-RR @('open', '-NoLaunch', '-Output', (Join-Path $mainRoot 'reports/evil.html'), '-RepoRoot', $mainRoot, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 1 'refuses to write generated HTML under reports/'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $mainRoot 'reports/evil.html'))) 'no file appears under reports/'

$failOut = Join-Path $work 'partial-out.html'
$r = Invoke-RR @('open', '-NoLaunch', '-Output', $failOut, '-RepoRoot', $mainRoot, '-BdJsonPath', $fixtureJson) @{ REPORT_ROOM_TEST_FAIL_RENDER = '1' }
Assert-Eq $r.Exit 1 'renderer failure exits 1'
Assert-True (-not (Test-Path -LiteralPath $failOut)) 'partial output cleaned up on failure'

$r = Invoke-RR @('open', '-NoLaunch', '-RepoRoot', $badLinks, '-BdJsonPath', $fixtureJson)
Assert-Eq $r.Exit 1 'open fails on link errors before writing output'
$r = Invoke-RR @('open', '-NoLaunch', '-RepoRoot', $mainRoot, '-BdJsonPath', $badJson)
Assert-Eq $r.Exit 1 'open fails on malformed bead JSON'

# ================================================== bd invocation contract ====
Write-Host "== bd seam: one batched read-only call =="
if (-not $IsWindows) {
    $fakeBd = Join-Path $work 'fake-bd'
    $bdLog = Join-Path $work 'fake-bd.log'
    @"
#!/bin/sh
echo "`$@" >> '$bdLog'
cat '$fixtureJson'
"@ | Set-Content -LiteralPath $fakeBd -Encoding utf8
    chmod +x $fakeBd
    $r = Invoke-RR @('check', '-Json', '-RepoRoot', $mainRoot) @{ REPORT_ROOM_BD_EXE = $fakeBd }
    Assert-Eq $r.Exit 0 'check succeeds through fake bd'
    $calls = @(Get-Content -LiteralPath $bdLog)
    Assert-Eq $calls.Count 1 'exactly one batched bd invocation'
    Assert-True ($calls[0] -match '^show .*--json') 'the single call is read-only `bd show ... --json`'
    Assert-True ($calls[0].Contains('mybd-aaa') -and $calls[0].Contains('mybd-bbb') -and $calls[0].Contains('mybd-ccc')) 'all unique IDs batched into the one call'
} else {
    Write-Host "  (skipped fake-bd invocation-count test on Windows shell stub)"
}

Write-Host "== bd seam: bounded per-ID fallback when the batched call fails =="
if (-not $IsWindows) {
    $fbLog = Join-Path $work 'fake-bd-fallback.log'
    $fakeBdFallback = Join-Path $work 'fake-bd-fallback'
    @"
#!/bin/bash
echo "`$@" >> '$fbLog'
shift
ids=()
for a in "`$@"; do
    if [ "`$a" != "--json" ]; then ids+=("`$a"); fi
done
if [ "`${#ids[@]}" -gt 1 ]; then
    exit 1
fi
id="`${ids[0]}"
echo "[{\"id\":\"`$id\",\"title\":\"Fallback `$id\",\"status\":\"open\",\"created_at\":\"2020-01-01T00:00:00Z\",\"updated_at\":\"2020-01-01T00:00:00Z\"}]"
exit 0
"@ | Set-Content -LiteralPath $fakeBdFallback -Encoding utf8
    chmod +x $fakeBdFallback

    # Under the cap: batched call fails, per-ID fallback resolves every ID,
    # and the page still builds.
    $fallbackRoot = New-FixtureRepo 'fallback-underCap' @'
## Active threads

### T

**Live Beads context:** `mybd-fba`, `mybd-fbb`.
'@
    $r = Invoke-RR @('open', '-NoLaunch', '-RepoRoot', $fallbackRoot) @{ REPORT_ROOM_BD_EXE = $fakeBdFallback }
    Assert-Eq $r.Exit 0 'per-ID fallback resolves both IDs and the page still builds'
    $fbOutPath = [string]$r.Out[-1]
    $fbCalls = @(Get-Content -LiteralPath $fbLog)
    Assert-Eq $fbCalls.Count 3 'fallback fires: one failed batched call plus one call per ID'
    Assert-True ($fbCalls[0].Contains('mybd-fba') -and $fbCalls[0].Contains('mybd-fbb')) 'first call is the batched attempt with both IDs'
    Assert-True (@($fbCalls[1..2] | Where-Object { $_.Trim() -eq 'show mybd-fba --json' }).Count -eq 1) 'a single-ID fallback call for mybd-fba'
    Assert-True (@($fbCalls[1..2] | Where-Object { $_.Trim() -eq 'show mybd-fbb --json' }).Count -eq 1) 'a single-ID fallback call for mybd-fbb'
    if ($fbOutPath -and (Test-Path -LiteralPath $fbOutPath)) {
        $fbHtml = Get-Content -LiteralPath $fbOutPath -Raw
        Assert-True ($fbHtml.Contains('id="bead-mybd-fba"') -and $fbHtml.Contains('id="bead-mybd-fbb"')) 'both fallback-resolved beads render detail cards'
        Remove-Item -LiteralPath $fbOutPath -Force
    }

    # Over the cap: batched call fails, ID count exceeds MAX_FALLBACK_BD_CALLS
    # (32), so the fallback must not fire at all (no unbounded per-ID calls).
    $capLog = Join-Path $work 'fake-bd-cap.log'
    $fakeBdCap = Join-Path $work 'fake-bd-cap'
    @"
#!/bin/bash
echo "`$@" >> '$capLog'
exit 1
"@ | Set-Content -LiteralPath $fakeBdCap -Encoding utf8
    chmod +x $fakeBdCap
    $manyIds = 1..33 | ForEach-Object { "mybd-cap$_" }
    $capReadme = "## Active threads`n`n### T`n`n" + ($manyIds -join ', ') + "`n"
    $capRoot = New-FixtureRepo 'fallback-overCap' $capReadme
    $r = Invoke-RR @('check', '-Json', '-RepoRoot', $capRoot) @{ REPORT_ROOM_BD_EXE = $fakeBdCap }
    Assert-Eq $r.Exit 1 'ID count over the fallback cap fails cleanly'
    $capCalls = @(Get-Content -LiteralPath $capLog)
    Assert-Eq $capCalls.Count 1 'no per-ID fallback calls are made once the cap is exceeded (only the batched attempt)'
    $doc = ($r.Out -join "`n") | ConvertFrom-Json
    Assert-True (@($doc.errors | Where-Object { $_.message -match 'fallback cap' }).Count -eq 1) 'cap-exceeded error surfaces in check -Json'
} else {
    Write-Host "  (skipped fake-bd fallback tests on Windows shell stub)"
}

# ================================================================== usage ====
Write-Host "== usage errors =="
$r = Invoke-RR @('frobnicate', '-RepoRoot', $mainRoot)
Assert-Eq $r.Exit 2 'unknown command exits 2'
$r = Invoke-RR @('-RepoRoot', $mainRoot)
Assert-Eq $r.Exit 2 'missing command exits 2'
$r = Invoke-RR @('open', '-Json', '-RepoRoot', $mainRoot)
Assert-Eq $r.Exit 2 '-Json with open exits 2'
$r = Invoke-RR @('check', '-NoLaunch', '-RepoRoot', $mainRoot)
Assert-Eq $r.Exit 2 '-NoLaunch with check exits 2'

# ================================================================ summary ====
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ''
Write-Host ("{0} passed, {1} failed" -f $script:Pass, $script:Fail)
if ($script:Fail -gt 0) {
    Write-Host 'Failures:'
    $script:Failures | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
exit 0
