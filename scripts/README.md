# scripts/

Helper scripts for the mybd coordination repo.

> **2026-08-10.** 55 scripts were removed here when maphew stepped down as a
> Beads maintainer: the whole upstream-triage lane (`tri-*`), the PR merge/close
> babysitter (`pr-babysit`, `pr-handoff`, `pr-close-handoff`), the local
> verification queue (`verify-*`), the bisect lane (`bisect-*`), the unattended
> model lane (`solo-*`), `reap-test-debris`, and their installers, tests, and
> systemd unit templates. All five systemd user timers were stopped and
> disabled. They assumed merge rights on `gastownhall/beads` and had no job
> left. Git history has them if one is ever needed again.

Most scripts are Bash. On Windows, run them through Git Bash or use the `.ps1`
wrapper beside the extensionless file. `scripts/agent-sig.sh` is deliberately
Bash-only — see below.

## Contributing upstream

### `pr-open`

Upstream preflight plus cross-vendor review, before a PR exists.

```bash
scripts/pr-open -C <worktree> --base main --search "<topic keywords>"
```

Runs `bd-main/scripts/pr-preflight.sh --search` (is there already an open PR for
this?), then `codex-agent reviewer --diff` on the branch, writing findings to
`.worktrees/.review-logs/<head-sha>.md`.

**Reconcile the findings yourself before posting.** A single reviewer's severity
ranking is not a verdict — ask of each finding "is this a regression, or
pre-existing behaviour?" Note the pass in the PR body.

Preflight answers "is there an open PR for this?", not "is anyone already doing
this?" For the second question, query the file you are about to edit:

```bash
git -C bd-main log --all --oneline --since=3.days -- <path>
```

### `pr-review-gate`

A `PreToolUse` hook (wired in `.claude/settings.json`) that blocks `gh pr create`
against `gastownhall/beads` until a review log exists for the **exact commit**
being proposed. Amending re-arms it — the log vouches for a commit, not a
branch. It stands down when `codex` is not on PATH.

Skip deliberately with `MYBD_SKIP_XVENDOR=1` prefixed to the command, and say
why in the handoff — in the command line, so the excuse sits next to the PR it
excused. Smoke-test: `scripts/test-pr-review-gate`.

### `gh-body-lint`

Guards GitHub PR/comment/review Markdown before posting: catches literal `\n`
sequences and non-linking issue refs. Always write bodies to a file and use
`gh ... --body-file`; never pass multiline bodies as inline shell strings.

```bash
scripts/gh-body-lint <body-file>
```

## Delegation

### `codex-agent`

Runs OpenAI Codex CLI non-interactively at a named delegation tier, mapping the
same tier names used for Claude subagents onto Codex model/sandbox/reasoning
defaults.

```bash
scripts/codex-agent scout    "where is X handled?"          # read-only, ephemeral
scripts/codex-agent builder  -C .worktrees/beads/foo "..."  # workspace-write
scripts/codex-agent reviewer "assess this design: ..."      # high reasoning, read-only
scripts/codex-agent reviewer --diff --base main             # structured diff review
```

The wrapper enforces two rules: the sandbox mode is always explicit, and
`builder` must target a linked worktree via `-C` (exit 3 on a main checkout;
`CODEX_AGENT_ALLOW_ROOT=1` to override deliberately). Close stdin (`</dev/null`)
when scripting. Codex bills to a separate quota pool and its tokens do not count
toward workflow `budget.spent()`.

### `agent-sig.sh`

Generates the signature line for GitHub comments and the `Agent-Signature:`
commit trailer, reading live session metadata.

```bash
scripts/agent-sig.sh --trailer
```

**Run it through Bash, never the PowerShell tool.** The `{reasoning}` field
comes from `CLAUDE_EFFORT`, which is exported only into Bash-tool subprocesses;
a PowerShell-tool invocation silently yields `unknown-reasoning`. There is
intentionally no `.ps1` wrapper — the `.sh` extension is the signal. The script
warns on stderr when it falls back to a placeholder; heed that rather than
posting the signature.

## Tracker health

### `check-beads-config`

Fails fast if `bd` is pointed at the wrong local database. The live database is
`.beads/embeddeddolt/mybd` (prefix `mybd-`); stale config can point `bd` at the
empty `beads` bootstrap DB, which makes `bd list` look mysteriously empty.

```bash
scripts/check-beads-config          # report
scripts/check-beads-config --fix    # narrow known-drift repair
```

`--fix` handles only the case where `.beads/metadata.json` points at an empty
`beads` DB while `mybd` is populated with the expected remote. If both contain
issues, export both and reconcile by hand. It also restores `core.hooksPath` to
`.githooks` when `bd hooks install --beads` has flipped it to `.beads/hooks`
(which has no git hooks of its own, silently deactivating the composed set).

### `pre-commit-beads-config`

Commit hook that rejects accidental `.beads/metadata.json` changes away from
`mybd`. Intentional database renames need `MYBD_ALLOW_DB_RENAME=1`.

### `bd-version`

Runs a specific released `bd` binary, downloading and caching it — useful for
bisecting behaviour across releases without disturbing the binary on PATH.

### `dolt-compat-matrix`

Empirical cross-version `dolt` CLI compatibility probes.

## Reading room

### `report-room.ps1`

