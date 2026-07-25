# mybd + Beads state sweep and next-batch orchestration

Date: 2026-07-25  
Window: 2026-07-21 through 2026-07-25  
Control bead: `mybd-9i93`

## Executive read

The last few days were exceptionally productive, but Beads is beginning to
outrun its control plane. The best next batch should emphasize reliability,
review completion, and state reconciliation rather than adding more feature
surface.

The durable orchestration model is deliberately three-layered:

1. This report preserves evidence, judgment, and the reason for the ordering.
2. Beads owns executable state: work items, dependencies, acceptance criteria,
   routing metadata, verification state, and outcomes.
3. Handoff prompts are generated from a selected live bead at dispatch time.
   They are transport, not durable project state.

A prompt such as “read this report and start the next batch” is therefore a
useful human entrypoint, but it must resolve into `bd ready` plus a specific
bead before an agent acts.

## Activity pulse

| Signal | Snapshot |
|---|---:|
| Upstream PRs merged | 75 |
| PRs closed unmerged | 10 |
| Open upstream PRs | 151 |
| Open upstream issues | 483 |
| mybd beads created since July 21 | 92 |
| mybd beads closed since July 21 | 111 |
| mybd beads in progress | 19 |
| In-progress beads that are explicit merge tails | 15 |
| Tracker lint | 260 warnings across 221 issues |
| Latest checked upstream `main` | Green |

The queue-clearing work is real: contributor PRs landed from anisoptera,
ecuthiell, imkp1, marcodelpin, pvinis, DyrtyJax, and others. The tracker also
closed more work than it created during the window.

## The good

- Author-clustered reviews are producing coherent outcomes instead of
  contributor starvation. The ecuthiell, athosmartins, mohamedramadan14,
  coffeegoddd, and singleton sweeps all preserved and landed useful work.
- Cross-vendor review repeatedly caught distinct real defects: vacuous tests,
  readonly side effects, proxy identity gaps, PID-reuse hazards, and fail-open
  cleanup behavior.
- Recent upstream work is focused on trust-critical behavior: conflict
  visibility, three-way issue merges, replica-aware leases, no-op versus
  vanished-row writes, sync retry, and managed proxy lifecycle safety.
- `pr-babysit` established the right role split. Sessions review, fix, and hand
  off; the patrol merges after fresh blocking preflight. Most current
  `in_progress` beads are now explicit merge tails rather than hidden work.
- Proxied-server work has real lifecycle evidence. The managed-local Linux
  offline lane landed, and the proxy identity candidate passed its recorded
  full-suite verification at the exact `verify_head`.
- Upstream base health recovered from the nightly failure recorded earlier on
  July 25 and was green at the final sweep.

## The bad

- The upstream queue remains very large and clustered: 151 open PRs. Large
  author groups include harry-miller-trimble, vishnujayvel, kevglynn,
  julianknutsen, and steveyegge.
- Tracker selection is weak. `bd ready` exposes 221 of 234 open issues, while
  221 issues also produce lint warnings. Many are intentionally thin upstream
  mirrors, but cold agents still see an insufficiently discriminated pool.
- Dependabot singleton Go-module updates are structurally wasteful here.
  `go.sum` changes invalidate the Nix `vendorHash`; bot vendor-hash pushes do
  not retrigger CI; each subsequent singleton rebase repeats the cycle.
  Upstream PR #5038 is the correct grouping fix but was not yet green at the
  final check.
- The nested `bd-main` source root is not a usable integration baseline. It was
  detached, three commits ahead and 71 behind the local `upstream/main`, with
  roughly 194 staged paths plus unstaged hook edits. Several linked source
  worktrees are also dirty and must be treated as owned, live state.

## The ugly

- PR #4942 merged with a red Nix job while another same-user session was
  reviewing it, leaving main red for about two hours. The patrol then needed
  five rapid hardening commits.
- The first patrol tail looped on PR #4702 for roughly eleven hours without
  successfully surfacing an actionable escalation.
- The drift sweep spawned 52 agents and spent roughly 2.1 million subagent
  tokens against a 200,000-token target. Parallel builders and tests also
  exhausted process capacity, and shared stash state collided across
  worktrees.
- A July 21 `bd admin reset` experiment resolved the wrong target and removed
  the global `.beads` directory plus source-repository hooks. Destructive reset
  and recovery work is not a fast-tier assignment.
