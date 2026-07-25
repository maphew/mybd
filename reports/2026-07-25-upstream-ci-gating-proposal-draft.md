# Upstream proposal — finish the required-gate rollout (merge queue + batching + auto-revert)

Status: **POSTED** 2026-07-25 as
[gastownhall/beads#5053](https://github.com/gastownhall/beads/issues/5053),
approved by maphew (title reworded to plain language per his review; body as
below plus #4391/#4392 issue refs, cc to admins steveyegge/csells/julianknutsen,
and the analysis-session transcript link). Tracking bead: mybd-jcx5.

---

## Posted issue title

Why is CI consistently jammed, and what can we do about it?

## Proposed issue body

### Summary

`engdocs/CI_REQUIRED_CHECK_TOPOLOGY.md` lays out an 8-step rollout to required
aggregate checks and a merge queue. Steps 1–6 shipped months ago — `PR / CI
Gate / Required` and `PR Risk / CI Gate / Required` exist, and `pr.yml`,
`pr-risk.yml`, and `conformance.yml` all already handle `merge_group` events.
Step 7 (require the gates in the default-branch ruleset) was never executed:
the live ruleset enforces only deletion and non-fast-forward.

We (downstream maintainers at maphew/mybd) classified 39 red-CI incidents from
our maintenance logs (May–July 2026) and measured the current state of `main`.
The data says the missing step 7 is now the dominant source of red main, and
that merge-queue **batching** answers the throughput concern that most
plausibly stalled the flip.

### Evidence

- **Ungated lane.** 17 of the last 60 first-parent commits on `main` are
  direct pushes that never ran PR CI. Both June direct-push breakages
  (issues 4391, 4392) and the July 25 macOS firefight came through this lane —
  including three consecutive direct-pushed fixes that each failed
  `Test (macos-latest)` again.
- **Saturation.** Pushes land on `main` roughly every 54 minutes; a Main run
  takes 35–75 minutes wall-clock (critical path: `Test (Embedded Dolt
  Storage)` at ~24 min, conformance halves ~14 min each). Result: 19 of the
  last 40 Main runs were cancelled by the next push — nearly half of main's
  commits never received a completed CI verdict.
- **Compounding.** The July 5–7 outage kept main red ~33 hours because
  "these failures are pre-existing" reasoning let four independent breakages
  stack. Semantic conflicts between individually-green PRs caused at least
  three more incidents; a merge queue tests the merged composition and closes
  that class too.

### Proposal

1. **Execute steps 7–8 of the existing rollout doc**: require the two
   aggregate gates via the default-branch ruleset; remove any direct
   job-name requirements.
2. **Enable GitHub merge queue on `main` with batching** (e.g. batch size
   5, timeout tuned to one gate run). At the current cadence this amortizes
   the ~25-minute gate to ~5 minutes per change — higher effective
   throughput than today once rework from red main is counted.
3. **Route the direct-push agent lane through the queue.** `gh pr create`
   plus `gh pr merge --auto` is scriptable inside the existing agent
   gateway; changes keep flowing unattended, but through the gate.
4. **Auto-revert/quarantine for whatever still lands red**: a small workflow
   that, on a deterministic Main failure (one rerun to rule out flake),
   reverts the offending commit or quarantines the failing test and opens a
   tracking issue — bounded time-in-red instead of hours of firefight.
5. **(Parallel, not blocking) shrink the gate itself**: shard
   `Test (Embedded Dolt Storage)` the way `test-embedded-cmd` already is
   (~24 min → ~5–8 min), which lowers the cost of every queue run and
   weakens the incentive to bypass.

### Why now

The gate plumbing is built and verified; only the ruleset flip is missing.
Every week without it converts contributor PR reviews into archaeology over
which failures are "pre-existing," and the fix-forward pushes during
firefights are themselves ungated — the July 25 sequence shows that loop
clearly.

---

Posted with: cc @steveyegge @csells @julianknutsen · transcript
https://claude.ai/code/session_01HmGSvX14yJcKD8Ezw7qZwd ·
signature `_claude-fable-5-xhigh on behalf of maphew_`
