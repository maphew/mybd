# Upstream beads PR triage

_Source: `steveyegge/beads` · 50 open PRs · generated 2026-04-27 22:00 UTC_

## Summary

- **T1** Merge candidates: 8
- **T2** Review soon: 11
- **T3** Needs attention: 13
- **T4** Blocked / low: 7
- **T5** Hold: 11

## Top 10 picks

1. [#3482](https://github.com/gastownhall/beads/pull/3482) **fix(export): sort memory keys for deterministic JSONL output (GH#3474)** — kevglynn, score +6
1. [#3488](https://github.com/gastownhall/beads/pull/3488) **fix(gate): drop removed 'merged' field from gh pr view call (GH#3411)** — kevglynn, score +6
1. [#3503](https://github.com/gastownhall/beads/pull/3503) **fix(history): respect --json flag when issue has no history** — seanmartinsmith, score +6
1. [#3555](https://github.com/gastownhall/beads/pull/3555) **test(setup): use filepath.Join in TestGeminiSettingsPaths assertions** — seanmartinsmith, score +6
1. [#3557](https://github.com/gastownhall/beads/pull/3557) **fix(hooks): preserve user content when migrating v0.62.x → v1.0.x (GH#3536)** — pmgledhill102, score +6
1. [#3549](https://github.com/gastownhall/beads/pull/3549) **fix: resolve symlinks in DirToFileURL for cross-filesystem-view backup remotes** — shaunc, score +5
1. [#3550](https://github.com/gastownhall/beads/pull/3550) **fix(dolt): bd dolt status probes SQL when local server is externally-managed (be-0eyj)** — quad341, score +5
1. [#3556](https://github.com/gastownhall/beads/pull/3556) **fix(hooks): inject BEADS INTEGRATION above trailing exec block (GH#3537)** — pmgledhill102, score +5
1. [#3267](https://github.com/gastownhall/beads/pull/3267) **fix(create): add --rig flag to bd create for Gas Town rig routing** — rohanmyer, score +4
1. [#3282](https://github.com/gastownhall/beads/pull/3282) **fix: include _meta truncation indicator in bd list --json** — jakeefr, score +4

## Scoring rubric

- **+3** bug fix · **+2** perf / test · **+1** feat / refactor · **+0** docs / chore
- **+2** small (≤50) · **+1** medium (≤300) · **−2** very large (>1000)
- **+1** fresh (<1d) · **+1** closes a tracked issue · **+2** approved
- **−1** stale (>7d since update) · **−1** open >14d · **−1** dependabot
- **−2** changes requested · **−3** draft · **−3** merge conflicts

Tiers: T1 ≥ 5 · T2 ≥ 3 · T3 ≥ 1 · T4 ≥ −2 · T5 < −2.


## T1 — Merge candidate

| # | Score | Title | Author | ± lines | Review | Merge | Updated |
|---|---:|---|---|---:|---|---|---|
| #3482 | +6 | [fix(export): sort memory keys for deterministic JSONL output (GH#3474)](https://github.com/gastownhall/beads/pull/3482) | kevglynn | 10/3 | — | Mergeable | 2026-04-25 |
| #3488 | +6 | [fix(gate): drop removed 'merged' field from gh pr view call (GH#3411)](https://github.com/gastownhall/beads/pull/3488) | kevglynn | 5/9 | — | Mergeable | 2026-04-25 |
| #3503 | +6 | [fix(history): respect --json flag when issue has no history](https://github.com/gastownhall/beads/pull/3503) | seanmartinsmith | 28/5 | — | Mergeable | 2026-04-26 |
| #3555 | +6 | [test(setup): use filepath.Join in TestGeminiSettingsPaths assertions](https://github.com/gastownhall/beads/pull/3555) | seanmartinsmith | 4/4 | — | Mergeable | 2026-04-27 |
| #3557 | +6 | [fix(hooks): preserve user content when migrating v0.62.x → v1.0.x (GH#3536)](https://github.com/gastownhall/beads/pull/3557) | pmgledhill102 | 190/3 | — | Mergeable | 2026-04-27 |
| #3549 | +5 | [fix: resolve symlinks in DirToFileURL for cross-filesystem-view backup remotes](https://github.com/gastownhall/beads/pull/3549) | shaunc | 107/1 | — | Mergeable | 2026-04-27 |
| #3550 | +5 | [fix(dolt): bd dolt status probes SQL when local server is externally-managed (be-0eyj)](https://github.com/gastownhall/beads/pull/3550) | quad341 | 143/7 | — | Mergeable | 2026-04-27 |
| #3556 | +5 | [fix(hooks): inject BEADS INTEGRATION above trailing exec block (GH#3537)](https://github.com/gastownhall/beads/pull/3556) | pmgledhill102 | 418/1 | — | Mergeable | 2026-04-27 |

## T2 — Review soon

| # | Score | Title | Author | ± lines | Review | Merge | Updated |
|---|---:|---|---|---:|---|---|---|
| #3267 | +4 | [fix(create): add --rig flag to bd create for Gas Town rig routing](https://github.com/gastownhall/beads/pull/3267) | rohanmyer | 29/1 | — | Mergeable | 2026-04-14 |
| #3282 | +4 | [fix: include _meta truncation indicator in bd list --json](https://github.com/gastownhall/beads/pull/3282) | jakeefr | 12/1 | Changes Requested | Mergeable | 2026-04-27 |
| #3438 | +4 | [fix: bd admin commands fail with 'embedded mode' error in server mode](https://github.com/gastownhall/beads/pull/3438) | medhatgalal | 130/7 | — | Mergeable | 2026-04-27 |
| #3483 | +4 | [fix(init): chmod existing .beads/ to 0700 instead of only warning (GH#3391)](https://github.com/gastownhall/beads/pull/3483) | kevglynn | 34/0 | Changes Requested | Mergeable | 2026-04-27 |
| #3540 | +4 | [perf(storage): gate compat migrations with tracking table](https://github.com/gastownhall/beads/pull/3540) | quad341 | 176/4 | — | Mergeable | 2026-04-27 |
| #3560 | +4 | [fix(create): validate --deps type and fix blocked-by/depends-on aliases](https://github.com/gastownhall/beads/pull/3560) | kevglynn | 659/15 | — | Mergeable | 2026-04-27 |
| #3275 | +3 | [fix(init): run embedded post-init diagnostics](https://github.com/gastownhall/beads/pull/3275) | oculairmedia | 162/18 | — | Mergeable | 2026-04-14 |
| #3526 | +3 | [perf(issueops): replace per-id wisp check in 3 bulk fetchers](https://github.com/gastownhall/beads/pull/3526) | quad341 | 126/22 | — | Mergeable | 2026-04-26 |
| #3535 | +3 | [Fix issue-prefix precedence in issueops ID generation](https://github.com/gastownhall/beads/pull/3535) | trillium | 12/3 | — | Mergeable | 2026-04-27 |
| #3551 | +3 | [test: AD-01 isProductionPort + DB-name firewall](https://github.com/gastownhall/beads/pull/3551) | quad341 | 302/10 | — | Mergeable | 2026-04-27 |
| #3559 | +3 | [feat(setup): omit bd dolt push from template when no remote configured](https://github.com/gastownhall/beads/pull/3559) | kevglynn | 238/30 | — | Mergeable | 2026-04-27 |

## T3 — Needs attention

| # | Score | Title | Author | ± lines | Review | Merge | Updated |
|---|---:|---|---|---:|---|---|---|
| #3435 | +2 | [/go.{mod,sum}: bump dolt driver](https://github.com/gastownhall/beads/pull/3435) | coffeegoddd | 21/20 | — | Mergeable | 2026-04-22 |
| #3462 | +2 | [feat(schema): stderr progress + large-rig warning for MigrateUp (be-8ja)](https://github.com/gastownhall/beads/pull/3462) | quad341 | 261/0 | — | Mergeable | 2026-04-24 |
| #3492 | +2 | [fix(embeddeddolt): pass DOLT_REMOTE_USER to push/pull/fetch](https://github.com/gastownhall/beads/pull/3492) | GGPrompts | 60/16 | Changes Requested | Mergeable | 2026-04-27 |
| #3493 | +2 | [fix(storage/dolt): DOLT_COMMIT after label/comment writes](https://github.com/gastownhall/beads/pull/3493) | GGPrompts | 134/8 | Changes Requested | Mergeable | 2026-04-27 |
| #3548 | +2 | [Add suppress-history update primitive](https://github.com/gastownhall/beads/pull/3548) | kingfly55 | 141/13 | — | Mergeable | 2026-04-27 |
| #3558 | +2 | [init: harden --remote error path and broaden test coverage](https://github.com/gastownhall/beads/pull/3558) | maphew | 67/1 | — | Mergeable | 2026-04-27 |
| #3401 | +1 | [feat(session): capture created_by_session on bd create (phase 1a of #3400)](https://github.com/gastownhall/beads/pull/3401) | seanmartinsmith | 306/17 | — | Mergeable | 2026-04-26 |
| #3405 | +1 | [feat(session): capture claimed_by_session on claim / status=in_progress (phase 1b of #3400)](https://github.com/gastownhall/beads/pull/3405) | seanmartinsmith | 519/38 | — | Mergeable | 2026-04-27 |
| #3439 | +1 | [fix(doctor): run full pipeline in embedded mode](https://github.com/gastownhall/beads/pull/3439) | sjsyrek | 494/96 | Changes Requested | Mergeable | 2026-04-27 |
| #3452 | +1 | [feat(cli): add bd prove issue evidence command](https://github.com/gastownhall/beads/pull/3452) | acrinym | 606/0 | — | Mergeable | 2026-04-24 |
| #3468 | +1 | [chore(deps): bump github.com/anthropics/anthropic-sdk-go from 1.37.0 to 1.38.0](https://github.com/gastownhall/beads/pull/3468) | app/dependabot | 19/3 | — | Mergeable | 2026-04-24 |
| #3469 | +1 | [chore(deps): bump github.com/dolthub/driver from 1.84.1 to 1.86.4](https://github.com/gastownhall/beads/pull/3469) | app/dependabot | 21/20 | — | Mergeable | 2026-04-24 |
| #3509 | +1 | [docs(import): enumerate all fields the importer handles in --help](https://github.com/gastownhall/beads/pull/3509) | seanmartinsmith | 26/2 | Changes Requested | Mergeable | 2026-04-27 |

## T4 — Blocked / low

| # | Score | Title | Author | ± lines | Review | Merge | Updated |
|---|---:|---|---|---:|---|---|---|
| #3395 | +0 | [Add The Agentic Covenant — agentic-forward Code of Conduct and community standards](https://github.com/gastownhall/beads/pull/3395) | kevglynn | 588/2 | — | Mergeable | 2026-04-23 |
| #3417 | -1 | [fix(dolt): batch wisp-ID partition in bulk hydrators (GH#3414)](https://github.com/gastownhall/beads/pull/3417) | harry-miller-trimble | 687/149 | Changes Requested | Conflicting | 2026-04-24 |
| #3422 | -1 | [feat(nix): turn packages into an overlay to allow for overriding](https://github.com/gastownhall/beads/pull/3422) | DylanRJohnston | 63/67 | — | Conflicting | 2026-04-22 |
| #3475 | -1 | [feat(telemetry): adopt standard OTel SDK env vars, wire WrapStorage, partition bd.* by bd.prefix](https://github.com/gastownhall/beads/pull/3475) | GraemeF | 1372/137 | — | Mergeable | 2026-04-26 |
| #3533 | -1 | [Add dolt.mode config key with ambiguous-config warning](https://github.com/gastownhall/beads/pull/3533) | trillium | 321/2 | Changes Requested | Mergeable | 2026-04-27 |
| #3242 | -2 | [fix: repair shared-server bootstrap and doctor metadata drift](https://github.com/gastownhall/beads/pull/3242) | Bella-Giraffety | 368/4 | — | Conflicting | 2026-04-13 |
| #3278 | -2 | [fix(nix): use gms_pure_go, fix vendorHash, drop ICU dependency](https://github.com/gastownhall/beads/pull/3278) | TheCTD | 3571/947 | — | Conflicting | 2026-04-25 |

## T5 — Hold

| # | Score | Title | Author | ± lines | Review | Merge | Updated |
|---|---:|---|---|---:|---|---|---|
| #3220 | -3 | [Feat: copilot cli integration](https://github.com/gastownhall/beads/pull/3220) | julianpalmerio | 1547/11 | — | Mergeable | 2026-04-12 |
| #3458 | -3 | [perf(storage): SearchIssueSummaries narrow-projection list (be-nu4.3, stacks on #3453)](https://github.com/gastownhall/beads/pull/3458) | quad341 | 2039/39 | — | Conflicting | 2026-04-24 |
| #3461 | -3 | [perf(storage): CountIssues / CountIssuesGroupedBy (be-nu4.1, stacks on #3458)](https://github.com/gastownhall/beads/pull/3461) | quad341 | 2853/94 | — | Conflicting | 2026-04-24 |
| #3215 | -4 | [Fix orphan dependency doctor checks for tracks and wisps](https://github.com/gastownhall/beads/pull/3215) _(draft)_ | vernon99 | 723/180 | — | Mergeable | 2026-04-21 |
| #3264 | -4 | [feat(dream): add bd dream subcommand for memory consolidation (#3263)](https://github.com/gastownhall/beads/pull/3264) | boaz-hwang | 1424/1 | — | Conflicting | 2026-04-14 |
| #3337 | -4 | [perf: batch wisp routing and enable InterpolateParams to eliminate remote bd latency](https://github.com/gastownhall/beads/pull/3337) | alexmsu75 | 2443/57 | — | Conflicting | 2026-04-19 |
| #3351 | -4 | [perf(export): incremental auto-export via dolt_diff](https://github.com/gastownhall/beads/pull/3351) | quad341 | 1003/8 | — | Conflicting | 2026-04-19 |
| #3426 | -4 | [docs(claude): fix stale CLAUDE.md content for Dolt default](https://github.com/gastownhall/beads/pull/3426) | sjsyrek | 30/28 | Changes Requested | Conflicting | 2026-04-24 |
| #3317 | -5 | [Add Codex hooks and shared agent plugin](https://github.com/gastownhall/beads/pull/3317) | ebrevdo | 2455/334 | — | Conflicting | 2026-04-25 |
| #3238 | -6 | [feat: cross-project inbox for shared Dolt servers](https://github.com/gastownhall/beads/pull/3238) | harry-miller-trimble | 3349/1 | — | Conflicting | 2026-04-14 |
| #3528 | -6 | [Sync Linear milestones as local epics](https://github.com/gastownhall/beads/pull/3528) _(draft)_ | jozefizso | 513/25 | — | Conflicting | 2026-04-26 |

## Per-PR factors

### [T1] [#3482](https://github.com/gastownhall/beads/pull/3482) fix(export): sort memory keys for deterministic JSONL output (GH#3474)
_kevglynn · score +6 · 10+/3− across 1 files · created 2026-04-25_

- `+3` type=fix
- `+2` small (13 lines)
- `+1` closes a tracked issue

> ## Summary - Sorts `_type:"memory"` keys alphabetically before writing to JSONL, eliminating non-deterministic order from Go map iteration - Fixes noisy diffs in committed `issues.jsonl` where memory lines were reshuffled on every export Cl…

### [T1] [#3488](https://github.com/gastownhall/beads/pull/3488) fix(gate): drop removed 'merged' field from gh pr view call (GH#3411)
_kevglynn · score +6 · 5+/9− across 1 files · created 2026-04-25_

- `+3` type=fix
- `+2` small (14 lines)
- `+1` closes a tracked issue

> ## Summary - Removes `merged` from `gh pr view --json` call — field was removed in gh CLI v2.89+ - Removes `Merged bool` from `ghPRStatus` struct - Simplifies CLOSED case — `MERGED` is already a distinct state value Closes #3411 ## Details …

### [T1] [#3503](https://github.com/gastownhall/beads/pull/3503) fix(history): respect --json flag when issue has no history
_seanmartinsmith · score +6 · 28+/5− across 2 files · created 2026-04-26_

- `+3` type=fix
- `+2` small (33 lines)
- `+1` closes a tracked issue

> ## Problem `bd history <id> --json` returns prose, not JSON, when the bead has no history. Breaks any consumer that pipes the output to `jq` or otherwise expects structured output. Every other input shape (non-empty history) honors `--json`…

### [T1] [#3555](https://github.com/gastownhall/beads/pull/3555) test(setup): use filepath.Join in TestGeminiSettingsPaths assertions
_seanmartinsmith · score +6 · 4+/4− across 1 files · created 2026-04-27_

- `+2` type=test
- `+2` small (8 lines)
- `+1` fresh (<1d)
- `+1` closes a tracked issue

> ## Problem `TestGeminiSettingsPaths` at `cmd/bd/setup/gemini_test.go:469-479` fails on Windows: ``` gemini_test.go:472: unexpected project path: \my\project\.gemini\settings.json gemini_test.go:477: unexpected global path: \home\user\.gemin…

### [T1] [#3557](https://github.com/gastownhall/beads/pull/3557) fix(hooks): preserve user content when migrating v0.62.x → v1.0.x (GH#3536)
_pmgledhill102 · score +6 · 190+/3− across 2 files · created 2026-04-27_

- `+3` type=fix
- `+1` medium (193 lines)
- `+1` fresh (<1d)
- `+1` closes a tracked issue

> Fixes #3536. ## Summary `preservePreexistingHooks` (`cmd/bd/hooks.go`) treated any file containing the `# --- BEGIN BEADS INTEGRATION` marker as wholly bd-managed and skipped it during preservation: ```go // before if strings.Contains(conte…

### [T1] [#3549](https://github.com/gastownhall/beads/pull/3549) fix: resolve symlinks in DirToFileURL for cross-filesystem-view backup remotes
_shaunc · score +5 · 107+/1− across 2 files · created 2026-04-27_

- `+3` type=fix
- `+1` medium (108 lines)
- `+1` fresh (<1d)

> ## Summary When the operator's pwd traverses a symlink (e.g. `~/src` → `/data/disk-b/src/`) but the Dolt SQL server runs in a container with a bind-mount of the *realpath* only, `bd backup` registration fails because `DirToFileURL` emits th…

### [T1] [#3550](https://github.com/gastownhall/beads/pull/3550) fix(dolt): bd dolt status probes SQL when local server is externally-managed (be-0eyj)
_quad341 · score +5 · 143+/7− across 2 files · created 2026-04-27_

- `+3` type=fix
- `+1` medium (150 lines)
- `+1` fresh (<1d)

> ## Summary `bd dolt status` previously printed **\"Dolt server: not running\"** when the rig pointed at a **local** Dolt sql-server whose lifecycle was owned by something other than bd (an orchestrator like gc, a systemd unit, etc.). Every …

### [T1] [#3556](https://github.com/gastownhall/beads/pull/3556) fix(hooks): inject BEADS INTEGRATION above trailing exec block (GH#3537)
_pmgledhill102 · score +5 · 418+/1− across 2 files · created 2026-04-27_

- `+3` type=fix
- `0` large (419 lines)
- `+1` fresh (<1d)
- `+1` closes a tracked issue

> Fixes #3537. ## Summary When `bd hooks install --beads` (and `bd init`) preserves an existing hook (typically copying `.git/hooks/<name>` into `.beads/hooks/<name>`) whose tail is an exec-replacing chain, the unconditional bottom-append in …

### [T2] [#3267](https://github.com/gastownhall/beads/pull/3267) fix(create): add --rig flag to bd create for Gas Town rig routing
_rohanmyer · score +4 · 29+/1− across 1 files · created 2026-04-14_

- `+3` type=fix
- `+2` small (30 lines)
- `-1` stale (13d since update)

> ## Problem `gt done` (and agents following Gas Town documentation) calls `bd create --rig=<rig>` to create MR beads in a specific rig's beads database. However, `bd create` does not have a `--rig` flag, causing: ``` Error: unknown flag: --r…

### [T2] [#3282](https://github.com/gastownhall/beads/pull/3282) fix: include _meta truncation indicator in bd list --json
_jakeefr · score +4 · 12+/1− across 1 files · created 2026-04-15_

- `+3` type=fix
- `+2` small (13 lines)
- `-2` changes requested
- `+1` closes a tracked issue

> Fixes #3280. Added `_meta` field to JSON output from `bd list --json` to indicate when results are truncated. Makes it easier to detect pagination needs programmatically. When truncated, the response wraps from a bare array to: ```json { "i…

### [T2] [#3438](https://github.com/gastownhall/beads/pull/3438) fix: bd admin commands fail with 'embedded mode' error in server mode
_medhatgalal · score +4 · 130+/7− across 5 files · created 2026-04-23_

- `+3` type=fix
- `+1` medium (137 lines)

> ## Problem `bd admin compact`, `bd admin cleanup`, and `bd admin reset` all return: ``` Error: 'bd admin' is not yet supported in embedded mode ``` ...even when the project is configured in server mode (`dolt_mode=server` in `metadata.json`…

### [T2] [#3483](https://github.com/gastownhall/beads/pull/3483) fix(init): chmod existing .beads/ to 0700 instead of only warning (GH#3391)
_kevglynn · score +4 · 34+/0− across 3 files · created 2026-04-25_

- `+3` type=fix
- `+2` small (34 lines)
- `-2` changes requested
- `+1` closes a tracked issue

> ## Summary - `bd init` now fixes permissions on pre-existing `.beads/` directories to 0700 - Adds `config.FixBeadsDirPermissions()` that checks and repairs overly permissive modes - Eliminates the recurring warning on every `bd` invocation …

### [T2] [#3540](https://github.com/gastownhall/beads/pull/3540) perf(storage): gate compat migrations with tracking table
_quad341 · score +4 · 176+/4− across 3 files · created 2026-04-27_

- `+2` type=perf
- `+1` medium (180 lines)
- `+1` fresh (<1d)

> ## What this changes Every time a `bd` command opens the Dolt store, the backward-compat migration runner unconditionally executed all 17 entries in `compatMigrationsList`. Each migration is idempotent, but its idempotency check is itself a…

### [T2] [#3560](https://github.com/gastownhall/beads/pull/3560) fix(create): validate --deps type and fix blocked-by/depends-on aliases
_kevglynn · score +4 · 659+/15− across 11 files · created 2026-04-27_

- `+3` type=fix
- `0` large (674 lines)
- `+1` fresh (<1d)

> ## Summary - **`blocked-by:<id>` now recognized** as an alias for `blocks` with correct direction (new issue depends on target), matching how `bd dep add --blocked-by` already works - **`depends-on:<id>` direction fixed** — was being swappe…

### [T2] [#3275](https://github.com/gastownhall/beads/pull/3275) fix(init): run embedded post-init diagnostics
_oculairmedia · score +3 · 162+/18− across 3 files · created 2026-04-14_

- `+3` type=fix
- `+1` medium (180 lines)
- `-1` stale (13d since update)

> ## Summary - run the post-init verification path after `bd init` in embedded mode as well as server mode - validate embedded init against the real read-only embedded/app store instead of the server-only doctor path to avoid false setup fail…

### [T2] [#3526](https://github.com/gastownhall/beads/pull/3526) perf(issueops): replace per-id wisp check in 3 bulk fetchers
_quad341 · score +3 · 126+/22− across 3 files · created 2026-04-26_

- `+2` type=perf
- `+1` medium (148 lines)

> ## What this changes `bd list --json --include-infra --include-gates --all --limit 50000` on a 50K-issue rig used to time out at 124s; on the 50,956-issue gm city it now runs in 28.40s (3x speedup vs current `origin/main`'s 85.49s baseline,…

### [T2] [#3535](https://github.com/gastownhall/beads/pull/3535) Fix issue-prefix precedence in issueops ID generation
_trillium · score +3 · 12+/3− across 1 files · created 2026-04-27_

- `+2` small (15 lines)
- `+1` fresh (<1d)

> ## Summary Companion fix to #2469. The YAML config `issue-prefix` precedence was corrected in `cmd/bd/create.go` but the same issue exists in `internal/storage/issueops/create.go`, which handles actual ID generation via `NewBatchContext`. W…

### [T2] [#3551](https://github.com/gastownhall/beads/pull/3551) test: AD-01 isProductionPort + DB-name firewall
_quad341 · score +3 · 302+/10− across 16 files · created 2026-04-27_

- `+2` type=test
- `0` large (312 lines)
- `+1` fresh (<1d)

> ## What this changes Test processes can no longer accidentally connect to a production Dolt server. Two new defenses: 1. **Production-port detection.** `BEADS_TEST_MODE=1` now forces the SQL port to a sentinel (1) whenever the configured po…

### [T2] [#3559](https://github.com/gastownhall/beads/pull/3559) feat(setup): omit bd dolt push from template when no remote configured
_kevglynn · score +3 · 238+/30− across 9 files · created 2026-04-27_

- `+1` type=feat
- `+1` medium (268 lines)
- `+1` fresh (<1d)

> ## Summary - Adds `RenderOpts` with `HasRemote` flag to the template rendering system (`internal/templates/agents/render.go`). When `HasRemote` is false, `bd dolt push` is stripped from the session-completion code block and the Auto-Sync bu…

### [T3] [#3435](https://github.com/gastownhall/beads/pull/3435) /go.{mod,sum}: bump dolt driver
_coffeegoddd · score +2 · 21+/20− across 2 files · created 2026-04-22_

- `+2` small (41 lines)

### [T3] [#3462](https://github.com/gastownhall/beads/pull/3462) feat(schema): stderr progress + large-rig warning for MigrateUp (be-8ja)
_quad341 · score +2 · 261+/0− across 3 files · created 2026-04-24_

- `+1` type=feat
- `+1` medium (261 lines)

> ## Summary Emits a one-line progress message to stderr before each migration's statement-execution loop ("Applying migration NNNN: name…") and a ` done (N.Ns)` line after. Before the migration loop, a one-shot large-rig warning fires if the…

### [T3] [#3492](https://github.com/gastownhall/beads/pull/3492) fix(embeddeddolt): pass DOLT_REMOTE_USER to push/pull/fetch
_GGPrompts · score +2 · 60+/16− across 2 files · created 2026-04-25_

- `+3` type=fix
- `+1` medium (76 lines)
- `-2` changes requested

> ## Summary Embedded-mode `bd dolt push`/`pull`/`fetch` failed against any Dolt remotesapi server that requires `CLONE_ADMIN` authentication (DoltHub, self-hosted `dolt sql-server` with auth, any team-shared Dolt remote behind credentials), …

### [T3] [#3493](https://github.com/gastownhall/beads/pull/3493) fix(storage/dolt): DOLT_COMMIT after label/comment writes
_GGPrompts · score +2 · 134+/8− across 3 files · created 2026-04-25_

- `+3` type=fix
- `+1` medium (142 lines)
- `-2` changes requested

> ## Summary `DoltStore.{AddLabel,RemoveLabel,AddComment,AddIssueComment,ImportIssueComment}` only committed the SQL transaction; they did not fire `CALL DOLT_COMMIT`. The other issue mutations (`CreateIssue`/`UpdateIssue`/`Claim`/`Close`/`De…

### [T3] [#3548](https://github.com/gastownhall/beads/pull/3548) Add suppress-history update primitive
_kingfly55 · score +2 · 141+/13− across 7 files · created 2026-04-27_

- `+1` medium (154 lines)
- `+1` fresh (<1d)

> ## Problem Some downstream callers need to persist issue changes without appending a durable update-history event row for every volatile metadata update. ## Why this fix is needed Current-state persistence must remain intact, but durable up…

### [T3] [#3558](https://github.com/gastownhall/beads/pull/3558) init: harden --remote error path and broaden test coverage
_maphew · score +2 · 67+/1− across 2 files · created 2026-04-27_

- `+1` medium (68 lines)
- `+1` fresh (<1d)

> ## Summary Three follow-ups to merged #3527 (`bd init --remote` bootstrap path). - **mybd-cb4** — `init_embedded_test.go::remote_bootstraps_existing_dolt_data` uses `os.Symlink` to mask `dolt` off `PATH`. Skip on Windows where symlink seman…

### [T3] [#3401](https://github.com/gastownhall/beads/pull/3401) feat(session): capture created_by_session on bd create (phase 1a of #3400)
_seanmartinsmith · score +1 · 306+/17− across 13 files · created 2026-04-21_

- `+1` type=feat
- `0` large (323 lines)

> Refs #3400 ## Problem bd has a first-class `closed_by_session` column that captures which Claude Code session closed a bead (added in commit `b362b3682` per decision doc `009-session-events-architecture.md`). but session provenance is only …

### [T3] [#3405](https://github.com/gastownhall/beads/pull/3405) feat(session): capture claimed_by_session on claim / status=in_progress (phase 1b of #3400)
_seanmartinsmith · score +1 · 519+/38− across 22 files · created 2026-04-21_

- `+1` type=feat
- `0` large (557 lines)

> Stacked on #3401 (phase 1a). this PR is only mergeable once #3401 lands — GitHub will auto-rebase the diff onto `main` after that, or i can rebase + force-push on request. Refs #3400 ## Problem phase 1a (#3401) added `created_by_session` so…

### [T3] [#3439](https://github.com/gastownhall/beads/pull/3439) fix(doctor): run full pipeline in embedded mode
_sjsyrek · score +1 · 494+/96− across 16 files · created 2026-04-23_

- `+3` type=fix
- `0` large (590 lines)
- `-2` changes requested

> ## Summary Fixes the silent no-op where `bd doctor` short-circuited in embedded mode — the default backend — hiding ~70 diagnostic checks behind a three-bullet stub and `os.Exit(0)`. On a freshly initialized embedded repo the doctor now run…

### [T3] [#3452](https://github.com/gastownhall/beads/pull/3452) feat(cli): add bd prove issue evidence command
_acrinym · score +1 · 606+/0− across 3 files · created 2026-04-24_

- `+1` type=feat
- `0` large (606 lines)

> ## Summary - add a native `bd prove <id>` command - emit deterministic proof packets with classification, confidence, path evidence, duplicate candidates, and recommendation - add focused tests for title normalization, duplicate scoring, an…

### [T3] [#3468](https://github.com/gastownhall/beads/pull/3468) chore(deps): bump github.com/anthropics/anthropic-sdk-go from 1.37.0 to 1.38.0
_app/dependabot · score +1 · 19+/3− across 2 files · created 2026-04-24_

- `+2` small (22 lines)
- `-1` dependabot routine

> Bumps [github.com/anthropics/anthropic-sdk-go](https://github.com/anthropics/anthropic-sdk-go) from 1.37.0 to 1.38.0. <details> <summary>Release notes</summary> <p><em>Sourced from <a href="https://github.com/anthropics/anthropic-sdk-go/rel…

### [T3] [#3469](https://github.com/gastownhall/beads/pull/3469) chore(deps): bump github.com/dolthub/driver from 1.84.1 to 1.86.4
_app/dependabot · score +1 · 21+/20− across 2 files · created 2026-04-24_

- `+2` small (41 lines)
- `-1` dependabot routine

> Bumps [github.com/dolthub/driver](https://github.com/dolthub/driver) from 1.84.1 to 1.86.4. <details> <summary>Release notes</summary> <p><em>Sourced from <a href="https://github.com/dolthub/driver/releases">github.com/dolthub/driver's rele…

### [T3] [#3509](https://github.com/gastownhall/beads/pull/3509) docs(import): enumerate all fields the importer handles in --help
_seanmartinsmith · score +1 · 26+/2− across 1 files · created 2026-04-26_

- `+2` small (28 lines)
- `-2` changes requested
- `+1` closes a tracked issue

> ## Problem `bd import --help` lists only four optional fields: > "Optional fields: description, issue_type (type), priority, acceptance_criteria." But `bd import` just `json.Unmarshal`s each JSONL line straight into `types.Issue`, so it rou…

### [T4] [#3395](https://github.com/gastownhall/beads/pull/3395) Add The Agentic Covenant — agentic-forward Code of Conduct and community standards
_kevglynn · score +0 · 588+/2− across 9 files · created 2026-04-21_

- `0` large (590 lines)

> ## Summary This PR adds complete community standards to the beads project, checking every box on the [GitHub Community Standards page](https://github.com/gastownhall/beads/community). The centerpiece is **The Agentic Covenant v1.1** — the f…

### [T4] [#3417](https://github.com/gastownhall/beads/pull/3417) fix(dolt): batch wisp-ID partition in bulk hydrators (GH#3414)
_harry-miller-trimble · score -1 · 687+/149− across 10 files · created 2026-04-21_

- `+3` type=fix
- `0` large (836 lines)
- `-3` merge conflicts
- `-2` changes requested
- `+1` closes a tracked issue

> ## Summary Fixes #3414 — every mutating `bd` command (`create` / `close` / `update`) and bare `bd ready` against a remote Dolt backend hangs ~10–15s with: ``` Warning: auto-export failed: failed to search issues: search issues: search issue…

### [T4] [#3422](https://github.com/gastownhall/beads/pull/3422) feat(nix): turn packages into an overlay to allow for overriding
_DylanRJohnston · score -1 · 63+/67− across 4 files · created 2026-04-22_

- `+1` type=feat
- `+1` medium (130 lines)
- `-3` merge conflicts

> ## Summary Turn the nix packages into an overlay so they can be more easily overridden. ## Details Currently the exported bd / default package is a stdenv.mkDerivation wrapper around the `callPackage` beads package which makes it impossible…

### [T4] [#3475](https://github.com/gastownhall/beads/pull/3475) feat(telemetry): adopt standard OTel SDK env vars, wire WrapStorage, partition bd.* by bd.prefix
_GraemeF · score -1 · 1372+/137− across 19 files · created 2026-04-25_

- `+1` type=feat
- `-2` very large (1509 lines)

> ## Summary Three related changes: 1. Telemetry configuration moves to the standard OpenTelemetry SDK environment variables, behind an explicit `BD_OTEL_ENABLED=true` opt-in. Legacy `BD_OTEL_*` variables continue to activate telemetry on the…

### [T4] [#3533](https://github.com/gastownhall/beads/pull/3533) Add dolt.mode config key with ambiguous-config warning
_trillium · score -1 · 321+/2− across 6 files · created 2026-04-27_

- `0` large (323 lines)
- `+1` fresh (<1d)
- `-2` changes requested

> ## Summary - `bd init` can now read `dolt.mode: server` from config.yaml instead of requiring `--server` or `BEADS_DOLT_SERVER_MODE=1` every time. Valid values: `server`, `embedded`. - Priority order: CLI flag > env var > metadata.json > co…

### [T4] [#3242](https://github.com/gastownhall/beads/pull/3242) fix: repair shared-server bootstrap and doctor metadata drift
_Bella-Giraffety · score -2 · 368+/4− across 6 files · created 2026-04-13_

- `+3` type=fix
- `0` large (372 lines)
- `-1` stale (14d since update)
- `-1` old (14d open)
- `-3` merge conflicts

> ## Summary - repair shared-server bootstrap/doctor metadata recovery so local metadata can realign with the authoritative server database - add regression coverage for bootstrap and doctor metadata repair flows in shared-server mode - reduc…

### [T4] [#3278](https://github.com/gastownhall/beads/pull/3278) fix(nix): use gms_pure_go, fix vendorHash, drop ICU dependency
_TheCTD · score -2 · 3571+/947− across 122 files · created 2026-04-14_

- `+3` type=fix
- `-2` very large (4518 lines)
- `-3` merge conflicts

> The Nix flake failed to build on NixOS due to three issues: 1. Stale vendorHash (reported in #3221) — updated to the correct value for proxyVendor mode. 2. ICU C headers required by go-icu-regex unavailable in the Nix sandbox. PR #3064 adde…

### [T5] [#3220](https://github.com/gastownhall/beads/pull/3220) Feat: copilot cli integration
_julianpalmerio · score -3 · 1547+/11− across 16 files · created 2026-04-12_

- `+1` type=feat
- `-2` very large (1558 lines)
- `-1` stale (15d since update)
- `-1` old (15d open)

> Summary Adds first-class GitHub Copilot CLI integration to bd setup and bd doctor. This introduces a new copilot setup target that manages Copilot instruction files and hooks, similar to the existing Claude and Gemini integrations, while st…

### [T5] [#3458](https://github.com/gastownhall/beads/pull/3458) perf(storage): SearchIssueSummaries narrow-projection list (be-nu4.3, stacks on #3453)
_quad341 · score -3 · 2039+/39− across 31 files · created 2026-04-24_

- `+2` type=perf
- `-2` very large (2078 lines)
- `-3` merge conflicts

> ## Summary D3 of the bd-perf ADR (be-nu4): adds `SearchIssueSummaries` for narrow-projection list paths so `bd list --all` and similar commands stop materializing the full wide row when only a few columns are needed. **Stacks on #3453** (be…

### [T5] [#3461](https://github.com/gastownhall/beads/pull/3461) perf(storage): CountIssues / CountIssuesGroupedBy (be-nu4.1, stacks on #3458)
_quad341 · score -3 · 2853+/94− across 35 files · created 2026-04-24_

- `+2` type=perf
- `-2` very large (2947 lines)
- `-3` merge conflicts

> ## What this changes Moves `bd count` aggregation into the storage layer. Before this, `bd count` called `SearchIssues` and returned `len(rows)` — paying the full per-row hydration cost (labels, metadata, JSON scanning) just to throw every …

### [T5] [#3215](https://github.com/gastownhall/beads/pull/3215) Fix orphan dependency doctor checks for tracks and wisps
_vernon99 · score -4 · 723+/180− across 7 files · created 2026-04-12_

- `0` large (903 lines)
- `-1` old (16d open)
- `-3` draft

> ## Summary - exclude `tracks` dependencies from orphan dependency validation and cleanup - exclude dependencies that intentionally target wisps from orphan dependency validation and cleanup - add regression coverage for both the validator a…

### [T5] [#3264](https://github.com/gastownhall/beads/pull/3264) feat(dream): add bd dream subcommand for memory consolidation (#3263)
_boaz-hwang · score -4 · 1424+/1− across 9 files · created 2026-04-14_

- `+1` type=feat
- `-2` very large (1425 lines)
- `-1` stale (14d since update)
- `-3` merge conflicts
- `+1` closes a tracked issue

> Closes #3263. ## Summary Adds `bd dream` — a subcommand that consolidates the memory store (`bd remember` / `bd memories`) by asking an LLM to identify duplicates, stale references, and low-signal entries, then applies a structured `forget`…

### [T5] [#3337](https://github.com/gastownhall/beads/pull/3337) perf: batch wisp routing and enable InterpolateParams to eliminate remote bd latency
_alexmsu75 · score -4 · 2443+/57− across 16 files · created 2026-04-19_

- `+2` type=perf
- `-2` very large (2500 lines)
- `-1` stale (9d since update)
- `-3` merge conflicts

> ## Summary Eliminate remote `bd` latency on LAN-central Dolt-server topologies. Two compounding fixes, one per commit, both motivated by the same investigation: 1. **`perf(storage)`** — Seven bulk helpers in `internal/storage/issueops/` cal…

### [T5] [#3351](https://github.com/gastownhall/beads/pull/3351) perf(export): incremental auto-export via dolt_diff
_quad341 · score -4 · 1003+/8− across 4 files · created 2026-04-19_

- `+2` type=perf
- `-2` very large (1011 lines)
- `-1` stale (8d since update)
- `-3` merge conflicts

> ## Summary `maybeAutoExport` currently re-serializes every non-infra, non-template issue plus its relational data (labels, dependencies, comments) on every auto-export trigger. On a mature repo with ~46k beads (99.5% closed), a single trigg…

### [T5] [#3426](https://github.com/gastownhall/beads/pull/3426) docs(claude): fix stale CLAUDE.md content for Dolt default
_sjsyrek · score -4 · 30+/28− across 1 files · created 2026-04-22_

- `+1` medium (58 lines)
- `-3` merge conflicts
- `-2` changes requested

> ## Summary Root `CLAUDE.md` had drifted and was actively misleading agents. Worst offense: it prescribed a routine `bd export → git add → bd import` sync loop that's obsolete under the Dolt default and can silently drop data committed to Do…

### [T5] [#3317](https://github.com/gastownhall/beads/pull/3317) Add Codex hooks and shared agent plugin
_ebrevdo · score -5 · 2455+/334− across 90 files · created 2026-04-17_

- `-2` very large (2789 lines)
- `-3` merge conflicts

> ###### Why/Context/Summary - Add a first-class Codex integration for Beads. `bd setup codex` now installs a repo-local Beads agent skill under `.agents/skills/beads`, with optional project-local Codex hooks via `--hooks`; `bd prime --codex`…

### [T5] [#3238](https://github.com/gastownhall/beads/pull/3238) feat: cross-project inbox for shared Dolt servers
_harry-miller-trimble · score -6 · 3349+/1− across 21 files · created 2026-04-13_

- `+1` type=feat
- `-2` very large (3350 lines)
- `-1` stale (14d since update)
- `-1` old (14d open)
- `-3` merge conflicts

> ## Summary Adds a cross-project inbox feature for sending issues between projects on a shared Dolt server. ### New Commands - **`bd send <issue-id> --to <target>`** — Send issues to another project's inbox - **`bd inbox list`** — List pendi…

### [T5] [#3528](https://github.com/gastownhall/beads/pull/3528) Sync Linear milestones as local epics
_jozefizso · score -6 · 513+/25− across 11 files · created 2026-04-26_

- `0` large (538 lines)
- `-3` merge conflicts
- `-3` draft

> ## Summary - add opt-in `bd linear sync --pull --milestones` support for reconstructing Linear project milestone hierarchy - persist Linear `projectMilestone` metadata and create/reuse local epic issues with synthetic milestone external ref…