- Upstream issue #5012 is the sharpest current technical risk. Proxied fresh
  initialization intermittently sees dirty pre-existing schema state and a
  MySQL busy-buffer symptom. The same infrastructure failure contaminates
  otherwise viable contributor PRs.
- The julianknutsen deterministic-upgrade stack conflicts with the current
  Dolt-only product direction. It is a design-integration program awaiting a
  path decision, not a rebase chore.

## Encoded next batch

The control plane is the open epic `mybd-9i93`. Run:

```bash
bd show mybd-9i93
bd ready --parent mybd-9i93
```

### Parallel lane A: proxy reliability

Bead: `mybd-4t6s`  
Routing: mixed, staged, `gpt-5.6-sol`, xhigh  
Parallel group: `batch-proxy-reliability`

Own upstream issue #5012 as one semantic invariant. Reproduce or establish a
defensible non-reproduction window; identify the transaction/connection
boundary behind dirty-schema detection and the busy-buffer symptom; then
delegate only a bounded implementation in an isolated source worktree.

Coordinate with active #5013, #5024, and #5027 work. Do not collide with the
existing `pr-5027-review` worktree, and do not add more proxied command surface
as part of this bead.

### Parallel lane B: quad341 author sweep

Bead: `mybd-9i93.1`  
Routing: mixed, staged, `gpt-5.6-sol`, high  
Parallel group: `batch-pr-quad341`

Review #5028, #5029, and #5030 together. They were clean with no bad checks at
the sweep and look like immediate safety and benchmark-boundary wins. Separate
older #3906/#3458 into a performance-design decision rather than sweeping them
through as easy wins.

### Parallel lane C: rjc123 author sweep

Bead: `mybd-9i93.2`  
Routing: mixed, staged, `gpt-5.6-sol`, high  
Parallel group: `batch-pr-rjc123`

Treat #5032 and #5035 as a paired CI-hygiene story, then assess #4815, #4821,
and #4844. If storage or child-ID correctness expands beyond a bounded review,
split that subset into a separate high-risk bead.

### Serial control-plane lane: Dependabot and merge tails

Bead: `mybd-ysu1`  
Routing: mixed, staged, `gpt-5.6-terra`, medium  
Parallel group: `batch-merge-tails`

This lane waits for #5038, confirms grouped PR creation and superseded
singleton closure, ensures CI runs on bot vendor-hash heads, and hands green
tails to `pr-babysit`. It owns reconciliation, not interactive merging. All
`bd`/Dolt and GitHub write operations remain serial.

### Gated next author selection

Bead: `mybd-9i93.3`  
Routing: explorer, delegated, `gpt-5.6-terra`, medium  
Parallel group: `batch-pr-next`

This bead is blocked by the quad341 and rjc123 sweeps. It cheaply compares the
harry-miller-trimble and vishnujayvel heads against their July 24 reviews.
Only updated or concretely fixable branches earn another full reviewer/builder
batch. Unchanged `CHANGES_REQUESTED` heads are recorded and deferred.

## Dispatch pattern

The orchestrator should dispatch one specific bead, not the whole report:

```text
Work bead <id>. Run bd prime, then bd show <id> --json and follow its
execution_* metadata. Read
reports/2026-07-25-mybd-beads-sweep-and-next-batch.md for rationale, but treat
GitHub and Beads as live state. Claim the bead before writes. Source edits use
an isolated worktree. Do not run bd/Dolt operations in parallel. Do not merge
interactively; hand green tails to pr-babysit. Record outcomes and discovered
work back in Beads before closing.
```

For a human, the shorter entrypoint is sufficient:

```text
Read reports/2026-07-25-mybd-beads-sweep-and-next-batch.md, inspect
mybd-9i93 with bd, and dispatch the ready child beads according to their
execution metadata and dependencies.
```

The short prompt works because the executable details live in Beads. Without
the Beads graph it would be an underspecified, rapidly stale instruction.

## Directions to avoid

- Generic builders told to clean up or finish the dirty `bd-main` root.
- More proxied feature expansion before #5012 is contained.
- The julianknutsen ownership/CAS/upgrade program before its path decision.
- Fast-tier agents touching migrations, storage integrity, embedded `doctor`,
  admin reset, PID cleanup, or destructive recovery.
- Wide workflow fan-out, parallel heavy test storms, shared stashes, or
  parallel `bd`/Dolt operations.
- Restoring interactive-session merge authority.

The desired batch is intentionally small: three independent high-value lanes,
one serial control-plane lane, and one dependency-gated scout for what follows.
