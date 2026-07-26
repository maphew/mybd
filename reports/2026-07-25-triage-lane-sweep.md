# Triage-lane sweep — 2026-07-25

**Session shape:** parallel session. A second agent was concurrently working the
kevglynn upstream PR backlog (`mybd-ds4v`, `#4329` fix-merge). To avoid the
claim-does-not-exclude problem, the lanes were partitioned *before* any work
started: this session took the `tri:claim` triage lane only and never re-read
`bd ready` as an open queue. Verified no overlap — none of the 31 PR beads in
this lane are kevglynn PRs.

## Why lane partitioning was necessary

`bd update --claim` is idempotent for the same user, and both sessions run as
`maphew@gmail.com`. Claims therefore cannot mutually exclude parallel sessions —
this is the same hazard that merged `#4942` with a red nix job on 2026-07-24
while another session was mid-review. The mitigation is a pre-agreed lane split
plus the standing role rule: **sessions produce, only the patrol merges.**

## What the lane actually contained

86 open `tri:claim` beads. The first two passes reframed the work substantially:

| Finding | Count | Consequence |
|---|---|---|
| Upstream already closed/merged | 10 | Closed as dead stubs |
| PR beads parked on the author | 17 | No maintainer action available |
| Issue beads with an open fix PR | 24 | Disposition is *review*, not *implement* |
| Issue beads with no candidate fix | 29 | The genuine implement backlog |

The dominant discovery is that **this lane is mostly a review queue, not an
implementation queue** — 24 of 53 open issue beads already have someone's fix PR
attached. Treating them as "implement from scratch" would have duplicated
contributor work.

## The freshness idiom (the reusable part)

Comparing the last review timestamp against the head commit timestamp separates
"waiting on author" from "stale review, ball back in our court":

```bash
gh pr view <n> --repo gastownhall/beads --json reviews,commits --jq \
  '[([.reviews[]?|select(.state=="CHANGES_REQUESTED" or .state=="APPROVED")|.submittedAt]|max),
    ([.commits[]?.committedDate]|max)]|@tsv'
```

`head > review` → needs re-review. `review > head` → parked, do not spend a
review on it. This classified 19 PR beads in about two minutes and found that 17
were genuinely parked. Stored as memory `pr-triage-freshness-idiom`.

## Work completed

**Closed (10):** `mybd-fnlc` `mybd-1ll5` `mybd-j90z` `mybd-6iep` `mybd-y3lm`
`mybd-lum9` `mybd-cg3u` `mybd-gp9z` (PRs merged upstream) and `mybd-jclk`
`mybd-q307` (issues completed upstream).

**Handed to the pr-babysit patrol (3):**

- `#4821` (`mybd-xemi`) — approved but red. The failure was
  `TestProtocol_GrantingReplicaRoundTripsJSONL`, unrelated to its `bd list --deps`
  diff, with main green — flake-or-stale-base, exactly the patrol's job.
- `#4912`, `#4910` — approved, CI mid-run, merge-when-green.

**`#4844` branch updated.** Its red CI ran 07-24 19:06–19:09Z, *before* main went
green at 21:02Z, so the red was inherited. GitHub reuses the original merge base
on rerun, so `gh pr update-branch` was the only action that changes the outcome.
Its proxied failure (`rekey dependency ids: wisp_dependencies: Error 1105 no root
value found in session`) is already classified as a transient Dolt session race
at `internal/storage/dolt/store.go:449` — do not chase it as a bug.

**P0 `mybd-rr4x` (`#4637`) — recon done, scope narrowed, split.** The missing
server-identity check still reproduces: `EnsureGlobalDatabase`
(`internal/doltserver/doltserver.go:1215`) goes `sql.Open` → `PingContext` →
`CREATE DATABASE IF NOT EXISTS beads_global`, with no identity probe. The
existing project-identity verifier is gated behind `if !cfg.CreateIfMissing`
(`internal/storage/dolt/store.go:1259`) and the global initializer passes
`CreateIfMissing: true` (`cmd/bd/init.go:2827-2837`), so it is bypassed exactly
on the creation path. Commit `9d7ae74a` (`#4823`) says so in its own message.

