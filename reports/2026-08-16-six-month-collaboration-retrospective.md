# Six months of human-agent collaboration: a retrospective (2026-02-10 to 2026-08-16)

**Bead:** mybd-fh118 | **Date:** 2026-08-16 | **Method:** see Provenance at bottom

## Why this report exists

The Claude Code `/insights` report generated 2026-08-16 covers only 2026-07-26
onward, because Claude Code's default 30-day transcript retention had silently
deleted everything earlier (fixed: `cleanupPeriodDays: 730` now set on this
machine; cross-vendor archiving is bead mybd-8vhy3). The owner wants
quarterly and year-in-review reporting, so this report reconstructs the full
six months from the durable record instead: 145 tracked reports, the retro
campaign corpus, six months of git history, and 169 bd memories.

The short version: the one-month insights report saw the mature system.
The six-month record shows how it got that way, and which lessons actually
stuck versus which keep having to be relearned.

## The six eras

| Era | Period | Character |
|-----|--------|-----------|
| Bootstrap | 2026-02-10 to 02-28 | bd init, SQLite-to-Dolt migration, role set to maintainer. 39 commits, mostly human bookkeeping. |
| Dormancy | 2026-03 | Zero commits. The only true gap in six months. |
| Restart & analysis | 2026-04-03 to ~05-20 | Single-agent, read-only: codebase health assessment, upstream digests, triage scans. Agents recommend; the human acts. |
| Protocol era | ~2026-05-20 to 06-30 | The coordination layer becomes the product: AGENTS.md/CLAUDE.md split, signing convention, worktree rules, first deep root-cause investigations (CGO shim, #4259 data corruption). Multi-runtime experiments (amp, kilocode, zcode) narrow to Claude + Codex. |
| Supervised autonomy | 2026-07 | Peak month: 226 commits. Delegation tiering (07-03), team-maintainer profile (07-08), Workflow standing opt-in, five unattended systemd patrol lanes built in three weeks, cross-vendor review hardening into a mechanical gate, the retro campaign (07-14). Six-report days become normal. |
| Step-down & wind-down | 2026-08-10 onward | Maintainer role ends. All five merge-capable lanes deleted the same day; 526 open beads collapse to 160; posture flips to contributor + hand-off (epic mybd-ykt9f). |

The sharpest single fact in the timeline: July's five automation lanes,
built in under three weeks, were deleted wholesale five weeks later when the
role changed. Automation tracked authority, not sunk cost.

## The trust arc (only visible at six-month range)

Trust was extended in discrete, dated, owner-issued steps, each one earned by
the system absorbing the previous step without disaster:

1. **Read-only analysis** (Apr-May): agents produce reports, human executes.
2. **Templated execution** (late May): fixed review rubrics, signed comments,
   worktree conventions - agents act, but inside written protocol.
3. **Tiered delegation** (07-03 directive): scout/builder/reviewer, cheapest
   adequate model per task.
4. **Routine write authority** (07-08): `agent.profile=team-maintainer` -
   commit/sync/push stop being gated.
5. **Standing orchestration opt-in** (07-03, reaffirmed): multi-agent
   Workflows pre-authorized for every substantive task, +200k soft budget.
6. **Budget generosity** (07-25): "200k is a soft target, not a ceiling" -
   issued specifically so agents stop rationing *verification*.
7. **Unattended lanes** (07-23 to 07-28): agents merge and triage with no
   human in the loop, via patrol timers.
8. **Global promotion** (08-12): the mybd conventions become cross-project
   defaults in ~/.config/agents/AGENTS.md.

Notably, the wind-down did not reverse the trust arc. Post-step-down the
review pipeline got *stricter* (pr-review-gate hook, mandatory cross-vendor
review) precisely because "nobody here can wave a rough PR through" anymore.
Trust in agents and rigor of gates rose together, not as opposites.

## The verify ratchet

The single most consistent long-range pattern: **every era rediscovered that
unverified claims run ~30% false, and every era responded by adding an
independent verification stage.** Dated evidence:

- 2026-07-05: post-hoc audit of 7 unposted review claims found 3 materially
  wrong; corrections posted.
- 2026-07-26: haiku recon's "fixed/merged" claims measured wrong ~30% of the
  time (3 of 10 rejected, one p0-adjacent); "verify every fix-merged claim"
  became a standing rule.
- 2026-07-31: only 1 of 3 "ACTIONABLE" scout verdicts survived a ten-minute
  code read (memory `scout-verdicts-are-leads-not-findings`).
- 2026-07-30: two of three fixes were aimed at wrong code that *passed review
  by inspection*; only running the repro caught it.
- 2026-08-01: an 8-agent classify-then-adversarially-verify workflow
  overturned two of its own proposals before any mutation was applied.

Cross-vendor review is the same ratchet applied to the agents' own output:
from occasional practice (07-05, first paired catch on PR #4586) to standard
(07-07: Codex caught a P1 data-loss bug Claude-family review missed) to
mechanically enforced (scripts/pr-review-gate PreToolUse hook blocking
`gh pr create` without a review log for the exact commit). Across 13+ dated
pairings the two vendors found largely *disjoint* defect sets every time -
the strongest empirical result in the whole record.

## What sticks: mechanism beats documentation

The retro campaign (F-001..F-017) plus the memory corpus give a clean natural
experiment. Sorting friction classes by what the fix was made of:

**Mechanically fixed, then verified quiet:**
- F-001 pr-babysit merge-state thrash: bounded retry + re-arm sweep in the
  script; verified fixed by 07-27 (18 stranded beads -> 9).
- F-002 delegation debris (two hard outages in one day, 07-24: fd exhaustion
  + 10GB stale caches): worktree-local GOCACHE/GOTMPDIR enforced in
  codex-agent; clean across 19 later sessions.
- F-007 hidden team-maintainer profile: PRIME.md shrunk + explicit
  declaration; zero recurrences in 19 sessions.
- F-004 bd --json shape drift: 13 sightings *despite* an upstream issue and a
  bd memory; stopped only when `scripts/bdj` (a normalizing wrapper) landed
  2026-08-11. The memory alone fixed nothing - agents don't consult a memory
  before their first failure.
- Label-soup human gating: replaced by first-class bd gates (08-01).

**Documented only, still recurring:**
- F-014 wrong-cwd / worktree lifecycle slips: 6 sightings in the retro
  window, habit-level fix only ("use git -C") - and the 30-day insights
  report independently lists wrong-cwd bd/git as a *current* top friction.
  Six months of evidence says this will not fix itself by rule.
- Bare `git stash` in shared stacks: banned in AGENTS.md after the 07-24
  cross-pop incident, violated again 08-10.
- F-013 session-close protocol skipped after post-close mutations: 5
  sightings, no mechanical backstop landed in-window.
- Delegated-commit signing trailer misattributes the orchestrator's model
  instead of the executing subagent's: known since 07-04, still open.

The rule this yields is blunt: **a lesson is not learned until it is a shim,
a hook, or a gate.** Prose rules decay in roughly two weeks; wrappers hold.
This retro-validates the 30-day report's "quick wins" recommendation
(PreToolUse guards for rm -rf/cwd) with six months of controlled evidence.

## The owner's interaction style, long-range

The one-month report characterized the style as "policy-laden autonomous
mandates plus surgical corrections." The six-month record adds texture:

- **Cheap, specific skepticism as a QA instrument.** "100 is an oddly
  perfect number" caught the bd list truncation cap; "been idling quite
  awhile now. what does that cost?" caught a session burning ~4 hours on a
  5-minute poll. Neither was a broad distrust move; both were single pointed
  questions that found real defects.
- **Values corrections, empirically grounded.** The 07-25 tone audit
  ("Steve was very good at welcoming... I don't think I've been doing that")
  was answered with corpus analysis, not sentiment: agent-era thanks rate on
  change-requests was 5% versus the human-maintainer era's 66%, and all 14
  decline comments got zero replies because dispositions closed 0-1 seconds
  after posting. Fixes went into PR_MAINTAINER_GUIDELINES.md as rules.
- **Hard reversals stay cheap.** "back out Entire, I'll set it up properly
  later" (07-30) removed an entire adopted tool 17 days after adoption, with
  the postmortem written into the revert commit. Same pattern later applied
  to the agents' own converged habit ("decide the maintainer edit instead of
  offering it", 07-29/30, after 12/12 contributors rubber-stamped the offer).
- **Terse continuation grants.** "carry on" / "4430" / "start" authorize the
  next leg only because the prior handoff enumerated concrete options - the
  brevity is downstream of agents writing good handoffs, not a substitute.

## Incident ledger (the ones worth retelling)

| Date | Incident | Outcome |
|------|----------|---------|
| 06-16 to 07-05 | "History re-root" false alarm: shallow clone misread as rewritten history; ~2 days of disposition work on a wrong premise | Retracted in a full erratum report; is-shallow check now precedes any rewrite conclusion |
| 07-24 | Two independent resource-exhaustion outages in one day (fd exhaustion, /tmp quota) | Worktree-local Go caches enforced in the wrapper |
| 07-26 | v1.1.1 tag pushed before the lockfile gate ran; protected-tag rules made the tag immutable in every phrasing tried | Version number burned; rolled forward to v1.1.2; pre-tag preflight added upstream (#5082) |
| 07-27 | PR #4376: a 44-day-old compliant contributor PR superseded by a 5-day-old duplicate; author frustrated | Owner replied personally; 2,973-PR historical audit; prior-art check made part of every review |
| 07-13 to 07-30 | Entire CLI silently overwrote tracked git hooks, left 24 shadow branches | Fully backed out on owner directive, with bundle backup first |
| 08-10 | Worktree prune loop rm -rf'd the `.bare` object store (92 branches) | Recovered in 15 minutes from a bundle taken ~15 minutes earlier; hard rule + memory `never-rm-rf-worktree-list-paths` |

The 08-10 incident is also the strongest argument for the snapshot-before-
prune habit: the bundle was the difference between a 15-minute recovery and
losing the entire beads object store.

## What six months adds that one month could not see

1. **The trust arc is deliberate and dated.** The 30-day report saw a fleet
   operator; the record shows eight explicit trust-extension steps over five
   months, each following demonstrated absorption of the last.
2. **Friction classes have lifecycles.** The 30-day report counts friction;
   the 6-month record shows which classes died (mechanized) and which are
   chronic (documented-only). The chronic list is the actionable one:
   wrong-cwd, stash discipline, close-protocol skips, trailer attribution.
3. **The verify ratchet is the system's core adaptation.** Every scale-up of
   autonomy was paired within days by a new independent-verification stage,
   usually after a measured ~30% false-claim rate. This is the pattern to
   preserve through any future re-scale-up.
4. **Automation is disposable; conventions are not.** All five patrol lanes
   died with the role. What survived the step-down: signing, worktrees,
   cross-vendor review, session-close self-asks, bd-as-tracker, and the
   retro habit - the conventions, promoted to global scope on 08-12.
5. **The record itself is infrastructure.** This report was reconstructable
   at all only because reports are git-tracked ("the retroactive why
   record"), memories are in bd, and the retro campaign left a ledger.
   The raw transcripts - the medium /insights depends on - turned out to be
   the *least* durable layer of the whole stack (bead mybd-8vhy3).

## Open threads carried forward

- Chronic doc-only frictions above are candidates for mechanization
  (PreToolUse cwd/destructive-op guards - also the 30-day report's top
  suggestion; the two analyses agree from independent evidence).
- Delegated-commit trailer misattribution: open since 07-04.
- Cross-vendor session archiving: bead mybd-8vhy3 (research is
  time-sensitive; other machines/vendors may be pruning now).
- Retro campaign stopped at sweep-2d-0727 without reaching its own
  saturation stop-rule; superseded by wind-down. If quarterly reviews
  become routine, the campaign's batch pipeline is the natural engine.

## Provenance

Produced under bead mybd-fh118 by a 7-agent mining workflow (four
chronological report-batch readers, one retro-corpus reader, one git-history
analyst, one serial bd-memories reader; ~820k subagent tokens) with
in-session synthesis, cross-checked against the 2026-08-16 /insights report
(81 sessions, 2026-07-26 to 08-16). Sources: reports/*.md (145 files,
2026-04-24 onward), retro/{findings.md,PLAYBOOK.md,ledger.tsv,digests,batches},
git history of ~/dev/mybd (2026-02-10 onward), bd memories (169). Feb-Apr has
no report coverage and is reconstructed from git history alone; per-message
interaction detail before 2026-07-23 is unrecoverable (transcript pruning).

_claude-fable-5-high on behalf of matt wilkie_
