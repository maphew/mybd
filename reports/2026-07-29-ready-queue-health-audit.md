# Ready-queue health audit — 2026-07-29

Question asked: how many ready items are there, how does that compare with 24 /
48 / 72h ago, what is the drain vs fill rate, and is this a balanced system or
are we lurching from one thing to the next?

## Method and its limits

bd keeps no historical snapshot of `bd ready`, so the backlog series below is
reconstructed from timestamps in `bd list --all --json`: created-to-date minus
closed-to-date at each offset. That list output has no `closed_at` field, so
**`updated_at` stands in as the close time** for closed issues — accurate for
the large majority, since closing is normally the last write, but not exact.
(`bd show` / `bd close --json` *do* expose `closed_at`; only the bulk list path
omits it. A per-issue pass over 1053 closed beads was not worth the precision.)

The series is therefore **open backlog**, not ready count. Ready is a subset
(open, unblocked, unclaimed, non-deferred). Shape is trustworthy; absolute
values are ±.

Counts drifted during the session — 326 → 335 → 349 ready across roughly two
hours — because the pr-babysit patrol keeps filing. Treat any single number
here as a sample, not a constant.

## Numbers

Total ready at audit time: **335** (`bd stats` reported 326 from a different
code path; `bd ready --json` defaults to a 100-item limit, which is the easy
way to undercount this).

| | open backlog | 24h fill | 24h drain | net |
|---|---|---|---|---|
| now (07-29 06:00Z) | 526 | 108 | 71 | +37 |
| 24h ago | 489 | 28 | 86 | −58 |
| 48h ago | 547 | 397 | 121 | **+276** |
| 72h ago | 271 | 68 | 68 | 0 |
| 96h ago | 271 | 37 | 71 | −34 |
| 120h ago | 305 | 41 | 27 | +14 |
| 168h ago | 298 | 5 | 12 | −7 |

## Reading

**Two regimes, split by one event.** Before 07-26 the system was at
equilibrium: backlog pinned in a 270–305 band for a week, daily net oscillating
between −34 and +14.

**On 07-26, 397 issues were created in one day** — the bulk upstream triage
mirror, not organic demand (292 tasks; 70 landed straight in `tri:defer`; 26
`theme:pr-mirror`). Backlog stepped 271 → 547 and has not returned. Of that
batch: 147 already closed, 74 deferred, 152 still open.

**Drain capacity is real and steady: 70–120 closes/day.** Excluding the
injection, fill runs 28–108/day. Drain ≈ fill. The system is not underwater; it
swallowed something large.

**The age profile says this is a working organism, not a lurching one** — and
age is the metric that cannot be faked:

- 234 of 335 ready items (70%) are under 3 days old; exactly **one** is older
  than 30 days.
- Nothing in ready has gone untouched for 30+ days; only 25 are stale by 7+.
- 150 beads sit `deferred` — the queue stays young because we actually say no.
- No `base-red` P0. The stop-the-line alarm is quiet.
- Patrol lanes alive: 6 `review-needed` queued, several `close-when-quiet`
  mid-window.

At 335 deep with ~70/day drain, Little's law puts residence at ~5 days, which
matches the observed age distribution. The queue is consistent with itself.

## Three findings

1. **P0s were camouflaged.** Five (now six — `mybd-rr4x` returned to ready
   mid-audit) P0 silent-data-loss beads sat in a ~335-deep pool. A P0 queued
   behind 330 items is not prioritised, it is hidden. → `mybd-6ozys`.
2. **`mybd-0bxs` was claimed and untouched since 2026-07-12** (17 days, lease
   expired). Investigation showed it was not merely stale but *obsolete*:
   upstream PR #4350 was closed 2026-07-29 by the patrol in favour of #4720,
   with the surviving work tracked in open bead `mybd-bc9cc`. Closed as
   superseded. Stale claims are a silent leak — the patrol skips claimed beads,
   so a dead claim parks a lane indefinitely.
3. **The queue stopped being ours.** 187/335 ready items (56%) are
   upstream-mirrored stubs and 176 are default P2, so `bd ready` answers "what
   exists upstream" rather than "what should I do next" — which is *why* the
   P0s vanished. → `mybd-xhb6x`, delivered as `scripts/ready-lanes`.

Throughput was never the problem. The triage lens had lost its focal length.

## Not on any list

The `bd list --json` / `bd show --json` field asymmetry around `closed_at` is
worth knowing before anyone else tries to measure flow here: the bulk path
silently omits it, so a naive throughput script will reach for `updated_at`
without noticing it is a proxy. Not filed as a bead — it is upstream surface
area and may be deliberate — but recorded here so the next measurement starts
informed.

_claude-opus-5-medium on behalf of maphew_
