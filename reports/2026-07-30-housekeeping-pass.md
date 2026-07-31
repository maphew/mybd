# Housekeeping pass — 2026-07-30

Solo session, no delegation. Pinned daily routine (AGENTS.md) plus one general
hygiene pass. Ran while the three other agent sessions were idle post-`/new`.

## Pinned routine — all green

| Check | Result |
|---|---|
| `git pull --rebase` | already up to date |
| `bd --version` vs `.beads/.local_version` | both 1.1.0, `/var/home/matt/.local/bin/bd` |
| `scripts/check-beads-config` | ok — `core.hooksPath=.githooks`, active DB `mybd` (1645 issues) |
| `bd-main` fetch --all --prune | ok (new `rjc123/*` remote branches appeared) |
| `bd ready` / `bd list --status=in_progress` | 60+ ready, 14 in progress |
| `scripts/verify-status` | **queue fully drained** — 10 recorded jobs, all `passed`, none queued or running |
| timers | all three healthy: `verify-babysit` (12s ago), `pr-babysit` (2m ago), `solo-sweep` (next 02:25 MST) |

No migration gate hit; no lock contention.

## The headline finding: two P0 lanes parked on an already-fixed upstream bug

`mybd-rr4x` (PR 5143) and `mybd-rqqa2` (PR 5163) are both P0, both labelled
`merge-blocked`, both returned to `bd ready` by the patrol after the rerun
budget ran out. They looked like two independent PR defects. They are not.

Both PRs fail **exactly one** job — `Test (Proxied Dolt Cmd 14/15)` — and within
it **exactly one** test: `TestProxiedServerComment/multiple_comments_ordered`.
Neither PR touches comments.

Root cause is `gastownhall/beads#5165`: since #5150 (`423afdcb2`, content-derived
ids at insert time), comments written inside the same wall-clock second read back
in content-digest order, because `created_at` is whole-second `DATETIME` and the
`id` tie-break is no longer a time-ordered UUIDv7. That issue is **CLOSED
upstream** (2026-07-30T09:56:52Z).

So the cure is already on main. **Next action for both: rebase onto current main
and re-arm the merge lane — do not debug either diff.** Diagnosis is recorded as
a `bd comment` on both beads, and the generalizable triage rule is saved as the
`merge-blocked-shared-shard-triage` memory (visible at `bd prime`), because the
expensive part was not the fix, it was noticing that two separate P0s shared one
failing test.

## Actions taken

- **Landed a stranded 561-line deliverable.**
  `reports/proxied-server-production-readiness.md` existed only on the local,
  never-pushed, diverged branch `campaign/proxied-server-readiness`. Open bead
  `mybd-psxg` references it by path — a cold agent would have followed that
  pointer to a file that was not on `main`. Cherry-picked onto main (`9d1e06766`)
  and pushed.
- **Removed 2 orphaned verifier worktrees** —
  `verify-mybd-psxg.2-42ec2baa1d1c-*` and `verify-mybd-uiiu-2fd873e47ba2-*`.
  `verify-next` creates and removes these itself; both were clean, detached, and
  stranded from runs whose beads have since passed at *different* heads. Verifier
  confirmed idle before removal.
- **Removed 4 coordination worktrees + branches**, all clean and fully merged into
  `main`: `next-batch-report`, `retro-tuning`, `session-0728`, and
  `proxied-server-readiness` (after landing its commit above).
- **Deleted merged remote branch** `origin/report/2026-07-28-session` (verified
  contained in `main` first).
- **Closed `mybd-3fnvu`** — "solo-sweep sandbox write probe (delete me)", a P4
  throwaway that had served its purpose.
- Pushed: `git push`, `bd dolt push`.

## Reported, not touched

