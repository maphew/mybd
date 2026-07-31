# Issue sweep — theme:hooks-install (solo-sweep run 8)

2026-07-31. Unattended lane. Procedure: `reports/2026-07-26-triclaim-drain-strategy.md`.
Theme had **3 open `tri:claim` stubs — all 3 examined**, none deferred for scope.
Everything below is a **proposal**; nothing was published, closed, labelled, or merged.

Code claims are read from `upstream/main` (tip `8bb0d36be`) via `scripts/solo-recon`,
never from the `bd-main/` working tree.

## Dispositions

| Stub | Upstream | Proposed | Evidence |
|---|---|---|---|
| mybd-d3f7j | [#3962](https://github.com/gastownhall/beads/issues/3962) pre-commit joins unrelated commits | **close** | Fixed by `c0bdf4972` "guard JSONL auto import/export edge cases" — **verified reachable from `upstream/main`**, not merely referenced. It added `preCommitHasStagedBeadsFiles()` + an early return in `exportJSONLForCommit()` (`cmd/bd/hooks.go`), gating on `git diff --cached --name-only -- .beads` — exactly the staged-set check requested. |
| mybd-b8ht | [#4440](https://github.com/gastownhall/beads/issues/4440) core.hooksPath survives manual uninstall | **flesh-out** | Live. Zero timeline events — nothing upstream has ever touched it. Of the reporter's 3 suggested fixes, 1 is done (`resetHooksPathIfBeadsManaged`, and it doesn't help them), 2 are not: no `bd doctor` check, no `core.hooksPath` line in the uninstall doc. Scoped to AC1–AC3 in the note. |
| mybd-v42x4 | [#4272](https://github.com/gastownhall/beads/issues/4272) hook-skip misses the SQL push path | **keep-open** | Fix written and green but **unmerged**: PR #5186 is `state=open, merged=false`, `mergeable_state=clean`, head `bdae7e961`, local `make test` passed 06:40Z today. Active claimed lane; I only annotated it. |

**Counts:** close 1, flesh-out 1, keep-open 1.

## Root-cause map

All three are the same class: **a git hook acting outside the scope it was meant for.**
Two were fixed by adding an explicit scope check; the third has no scope check yet.

- **Hook fires where it shouldn't** — #4272: the repo's own git hooks execute inside
  Dolt's internal git mirror during `CALL DOLT_PUSH`. Fix (PR #5186) sets a
  hook-disable scope around the call. *Written, verified, unmerged.*
- **Hook effect joins work it shouldn't** — #3962: the export re-stages
  `.beads/issues.jsonl` into a focused commit. Fix (`c0bdf4972`) scopes the export to
  the staged set. *Merged.*
- **Hook config outlives its target** — #4440: `core.hooksPath` points at a `.beads/hooks`
  the user deleted, so checkout re-runs a hook that recreates `.beads/`. *No scope check
  exists.* This is the only genuinely open engineering work in the theme.

### New beads

- **mybd-4744h** (p2) — `bd doctor` check for a `core.hooksPath` resolving to a
  non-existent directory, with a beads-managed-only `--fix`; plus the missing
  `git config --unset core.hooksPath` line in `docs/recovery/uninstalling.md`, plus
  `uninstallHooks()` unsetting `beads.role`. This is the actionable core of #4440.
- **mybd-3bevm** (p1) — target-coherence guard for `bd admin reset`. Lifted out of a
  BLOCKER/INCIDENT note buried in mybd-b8ht's notes field (2026-07-21): `bd -C <temp>
  admin reset --force` unioned the caller repo's git root with global `.beads`
  discovery and deleted `C:\Users\Matt\.beads`, `bd-main/.git/hooks/*`, and
  `bd-main`'s `beads.role`. Filed because a cold-start agent running `bd ready` would
  never have seen it where it was.

## Things worth the owner's attention first

1. **PR #5186 has no owner.** It is clean, green, and open only because the session that
   wrote it ran under do-not-merge and never armed the lane. Nothing blocks it. Suggested:
   review, then `scripts/pr-handoff 5186 --repo gastownhall/beads --bead mybd-v42x4`.
   Arming a lane is acting, so this lane could not do it.
2. **`bd admin reset --force` is the documented uninstall path** (`uninstalling.md` lines
   31–41) *and* the command with the 2026-07-21 destruction incident. That pairing is the
   thing that surprised me most this run.
3. **`reports/2026-07-30-oldest-first-ready-queue-sweep.md` is stranded** on branch
   `report/oldest-first-sweep` (maphew/mybd), not on main.
4. **#3962 was fixed ~7 hours after we told the reporter it wasn't.** maphew commented
   2026-05-22T00:03:39Z "the pre-commit behavior itself is unchanged"; `c0bdf4972` is dated
   2026-05-22T07:01:59Z. The reporter then supplied a repro on 2026-06-17 and asked
   "please confirm whether current bd still defers/joins the export" — never answered.
   That unanswered question, not a live defect, is why the issue is still open.

## Confidence and caveats

**High confidence — verified this run, by me, not by a delegate:**

- All three upstream issues are `state=open` (GitHub API this run).
- #4272 and #4440 timelines return **zero events**. No unlinked or commit-message-only fix
  can be hiding there; there is nothing there at all.
- `c0bdf4972` is reachable from `upstream/main` and its diff adds exactly the claimed gate.
  I read both the commit diff and the current `upstream/main` file.
- `export.auto` and `export.git-add` both default `false` (`internal/config/config.go:259,262`).
- PR #5186 `merged=false`; PR #4281 (pmgledhill102's earlier attempt) `state=closed,
  merged=false`. #4281 is precisely the closed-but-unmerged shape the strategy report names
  as a false-positive source — a skim would read it as "already fixed".
- `docs/recovery/uninstalling.md` exists and contains **no** occurrence of `hooksPath`.

**Medium confidence — source-reading only, no execution:**

- "No `bd doctor` check exists for a stale `core.hooksPath`." This is a claim over the
  registrations in `cmd/bd/doctor.go` and the files in `cmd/bd/doctor/`, surfaced by a
  delegated scout and spot-confirmed by me (`hooks_migration.go` resolves the path and
  never `os.Stat`s it). It is not `bd doctor` output. Confirm before writing the patch.
- The #3962 close proposal rests on reading code, not on running the reporter's repro —
  this lane has no build or exec. The reporter themselves could not produce a clean
  capture (their `bd init` hung on the dolt export step). The buggy code is provably gone
  and replaced by the requested guard; an execution-level confirmation before replying
  upstream would still be worth ten minutes.
- Nuance to carry into any upstream reply: the reporter asked to **defer** the export;
  upstream **skips** it. Intent met, wording differs — a bd change made without staging
  `.beads` is exported by the next commit that does stage it, or by explicit `bd export`.

**Not verified at all:**

- mybd-3bevm's incident is a faithful transcription of the 2026-07-21 note plus a doc
  cross-reference I checked. I did **not** reproduce it and did **not** read the
  `bd admin reset` implementation; the "suspected shape" in that bead is inference and
  may be wrong. I also did not check whether it was fixed in the intervening ten days —
  there is no upstream issue or PR to enumerate a timeline from.
- I did not re-audit PR #5186's diff. The technical claims about what it does are the
  prior session's, carried forward unaudited; only its *merge state* is mine.

**Not blocked on anything.** No denied command I needed, no rate limiting, bd available
throughout. One `solo-bd note` was rejected for containing the reserved word "human" and
one for length; both were reworded, not dropped.

_claude-opus-5-medium on behalf of maphew_