Split into a mechanical part (verify identity against an already-existing
database despite `CreateIfMissing`) which stays on `mybd-rr4x` with a full design
+ acceptance spec, and a design call (`mybd-y18b`, flagged `human`). Late
cross-reference caught that `#5013` introduces `internal/procid` with a
`Token`/`Verify` shape explicitly built for `doltserver` to adopt — so `mybd-y18b`
should be sequenced *after* `#5013` rather than designed from scratch.

**P0 `mybd-j881` (`#4468`) — does not reproduce.** The recompute is split by ID
set (`internal/storage/issueops/blocked_state.go:60`) and queries typed columns,
not a physical `depends_on_id`. Repairs landed since filing: `80ba331a604`
(`#4558`), `3f5e1ba3e8b`, `2f9367d6a76` (`#4987`). **Cluster check came back
negative** — `#4468`, `#4483`, and the CI `no root value` string are three
distinct causes, not one. Not closed: no live shared-sql-server repro was run.

**Dependency edges wired (7).** Issue beads whose fix PR is itself a bead in this
lane now carry a real `bd dep` edge, so `bd ready` stops offering blocked work.

## Dual-vendor review: `#4430`

The one PR in the lane with *no review at all*. Reviewed by both vendors on the
same diff, and the disagreement was the point:

- **Codex (gpt-5.6-sol):** REQUEST-CHANGES on 3 High findings.
- **Claude (opus reviewer), verifying adversarially:** all three describe cases
  the *current* code also deletes — an incomplete new guard, not regressions —
  so merging is a monotonic improvement. Call: **APPROVE-WITH-FOLLOWUPS.**

It also found the most useful output of the whole review: `cmd/bd/purge.go:105-128`
plus `types.BuiltInStatusCategory` already solve the identical problem for a
sibling destructive command, and reusing that "category is not done" predicate
collapses two of the three findings into a change *shorter* than the
contributor's hand-written switch. Filed as absorb bead `mybd-q9n4`.

Lesson stored as memory `dual-vendor-review-disagreement`: the decision-relevant
question to put to the second reviewer is **"is this finding a regression or
pre-existing?"** — a single reviewer's severity ranking is not a maintainer
decision.

**Deliberately not actioned:** no review posted, no approval, no merge on
`#4430`. That is an outward-facing act on a contributor's PR, the two reviewers
disagreed, and `PR_MAINTAINER_GUIDELINES.md` treats request-changes as a last
resort. Left for the owner.

## What I noticed that isn't on any list

`bd-main/` is on a **detached HEAD with a large staged working set** (workflows,
`Makefile`, `CHANGELOG.md`, a new `PROPOSAL-cas-conditional-update.md`, ~20+
files). That is almost certainly the other session's in-flight `#4329` work, so
it was left strictly alone — but it means **any recon run against `bd-main` right
now reads an unstable tree**. Both scouts this session were told to read
committed state only, and the `mybd-j881` recon explicitly excluded uncommitted
`0059` files. Future sessions doing source recon while another session holds
`bd-main` should either verify via `git show HEAD:<path>` or use a clean
worktree. If that working set is *not* another session's, it is orphaned and
wants triage.

## Open tails

- `mybd-rr4x` — spec'd and unclaimed, ready for a builder (part A only).
- `mybd-y18b` — `human`, gated on `#5013` landing.
- `mybd-j881` — recommend close-as-fixed, needs a live repro or a
  reporter-confirms round trip via `scripts/tri-submit` (human-gated).
- `mybd-6r1o` / `mybd-q9n4` — `#4430` awaiting the owner's approve-vs-absorb call.
- `mybd-sfiw` / `mybd-1ox6` — gated on kevglynn `#4820`, which belongs to the
  other session's lane. Noted, not touched.
- 29 issue beads with no candidate fix remain the untouched implement backlog.