Deterministic, local, zero-inference reader over `reports/README.md`: joins
the authored Active Threads with a current read-only Beads snapshot into a
disposable offline HTML page. The Markdown source and Beads stay canonical;
the generated page is never tracked and never written under `reports/`.

```powershell
scripts/report-room.ps1 open  [-NoLaunch] [-Output <path>] [-RepoRoot <path>]
scripts/report-room.ps1 check [-Json] [-RepoRoot <path>]
```

**Prerequisites:** PowerShell 7+, and `bd` on PATH (only for live bead
hydration; `-BdJsonPath` substitutes a fixture). No other dependency: the
Markdown renderer is a minimal internal converter for the constrained subset
used by the source (headings, paragraphs, links, bold/italic/code, lists,
tables, blockquotes), not a general Markdown parser.

**`open`** parses each H3 under `## Active threads` as one authored thread,
validates every relative report link (paths traversing outside the repo are
rejected), hydrates every unique `mybd-*` ID with a **single batched**
`bd show <ids...> --json` (bounded per-ID fallback if batching is
unsupported), and renders a self-contained HTML file under the OS temp
directory (override with `-Output`). Bead IDs in prose become same-page links
to embedded detail cards - clicking one needs no process, network request, or
model call. Closed and missing beads stay visible and clearly marked. Each
thread shows exact age facts (oldest/newest linked report date, span in days,
oldest active bead and its age, stalest non-closed bead and days since
update); emphasis thresholds are named constants (`AGE_EMPHASIS_SOFT_DAYS`=30,
`AGE_EMPHASIS_STRONG_DAYS`=90) and are neutral emphasis only - age never
claims priority or neglect. The default browser is launched unless
`-NoLaunch`; the output path is printed either way. Partial output is deleted
on failure.

**`check`** prints a compact human summary; `-Json` emits a stable schema
(`schema_version` 1):

```
{ schema_version, generated_at, source, repo_root,
  prerequisites: { pwsh, bd_available, bead_source, renderer },
  age_thresholds: { soft_days, strong_days },
  counts: { threads, unique_report_links, unique_bead_ids },
  threads: [ { title, report_count,
               report_links: [{ target, date, in_repo, resolved }],
               bead_count, bead_ids, unresolved_bead_ids, closed_bead_ids,
               age: { oldest_report_date, newest_report_date,
                      report_span_days, oldest_active_bead, stalest_bead } } ],
  unthreaded_since_latest: [ ... ],   # informational, never an error
  errors:   [{ code, message }],      # exit 1 when non-empty
  warnings: [{ code, message }] }     # findings only, exit stays 0
```

Report dates come from a leading `YYYY-MM-DD` filename prefix; `unknown` is
reported rather than an invented date.

**Failure behavior / exit codes:** 0 success (warnings allowed), 1 error -
missing prerequisites (`bd` absent), malformed source structure, missing or
out-of-repo report links, invalid bead JSON, renderer failure - and 2 usage
error. Errors and warnings are distinguished in the JSON (`link_missing`,
`link_outside_repo`, `bd_unavailable`, `bd_json_invalid`, `malformed_source`
vs `bead_unresolved`, `bead_closed`).

**No-inference / no-mutation boundary:** no model or API call, no network, no
standing service or `bd serve`, no tracked HTML twin, and no mutating `bd`
command ever - Beads is read only through `bd show --json`. Neither command
modifies reports or Beads.

**Test seams** (used by `test-report-room.ps1`): `-BdJsonPath <file>` injects
fixture bead JSON, `REPORT_ROOM_BD_EXE` overrides the bd executable, and
`REPORT_ROOM_TEST_FAIL_RENDER=1` forces a renderer failure after the output
file exists to exercise cleanup.

## Session lifecycle

### `session-start-stamp`

SessionStart hook; records the session boundary in `.beads/.session-start` that
`session-close-check` reads.

### `session-close-check`

Cold-start-readiness backstop. Warn-only — it never blocks a close.

```bash
scripts/session-close-check              # warn, exit 0
scripts/session-close-check --strict     # non-zero if any warning fired
scripts/session-close-check --since <git-ref|RFC3339>
```

Catches the cheap omissions: unreferenced new reports, thin new beads, beads
left `in_progress`, and branches this session advanced that are neither pushed
nor named by an open bead. The boundary comes from `.beads/.session-start` or
`--since`; with neither, session-scoped checks warn-skip rather than passing
silently. If `bd` is unavailable the bd-backed checks warn-skip too.

The script is only a backstop — the three judgment prompts in AGENTS.md
("Cold-start handoff") are the real work. `/session-close` runs both.

## Tests

| Script | Covers |
|--------|--------|
| `test-git-hooks` | the composed `.githooks` set (bd wrappers + root-commit guard) |
| `test-agent-hooks` | the cross-platform agent hook configs |
| `test-pr-review-gate` | the `gh pr create` PreToolUse gate |
| `test-session-close-check` | the cold-start report-reference check |
| `test-report-room.ps1` | the report-room reader (fixture Markdown + injected bead JSON; no live DB, no browser) |

## Retired but kept

| Script | Status |
|--------|--------|
| `bd-import-on-pull`, `install-sync-hook` | retired JSONL-through-git sync fallback; Dolt (`bd dolt push`/`pull`) is the sync protocol |
| `bd-stealth-init` | one-off bootstrap helper |
| `repro-worklist` | ad-hoc reproduction worklist helper |
| `jdiff.bat`, `_invoke-shebang.ps1` | Windows shims |
