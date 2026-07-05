# Upstream PR review sweep (oldest band batch 2, #3770-3867) - 2026-07-05

14 signed review comments posted to gastownhall/beads (session: claude-opus-4-8-high, bead: mybd-w15y). Continuation of the oldest-band sweep (batch 1 covered #3563-3759). Selection: the next-oldest open contributor PRs with **no maphew feedback**, non-draft, from the pre-rewrite backlog - including a cluster of @seanmartinsmith Windows/test-hardening fixes.

## Method

Same harness as batch 1: workflow fan-out, one reviewer per PR (sonnet; haiku for the pure Windows-skip test PRs), each running its own supersession search against `upstream/main` and the PR head at `refs/prtmp/<pr>`. Adversarial verify (opus, high) on every retire/reject/cherry-pick-of-a-superseded-claim. **All 7 verify checks returned CONFIRMED.** Concurrent-safety gate before posting (open state, unchanged head SHA, no new maphew feedback). All posted as plain comments, not blocking reviews. ~793k workflow tokens.

Orphan (no common ancestor with main): all except #3778 and #3779, which are based on `fa4dce454`.

## Results

| PR | Author | Kind | Recommendation | Verify | Summary |
|---|---|---|---|---|---|
| [#3770](https://github.com/gastownhall/beads/pull/3770) | idvorkin-ai-tools | orphan | **merge** | - | `bd close --continue` didn't update `.beads/last-touched` on auto-advance (unlike `--claim-next`); minimal 8-line fix + regression test, bug still live on main. |
| [#3778](https://github.com/gastownhall/beads/pull/3778) | kevglynn | based | **merge** | - | `bd graph --open` LLM-friendly compact output (#3544); 9 new tests, zero-conflict rebase, only red CI is an unrelated dbproxy flake. |
| [#3779](https://github.com/gastownhall/beads/pull/3779) | kevglynn | based | **reject/close** | CONFIRMED | `bd checkout/merge/branch -d` wrappers, but #3680 was frozen the day after this opened ("please don't start coding yet"); author himself offered to close. Kind close, code kept as reference. |
| [#3785](https://github.com/gastownhall/beads/pull/3785) | jjgarzella | orphan | **retire** | CONFIRMED | cloneSubgraph label persistence already fixed on main via the shared `CreateIssue -> PersistLabels` path; patch redundant. Offered to cherry-pick the regression test. |
| [#3789](https://github.com/gastownhall/beads/pull/3789) | jmdaly | orphan | **cherry-pick** | CONFIRMED | Jira JQL bare-timestamp bug (interpreted in profile TZ, not UTC) still live at `internal/jira/tracker.go:210`; one-line UTC fix to reimplement onto main. |
| [#3797](https://github.com/gastownhall/beads/pull/3797) | seanmartinsmith | orphan | **cherry-pick** | - | Windows release-script test path canonicalization (#3796); absent from main, applies cleanly. |
| [#3801](https://github.com/gastownhall/beads/pull/3801) | seanmartinsmith | orphan | **cherry-pick** | - | Windows file-lock on `server.log` in doltserver test cleanup (#3798); bug still live, fix re-applies to the moved `dbproxy/server` path. |
| [#3802](https://github.com/gastownhall/beads/pull/3802) | seanmartinsmith | orphan | **cherry-pick** | - | Skip `TestUpdateCloseHookFiring` on Windows (#3800); absent from main. |
| [#3803](https://github.com/gastownhall/beads/pull/3803) | seanmartinsmith | orphan | **cherry-pick** | CONFIRMED | dolt tx path skips event rows for CloseIssue/AddLabel/RemoveLabel - still true on main (raw SQL, and CloseIssue now routes through `CloseIssueWithoutEventInTx`); reimplement onto main's issueops helpers. |
| [#3806](https://github.com/gastownhall/beads/pull/3806) | seanmartinsmith | orphan | **cherry-pick** | - | Skip 5 POSIX-shebang hook tests on Windows (#3800); absent from main. |
| [#3808](https://github.com/gastownhall/beads/pull/3808) | seanmartinsmith | orphan | **retire** | CONFIRMED | Proposes delegating `DeleteIssue` cascade to `issueops.DeleteIssueInTx` - main already does exactly that (transaction.go:658-668); fully superseded. |
| [#3812](https://github.com/gastownhall/beads/pull/3812) | seanmartinsmith | orphan | **cherry-pick** | - | Tolerate timeout-killed processes in `TestEmbeddedInitConcurrent`; test-only flakiness fix, absent from main. |
| [#3838](https://github.com/gastownhall/beads/pull/3838) | ckumar1 | orphan | **reimplement** | CONFIRMED | Staged export-file deletion gets re-staged as a modification (no `--diff-filter=D` guard in `exportJSONLForCommit`); bug still live on main. Orphan can't merge - reimplement fresh crediting @ckumar1's repro/diagnosis. |
| [#3867](https://github.com/gastownhall/beads/pull/3867) | scotthamilton77 | orphan | **retire** | CONFIRMED | One-hop-descendant `bd ready` fix fully superseded by main's materialized `is_blocked` column with transitive fixed-point recompute (migrations 0046/0047); PR's edited functions no longer exist on main. |

## Verify highlights (all CONFIRMED)

- **#3808 / #3867 / #3785**: independently confirmed the fix/feature already exists on main - safe retires.
- **#3803**: confirmed the event-emission gap persists on main (traced callers `batch.go:349`, `mol_squash.go:285`); corrected a peripheral commit-provenance detail (#3568 root, not #4537).
- **#3838**: confirmed no staged-deletion guard on main - real, still-open bug worth a reimplementation bead.
- **#3779**: confirmed the #3680 freeze timeline and the author's own offer to close.

## Follow-through

- Bead **mybd-w15y**.
- Merge-ready: #3770, #3778. Cherry-pick/reimplement candidates (value confirmed, absent from main): #3789, #3797, #3801, #3802, #3803, #3806, #3812, #3838. Safe retires: #3785, #3808, #3867. Close-per-freeze: #3779.
- File reimplementation beads for the confirmed-still-live bugs behind orphan PRs: #3838 (staged-deletion export guard) and #3803 (dolt-tx event emission) are the highest-value.
- **Superseded by the orphan-PR inventory (2026-07-05, bead mybd-bys5).** The per-PR "continue the oldest band forward" plan is obsolete: the deferred #3846/#3858/#3859 and the entire pre-re-root orphan band through #4133 (70 PRs) are now fully classified in `reports/orphaned-pr-inventory-2026-07-05.md`. Do **not** re-sweep the orphan band. Next action is a *decision* on that inventory (triage-then-decide), gated on the re-root cause/recurrence question (bead mybd-q1c9), not more reviews. The only genuinely-remaining *review* work is the ~12 old-but-based (non-orphan, mergeable) PRs - #3458, #3610, #3813, #3906, #3914, #3919, #3920, #3971, #3985, #4023, #4055, #4096 - and the post-#4133 band not already covered by the batch A/B sweeps.
