# Issue sweep: theme:import-export (re-sweep) — 2026-07-30, solo-sweep run 4

Unattended lane. Nothing published, nothing closed — every row below is a
**proposal** on the stub (label `solo-sweep:proposed`).

The theme was already swept once (`reports/2026-07-26-issue-sweep-import-export.md`,
13 stubs → 8 closed). This run re-swept the **5 survivors**, all still open
upstream, four days later. Scope was 12; the theme only has 5 open stubs, so
coverage is complete.

## Dispositions

| bd | gh | proposed | evidence |
|----|----|----------|----------|
| mybd-jnrff | 3787 | **close** | Fixed. `651a52afe` "sort memory keys for deterministic JSONL output (GH#3474) (#3482)" is reachable from `upstream/main` (verified by `git log upstream/main --grep` **and** pickaxe `-S 'sort.Strings(memKeys)'` — sole introducing commit); sorted emission present in both `export.go:244-251` and `export_auto.go:435-444`. Exposure cut by #4063, **merged** 2026-05-21 (`3988db7e0`), `export.auto=false`. |
| mybd-g4vgq | 3885 | flesh-out | Still reproduces. `init.go:1441-1449` rewrites `cfg.DoltMode` from process state; the seeding at `:538-546` reads the flag/env/global `dolt.mode` but never `existingCfg.DoltMode`. Timeline is **empty** — nothing has been attempted upstream. |
| mybd-rm29u | 3884 | flesh-out | Partly wrong as titled: comments **are** round-tripped (`export.go:188,196`; ids stabilised by `5629e1867`/#4103). Wisps excluded by design (`:149-150`), events/history never exported. Real defect = no fidelity warning on the rebuild path. No linked PR. |
| mybd-itgj | 4492 | flesh-out | Abort-on-first-bad-row confirmed (`issueops/create.go:198,211-214` continues only on `StaleRejected`; whole import is one tx at `embeddeddolt/store.go:653`). But blast radius shrank: auto-import now runs only on an empty DB (`auto_import_upgrade.go:107`) and is gated out in server mode (`main.go:1644`) — the reporter's mode. Rescope, don't close. |
| mybd-7z1xc | 4080 | keep-open | Still reproduces: `scrubGitHookEnv` strips `GIT_INDEX_FILE=` (`export_auto.go:665+`) and `gitAddFile:583` always uses it. The only fix artifact is fork commit `632fee931` in **ylcn91/beads** — `commits/632fee93.../pulls` returns `[]`, **never a PR here, not merged**. Absorb candidate (ships a test). |

Counts: 1 close, 3 flesh-out, 1 keep-open. New engineering bead: **mybd-d1y7m** (p1).

## Root-cause map

- **Rebuild-from-JSONL degrades silently, two ways** (3884 data, 3885 config) —
  one design assumption: that `init --from-jsonl --reinit-local` can reconstruct
  a project from a JSONL subset plus the current process's flags. Filed as
  **mybd-d1y7m** with acceptance criteria; the two stubs stay as the upstream
  mirrors.
- **All-or-nothing JSONL import** (4492) — genuinely single; the fix is a
  skip-and-quarantine policy plus a `--strict` flag preserving today's abort.
- **Auto-export git env scrubbing** (4080) — single; fix already written by a
  contributor on a fork, route is absorb-with-attribution, not reimplement.
- **Determinism** (3787) — resolved upstream; the only closable stub here.

Neither new-family evidence nor new stubs appeared: no import-export issue has
been filed upstream since the 07-26 sweep, and four of the five surviving
issues have had **zero** upstream activity since filing (3885's timeline is
literally empty; 3884's only event is our own 06-16 request for a repro).

## Confidence and caveats

- **The one "fixed" claim is verified two ways.** `651a52afe` was confirmed
  reachable from `upstream/main`, not merely referenced, and the resulting code
  read at `upstream/main`. #4086 (`4dc8dbd2c`, merged) is **test-only**, 1 file,
  +186/-0 — it must not be cited as the fix, and the 07-26 sweep's note came
  close to doing so.
- **The three "still reproduces" claims are code reads, not repros.** This lane
  cannot build or run `bd`. Each names exact `upstream/main` file:line and the
  control flow; none was executed. A reviewer should treat them as strong static
  evidence, not as a reproduction.
- **All code claims are against `upstream/main`**, read via
  `solo-recon show beads upstream/main:<path>`. `bd-main/`'s working tree was
  used only to locate filenames.
- **The "never opened as a PR" claim for 4080** rests on all open PRs plus the
  100 most recent closed ones; `gh search` is off this lane's allowlist, so a
  very old closed PR could in principle have been missed. The fork commit's
  non-merge is solid (`/pulls` → `[]`).
- **Unverified, stated in the stub notes:** whether 1.0.4 differed from
  `upstream/main` on the auto-import server-mode gate (4492); whether the data
  directory relocates between `.beads/dolt` and `.beads/embeddeddolt` on a mode
  downgrade (3885); whether `bd backup` captures wisps/events (3884); and
  sub-collection ordering (labels/comments/deps) inside an exported issue
  record, which no one has audited for determinism (3787).
- **Process finding, worth a minute of the owner's attention.** The 07-26 sweep
  report says these five stubs were "keep, fleshed out … with acceptance
  criteria". In bd, all five have `acceptance_criteria: null`, `design: null`,
  and still carry only their one-line triage note. The flesh-out was written in
  the report, not into the beads — so a cold-start agent reading `bd ready` sees
  five bare stubs. This run put the substance into the stub notes. Worth
  checking whether the other 07-26 sweeps (data-integrity, migration-schema,
  sync-remote, test-ci/cli-ux) have the same gap.
- **Adjacent state, not touched:** consolidation bead **mybd-vkc56** (auto-export
  wedge, gh 4887/4988) is still open and was not re-verified this run;
  **mybd-zlqec** is closed. `mybd-s8edp` (close-when-quiet, PR 4257 auto-import
  stamp) is another session's lane — left alone.
- Nothing was blocked. `bd`, `solo-recon`, and GitHub were all available; no
  denied command was needed.
