# Maintainer PR Guidelines — mybd overlay

@bd-main/PR_MAINTAINER_GUIDELINES.md

The upstream beads maintainer guidelines (imported above from the `bd-main/`
checkout) are the base policy: philosophy, contributor protection, the
prior-art rule, triage groups, outcomes, merge discipline, operating rules, and
rebases-are-maintainer-work all live there. This file holds only what
supplements or overrides them for sessions run from this coordination repo. Do
not copy upstream text here; if the two disagree and no override below covers
it, the upstream doc wins for beads PRs and this file wins for mybd-local
machinery.

Mechanical mappings when reading the imported doc from this repo:

- Paths are relative to `bd-main/`: `scripts/pr-preflight.sh` means
  `bd-main/scripts/pr-preflight.sh`, `engdocs/PROJECT_CHARTER.md` means
  `bd-main/engdocs/PROJECT_CHARTER.md`, and so on. (Both repos carry
  `gh-body-lint`; use whichever root you are in.)
- "Merge automation" is the pr-babysit patrol, and "take it to merge" means
  `scripts/pr-handoff` — see AGENTS.md "PR Merge Tails". Sessions produce
  (review, fix, push, hand off); only the patrol merges.
- The imported signing rule (`engdocs/AGENT_SIGNING.md`) is implemented here by
  AGENTS.md and `scripts/agent-sig.sh`.

Import status: the "Prior art is part of the review" and "Rebases are
maintainer work" sections land upstream via gastownhall/beads#5094 (bead
mybd-jus2j). Until `bd-main` is pulled past that merge, the authoritative local
text is this repo's git history (commit `2cffec709`); once it lands, drop this
paragraph.

## How a Review Opens and Closes

The imported rules protect the contributor's *code*. These protect the reason
they came back. They are cheap, they cost no rigor, and they are the part that
drifts silently because nothing fails when they are skipped.

Measured 2026-07-25 over the previous six weeks (19 changes-requested + 20
approving reviews on outside-contributor PRs), against steveyegge's first eleven
weeks of maintainership (117 contributor-facing messages):

| | thanks the contributor when asking for changes | when approving |
|---|---|---|
| steveyegge, Oct–Dec 2025 | 66% | 26% |
| here, Jun–Jul 2026 | **5%** | 65% |

A near-perfect inversion. Warmth on approval rewards compliance; warmth on
refusal is what makes someone try again. Concretely:

- **The first sentence belongs to the contributor, not to us.** All 19
  changes-requested reviews in that sample opened with the identical string
  `Cross-vendor agent review (Codex … primary trace; Claude adjudication …)`.
  Review provenance is real and worth recording — put it at the **bottom**, next
  to the `Agent-Signature` line. Open on the specific thing their patch got
  right, named precisely enough that they can tell it was read.
- **Thank them in the changes-requested review, not only in the approval.** Zero
  of 19 did; 13 of 20 approvals did.
- **Say what the review volume means.** A 400-word audit reads as being audited
  unless told otherwise. One clause fixes it: *"docs that match the binary are
  worth this much scrutiny"* (gastownhall/beads#4913).
- **`CHANGES_REQUESTED` is not a notepad.** The imported Outcomes list already
  calls request-changes a last resort that can strand contributor work; it then
  became the default opening 19 times in six weeks, 7 of which we fixed
  ourselves anyway. A `COMMENT` review carries identical findings without
  stamping a red ✗ on someone's first contribution.
- **Ask before finishing their PR for them.** Absorbing is correct policy, but
  "the fixes are applied as maintainer commits" as the contributor's *next news*
  removes the thing they came for. Offer first: *"Want to take these, or shall
  I push them?"*
- **Do not post the disposition and close in the same second.** All five sampled
  2026 declines closed 0–1s after the comment; none of 17 contributors replied
  to any of them, even though every message thanked them, preserved attribution
  and offered a route back. The generosity lands in a locked room. Contrast
  gastownhall/beads#77 (2025-10-18): the decline sat open for eight hours, the
  contributor replied, and *they* asked for the close. Leave the PR open at
  least 48h after a disposition comment, or hand the close to the patrol
  (`scripts/pr-close-handoff`, the close-when-quiet lane). This extends the
  imported "Be explicit when closing a PR" rule: the close is a separate act
  from the disposition comment.