- **Entire CLI clobbered upstream's tracked hooks in `bd-main`.** `.githooks/pre-push`
  went 76 lines → 10 and `.githooks/prepare-commit-msg` 39 → ~8, as *uncommitted
  modifications to tracked files* in the beads source clone. The deleted
  `pre-push` content is upstream's release-tag version-drift guard — the one added
  after the 1.0.5 release left main red. Two consequences: that guard is inert
  locally, and a stray `git commit -a` in `bd-main` would push hook deletions into
  an upstream PR. Entire left `.pre-entire` backups. The root coordination repo is
  **not** affected (its `.githooks` are clean). Restoring upstream's versions is
  `git -C bd-main checkout -- .githooks/pre-push .githooks/prepare-commit-msg`,
  but that removes Entire's hooks — an owner call, not mine.
- **27 `bd-main` worktrees, and they are mostly legitimate.** I checked the PR
  behind each review/fixmerge worktree: 4329, 4581, 4720, 4844, 5127, 5128, 5132,
  5121, 5122, 5123 are all still **OPEN**. Only `pr-5027-review` maps to a MERGED
  PR, and it holds uncommitted work (`cmd/bd/ready_proxied_integration_test.go`) —
  so not obviously dead. `matrix-bd` is detached at a commit already in
  `upstream/main` with only a stray `bd-matrix` binary; likeliest genuine leftover,
  but plausibly someone's A/B build.
- **Uncommitted work in 3 other worktrees**: `pr-4329-fixmerge`
  (`internal/tracker/engine.go` + test), `pr5128-review`
  (`internal/storage/dolt/credentials.go` + a new peer test), `pr-5027-review`
  (above). All look like live review state, not cruft.
- **`fixmerge/pr-4720`** — upstream tracking ref is `gone` but PR 4720 is OPEN;
  the branch is not merged. Left alone.
- **`mybd-t7mk.6`** stale 62 days (pure-Go embedded Dolt / gozstd validation).
- **`bd orphans`** lists `mybd-alw6l`, `mybd-fh6ff`, `mybd-q0ki6` — all three are
  legitimately standalone top-level action items, not missing edges. No action.
- **`bd lint`** flags a tail of task beads missing `## Acceptance Criteria`. Long
  pre-existing backlog, not this session's to fix.
- **Disk**: `.worktrees/beads` 1.9G, `.bare` 617M, `.git` 183M. `.verify-logs` is
  only 692K / 33 files — no buildup. Nothing worth reclaiming given the worktrees
  are live.
- No stashes in either repo. (Given the 2026-07-24 cross-contamination incident,
  worth stating explicitly.)

## What did I notice that isn't on any list?

**24 `entire/*` branches** — 14 in the coordination repo, 10 in `bd-main` — plus an
`entire/checkpoints/v1` ref. Nothing in AGENTS.md mentions them, no cleanup routine
covers them, and they now outnumber the real branches in `git branch` output to the
point that a plain `git branch` is no longer readable at a glance. They are Entire
CLI checkpoint refs, so presumably Entire's to garbage-collect — but nobody has
established whether Entire ever prunes them or whether they accumulate forever. Pair
this with the hook clobber above: Entire is installed in `bd-main`, has modified
tracked upstream files, and creates unbounded refs, and none of that is written down
anywhere. That is the gap worth closing — either a line in AGENTS.md saying Entire
owns `entire/*` and the hook diff is expected, or a decision to back it out of the
source clone.

## Cold-start self-asks

1. **What did this session learn that changes how a future agent works?** The
   shared-shard triage rule — saved via `bd remember` as
   `merge-blocked-shared-shard-triage`, not only in this report.
2. **Is every deliverable reachable from an OPEN bead or a memory?** Yes, and
   fixing one violation was the main repair: `mybd-psxg` pointed at a report that
   only existed on an unpushed branch. This report is reachable via the two bead
   comments and the new memory.
3. **Does any bead I touched say "after/gated-on X" without a dependency edge?**
   `mybd-rr4x` and `mybd-rqqa2` are both gated on a rebase, but that is a
   same-bead next action rather than a cross-bead ordering, so no edge is
   warranted. No prose-only ordering introduced.
