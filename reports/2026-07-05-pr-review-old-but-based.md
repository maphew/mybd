# Upstream PR review sweep (old-but-based + post-#4133 gap) - 2026-07-05

9 signed review comments posted to gastownhall/beads (session: claude-fable-5-high, bead: mybd-53s1). This closes the review gap identified at the end of the oldest-band batch-2 report: the pre-re-root PRs that still SHARE ancestry with main (non-orphan, mergeable - normal review scope, no `rebase --onto` remedy needed), plus the post-#4133 band not covered by the 2026-07-05 batch A/B sweeps.

## Coverage confirmation (the recon result that reshaped scope)

- Of the 35 open non-draft post-#4133 contributor PRs not covered by batches A/B, **34 already had maphew feedback** from a signed-agent sweep on 2026-06-16. Only **#4151** was genuinely unreviewed. The post-#4133 band is therefore fully covered; no re-review was needed or posted there.
- Of the 12 old-but-based PRs: 4 had no feedback (#3906, #3914, #3919, #3985), 4 had feedback with contributor/other activity after it - re-reviewed (#3458, #4023, #4055, #4096), and 4 are simply waiting on the contributor or a maintainer action, so commenting again adds nothing: **#3610** (fix-merge branch queued, no activity since), **#3813 / #3920 / #3971** (maphew requested repro 2026-06-16, no contributor reply yet).

## Method

Same harness as the earlier 2026-07-05 sweeps: workflow fan-out, one reviewer per PR (sonnet, medium) reading the full thread + linked issues, diffing against `upstream/main` (tip `1914af585`) via `refs/prtmp/<n>`, computing real rebase-conflict scope (`git merge-tree`/`merge-file`, not just GitHub's CONFLICTING bit). Adversarial verify (inherit, high) on every retire/reject/blocker claim - **all 4 verify checks returned CONFIRMED**. Concurrent-safety gate before posting (open state, unchanged head SHA, no new same-day feedback): 9/9 passed. ~655k workflow tokens.

## Results

| PR | Author | Kind | Recommendation | Verify | Summary |
|---|---|---|---|---|---|
| [#3906](https://github.com/gastownhall/beads/pull/3906) | quad341 | fresh | **rebase + re-home** | - | Well-designed opt-in lite SELECT foundation, but #4150's generic-projection refactor deleted the exact function it patches (`searchTableInTx`); the `Lite` switch needs re-homing in `searchProjection[T]`, and two new lease columns need lite/heavy classification. Design is sound; timing is the problem. |
| [#3914](https://github.com/gastownhall/beads/pull/3914) | quad341 | fresh | **fix-merge** | - | Small stderr migration-progress fix that also catches a real `migrationSource`-threading bug (wisp tables never created via `ignoredSource.migrate()`); needs a manual re-merge into main's diverged `migrate()` loop and the `release-gates/` artifact dropped. |
| [#3919](https://github.com/gastownhall/beads/pull/3919) | quad341 | fresh | **rebase, carefully** | CONFIRMED | Useful progress output + large-rig warning, but a naive conflict resolution would silently drop main's new per-migration `preMigrationRepair` call (schema.go:1058, added 2026-07-01); also overlaps #3914 in the same function - merge order needs deciding first. |
| [#3985](https://github.com/gastownhall/beads/pull/3985) | quad341 | fresh | **retire** | CONFIRMED | Everything of value (reference-aware prune + the NFR-02 bench test) is carried more completely by the same author's open #4023; the lone unrelated commit (auto-import fallback guard) is dead code since #3960 landed. Close in favor of #4023, credit the bench-fixture design. |
| [#4151](https://github.com/gastownhall/beads/pull/4151) | quad341 | fresh | **retire** | CONFIRMED | Entire diff already on main **byte-identical** - absorbed when stacked PR #4153 merged (fffed97d3); the branch just never got closed. Nothing left to land. |
| [#3458](https://github.com/gastownhall/beads/pull/3458) | quad341 | re-review | **await coffeegoddd** | - | Contributor answered the storage owner's 2026-05-17 architectural question thoroughly (issueops refactor + benchmarks) but coffeegoddd hasn't replied; comment posted is a status refresh + new #4300-driven conflict scope, decision stays with the storage owner. |
| [#4023](https://github.com/gastownhall/beads/pull/4023) | quad341 | re-review | **fix-merge** | - | All three P1 findings from maphew's 2026-05-22 review fixed with regression tests (d9bf08d98, d16cbe5be, 3604d68ac0), CI was 51/51 green; the CONFLICTING state is unrelated main-side RunE/metrics drift - rebase, then merge. Canonical branch for the prune feature (supersedes #3985). |
| [#4055](https://github.com/gastownhall/beads/pull/4055) | quad341 | re-review | **partial-land / redirect** | CONFIRMED | The doubled "Error:" prefix fix is good, but upstream's #4419 RunE+HandleError refactor has since converted 8 of the PR's 12 files in the opposite direction (3-way merge: real conflict markers, 22 in config.go alone); only compact/dolt/help_all/restore.go remain valid targets. |
| [#4096](https://github.com/gastownhall/beads/pull/4096) | quad341 | re-review | **merge** | - | kevglynn's repro checks out against current main (`GraphApplyNode` still lacks the four JSON field tags); fix is clean, tested, CI green, MERGEABLE with conflict-free rebase. Ready to land. |

## Verify highlights (all CONFIRMED)

- **#4151**: `git diff upstream/main..refs/prtmp/4151 -- cmd/bd/dolt_local_only.go` is empty; all five `isDoltLocalOnly()` guards found on main in #4153's squash commit, whose PR body declares the stacking. Safe retire.
- **#3985**: #4023 carries the `--ignore-references` feature + `TestPruneLargeFixture` NFR-02 guard (and adds custom-status handling); main's #3960 guard makes the auto-import commit dead code. Safe retire.
- **#3919**: main's `preMigrationRepair` call (5589e3f6d, 2026-07-01) postdates the PR's merge-base and sits exactly in the loop the PR rewrites - the silent-drop trap is real.
- **#4055**: independently reproduced the 3-way merge: 8/12 files conflict against #4419's refactor; `errors.go` on main now reserves `FatalError` for the unreachable proxied-server path.

## Follow-through (maintainer actions arising)

- **Merge-ready**: #4096. **Rebase-then-merge**: #4023 (contributor rebase or maintainer fix-merge).
- **Decide merge order** #3914 vs #3919 (same function, same author), then request the corresponding rebase(s).
- **Retire-closes to execute**: #3985 (in favor of #4023) and #4151 (absorbed by #4153) - both verified safe, comments already posted explaining why; the close itself was left for maintainer follow-through.
- **No action**: #3458 (ping coffeegoddd if it stays silent), #3610/#3813/#3920/#3971 (waiting on contributor replies to 2026-06-16 repro requests).
- With this sweep, **the review pass over the entire open contributor PR backlog is complete**: orphan band inventoried (mybd-bys5/mybd-ufzk), oldest band reviewed (mybd-y7u0/mybd-w15y), post-#4133 band covered (2026-06-16 sweep + batches A/B + #4151 here), old-but-based band reviewed (this report). Remaining work is *decisions and merges*, not reviews: beads mybd-j5ed (act on batch-A verdicts), mybd-ufzk (orphan disposition), and the follow-through bead filed for this sweep.
