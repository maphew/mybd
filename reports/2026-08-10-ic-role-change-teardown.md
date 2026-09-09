# 2026-08-10 — maintainer → contributor: lane shutdown, backlog collapse, repo teardown

maphew stepped down as a Beads maintainer and is now a normal contributor to
`gastownhall/beads`. This session turned off the automation that assumed merge
rights, collapsed the backlog that existed to serve it, and cut the agent docs
down to what a contributor needs.

## What changed

### Scheduled lanes — all five off

`pr-babysit`, `verify-babysit`, `solo-sweep`, `tri-daily`, `reap-test-debris`
stopped and disabled (`systemctl --user disable --now`). No crontab entries, no
straggler processes. Nothing was stranded: no `merge-when-green` or
`close-when-quiet` beads were armed and the verify queue was fully drained.

### bd backlog: 526 open → 160

| Closed | What |
|--------|------|
| 283 | upstream issue/PR mirrors, `tri:*` stubs, `solo-sweep:*` proposals, `review-needed` |
| 83 | maintainer-lane work: acting on others' PRs, review sweeps, governance/release rulings, dead-lane maintenance |
| 2 | in_progress beads whose upstream PR merged or was maintainer re-port work |

`bd ready` went 467 → 149. Engineering findings that merely *cite* a PR number
as provenance were deliberately kept — a first-pass keyword classifier flagged
154 beads, and reading them individually moved ~70 back to the keep pile
(including a real concurrency bug, `mybd-e1b3f`, and the docs-rewrite bead
filed earlier the same session).

### Repo: 8.2 G → 3.6 G

85 stale Beads worktrees removed, 91 spent local branches deleted, `.bare`
repacked. All 92 branches are preserved in
`.beads/backup/pre-ic-teardown-20260810/bd-main-all-branches.bundle`, and the
four worktrees with uncommitted changes had their diffs saved beside it.

### Scripts: 86 → 30

55 removed: the `tri-*` triage lane, `pr-babysit`/`pr-handoff`/
`pr-close-handoff`, `verify-*`, `bisect-*`, `solo-*`, `reap-test-debris`, their
installers, tests, and `scripts/systemd/` templates.

Kept deliberately: `pr-open` and `pr-review-gate`. The cross-vendor review
before `gh pr create` matters *more* as a contributor — nobody here can wave a
rough PR through.

`session-close-check` lost its lane-unit check (check 5) and gained inlined
copies of `tri_die`/`tri_require`, the only two things it used from the deleted
`_tri-lib.sh`. All four kept test scripts pass.

### Docs

`AGENTS.md` 903 → ~420 lines. `PR_MAINTAINER_GUIDELINES.md` moved to
`archive/` with a do-not-apply banner. `Readme.md` rewritten — it had described
a PowerShell `main/` worktree layout that has not existed for months and pointed
at `steveyegge/beads`. `scripts/README.md` 1,165 lines → the 30 surviving
scripts.

## Two repairs that had nothing to do with the role change

**`git` was fatally broken in `bd-main`.** `.bare/config` carried
`hooksPath = ~\.githooks` — a Windows backslash path Git on Linux cannot expand
— so `git status` and `git log` died with `fatal: failed to expand user dir`.
`git branch` and `git diff` still worked, which is why it went unnoticed since
7 Aug. Same config had `remote.origin.url` pointing at
`git@github.com:test/metadata-test.git` instead of the `maphew/beads` fork;
both look like collateral from a metadata test run against the real repo. Fixed
to `.githooks` (which is what upstream's own hook headers document) and the
real fork.

**Four of maphew's own PRs are open upstream and unattended** — #5277, #5092
(both `MERGEABLE=CONFLICTING`, need rebases), #5202, #5229. Unreviewed, untouched
since 2026-08-03 when the lanes went quiet. Filed as `mybd-jcylm` (P0): this is
now the highest-value work in the repo.

## Salvage: nothing was stranded

Earlier in the session I told the owner four unpushed branches looked worth
rescuing. **That was wrong, and the correction matters more than the original
claim.** A patch-equivalence sweep across all 39 never-pushed branches, plus
in-depth checks on the four, found:

- `mnt/5144` — content already in main (PR #5144 merged 31 Jul)
- `fix/pr-5028-macos-temp` — main has an equivalent implementation at
  `internal/beads/context.go:318-329`
- `hotfix/v1.1.1` — release artifacts; v1.1.2 shipped upstream via #5091
- `fix/lease-reclaim-test-assertion` — main fixed the same flaw differently
  (structured `reclaimedIDs` parse instead of `strings.Contains`); our version
  is marginally more robust (splits stdout/stderr rather than scanning combined
  output for the first `{`), but it is a nice-to-have, not a fix

The two newest branches confirmed the base rate: #5220 (maphew) and #4985
(davevan2) both merged. Every unpushed branch is a spent working copy of a PR
that subsequently landed.

**Methodological note.** The first pass used `git diff upstream/main...branch`
(three-dot), which shows branch-side changes even when main already holds
equivalent content from a squash merge — it reported "still unlanded" for work
that had landed weeks earlier. The reliable test is cherry-picking each commit
onto current main and checking whether the staged diff is empty. `git cherry`
is also insufficient alone: squash merges change patch-ids, so it reports `+`
for landed work.

## Incident: `.bare` deleted mid-prune

While removing stale worktrees I looped over `git worktree list --porcelain`
output with `git worktree remove || rm -rf "$w"` as a fallback. **That list
includes the bare repository itself.** `worktree remove` refused it, the
fallback ran, and the entire object store for `bd-main` was deleted — 92
branches and all history, gone in one command.

Recovered in full from the `git bundle` taken ~15 minutes earlier, before any
pruning: recreated `.bare`, fetched all 92 branches from the bundle, restored
remotes and `hooksPath`, re-attached `bd-main` as a worktree at the same commit
(`4a76685f9`). Verified the recovered tree against a fresh checkout — the only
differences were a gitignored build binary and local `.beads/hooks` state, both
preserved.

The bundle is the only reason this was a 15-minute detour rather than a data
loss. Two rules now in `AGENTS.md` and `Readme.md`:

- Never `rm -rf` a path that came out of `git worktree list` — skip anything
  flagged `bare`, and let `git worktree remove` fail rather than forcing.
- Take `git bundle create <file> --branches` before any bulk prune.

Also recorded as bd memory `never-rm-rf-worktree-list-paths`.

## State at close

- open beads 160, ready 149, in_progress 5 (all live upstream PRs)
- `bd-main` on `main` @ `4a76685f9`, tracking `upstream/main`, git healthy
- disk 3.6 G (from 8.2 G)
- 4 kept test scripts pass; `session-close-check` runs clean

## What a contributor session does next

1. **`mybd-jcylm`** — rebase and shepherd the four open PRs. Highest value here.
2. **Harvest the unfiled bugs.** ~30 specific, file-and-line-level Beads defects
   found while reviewing others' PRs, none reported upstream: wisp rename
   orphaning labels/comments/events (`mybd-o1i9c`), custom dependency types
   failing open so they never gate `bd ready` (`mybd-zg2dj`), `bd defer` being
   write-only (`mybd-guity`), and more. This is what converts three months of
   maintainer effort into contributor standing.
3. **`mybd-s00hz`** is now largely done by this session; what remains is
   whatever the next reader finds still stale.
