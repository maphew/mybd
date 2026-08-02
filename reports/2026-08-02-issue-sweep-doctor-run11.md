# Issue sweep — theme:doctor (solo-sweep run 11, 2026-08-02)

All 6 open `tri:claim` stubs in the theme examined; none deferred for scope.
This is a **re-sweep**: run 4 (2026-07-30) covered the same six, and 07-31/08-01
passes adjudicated two and added dep edges to three. So the job here was
freshness — has anything landed, and did the earlier claims survive
re-verification against a main that moved 9+ doctor commits since.

Every code claim below is against `upstream/main` @ `17824fc7c` (2026-08-01),
not the working tree.

## Dispositions

| Stub | Pri | Upstream | Proposed | Evidence |
|---|---|---|---|---|
| mybd-uh8q | p1 | #4993 | keep-open | `cmd/bd/doctor/fix_gate.go` does not exist on main; no schema-skew guard. PR #5145 re-verified `state=open merged=false`. **New:** it is `Refs #4993`, not `Closes` — author states it gates only *schema-ahead*, and `--fix` still applies a *pending* migration alongside cosmetic fixes. Do not close this on 5145's merge. |
| mybd-kr0i | p1 | #5025 | keep-open | `detect_pollution.go:25` scorer regex unchanged, still no status/priority/type filter. PR #5137 `open, merged=false`, author pushed 07-31 (head `e42bb260`) — newer than the head mybd-54zj9 was queued for. **New:** body discloses it omits the "exclude issues with children/links from `--clean`" hardening. Closeable on merge, unlike uh8q. |
| mybd-rnjr | p2 | #5026 | keep-open | `epic_closure.go:137-148` still counts children by status alone; `close_reason` never read. PR #5138 `open, merged=false`, head unchanged since 07-29. **Gap:** the 08-01 hygiene pass edged uh8q/kr0i/7vyw but skipped this one — `dependency_count=0` while mybd-kj8rp sits open. Needs `bd dep add mybd-rnjr mybd-kj8rp`. |
| mybd-7vyw | p2 | #4539 | keep-open | No `OrphanedChildCounters` anywhere in `cmd/bd/doctor/validation.go` on main. PR #4858 `open, merged=false, merge_commit_sha=null`, quiet since 07-28, base `7919c9c9` vs main `17824fc7c` — needs a rebase. **The material find of this run, below.** |
| mybd-8bse | p2 | #4814 | keep-open | `integrity.go:353` `addBlockingDependencyEdge` still `DepBlocks \|\| DepConditionalBlocks` only. Issue unchanged since the 07-28 comment. Already adjudicated 07-31; engineering bead mybd-p2wyk exists and is open. No new evidence — suggest a dep edge to p2wyk. |
| mybd-1yi6x | p3 | #3705 | keep-open | `git.go:299` `CheckGitWorkingTree` still has no `core.bare` / `--is-bare-repository` / `--git-common-dir`; `legacy.go:19` `agentDocFiles` still a bare `filepath.Join`. Issue untouched since 2026-05-04. Fully specified, **no PR in flight, no dep edge** — the theme's best implementation candidate. |

Counts: **6 keep-open, 0 close, 0 consolidate, 0 flesh-out.** Nothing in the
theme became closeable this week. No collision: none of the six, nor their
owning beads, is `in_progress` in another lane.

## Root-cause map

**One contributor, four unmerged PRs, and the theme is review-bound, not
triage-bound.** 4858 / 5137 / 5138 / 5145 are all vishnujayvel's, all `open`,
all carry `triaged`, and each already has an owning bead (mybd-dodi9,
mybd-54zj9, mybd-kj8rp, mybd-dcdfw). Four of the six stubs are blocked on those
four PRs. Nothing here is waiting on a triage decision; it is waiting on review
throughput against one author's queue — the shape the `author-clustered-pr-sweeps`
pattern exists for. Oldest, 4858, has been open 16 days.

**The CI-coverage premise under mybd-dodi9 expired, asymmetrically.** dodi9
(p1) parks 4858 because "the destructive `--fix` half ships with ZERO executed
CI coverage", and its reviewer recommended splitting: land read-only detection
now, hold the fix until coverage arrives. Coverage arrived — merged `132fec3f4`
(#5174, 07-30) and `d223edcb6` (#5185, 07-31), both verified as ancestors of
main, added a `Test doctor/fix (Dolt-backed, hard-require container)` job to
`pr.yml` running `./cmd/bd/doctor/fix/` under `BEADS_FIX_REQUIRE_DOLT=1`. But
grepping all of main's `pr.yml` for `doctor` returns exactly that one job: the
**destructive** half now runs on every PR and the **detection** half still does
not, which is the reverse of what "safe checks first" assumed. Filed as
**mybd-8kxvz** (p1). `mybd-qx3f` is partly resolved, not resolved; PR #5133
(review bead mybd-1e2yl) may be the remaining piece or may have been
superseded by #5174 — worth checking before reviewing it on its original terms.

**A "Closes" tag is not a scope guarantee, in either direction.** 5145 says
`Refs` and covers half its issue; 5137 says `Closes` and discloses an omission.
Both were caught by reading the PR body, which is cheap. The 5145 residual —
should a *pending* migration also gate `--fix`, or is applying it the normal
upgrade path — is an unmade design call, and it is the half nearer the original
fleet-skew incident. Filed as **mybd-fj2oj** (p2) so it survives the moment
someone closes mybd-uh8q on 5145's merge.

**Dep-edge hygiene is one stub short.** The 08-01 pass edged three of the four
PR-gated stubs. mybd-rnjr was missed and is the only doctor stub still
presenting to `bd ready` as independently actionable while its fix is in flight.

## New beads

- **mybd-8kxvz** (p1) — re-decide mybd-dodi9 against the corrected CI asymmetry.
- **mybd-fj2oj** (p2) — the pending-migration half of #4993, which survives 5145.

## Confidence and caveats

- **High** on every "still unfixed" claim: each is a named symbol or its absence,
  read from `upstream/main` @ `17824fc7c` this run, not from `bd-main/`'s
  working tree and not carried over from the 07-30 notes.
- **High** on all four PR states — fetched live from the GitHub API this run
  (`merged=false`, `merged_at=null` on each). Nothing was inferred from a
  timeline cross-reference.
- **Medium** on the two scope findings (5145 partial, 5137 omission): both come
  from the PR authors' own descriptions of their work. Reliable about intent,
  unverified against the diffs. Flagged as such on both stubs.
- **Medium** on mybd-8kxvz's practical effect: the CI job's existence and both
  commits' presence on main are verified from the workflow file and git history.
  I did **not** observe that job run against any PR, and specifically not
  against 4858, which is behind main and unrebased. "Would execute" is read
  from YAML, not from a green check.
- Not attempted: reading any of the four PR diffs, or reproducing jacobhausler's
  two cycle instances on #4814 (still their `bd dep list` output, not mine).
- No blocks. `bd`, GitHub, and `solo-recon` all available; no denied command
  changed a disposition.
