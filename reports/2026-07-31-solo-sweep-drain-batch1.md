# solo-sweep drain, batch 1 — the not-in-`bd ready` slice

**Date:** 2026-07-31
**Session:** interactive (Claude Code, opus-5, high reasoning), owner present via remote control
**Scope:** adjudicate solo-sweep proposals that the two concurrent `bd ready` drainers structurally cannot reach

## Why this slice

Three other sessions were live when this one started: one on red `main` CI, two draining
`bd ready` from opposite ends (oldest-first and newest-first). Claims cannot fence parallel
sessions here — all local sessions run as the same user, so `bd update --claim` is
idempotent and excludes nobody (see `agent-batch-current`, and the 2026-07-24 incident
behind the role-split rule).

So the lane was chosen by **structure, not by claim**. At session start the solo-sweep batch
was 70 beads labeled `solo-sweep:proposed`; 31 of them were in `bd ready` and therefore in
the two drainers' path. This session took the **32 that were not in `bd ready`** — beads that
are blocked, or otherwise invisible to a `bd ready` consumer. Disjoint by construction, no
coordination needed.

Composition of the 32:

| Proposal | Count | Action taken |
|---|---|---|
| `proposed=close` | 10 | all 10 verified and closed |
| `proposed=flesh-out` | 5 | 4 adjudicated, 1 deliberately skipped |
| `proposed=keep-open` | 11 | no action required (see "not done") |
| new engineering beads filed by the lane | 6 | not stubs, nothing to adjudicate |

## The headline: 10 of 10 close proposals survived verification

The solo-sweep lane exists because the triage-drain strategy report measured a **~30%
false-positive rate on "fixed upstream" recon claims**, which is why the lane is forbidden
from closing anything itself. This batch is the first real calibration of that fear against
the lane's actual output.

Every one of the ten was re-verified independently this session, not taken on trust:

- every claimed fixing commit re-checked with `git merge-base --is-ancestor <sha> upstream/main`
  (tip `9973e9628`) — **10/10 genuine ancestors**, none merely referenced;