None of this softens a finding. State the blocker exactly as harshly as the
evidence warrants — just do not make the apparatus the first thing they meet.

**Do not automate the greeting.** A patrol *could* post "thanks, this is in the
review queue" on unanswered contributor PRs, and it would silence the polite
pings at zero token cost. Owner decision, maphew 2026-07-25: **no** — an
essentially empty bot auto-response is worse than silence, because it converts an
honest "nobody has looked at this yet" into a false signal that someone has. The
fix for a contributor waiting is a human answer sooner (see mybd-aayb), not a
faster acknowledgement of the wait. The patrol may automate the *close* of a
disposition already written by an agent (mybd-sx1w); it may not originate
contributor-facing text.

## Sweep by author, not by age

Supplements the imported Triage Groups section: when working the open-PR queue,
prefer **author-clustered sweeps** — pick one contributor, process all of their
open PRs in a single session, and leave them a single consolidated picture
(what merged, what was fixed on their branches, what needs their judgment, what
was retired and why).

Why this beats oldest-first or one-at-a-time:

- One context load covers the author's style, recurring themes, and cross-PR
  dependencies — their PRs often share branches-behind-main problems,
  overlapping files, or one design thread.
- The contributor gets one coherent conversation instead of scattered verdicts,
  and follow-ups concentrate into one tracking bead (e.g. mybd-5bz2).
- Retirements land better when paired with merges of the same author's other
  work — attribution and goodwill are preserved in context.
- It converts the queue into a finite list of named clusters, which makes
  progress visible and delegable (one sweep bead per author).

Age still matters *within* the system: the imported prior-art rule gives older
PRs precedence over newer duplicates, and the waiting queue (mybd-aayb) tracks
contributors left holding the ball. Clustering is a processing order, not a
license to let old PRs rot.

Reference runs: `reports/2026-07-23-coffeegoddd-pr-sweep.md` (6 PRs: 2 merged
with maintainer fixes, 3 retired with re-cut requirements, follow-ups in one
bead) and the johnzook triage (`reports/johnzook-pr-triage-2026-07-03.md`).
Pick the next cluster by open-PR count and staleness
(`gh pr list --repo gastownhall/beads --state open --json author | jq ...`).

## Base-Branch Health (stop-the-line)

When upstream main is red, per-PR check verdicts stop being reliable: every PR
inherits red checks, and "these failures are pre-existing" reasoning lets new
breakage stack on top of old. The 2026-07-05..07 window (~33h red, 4 independent
breakages, fixed by gastownhall/beads#4623 + #4624) and the 2026-07-07
CLI-docs-drift red (#4631) are both instances.

- **Check base health before merging anything.** `pr-preflight.sh` does this
  automatically since gastownhall/beads#4630 (per-workflow newest *decisive*
  run; cancelled runs are ignored, so a later green unrelated workflow cannot
  mask a red test workflow). Run the same check in blocking mode for the
  candidate PR:
  `PR_PREFLIGHT_BLOCK_RED_BASE=1 bd-main/scripts/pr-preflight.sh <pr-number> --repo gastownhall/beads`
- **While main is red, merge ONLY the fix for main.** Everything else waits,
  no matter how green its own checks look.
- **After the fix lands**, any PR whose green checks predate it must be
  refreshed (`gh pr update-branch`) and re-watched before judging.
- Autonomous agents run preflight with `PR_PREFLIGHT_BLOCK_RED_BASE=1` so a
  red base is a hard block rather than a warning (see AGENTS.md).

## Open tension: Merge Discipline vs single-human reality

The imported "Merge Discipline and Review Requirements" section requires a
substantive **human** review for nontrivial merges and says bot-only approval
does not satisfy it. Local practice — one human maintainer, sessions reviewing
with cross-vendor agents, the patrol merging maintainer-authored nontrivial PRs
on green — has not been formally reconciled with that text. Until the owner
decides (see the tracking bead): treat the imported rule as binding for
schema/migration/sync-path changes (real human review, no patrol merge), and
when in doubt on other nontrivial maintainer-authored work, flag for the owner
rather than merge.
