# Report reading room

> **Experiment, 2026-08-10.** This is a hand-curated reading surface over the
> report stream, not a new source of operational truth. Beads remains current
> for work state; reports preserve what the work meant when it happened. This
> page is deliberately a one-off prototype so its usefulness can be judged
> before any generator, metadata convention, or site is built.

## Start here

The repo changed identity on 2026-08-10: maphew stepped down as a Beads
maintainer and the maintainer control plane became a contributor workspace.
Read [the role-change teardown](2026-08-10-ic-role-change-teardown.md) first.
It records the lane shutdown, backlog collapse, repository cleanup, a serious
worktree-pruning incident and recovery, corrections to the salvage assessment,
and the resulting contributor priorities.

Then read [the unfiled-defect harvest](2026-08-10-unfiled-defect-harvest.md).
It is the first substantial follow-through in the new role: 31 verified defects
that existed only in local review findings were converted into upstream issues
rather than retained as a private maintainer-era asset.

That transition is a fault line in this archive. Reports before it remain
useful evidence and institutional history, but recommendations that assume
merge, close, label, release, or upstream-triage authority are historical.

The immediate operational follow-through is `mybd-jcylm`: decide the fate of
the four upstream PRs still authored by maphew. Use `bd show mybd-jcylm` for
their current state; the report explains why that work became important.

## What this room is trying to preserve

Beads and reports answer different questions:

| When the question is… | Start with… |
|---|---|
| What can be worked now? What is blocked? | `bd ready`, `bd show`, dependencies |
| What actually happened, and why did it matter? | a dated report |
| How did the working theory change? | a sequence of reports, including corrections |
| What deserves thought but is not yet a commitment? | open questions and observations in reports |
| What became durable operating knowledge? | `bd memories`, `AGENTS.md`, and project docs |

A report may result from a bead, span many beads, or create beads that did not
exist when the investigation began. It is a dated interpretation, not merely a
large issue attachment.

## Active threads

### Contributor reset

**Read:**

- [Maintainer → contributor teardown](2026-08-10-ic-role-change-teardown.md)
- [Unfiled-defect harvest](2026-08-10-unfiled-defect-harvest.md)

**Live Beads context:** `mybd-jcylm` and its four PR-specific beads.

**Questions now:** Which existing contributions are still worth shepherding?
Which maintainer-era commitments should be retired rather than quietly carried
into the contributor role? What lightweight habits replace automation that
previously supplied queue awareness?

### Local-first proxied Dolt

**Read in this order:**

1. [Production-readiness audit](proxied-server-production-readiness.md) — the
   full acceptance journey, invariants, and missing production paths.
2. [Campaign review sweep](2026-07-26-proxied-campaign-review-sweep.md) — what
   moved after the audit and which findings became concrete work.
3. [Proxy identity design](2026-07-24-psxg5-proxy-identity-design.md) — one
   important safety seam in detail.

**Live Beads context:** `mybd-psxg` remains open. Its campaign is 2/5 complete;
the executable/version contract (`mybd-psxg.4`) and safe copy migration
(`mybd-psxg.2`) remain open, along with a live concurrency blocker.

**Question now:** Does this remain the right large contribution campaign after
the role change, or should it be decomposed into smaller upstream contributions
that do not require local campaign ownership?

### Agent and session machinery

**Read:**

- [Cross-runtime session machinery retrospective](2026-07-25-cross-runtime-session-machinery-retrospective.md)
- [Independent second opinion](2026-07-25-session-machinery-retro-claude-second-opinion.md)
- [Orchestration-layer landscape](2026-07-29-orchestration-layer-landscape.md)

The retrospective separates execution quality from the work being executed.
The landscape report asks whether the former maintainer automation stack was
reinventing an existing orchestration product. Much of the lane-specific
recommendation is now historical, but the findings about isolation, recovery,
cross-runtime policy, and local-first orchestration still apply.

**Live Beads context:** the cross-runtime follow-ups under `mybd-lq8i` remain
open. The maintainer lanes discussed in the landscape report were removed on
2026-08-10.

**Question now:** Which guardrails are properties of sound agent work in any
role, and which existed only to support maintainer-scale throughput?

### What `bd ready` cannot express

**Read:**

- [`bd ready` gating audit](2026-07-31-ready-gating-audit.md)
- [Human-gating conversion](2026-08-01-bd-ready-human-gating-conversion.md)
- [Cold-start readiness and session close](2026-07-05-cold-start-readiness-session-close.md)

