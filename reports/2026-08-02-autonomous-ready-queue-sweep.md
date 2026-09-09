# Autonomous ready-queue sweep — 2026-08-02 early morning

Brief: work `bd ready` autonomously until dry or genuinely blocked; verify
nothing is already covered by a branch/PR before claiming; worktree + branch +
tests + PR per task; do not decide product questions; do not touch history.

Runtime: Claude Code, opus-5, high reasoning.

## Headline

The queue does not go dry — it is ~100+ deep and capped at 100 in `bd ready`.
The useful finding is that a large slice of what looked like *unfinished* work
was actually *finished and shipped*, and the queue could not tell the
difference.

**Six beads were parked `in_progress` on branches whose work had already
landed upstream**, under different PR numbers, days earlier. Each had a
worktree, a passing local verification record, and no pull request — the exact
shape AGENTS.md's cold-start section warns about ("an unpushed branch named by
no bead is invisible"). Here the inverse had happened: the beads existed, the
work was done, and nobody had closed the loop.

## What was done

| Bead | Disposition | Evidence |
|---|---|---|
| mybd-qrm9 | closed — landed | upstream 28b566259 (#5184) |
| mybd-f0wgx | closed — landed | upstream 2b2985e6d (#5187) |
| mybd-v42x4 | closed — landed | upstream bfdc54b06 (#5186) |
| mybd-cjcpt | closed — landed | upstream 3385ceef9 (#5205) |
| mybd-b8ht | closed — landed | upstream 868dd077a (#5203) + fabac4e3c (#5210) |
| mybd-3bevm | closed — landed | upstream #5221/#5223/#5227 |
| mybd-q6o2s | closed — duplicate | same PR as mybd-5g9n5 (merge lane) |
| mybd-pmv94 | closed — duplicate | same PR as mybd-e1b3f (merge lane) |
| mybd-4u8k0 | closed — no action ours | #5219 already reviewed+approved; upstream owns next step |
| mybd-wmeks | claimed + fixed | gastownhall/beads#5265 opened |
| mybd-5obcc | filed | merge lane for #5265, handed to patrol |
| mybd-ki3pc | filed | two pre-existing local `cmd/bd/doctor` test failures |
| mybd-xrp9v | filed | the missing reconciliation check (see below) |
| mybd-5g9n5, mybd-e1b3f | re-armed | stale-green congestion, not defect |

Six worktrees and six branches removed; `bd-main` worktree count 65 → 58.
P0 ready items: 4 → 1 (the one being fixed).

## How the "already landed" claim was verified

`git cherry` was not trusted: it is patch-id based, and three of the six came
back `+` (not upstream) purely because upstream had landed a rebased or
reworded variant. Add/add conflicts on the *test files the branches introduce*
were the tell.

A 12-agent workflow verified each branch semantically (does upstream/main
contain the behaviour, allowing for rename/refactor/reword?) and then ran an
adversarial refuter against every "fully landed" verdict, tasked with naming
one specific thing the branch has that upstream lacks.

Result: **6/6 fully landed, 6/6 survived refutation, zero residual.** In two
cases upstream is a strict superset carrying post-review improvements the local
branch never got (a corrected BSD/devfs comment; `debug.Logf` in place of a
bare `log.Printf`). Deleting the branches loses nothing.

Two process notes from that run, both worth keeping:

- A refuter reported that **a concurrent session clobbered its scratch file
  mid-run**, turning a 240-line working set into 94 lines of unrelated content.
  It noticed, redid the comparison inside a `mktemp -d`, and said so. The
  shared scratchpad directory is not safe for parallel agents using fixed
  filenames.
- The one branch `git cherry` marked `-` for both commits (`mybd-cjcpt`) was
  also the only one that was byte-identical upstream. Where `cherry` agrees it
  is right; where it disagrees it is uninformative, not evidence.

## The one new PR: #5260 doctor skip-list drift

`bd doctor` has two checks that scan `dolt_status` for uncommitted tables —
"Dolt Status" and "Dolt Locks" — and each kept its own skip-list. They drifted:
one skipped `isIgnoredTable`, the other skipped `isWispTable`, a strict subset
missing `leases`, `local_metadata`, `repo_mtimes` and `events`. `isWispTable`
was already marked *"Deprecated: use isIgnoredTable for broader coverage"* — its
last caller had simply never been moved. The result is a warning that can never
clear: the same healthy store is clean by one check and permanently dirty by
the other.

Both checks now share one scan and one filter.

**The cross-vendor review changed the design, twice, and the second time it
changed it back.** This is the most useful thing in this report, so it is worth
the detail.

The bug report recommends deriving the skip-set "from a single canonical source
(the store's `dolt_ignore` patterns)". Round one of the Codex review said the
same thing from the other direction: a hard-coded name list is wrong because the
ignored set is neither fixed nor global — `events` is version-gated to main
schema version 62, and `seedDoltIgnorePatterns` uses `INSERT IGNORE` precisely
so an operator's explicit `ignored=false` survives re-seeding. Both checked out
against `internal/storage/schema/schema.go`. So the filter was rewritten to read
live `dolt_ignore` rows, with a hand-written SQL LIKE matcher for the patterns.

Round two raised three P2s against that rewrite. All three were checked against
the **vendored Dolt source** rather than taken on trust, and all three were
right:

1. `doltdb.ShouldIgnoreDelta`: *"Only newly added or dropped tables are matched
   against the patterns. Changes to already tracked tables are always
   included."*
2. `doltdb.compilePattern`: regex-quote, then `?`→`.`, `*`→`.*`, `%`→`.*`. `_`
   stays **literal**; matching is **case-sensitive**. Not SQL LIKE.
3. An empty `dolt_ignore` read as "unreadable", silently taking the fallback.

Finding (1) is the one that matters, because it invalidates the premise rather
than the implementation. Every table in the skip-set is *tracked*, so
`dolt_ignore` has no opinion about it at all — Dolt reports those tables dirty
forever by design. `dolt_ignore` means "don't auto-add this **new** table", not
"don't report changes". The canonical-source refactor that both the reporter and
the first review asked for was borrowing a mechanism that answers a different
question.

So the change was reverted to a static list shared by both checks — which is
just the drift fix, and is what the bug actually is. Findings (2) and (3)
evaporated with the code that caused them. The reasoning is now a comment at
`describeUncommittedTables` so the next person does not re-derive it, and a
`bd remember` entry (`dolt-ignore-is-not-a-quiet-list`) so it is on the
cold-start path.

Final diff: 140 insertions across 3 files, down from 359 at the high-water mark.
The reviewer's own advice — "prefer Dolt's own result rather than reimplementing
engine behavior" — was ultimately satisfied by *not* consulting Dolt's ignore
machinery, since it was never the right authority for this question.

**Deliberately not decided:** whether the bookkeeping tables (`child_counters`,
`labels`, `metadata`, `schema_migrations`, …) should join the ignore set or be
committed by the store instead. That is fix-direction (2) in the report and it
is a durability question — are those tables meant to be versioned? — not a
mechanical one. Left for the owner. With this change, adding one to
`dolt_ignore` is all it takes for both checks to agree.

## Judgment calls, and what was left alone

**Left alone: the stale-green patrol itself.** `mybd-j1wcr` ("serialize
stale-green freshens") was claimed 10 minutes into this session and was live
throughout. Its lane was not touched. It has since merged to `main`.

**Left alone: PR #5219's semantics.** An approved contributor PR whose one CI
failure is the pre-existing integration test pinning the exact behaviour the PR
corrects. Upstream maintainer steveyegge had already diagnosed it, written out
the required test update, and offered to push it. A second maintainer pushing to
the same contributor branch is the collision AGENTS.md warns about — and which
of the two cascade semantics is right is a product call. Bead closed as
"upstream owns the next step", nothing posted.

**Acted on: two parked merge lanes.** #5243 and #5241 were parked
`stale-green-persistent` with the patrol's own note asking for agent judgment.
Both are ours, MERGEABLE/CLEAN, all checks green, and still behind base. The
block was congestion, not defect: the 2026-08-01 merge burst moved `main`
faster than their CI could finish, so all three freshen attempts re-staled each
other. Base had then been quiet ~2h. Re-armed both (cleared `merge-blocked` and
the freshen budgets, per `scripts/README.md`'s instruction that a hand re-arm
must clear the counters too) and left the merge to the patrol — a merge lane
bead exists for each, and sessions produce while only the patrol merges.

## What I noticed that isn't on any list

The queue has **no mechanism for noticing that its own work has shipped.** Six
beads sat `in_progress` for one to eleven days after their content was merged
upstream. Nothing in the cold-start path (`bd prime`, `bd ready`) or in
`session-close-check` compares a bead's branch against `upstream/main`, so the
staleness is invisible until someone does what this session did by hand.

This is the mirror image of the failure the "Cold-start handoff" section already
guards (an unpushed branch nothing points at). Both come from the same gap:
**branch state and bead state are never reconciled.** The existing check warns
about branches this session advanced that are neither pushed nor named by an
open bead; the missing half is beads whose named branch is already an ancestor
of — or patch-equivalent to — upstream. That is cheap to detect (`git cherry`
plus a content check for the rebased case) and would have closed all six of
these without a 12-agent workflow. Filed as a follow-up.

The same pass turned up **five more branches in `bd-main` with a deleted
`origin` ref** (`fix/doctor-fix-container-guard`,
`fix/dolt-push-remote-adoption-consent`, `fix/ignored-cursor-verify-tables`,
`fix/reinit-preserve-dolt-mode`, `fixmerge/pr-4720`), each still holding a live
worktree. `git cherry` proves the first landed; the other four are
inconclusive by that test and were left alone — hygiene posture here is
notice-and-report. They are recorded on mybd-xrp9v as regression fixtures.
A deleted remote branch turns out to be a useful third signal: cheaper than
either content check and independent of both, good as a prefilter rather than
as proof.

A second, smaller thing: **`bd ready` is capped at 100 and gives no total.** A
brief to "work the queue until it's dry" cannot be satisfied or even measured
against a view that silently truncates. The count read 100 before and after
nine closes.

## State at handoff

- **Open PR:** gastownhall/beads#5265, merge tail handed to the patrol as
  mybd-5obcc. `make test` enqueued in the local verify queue at 02cb0c5d8.
- **Re-armed and back under patrol:** mybd-5g9n5 (#5243), mybd-e1b3f (#5241).
- **Left claimed by another session:** mybd-j1wcr (stale-green serialization);
  merged to `main` during this session.
- **Hygiene:** `check-lane-units` clean — installed units match templates. No
  stashes, no gone-upstream branches in the coordination repo. `bd-main`
  worktrees 65 → 58.
- **New memory:** `dolt-ignore-is-not-a-quiet-list` — the finding above, on the
  cold-start path rather than only in this report.

Nothing is blocked on the owner except the two product questions deliberately
left open: fix-direction (2) of #5260 (should bookkeeping tables be durable?),
and the cascade-semantics call on #5219 (which upstream already owns).
