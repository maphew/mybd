# Stale-tail PR sweep — 2026-08-04

**Why:** owner question 2026-08-03: open-PR count on gastownhall/beads has hovered
110–115 for days despite the babysitter merging steadily. Measured answer: inflow
caught up with throughput (~155 opened vs ~121 merged, 07-29→08-03, two-thirds of
inflow from in-house contributor-agents), and beneath the churn sits a static
pre-July tail of **31 open PRs** (oldest 2026-04-21) in states no zero-token lane
can act on. Owner: "yep, go. use workflow." Sweep bead: `mybd-m07q0`.

**Method:** Workflow `stale-pr-tail-sweep` (run `wf_3cd0b91b-034`): 24
author-clustered assess agents (sonnet) judging each PR's live state against the
disposition already recorded in its beads, + 14 adversarial verify agents
(fable) on every actionable verdict. 38 agents, 0 failures, ~2.05M subagent
tokens — well past the 200k soft target; the overrun bought a full verify pass
on all 14 actionable verdicts, which caught 1 unsafe close and 2 factual errors
(below). All bd writes done serially by the orchestrator; agents were read-only
gh + the pre-fetched bead context.

**Headline:** the tail was not un-triaged — it was *dispositioned but stuck*.
28 of 31 PRs already had bead state. The sweep's work was checking whose gating
condition had ripened, then executing.

## Executed this session

| PR | Verdict | Action taken |
|----|---------|--------------|
| 3549 shaunc | close (redirected design) | Disposition comment posted; close-when-quiet lane `mybd-x1324` (opens 08-07). #3524 stays open. |
| 3572 jozefizso | close (dead draft) | Comment posted per `mybd-do1mx`'s recorded disposition; lane `mybd-rccmd`. Stub `mybd-5rpun` closed. |
| 3579 jozefizso | close (dead draft, judgment-by-analogy) | Comment posted (wording fixed per verifier: *extends existing* `internal/jira`, not a new subsystem); lane `mybd-ogmwv`. Stub `mybd-31nyl` closed. Code survives on ylcn91 fork `6d07bec0`. |
| 4493 steveyegge | close (carried by #4537) | Comment posted (verified: 4493's file list ⊂ #4537's, authorship preserved); lane `mybd-y5mjg`. Stub `mybd-8w67` closed. |
| 4206 maphew | stale-green refresh | `gh pr update-branch` (was 421 commits behind), merge lane armed (`mybd-lpqf`, re-scoped). Patrol judges fresh CI; reviewDecision is empty so the green-checks gate is the merge authority. |

Direct queue effect once lanes fire: **−5**.

## Queued as ready implementation work (verified ripe, windows expired)

- `mybd-ekhyz` (new, P2) — **3837** ckumar1: fix retry-command bug + narrow classifier + gosec G705, merge with credit (08-02 review superseded the expired absorb gate).
- `mybd-51xab` (new, P2) — **4376** sarendipitee: refresh + repair `TestResolvePartialID_WispSubstringCollision` (short-circuits the fuzzy path — verified in `id_parser.go`) + merge with attribution. The old close-disposition bead `mybd-k6zxf` was **reversed** by the 08-02 review and is closed — do not execute its close text.
- `mybd-xymzr` (new, P1) — **4461** sjarmak (APPROVED): third rebase + actually run `pr-handoff` — the 07-27 comment promised merge automation but patrol.log has zero mentions of 4461. Verifier caution recorded: head is NOT fully green (08-01 wrapper/gate failures, plausibly the red-main incident).
- `mybd-nathu` — **4288/4348** realies re-port: 08-03 window expired, zero engagement; ready to claim as written.
- `mybd-ncx38` — **4383** aaronlippold rebase: window expired; read the 08-02 #5140 consolidation analysis first (transplant scope narrowed). `mybd-qwffl` closed (absorb decided; rebase item in `mybd-alw6l` now unblocked by merged #5135).
- `mybd-xixp4` — **4284** krantiutils absorb: re-verified unsuperseded on current main; `mybd-d6y1` closed as duplicate.
- `mybd-j5ed` SPLIT-MERGE item — **4449** bourgois: scrub 6 `vc-8djyca` IDs, land Layer 1 maintainer-side (author silent 29d after agreeing).

## Escalations for maphew (owner decisions, all pre-existing beads)

1. `mybd-juqgs` — **3395** Agentic Covenant: mergeable-clean, kevglynn constructive 08-03; sole blocker is the yes/no adoption call (steveyegge has never commented on the PR).
2. `mybd-982o` — **4316/4317/4318** MovGP0 trio: must attachment bytes survive `bd dolt push`+clone, or metadata-only? Unanswered since 07-26.
3. `mybd-6k80` (human-decision label added) — **4473** rbriski gates on **4303** cstar, which is itself stalled: push 4303 to landing or close both.
4. (soft) `mybd-7kcg` — **3458**: design-gate premise now moot (#3906 merged, 3458 re-cut on top); remaining question is only dismissing coffeegoddd's stale 05-07 CHANGES_REQUESTED.

## Left alone deliberately (in-motion / waiting)

3458 (active bilateral review, author replied 08-03), 3595 (trillium force-pushed
**during this sweep**, 04:12Z — the rework `mybd-42cf6` waits for), 3777 (mid-review),
3861 (GraemeF nudge window to ~08-16, `mybd-do1mx`), 4242 (lanes `mybd-5g9n5`/`mybd-tmheo`
armed), 4303 (arcaven stack `mybd-94l2i`), 4415 (live direction discussion `mybd-f6wqh`),
4289 (`mybd-lwcg` deferred with scoped pickup notes), 4409 (`mybd-q2qs`, needs content
review), 4313 (gated on 4303), 3717 (holds on dormant design issue #3894 → part of
escalation context).

## Queue arithmetic

31 = 5 executed + 7 ready-work queued + 3 escalated + 11 in-motion/waiting +
5 covered inside the clustered rows above. Nothing untracked. Expected trajectory:
~112 → ~107 within the week from this session's lanes alone; the 7 ready work items
are worth roughly another −7 (several are merges, not closes, but each clears a
tail slot).

## What I noticed that isn't on any list

- The 07-27 "handing to merge automation now" comment on 4461 that never became a
  `pr-handoff` call is the same producing-end failure `session-close-check` warns
  about for branches — but for *lane handoffs*. A promised handoff that doesn't
  exist in patrol state is invisible to every zero-token lane. Worth a check:
  grep recent maintainer comments for "handing/merge automation" phrases and diff
  against patrol queue state.
- Workflow args arrived as a JSON string despite being passed as a JSON object;
  scripts should defensively `typeof args === 'string' ? JSON.parse(args) : args`.

_claude-fable-5-high on behalf of matt wilkie_