- every claimed code change re-read in the tree at `upstream/main`, not in a working copy;
- every cited PR's merge state re-queried — and the four contributor PRs the lane explicitly
  warned *not* to credit (#3797, #3801, #3802, #3806) are indeed all CLOSED-unmerged, exactly
  as it said.

**Zero false positives.** The lane's caveats were also accurate rather than defensive: where
it said "this is a SKIP, not a fix" or "this is covered-by-family, there is no fix PR", the
source agreed.

That is a meaningfully better hit rate than the strategy report's prior, and it is the
strongest argument so far that the lane's `proposed=close` notes are worth an adjudicator's
time. It is **not** an argument for letting the lane close beads itself — the value came from
a second pair of eyes finding things the lane could not (below).

### What verification added that the lane could not

1. **mybd-a7wxv — the lane's one self-declared unverifiable claim, resolved.** gh 3982 had a
   second ask ("release beads-mcp to PyPI") that the read-only lane had no network to check.
   Checked here: **beads-mcp 1.1.2 was published 2026-07-26 requiring `fastmcp==3.3.1`** —
   precisely the pin the issue asked for. Both asks satisfied, no split needed, close is clean.

2. **mybd-1yi6x — the flagged recon gap closed, and it is wider than described.** The lane
   inferred the Agent Documentation half of gh 3705 from a shared root-cause argument without
   reading `agentDocFiles`. Read here: `cmd/bd/doctor/legacy.go:19` is a pure `filepath.Join`
   over its argument with no resolution logic of its own — so the defect is entirely in the
   `repoPath` handed to it, and **four** checks consume it (`legacy.go:44`, `:98`, `:158`,
   `claude.go:365`), not one. The inference was right; the blast radius was understated.

3. **mybd-8bse — a third asymmetry the lane missed.** It correctly found that
   `AffectsReadyWork()` includes `DepParentChild` while `IsBlockingEdge()` excludes it. But
   `addBlockingDependencyEdge()` (`cmd/bd/doctor/integrity.go:353`) admits only `DepBlocks`
   and `DepConditionalBlocks` — it drops `DepWaitsFor` as well, which `IsBlockingEdge`
   *includes*. The doctor cycle detector is narrower than **both** predicates, so a waits-for
   cycle is invisible to it too. A fix that only reconciles the parent-child half leaves this
   standing.

4. **mybd-j2v39 — a near-miss on my side, not the lane's.** My first grep for `commitBeforePull`
   found it in only one federation backend, appearing to refute the lane's "BOTH backends"
   claim. Reading further: `internal/storage/embeddeddolt/federation.go` achieves it via
   `CommitPending`, citing the same GH#2474. Different function name, same guarantee. The
   claim was correct and a shallower check would have wrongly refuted it.

## Closed (10)

| bead | upstream | basis |
|---|---|---|
| mybd-2n1ns | gh 3796 | #4600 / `7865493f7` |
| mybd-u8vex | gh 3798 | #4600 / `7865493f7` |
| mybd-5fbkt | gh 3805 | #4600 — **skip, not fix**; gap survives as mybd-zqgat |
| mybd-nfvi1 | gh 3800 | #4600 — **skip, not fix**; gap survives as mybd-zqgat |
| mybd-d3f7j | gh 3962 | `c0bdf4972` |
| mybd-ec9bm | gh 3463 | #3446 / `456a66071`; residual survives as mybd-l07hc |
| mybd-j2v39 | gh 3547 | #4190 / `352bdb3c2` + #4412 / `387959695` |
| mybd-jnrff | gh 3787 | `651a52afe` (both export paths) |
| mybd-rkn87 | gh 4331 | **covered-by-family, no fix PR exists** |
| mybd-a7wxv | gh 3982 | `e1c8b8b97` (#3957) + PyPI 1.1.2 |

Three of these are *not* plain "fixed by PR N" and must never be flattened into one: two are
test **skips** whose product gap survives in `mybd-zqgat`, and `mybd-rkn87` is closed because
the mechanism is gone from main, not because anyone fixed it.

## Adjudicated without closing (4)

- **mybd-1yi6x** (doctor, bare+worktree layout) — acceptance criteria written, including the
  four-check blast radius found above.
- **mybd-8bse** (cycle detector) — acceptance criteria written covering the three-way predicate
  disagreement; **wired `blocked-by mybd-p2wyk`**, which is the general fix. The originally
  filed predicate is recorded as insufficient so nobody implements it as asked.
- **mybd-co9w9** (DOLT_BACKUP) — scope narrowed to the explicit-CLI backup path; the auto and
  push/pull paths are fixed. #3595 re-confirmed **OPEN and unmerged** — referenced-not-merged.
- **mybd-k4s27** (steveyegge refs) — relabeled `human`: this is the owner call on the Go module
  path rename, deferred by maphew 2026-04-07 and still unmade (`go.mod:1` unchanged). Refreshed
  scope at `upstream/main`: 1286 files, 1257 of them `.go` carrying the module import path. The
  mechanical non-module subset is **mybd-qcshp**, now wired `discovered-from mybd-k4s27`.

Both dep edges were missing before this session — a textbook instance of cold-start rule 3:
the prose said "I filed X for the mechanical subset, keep this for the owner call", and
`bd ready` could not see any of it.

## Deliberately not done

- **mybd-qx3f** — the one intentional skip. It asks for PR-CI coverage of the Dolt-backed
  `cmd/bd/doctor` tests, which is exactly the surface of **mybd-1fisj**, `in_progress` in
  another session's lane as a live red-main P0. Acting on it would race that fix, and the fix
  may change what coverage is even needed. Left labeled `solo-sweep:proposed` on purpose, with
  the reason recorded as a bead comment.
- **The 11 `proposed=keep-open` beads** — left labeled `solo-sweep:proposed` and *not*
  relabeled adjudicated. Keep-open is the conservative verdict with no action attached; marking
  them adjudicated would falsely signal they had been verified. Worst case for a wrong
  keep-open is a bead that stays open longer than it should, which is the cheapest failure in
  this batch. Lowest-value slice, genuinely remaining work.
- **Nothing was published upstream.** All ten closes are bd-side only; all ten upstream issues
  are still OPEN.

## The debt this batch created

Closing a bd stub does not answer the reporter. All ten upstream issues remain open and owe a
reply naming the fixing commit, and publication is human-gated through `scripts/tri-submit`.
That pointer would have died inside ten *closed* beads, where a cold-start agent running
`bd ready` never looks — so it is now **mybd-oq115** (P2, `human`), one open bead carrying the
per-issue script for all ten.

The heaviest item in it: **gh 3962** (fkberthold). The fix landed roughly seven hours after we
told them it was unfixed, and their June request for a repro was never answered.

## Numbers

- solo-sweep batch at session start: 70 proposed (65 open, 5 in_progress); 31 in `bd ready`.
- This session: **10 closed, 4 adjudicated, 2 dep edges wired, 1 new open bead, 1 deliberate skip.**
- Remaining in the drain queue after this batch: ~53 proposed-open, the bulk of it the
  `bd ready`-visible half the other two sessions are working.
- Verification cost: ~25 read-only shell calls. No subagents, no workflow — three sessions were
  already competing for the host, and the work was serial verification rather than fan-out.

## What I noticed that isn't on any list

The solo-sweep lane's output is accumulating faster than it is consumed — 8 proposals per run
every 6h against, until today, zero adjudication in two days. The lane is working; the
*queue* is the bottleneck, and its safety design guarantees that (it may propose but never
publish, so a human or an interactive session is always the throughput limit). If the
remaining 7 runs in the window land at the same rate, the batch will roughly double before the
window closes 2026-08-05. Worth deciding whether that is fine (a rich reviewed backlog) or
whether the arming window should be shortened to match actual drain capacity.

Second: this batch's 10/10 verification rate is one sample from one adjudicator on the
close-proposal subset only. It should not be generalized into "the lane can be trusted to
close" — the strategy report's 30% figure covered recon claims broadly, and the four
value-adds listed above all came from a *second* actor, not from the lane being right.

_claude-opus-5-high on behalf of maphew_
