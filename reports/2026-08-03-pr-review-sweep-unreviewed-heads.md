# PR review sweep: every open non-draft PR without a maintainer review at its current head

**Date:** 2026-08-03 · **Session:** claude-fable-5-high, workflow-orchestrated
**Mandate:** review every open non-draft `gastownhall/beads` PR lacking a substantive maintainer review for its current head commit; publish reviews; no merges/closes/pushes to contributor branches.
**Outcome:** 14 publications (5 approvals, 8 comment-reviews, 1 prior-art coordination comment) across 13 PRs + 1 older prior-art PR; dry at close.

## Eligibility recon

95 open non-draft PRs at sweep start. A zero-token collector pulled reviews +
comments + head-commit dates for all of them; 81 already had maintainer
coverage at their current *content* head (patrol `update-branch` merges do not
invalidate a review — verified per-PR that head movement was branch-freshening,
not contributor pushes). The review-needed lane's 36 queued beads were mostly
contributor-response re-queues, not missing reviews.

Eligible: 10 contributor PRs + 2 maphew PRs. During the sweep 3 more arrived
(5316/5317/5318) and were triaged; 5312 merged upstream before review.

## Reviews published (13 posts)

| PR | Author | Disposition | Post |
|----|--------|-------------|------|
| [5277](https://github.com/gastownhall/beads/pull/5277) | maphew | ready-to-merge, 2 nits (comment — own PR) | [comment](https://github.com/gastownhall/beads/pull/5277#issuecomment-5163180049) |
| [5286](https://github.com/gastownhall/beads/pull/5286) | dependabot | **APPROVE** (easy win, verified locally) | review |
| [5315](https://github.com/gastownhall/beads/pull/5315) | julianknutsen | **APPROVE** (all 17 removed subtests traced to owners) | review |
| [5283](https://github.com/gastownhall/beads/pull/5283) | atbrace | COMMENT: verified **high** — dedup stubs break `filterTreeByStatus` (dup IDs); concrete fix given | review |
| [3458](https://github.com/gastownhall/beads/pull/3458) | quad341 | COMMENT: approve-with-followups; 3 cheap asks (JSON tags on `IssueSummary`, body refresh, fresh bench paste) | review |
| [5284](https://github.com/gastownhall/beads/pull/5284) | steveyegge | **APPROVE**; medium follow-up: tracked-hooks refusal bricks `bd config apply` for composed-hooksPath repos | review |
| [5285](https://github.com/gastownhall/beads/pull/5285) | steveyegge | COMMENT: one-line chmod-hoist regression before merge; CI rerun (unrelated uow race) | review |
| [5295](https://github.com/gastownhall/beads/pull/5295) | cosentinode | **APPROVE**; ask: `.Local()` on show_format DueAt/DeferUntil (east-of-UTC day shift) | review |
| [5297](https://github.com/gastownhall/beads/pull/5297) | cosentinode | COMMENT: fix correct; own test fails deterministically 4/4 — one-line `.Round(time.Second)` | review |
| [4730](https://github.com/gastownhall/beads/pull/4730) | jakelindsay87 | prior-art coordination: 5297 lands first, 4730 rebases with additive scope preserved; rebase is maintainer work if author silent | [comment](https://github.com/gastownhall/beads/pull/4730#issuecomment-5163476027) |
| [5310](https://github.com/gastownhall/beads/pull/5310) | julianknutsen | COMMENT: land once the §E3 exit-code precedence flip (12→10) is disclosed in body+docs, ideally pinned | review |
| [5293](https://github.com/gastownhall/beads/pull/5293) | julianknutsen | COMMENT: dual-vendor; 2 verified should-fixes (close-fence CAS, batch error taxonomy in *both* bodies); 1 Codex claim de-escalated as pre-existing | review |
| [5317](https://github.com/gastownhall/beads/pull/5317) | ecuthiell | **APPROVE** (every doc claim verified against actual CI wiring; discovered items → mybd-jp0l8) | review |
| [5318](https://github.com/gastownhall/beads/pull/5318) | julianknutsen | **APPROVE**; non-blocking gap: proxied `--no-inherit-labels` negative branch now untested at any seam | review |
| [5319](https://github.com/gastownhall/beads/pull/5319) | ecuthiell | COMMENT: EOL half verified sound (zero-renormalization claim reproduced); split of unrelated ci-gate hardening requested | review |

## Dual-vendor adjudication on 5293

Codex `gpt-5.6-sol` (high) flagged 1×P1 + 2×P2 transaction-boundary
regressions; the Claude conformance reviewer found none of them. A dedicated
verification agent traced head against merge-base 8b94291:

- **P1 close-fence: REGRESSION-CONFIRMED** (proxied route; base ran fence+close
  in one retried UoW, and the `row_lock` collision cell made the retry real).
  Direct route already had the gap. Fix: `ExpectedVersion` on `BatchCloseItem`.
- **P2 batch error taxonomy: REAL and NEW — in both batch bodies** (issueops
  *and* uow), including a no-survivor `tx.Commit()` path that lands a close
  with no history entry. No conformance slice covers infra failure.
- **P2 comment-template atomicity: PRE-EXISTING-EQUIVALENT, de-escalated** —
  base's single tx read a different table's cell; Dolt cell-merge meant the
  race was never detected at base either. (Same pattern as bd memory
  `dual-vendor-review-disagreement`.)

## Tests/checks run (by delegated reviewers, in detached worktrees)

Focused `go build`/`go vet`/`go test -tags gms_pure_go` per touched package on
every PR; highlights: 5293's uow (126s, 88 cases) + embedded (115s) conformance
legs; 5310's regression test under the sanctioned harness (10/10, zero panics)
plus 40× stress + 2× `-race`; 5297's test failure reproduced 4/4 incl. `-short`;
5283's regression reproduced via standalone algorithm extraction; 5284's three
manual end-to-end repros (symlinked hooks dir wrote through; composed-hooksPath
hard error; silent `.backup` sidecar). Pre-existing red found on main:
`TestRecomputeAllBlocked_RefusesDirtyDependencies` (tracked in mybd-jw9ch).

## Skipped and why

- **5202, 3859** — claimed in_progress by other active sessions (cebxh, 8chd.8).
- **5229, 5241, 5243, 5064, 5092, 4206, 4959** — covered at content head;
  head movement was our own lane merges.
- **5312** — merged upstream before review; bead closed.
- **5316** (maphew) — owned by open human-decision bead mybd-43k7j; findings
  already in reports/2026-08-02-ready-queue-autonomous-sweep.md; not duplicated.
- **81 head-matched PRs** — outside mandate (already reviewed at head). The
  review-needed lane queue for contributor *responses* remains open work.

## Follow-up beads filed

- **mybd-5dygy** — fix-merge candidate: 5283 `filterTreeByStatus` dup-ID fix
- **mybd-kvqho** — 3458: wiring-PR tracking + stale coffeegoddd CHANGES_REQUESTED needs owner dismissal decision
- **mybd-g2g01** — 5284 tracked-hooks refusal affects our own composed-hooksPath repos (local action on next bd deploy)
- **mybd-s8wbq** — 5285 chmod hoist + anti-dup test + re-run 4791 after landing
- **mybd-jw9ch** — UTC cluster: 4730 rebase-carry, pre-existing red test on main, `NOW()` remnants, gh 5233 data-repair question, first-contributor CI gates
- **(5310 bead)** — init-safety doc bug (exit 11 vs 12) + two pre-existing preflight hazards
- **(5293 bead)** — two should-fixes + CAS-series sequencing question

## Budget note

Workflow + verification agents: ~1.05M subagent tokens + one Codex reviewer run
(separate pool, logged per policy) — well over the 200k soft target, spent on a
13-PR mandate; no stage was skipped to stay under target.

## What I noticed that isn't on any list

The review-needed lane queues on *any* contributor activity, so its backlog
conflates "needs first review at head" (this sweep's mandate, 11 PRs) with
"contributor replied, needs an answer" (~25 beads still open). Those response
beads are real waiting-contributor work (`mybd-aayb` class) that this sweep
deliberately did not touch — the queue is not as done as the closed beads make
it look.

_claude-fable-5-high on behalf of maphew_
