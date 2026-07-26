# Maintainer PR Guidelines

This is the source of truth for agents triaging, reviewing, landing, closing, or otherwise maintaining pull requests for `mybd` and upstream beads work.

## Philosophy

Help contributors get to the finish line. Optimize for community throughput.

For every PR, look for the value in it and choose the action that moves useful work into the codebase with the least contributor starvation. If a PR contains something worth keeping, absorb that value directly when practical: accept it as-is, fix bugs, improve the architecture, rename things, turn it into a plugin, cherry-pick parts, or reject the parts that do not fit.

The goal is not to block contributors unnecessarily. The goal is to identify useful work, preserve it, and keep the project moving.

For upstream beads PRs that change product surface area, read
[bd-main/docs/PROJECT_CHARTER.md](bd-main/docs/PROJECT_CHARTER.md). Scope
boundaries should guide where value lands: core, metadata, integration, plugin,
orchestration layer, or external tool.

## Contributor Protection

External contributor PRs have priority. Before implementing related work, opening a competing PR, or closing a PR, check whether an existing contributor PR already addresses the same area.

- Review contributor work first. Read the PR description, changed files, linked issues, tests, CI status, and latest discussion.
- Build on the contributor branch by default. If the PR branch allows maintainer edits, push maintainer fix commits directly to that branch instead of opening a replacement PR.
- Preserve contributor tests unless they are actually wrong.
- Preserve attribution with original commits when possible. Maintainer commits on a contributor branch should keep the contributor's original commits intact; transformed local commits must use `Co-authored-by:` and PR references.
- Never close, supersede, or replace a contributor PR silently. Explain what was preserved, what changed, and why.
- Open a replacement PR only when in-place maintainer edits are not possible or would create a larger risk, such as when the contributor branch is not writable, the branch history is unusable, or the accepted change must be substantially reimplemented. Document that reason in both PR threads.
- If a rewrite is unavoidable, credit the contributor's design, tests, bug report, or use case in the replacement commit or PR.

## How a Review Opens and Closes

The rules above protect the contributor's *code*. These protect the reason they
came back. They are cheap, they cost no rigor, and they are the part that drifts
silently because nothing fails when they are skipped.

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
- **`CHANGES_REQUESTED` is not a notepad.** The Outcomes list already calls
  request-changes a last resort that can strand contributor work; it then became
  the default opening 19 times in six weeks, 7 of which we fixed ourselves
  anyway. A `COMMENT` review carries identical findings without stamping a red ✗
  on someone's first contribution.
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
  least 48h after a disposition comment, or hand the close to the patrol.

None of this softens a finding. State the blocker exactly as harshly as the
evidence warrants — just do not make the apparatus the first thing they meet.

## Triage Groups

Classify each PR into one of these groups:

- **Easy win**: Targeted bug fixes, documentation updates, dependency bot upgrades, drafts to close, PRs from banned contributors, and other low-risk cases.
- **Fix-merge candidate**: A PR that otherwise fits easy-win criteria but has a simple blocker, such as failed CI, a needed rebase, or a small implementation error.
- **Needs review**: A PR that looks suspicious, complex, broad, risky, or otherwise requires deeper investigation.

Easy wins can be handled automatically during a PR review run and by recurring patrols. Fix-merge candidates can also be handled automatically when the maintainer determines the repair is simple enough to make locally.

Needs-review PRs require a deeper agent review and a concrete report. The maintainer can summarize those reports or inspect the agent sessions directly.

### Sweep by author, not by age

When working the open-PR queue, prefer **author-clustered sweeps**: pick one contributor, process all of their open PRs in a single session, and leave them a single consolidated picture (what merged, what was fixed on their branches, what needs their judgment, what was retired and why).

Why this beats oldest-first or one-at-a-time:

- One context load covers the author's style, recurring themes, and cross-PR dependencies — their PRs often share branches-behind-main problems, overlapping files, or one design thread.
- The contributor gets one coherent conversation instead of scattered verdicts, and follow-ups concentrate into one tracking bead (e.g. mybd-5bz2).
- Retirements land better when paired with merges of the same author's other work — attribution and goodwill are preserved in context.
- It converts the queue into a finite list of named clusters, which makes progress visible and delegable (one sweep bead per author).

Reference runs: `reports/2026-07-23-coffeegoddd-pr-sweep.md` (6 PRs: 2 merged with maintainer fixes, 3 retired with re-cut requirements, follow-ups in one bead) and the johnzook triage (`reports/johnzook-pr-triage-2026-07-03.md`). Pick the next cluster by open-PR count and staleness (`gh pr list --repo gastownhall/beads --state open --json author | jq ...`).

## Outcomes

Use these recommendations after review:

- **Easy win**: The PR turns out to fit easy-win criteria after all.
- **Merge**: Recommend merge. The PR is well-tested, broadly useful, well-documented, and ready as-is.
- **Merge-fix**: Merge the PR as-is, then push a follow-up fix to `main`. Use when the remaining issues are safe to repair afterward.
- **Fix-merge**: Pull the PR locally, make substantial fixes on the contributor branch, then push the branch so the original PR can merge. Use when the PR is busted but valuable and maintainer edits are possible.
- **Cherry-pick**: Keep only selected items from a PR with multiple features or fixes. Commit the useful parts locally with attribution, then close the PR with an explanation.
- **Split-merge**: Split a multi-concern PR into separate commits, then push all accepted parts with attribution to the original contributor.
- **Replacement PR**: Carry useful work into a new maintainer PR only after confirming the original branch cannot reasonably be fixed in place. Preserve attribution with original commits where possible, otherwise use `Co-authored-by:` trailers and PR references, and explain the reason replacement was necessary.
- **Redesign/reimplement**: Reject the submitted design but solve the underlying problem another way. Close the PR with thanks and an explanation.
- **Retire**: Close an obsolete PR with thanks because it was superseded or already fixed elsewhere.
- **Reject**: Close politely when the feature does not pay its weight in tech debt, is too niche for core, or the design does not meet project standards.
- **Request changes**: Last resort. Avoid this when the maintainer or agents can reasonably absorb, transform, or land the useful parts directly.

Other outcomes are possible, including rerouting a PR to the right project or banning a contributor, but the list above covers the normal cases.

## Operating Rules

- Prefer landing or transforming useful work over asking the contributor to do more rounds.
- Preserve contributor attribution when absorbing, fixing, cherry-picking, splitting, or reimplementing PR value.
- Before opening a competing or replacement PR, attempt the contributor-branch path first: fetch the PR, test it, make maintainer fix commits on that branch when permitted, and push back to the same PR.
- Be explicit when closing a PR: thank the contributor, state the outcome, and explain what was accepted, rejected, superseded, or implemented differently. Then leave the PR open — see "How a Review Opens and Closes" for why the close is a separate act from the disposition comment.
- Consider the entire PR thread. Valuable clarifying info are often in the comments.
- Treat request-changes as exceptional because it can strand contributor work.
- File follow-up work as beads issues instead of hidden notes.
- When code changes result from PR maintenance, follow repo quality gates and session completion rules in `AGENTS.md`.
- Post multi-line PR comments from a real Markdown body file or a shell heredoc, not from strings with escaped `\n` sequences. After posting or editing, verify the rendered body with `gh pr view --comments --json comments --jq ...` before moving on.
- Before finishing, re-read the PR, latest comments, review threads, and linked issues; address or explicitly note any unresolved action items.

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
