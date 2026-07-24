# State sweep: mybd + beads, 2026-07-21 → 2026-07-24 — the good, bad, and ugly

Owner request: sweep mybd and beads activity over the last few days and recommend
directions for the next agent batches. Sources: mybd git log, upstream
gastownhall/beads PRs/CI (gh), bd database (serial reads), pr-babysit patrol log,
reports/coffeegoddd-pr-sweep-2026-07-23.md.

## TL;DR

Unusually productive stretch: ~25 PRs merged upstream in two days, ~40 beads closed
since 07-21, the coffeegoddd backlog fully resolved, migration-chain hardening
(#4878) landed, and the new pr-babysit patrol did its first two unattended merges.
Main is green. The accumulating debt is *state* debt, not code debt: 57 in-progress
beads (oldest claim 2026-06-26), a contributor-PR queue of 30+ mostly stalled at
CHANGES_REQUESTED, and P0 triage items untouched since 07-17 — at least two of
which upstream may have just fixed out from under us.

## The good

- **Merge throughput.** 07-23/24 flushed a large backlog: Jim Wordelman's old
  `be-*` PRs (label filters #3971, PURGE #3663, mem-profile #3920, migration
  progress #3919, BEADS_MAX_ROWS tests #4160, test-DB refusal #3632), coffeegoddd's
  proxied-server trio (#5002/#5003/#4997), the dependabot cascade
  (#4705/#4707/#4709 + beads-mcp batch #4999), anisoptera's large #4877 (`--graph`
  full-field parity, 22 files, migration 0059), and steveyegge's #5006/#5008.
- **pr-babysit works.** Instituted after the #4942 incident, the patrol merged
  #5003 and then #4877 (2026-07-24T16:52Z) unattended — preflight, green checks,
  merge, bead closed, zero model tokens. Role split (sessions produce, patrol
  merges) held.
- **coffeegoddd sweep** (mybd-lw0b, see coffeegoddd-pr-sweep-2026-07-23.md): 2
  merged with maintainer fixes, 3 ancient PRs retired with attribution + re-cut
  requirements, follow-ups tracked in mybd-5bz2. Cross-vendor review again caught
  misses in both directions.
- **#4878 migration-chain hardening merged 07-23** (mybd-fevn deliverable),
  after a two-round cross-vendor review caught a chain-breaker.

## The bad

- **#4942 collision** (07-24 ~01:54Z): a parallel same-user session merged the Go
  1.26.5 bump with a red nix job mid-review of another session, main nix red ~2h.
  Institutional fix (babysitter) is right, but the patrol is not yet fail-closed —
  mybd-nfrv is the open follow-through.
- **Patrol looped BLOCKED on #4702 for ~11h** (05:52→16:52, every 12 min) without
  the "leave for agent judgment" path actually reaching an agent; a session had to
  manually merge main into the branch. #4702 is the last dependabot straggler:
  at sweep time 57 pass / 10 pending / 3 fail — two fails are the documented nix
  stale-commit artifact, but **Test (Proxied Dolt Cmd 1/15) failing needs a look**.
- **In-progress rot: 57 beads**, oldest claim 2026-06-26, a dozen+ untouched since
  early July. Same-user claims exclude nothing; they only hide work from
  `bd ready` and mislead cold-start agents.

## The ugly

- **bd-vs-reality drift.** mybd-8cxy / mybd-9abr (migration 0053/0047 failures)
  still in_progress though #4878 merged claiming #4690/#4695/#4353. mybd-zgxf
  (P0, `--claim` not a hard CAS, gh#4657) sat since 07-17 while steveyegge merged
  #5006 (claim verify-by-re-read) and #5008 (`--if-assignee`/`--if-status` CAS
  guards) that look like they address much of it. Unreconciled.
- **Contributor review queue**: 30+ open PRs, nearly all CHANGES_REQUESTED, some
  stalled since 07-17..19, clustered by author (ecuthiell ×6, athosmartins ×4,
  mohamedramadan14 ×3, julianknutsen's upgrade chain).
- **P0 triage from 07-17** still in `bd ready`: gh#4637 (missing server-identity
  check — real security gap, bead mybd-rr4x), gh#4521 (Dolt journal corruption —
  flagged `human`, needs the owner's call on the auto-repair stance).

## Recommended directions for the next agent batches

Best, in order:

1. **Drift-reconciliation sweep** — walk the 57 in-progress beads against what
   actually landed (#4878, #5006/#5008, #4877/0059), close done, unclaim stale,
   re-verify mybd-zgxf against the new CAS work. Cheapest, highest leverage;
   improves what every future cold-start agent sees. *(Started same session as
   this report.)*
2. **Author-clustered PR review sweeps**, coffeegoddd-style. Next cluster:
   ecuthiell's six PRs; then athosmartins, mohamedramadan14.
3. **mybd-nfrv fail-closed pr-babysit** — before the patrol gets more merge
   responsibility; the 11h #4702 loop shows the escalation hatch doesn't escalate.
4. **Finish the #4702 tail**: diagnose Proxied Dolt Cmd 1/15; if flake, patrol
   takes it.
5. **gh#4637 server-identity check** (mybd-rr4x) — well-scoped, security-relevant,
   not superseded.

Worst:

- Storage-boundary epic (mybd-hr4t.*) — blocked, design-heavy, API-freeze stakes.
- gh#4521 journal corruption — human design call first.
- Net-new features into an unreviewed 30-PR queue — review beats produce this week.
- Anything giving sessions merge authority or parallel bd writes — the #4942
  lesson is three days old.
