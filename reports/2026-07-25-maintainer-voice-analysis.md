# Maintainer voice: steveyegge Oct–Dec 2025 vs here Jun–Jul 2026

**Date:** 2026-07-25
**Asked by:** maphew — *"when I first started contributing to beads, Steve was very
good at welcoming my contributions, even when he didn't use them… now I'm a
maintainer and I don't think I've been doing that."*
**Beads:** mybd-sx1w (pr-babysit delayed-close lane), mybd-aayb (waiting queue)
**Artifact:** https://claude.ai/code/artifact/b7daca2b-2106-497e-8221-332dd1febc46

## Corpora

- **Steve baseline:** every comment and review by `steveyegge` on the 86 non-bot
  PRs created 2025-10-12 → 2025-12-31. n=117 messages.
- **Current:** every `maphew` comment and review on 28 outside-contributor PRs,
  2026-06-15 → 2026-07-25 (19 `CHANGES_REQUESTED`, 20 `APPROVED`); the 14 written
  declines 2026-06-01 → 07-25; a full GraphQL enumeration of the 460 PRs opened
  in the window; and all 119 currently-open PRs.
- **Control:** `steveyegge`'s own 2026 activity, to separate *person* from *era*.
- Two independent reads (a Claude cold-reader persona, a Codex `gpt-5.6-sol`
  reviewer) reached the same conclusion before seeing the counts.

## Finding 1 — warmth inverted

| | thanks when asking for changes | thanks when approving | median words |
|---|---|---|---|
| steveyegge 2025 | **66%** | 26% | 44 |
| here 2026 | **5%** (1 of 19) | 65% (13 of 20) | 306 (CR) / 160 (approve) |

A near-perfect mirror. Steve was warmest at refusal and nearly curt on approval;
we are the reverse. Warmth on approval rewards compliance; warmth on refusal is
what makes someone try again. maphew's own memory of feeling welcomed comes from
gastownhall/beads#77 — the PR that was **turned down**.

All 19 changes-requested reviews open with the identical 24-word string
`Cross-vendor agent review (Codex … primary trace; Claude adjudication …)`.
Zero name the contributor in the opening line. **This is not in any checked-in
template** — it is convention drift copied between sessions, which is why it was
cheap to fix.

Notable counter-example: the warmest openers in the recent corpus are the
Codex-authored comments on gastownhall/beads#5028 — *"Jim, thank you for the
`/var/tmp` fix…"* — confirming a template artifact rather than a personality
change.

## Finding 2 — the declines are excellent and nobody can reply to them

All 14 written declines thank the contributor, name the specific technical value,
preserve attribution (`Co-authored-by`, "your original commit is untouched"),
and offer a route back. Several exceed anything Steve wrote — e.g. #4905:
*"Nothing gets closed or superseded without your work credited"* with a decision
deadline and an offer to do the extraction.

**Zero of 17 contributors replied to any of them.** Cause, verified per-PR:

| PR | disposition comment | closed | gap |
|---|---|---|---|
| #4862 | 23:30:41 | 23:30:42 | 1s |
| #4884 | 19:40:38 | 19:40:38 | 0s |
| #4286 | 02:03:16 | 02:03:16 | 0s |
| #4694 | 03:37:53 | 03:37:54 | 1s |
| #4439 | 04:07:48 | 04:07:49 | 1s |

Against the baseline, gastownhall/beads#77 (2025-10-18): decline posted 08:10 and
**left open**; maphew replied 16:14 (*"would you prefer I close the PR? : )"*);
Steve closed 16:33 with "Closing as discussed"; maphew shipped `maphew/beads-ui`
three days later and linked it in the thread. Eight hours of open door is the
entire mechanism.

## Finding 3 — the real cost is rhythm, not tone

43 people opened their first-ever beads PR in the six-week window. Every review
landed on **five calendar days**: Jul 5, 12, 23, 24, 26. Median first-review
wait 4 days, mean 5.5, max 15. Twelve of 43 got nothing.

- **#4484** (iamthebot) — "This is currently a blocker in our setup" on day 3.
  Review arrived day 12; its entire body was the word `Test` plus an agent
  signature.
- **#4485** (brendan-appstart) — "HI! Anything I can do to bump =)))", then
  "Ping :)", then a screenshot. Eleven days, two-line docs change.
- **#4535** (Kevinwochan) — a genuinely warm review on Jul 5, contributor rebased
  himself Jul 15, still open and unanswered.
- **#4734** (vishnujayvel) — apologising to *us* for our own CI gate: "sorry for
  the extra click."

Current open-PR backlog is in mybd-aayb: 5 never answered (jjgarzella #3875/#3876
at **75 days**), 20 waiting after they replied, 14 dormant since a single mid-June
sweep.

## What is better now than the era being missed

Not a decline narrative. On every axis that costs effort, current practice is
more respectful:

- Attribution is defended, not assumed. (In 2025 maphew's own #305 and #309 were
  closed with "already merged in #319" — superseded, uncredited, no path back.)
- Claims are verified against the PR head rather than eyeballed.
- Maintainer-side failures are owned: *"Apologies that CI never ran until now"*,
  *"that's on us, not you"*. Steve never did this once.
- Wrong review calls are publicly retracted.

**Control result:** steveyegge's own voice fell off a cliff on 2026-04-03 —
warmth markers 38% → 0%, now under 1 contributor-facing comment per week,
agent-signed, 8th-most-active commenter in his own repo. maphew wrote 663
comments in the window to that account's 22. The warm era being compared against
no longer exists anywhere in the repo except in maphew.

Codex, independently: *"Steve is more likely to make an outsider feel welcomed;
maphew is more likely to make them feel taken seriously."*

## No evidence of contributor flight

34 distinct humans opened PRs in one ten-day window this month; 61% of active
authors were first-timers. Every contributor reply in the corpus is constructive,
several energised (*"Thanks for the thorough cross-vendor review — all four
should-fixes were real"*). Two politely corrected the maintainer's own diagnosis
and were thanked for it. None read as defensive or deflated.

Caveat on return rate: 4 of 31 engaged first-timers opened a second PR (13%), but
14 of 23 were reviewed 1–3 days before the window closed, so the number is
heavily time-censored and no conclusion is drawn from it. Separately, absorption
suppresses the signal — 9 first-timer PRs were finished by maintainer commits, so
"never replied" cannot be distinguished from "had nothing left to do".

## Actions taken this session

1. `PR_MAINTAINER_GUIDELINES.md` — new section **"How a Review Opens and Closes"**
   with the measured table and six rules (provenance to the bottom; thank in the
   critique; say what review volume means; `CHANGES_REQUESTED` is not a notepad;
   ask before finishing their PR; do not close in the same second).
2. mybd-sx1w — `close-when-quiet` patrol lane design.
3. mybd-aayb — the waiting queue, ordered by wait rather than age.

## Open question for the owner

Should the patrol post a mechanical arrival acknowledgement ("in the review
queue") on unanswered contributor PRs after N hours? It would kill the "=)))"
pings at zero token cost, but it is outward-facing automation writing to
strangers' PRs, and an unfollowed-up bot "thanks!" can read worse than silence.
Not built, not filed as actionable — owner decision.
