# PR #4376 post-mortem + repo-wide stall/supersede audit

**Date:** 2026-07-27 · **Bead:** mybd-g8kma (policy), mybd-aayb (queue), mybd-k6zxf (close decision)
**Trigger:** sarendipitee's frustrated reply on gastownhall/beads#4376 after their 44-day-old
PR was retired in favor of a 5-day-old duplicate (#4939).

## What happened to #4376

| Date | Event |
|---|---|
| Jun 12 | PR opened: correct fix for fuzzy ID resolution silently returning the wrong bead (repro, tests, comparison table) |
| Jun 12 → Jul 5 | **23 days, no maintainer contact** |
| Jul 5 | Review confirms diagnosis and fix are correct ("small and well targeted"); asks for a rebase |
| Jul 6 | Author complies **in under 24 hours**: rebase, conflicts resolved per our guidance, pinning test added, green |
| Jul 6 → Jul 26 | **20 days, no maintainer action.** PR is merge-ready; nothing tracks that the ball is in our court |
| Jul 21 | #4939 opened by another contributor — same bug, same protection |
| Jul 24–25 | A session reviews #4939, hands it to the pr-babysit patrol (bead mybd-5u3f). No prior-art search is run |
| Jul 26 05:28 | Patrol merges #4939 after **two substantive reviews (changes-requested Jul 23 → approved Jul 25) that never discovered #4376**. Preflight passed: it checks base health, contributor status, diff risk — it has no duplicate scan. (Correction 2026-07-27 via cross-vendor review of #5094: an earlier version of this row said "zero comments"; the comments array was empty but the reviews were real — the failure was no prior-art check, not no review) |
| Jul 26 19:30 | Retire notice posted on #4376; author replies frustrated 45 min later; maphew replies personally |

Two independent failures, either of which alone would have prevented this:

1. **No follow-through lane for complied-with requests.** After Jul 6 the PR needed
   only a merge decision, and it sat for 15 days *before the duplicate even existed*.
2. **No prior-art check at review/merge time.** The #4939 review and the patrol merge
   both had the information available (`pr-preflight.sh --search` exists) and neither
   used it. The patrol runs no dupe scan by design — the review was the only gate.

Aggravator: the rebase we requested on Jul 5 was work we could have done ourselves via
maintainer edit — and the author maintains 50+ PRs across gastownhall repos, so every
requested rebase multiplies across their whole queue.

## How often has this happened? (all-time audit, 2,973 closed PRs)

Of 922 closed-unmerged PRs, 588 are from outside contributors; 149 matched redundancy
keywords and were probed in depth; **127 confirmed redundant closes** (superseded /
duplicate / already-landed). The other 439 closed-unmerged externals had no redundancy
marker and were not probed (silent closes with rationale only in a report or bead would
be missed there).

By pattern:

- **90 quick/clean redundant closes** — mostly the 2025 steveyegge era: closed within
  hours-to-days of opening, with thanks and an explanation. Supersede itself is not the
  injury; speed and honesty made these largely harmless.
- **28 engaged-then-superseded** — maintainer engaged, author responded, work later
  closed as covered elsewhere. Within these, the *#4376 shape* — author complied, then
  weeks of maintainer silence, then a supersede close — appears **~7 times, all closed
  during the Jul 5–26 backlog drain**: #3773 (18d silence), #3808 (55d), #3867 (54d),
  #4296 (21d), #4520 (21d), #4439, #4376. This is a 2026 backlog-era phenomenon.
- **9 never-answered-then-closed-redundant** — first maintainer contact was the close
  itself, after waits up to 64 days (#3694 64d, #3789 61d, #3759 61d, #3785 59d,
  #3838 58d, #4104 47d, #4145 26d, #3452 14d, #4862 8d).

## Is it happening right now?

Cross-matched all 110 open PRs against all 464 PRs merged since Jun 1 by file overlap,
then adversarially verified the strong candidates against upstream/main code:

**Confirmed redundant, still open:**

- **seanmartinsmith ×5** (#3797 #3801 #3802 #3806 #3812) — #4600 (merged Jul 7) ported
  their Windows test-hardening verbatim with `Co-authored-by`. *In hand:* retire
  comments posted Jul 26, 48h-grace close pending (mybd-qy7m). Note they waited
  May 7 → Jul 7 for the port and the PRs then stayed open silently for three more weeks.
- **julianknutsen trio** (#4682 partially, #4697, #4715) — overtaken by main's lease
  work (#4863/#4911/#5008) *while sitting unanswered*. Reviews with salvage paths now
  posted (Jul 24–27); author is now a MEMBER.
- #4493 (steveyegge's own, landed via #4537) — internal, low stakes.

**Live repeat risk (the next #4376 if unanswered):**

- **#4561 duncan4123** — configured-backend API; the core landed a week later via #4601
  (which was then reversed by #4847/#4881 Dolt consolidation). Author replied to review
  and has been **waiting 15.7 days**. Companion #4736 never engaged at all. They are
  owed an honest disposition: "the direction you proposed was tried and rolled back."
- **#4242 osamu2001 — waiting 20.7 days** since replying (not known-superseded).
- **#4329 kevglynn — waiting 12.4 days.**

**Queue refresh (64 open external PRs as of Jul 27, vs the Jul 25 baseline in mybd-aayb):**
never-answered is down from 5 (worst 75d) to 4 (all <1 day old — brand-new arrivals);
waiting-after-reply down from 20 to 6. Part of the delta is definitional (this pass
excluded 27 MEMBER-authored PRs, incl. julianknutsen who has since become MEMBER), but
most is the last week's sweep work. The dial is moving.

## What changed (landed with this report)

`PR_MAINTAINER_GUIDELINES.md` (commit 2cffec709, owner directives maphew 2026-07-26/27):

1. **Prior art is part of the review, not the merge.** Every review runs a prior-art
   pass over older open PRs/issues before any verdict or merge handoff. Older open PR
   covering the same change ⇒ precedence goes to the older PR by default; if the newer
   is genuinely superior, the older is resolved personally *first*, never with a
   post-merge retire notice. The patrol merges what sessions hand off and runs no dupe
   scan — the reviewer owns this check.
2. **Rebases are maintainer work.** A "correct once rebased" verdict is a fix-merge we
   execute ourselves via maintainer edits, same session. Rebase requests only ride
   along with substantive asks; a complied-with request goes straight to the merge
   lane, never back into the ambient queue. (Org-owned-fork branches refuse maintainer
   edits — replacement-PR route with attribution, and say why.)

## Still open

- **mybd-k6zxf** — the planned Jul 28 close of #4376 should NOT fire mechanically:
  the author replied with frustration (not a technical case) and maphew answered
  personally. Close needs a human moment, and ideally an olive branch (e.g. invite the
  `wisp-goq` marginal-case test as a PR that merges promptly, credit in release notes).
- **mybd-aayb** — the answer-the-queue work; refreshed numbers above.
- Preflight backstop: add a warn-level "older open PRs touching these files" line to
  `pr-preflight.sh` per-PR mode so the policy has a mechanical reminder on the path
  reviewers already run.
- #4561/#4736 (duncan4123) need a disposition comment before they become the next
  #4376.

## Method note

Audit ran as an 11-agent workflow (three sweep lanes + per-candidate adversarial
verification against upstream/main code); ~614k subagent tokens total, 136k counted
against the turn budget. History lane probed 149 of 588 candidates (keyword-gated);
doomed-open lane had full file-overlap coverage of open×merged-since-Jun-1, deep reads
capped at ~22 PRs.