These reports explain why a mechanically ready queue can still contain work
that is not socially, temporally, or operationally claimable. They also expose
the opposite failure: knowledge can exist in a report or closed bead while
remaining invisible to the next cold-started agent.

**Live Beads context:** `mybd-jrbuu` and `mybd-zg2dj` cover dependency types
that fail to express the intended gating semantics. `mybd-0nzhq` is this
reading-room experiment.

**Question now:** Is the missing layer better represented as richer scheduling
semantics, or should some uncertainty intentionally remain narrative until a
person turns it into a commitment?

## Questions worth carrying

These are editorial prompts, not another task queue:

- What changed in our understanding, rather than merely in repository state?
- Which conclusion in a recent report is now stale, contradicted, or awaiting
  evidence?
- Which repeated observation has earned promotion into a memory, policy, test,
  or upstream contribution?
- Which apparent next action is really a question that should remain open?
- What was noticed that still is not on any list?

When one of these becomes a commitment, it belongs in Beads. Until then, its
ambiguity is useful information rather than missing issue metadata.

## The recent story

| Period | Read | Why it matters now |
|---|---|---|
| 2026-08-10 | [Role-change teardown](2026-08-10-ic-role-change-teardown.md) and [unfiled-defect harvest](2026-08-10-unfiled-defect-harvest.md) | Resets the meaning of everything that came before it, then converts the main unreported asset of the maintainer period into 31 upstream issues. |
| 2026-08-03–04 | [Stale-tail sweep](2026-08-04-stale-tail-pr-sweep.md) and [unreviewed-head sweep](2026-08-03-pr-review-sweep-unreviewed-heads.md) | Last broad maintainer-era picture of the upstream queue; useful history, no longer an operating mandate. |
| 2026-07-30–08-02 | [Ready-queue sweep](2026-08-02-ready-queue-autonomous-sweep.md), [human-gating conversion](2026-08-01-bd-ready-human-gating-conversion.md), and [ready-gating audit](2026-07-31-ready-gating-audit.md) | A burst of automation exposed the gap between database readiness and humanly claimable work. |
| 2026-07-29 | [Orchestration-layer landscape](2026-07-29-orchestration-layer-landscape.md) | Tested whether the local management machinery duplicated existing systems; its evidence outlives the machinery. |
| 2026-07-23–27 | [Proxied readiness audit](proxied-server-production-readiness.md), [session retrospective](2026-07-25-cross-runtime-session-machinery-retrospective.md), and [PR-stall postmortem](2026-07-27-pr-4376-postmortem-stall-supersede-audit.md) | Three durable investigations into product readiness, agent reliability, and the human cost of queue delay. |

## Durable shelf

These reports are good entry points when the need is understanding rather than
catching up:

- [Proxied Dolt production-readiness audit](proxied-server-production-readiness.md)
- [Orchestration-layer landscape](2026-07-29-orchestration-layer-landscape.md)
- [Cross-runtime session machinery retrospective](2026-07-25-cross-runtime-session-machinery-retrospective.md)
- [PR #4376 stall and supersession postmortem](2026-07-27-pr-4376-postmortem-stall-supersede-audit.md)
- [Cold-start readiness and session-close design](2026-07-05-cold-start-readiness-session-close.md)
- [CGO build divergence: root cause and solution](2026-05-29-cgo-enabled-build-divergence-root-cause-and-solution.md)

This shelf is editorial, not exhaustive. The directory listing remains the
complete archive.

## How to explore

- To follow a named work item, search both streams:
  `bd show mybd-…` and `rg -n "mybd-…" reports`.
- To follow a concept before it had a stable issue identity, search the prose:
  `rg -n -i "phrase or theme" reports`.
- To reconstruct a thread, begin with the most recent synthesis and follow its
  prior-report links backward. Treat an older report as a historical claim,
  especially when a later report records an erratum or supersession.
- To inspect current actionability, return to Beads. This page is allowed to be
  thoughtful and stale; it is not allowed to masquerade as the queue.

## Evaluate the experiment

After using this page, the useful questions are:

1. Did it make re-entry faster than scanning filenames or starting with
   `bd ready`?
2. Was the timeline, the thematic threads, or the open-question layer most
   valuable?
3. Did live Beads context improve the reading, or interrupt it?
4. What did you want to click or ask that this page did not expose?

Those answers should determine whether the next step is a writing convention,
a generated joined view, full-text browsing, or nothing more elaborate than a
periodically rewritten reading room.
