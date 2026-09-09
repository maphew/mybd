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

---

## Addendum — owner follow-through, same session

Owner directive after reading the above: *"back out Entire, I'll set it up
properly later. remove matrix-bd. rebase the blocked P0s."* All three done.

### Entire backed out of both repos

Recon corrected one thing in the report above: Entire was installed in the
**coordination repo too**, not just `bd-main`. Root's `.entire/` is gitignored,
which is why `git status` looked clean — but Entire's hooks were *committed* into
root's tracked `.githooks/` set, and it was actively tracking this very session.

Backed up first — 24 shadow branches hold session transcripts and the removal is
irreversible: `git bundle` of every `refs/heads/entire/` ref plus both `.entire/`
trees, at `~/.local/state/mybd/entire-backup/` (137M).

Then `entire disable --uninstall --force` in both repos and in the two worktrees
carrying residue (`pr-5027-review`, `v1.1.1-hotfix`).

Two things the uninstall got wrong, both repaired:

1. **In `bd-main` it was clean** — `git status` came back empty, upstream's
   76-line release-tag guard restored byte-for-byte.
2. **In the coordination repo it deletes hook files it owns rather than
   unwinding its preamble.** `.githooks/pre-push` and
   `.githooks/prepare-commit-msg` also carried **bd's** `bd hooks run <event>`
   wrappers, so backing out Entire silently took two of the five bd hook events
   with it. Both rebuilt as pure-bd wrappers modeled on `.githooks/post-merge`.
   `commit-msg` / `post-commit` / `post-rewrite` were Entire-only and stayed
   deleted. This is the trap worth remembering on reinstall, and it is now
   written into AGENTS.md.

Checked rather than assumed: `scripts/test-git-hooks` all-pass,
`scripts/check-beads-config` ok, and the `bd prime` + `session-start-stamp`
SessionStart hooks survive in both `.claude/settings.json` and
`.codex/hooks.json`. The `permissions` block the uninstall dropped held only
Entire's own `deny: Read(./.entire/metadata/**)`, so losing it is correct, not
collateral.

Also found and removed en route: a stray `.entire/.gitignore` **committed** onto
the local unpushed `hotfix/v1.1.1` branch in `20e493e56 chore(release): bump
version to 1.1.2` — Entire cruft that would otherwise have ridden along in a
release.

`matrix-bd` worktree removed as instructed.

### Both P0 lanes unparked

The diagnosis held up. `84431ee5c` (#5167, the #5165 fix) and `4bcfa89f3` (#5166,
its test follow-up) are both on `upstream/main`, so a rebase was the whole cure.

- **PR 5143** / `mybd-rr4x` — `fix/identity-existing-db` rebased onto
  `8bb0d36be`, 1 commit, no conflicts → `2352b1aa9`.
- **PR 5163** / `mybd-rqqa2` — `fix/port-provenance-fail-closed` rebased, 3
  commits, no conflicts → `157e0f7e2`.

Neither diff changed. `CGO_ENABLED=1 go build -tags gms_pure_go ./...` clean on
both before pushing; force-with-lease to the fork; `make test` enqueued for both
in the local verify queue; a short why-comment posted on each PR.

Merge tails handed back to the patrol with `scripts/pr-handoff` (squash). Note
that `pr-handoff` **adds** `merge-when-green` without clearing the stale
`merge-blocked` label — the two contradict each other, so I removed
`merge-blocked` by hand on both. Worth knowing for anyone else re-arming a
parked lane. Both beads are now claimed, `merge-when-green`, and out of
`bd ready`; CI is running green-so-far on both new heads.

### What I'd flag for the "set it up properly later" pass

If Entire goes back in, the failure mode to design against is not the shadow
branches — it is that its hook installer takes ownership of files that already
belong to bd, and its uninstaller then deletes them wholesale. Installing it
into `bd-main` at all is the sharper edge: that clone's `.githooks/` is
*upstream's tracked code*, so anything Entire writes there is a pending
accidental commit against `gastownhall/beads`. Consider limiting it to the
coordination repo.
