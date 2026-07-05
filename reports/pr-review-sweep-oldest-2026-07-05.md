# Upstream PR review sweep (oldest band #3563-3759) - 2026-07-05

10 signed review comments posted to gastownhall/beads (session: claude-opus-4-8-high, bead: mybd-y7u0). Selection: the **oldest** open contributor PRs waiting for review (per the user's "start with the oldest" directive), from the `#3395-4133` pre-rewrite backlog that the two earlier 2026-07-05 sweeps (batches A/B, covering `#4150+`) deliberately skipped. Filtered to PRs with no maphew feedback (plus a few with only a `coffeegoddd` review), excluding drafts and dependabot/flake bots.

## Key finding: the oldest band is dominated by pre-rewrite orphan branches

The beads history was rewritten, so most of these old branches share **no common ancestor** with current `upstream/main` (`git merge-base` returns nothing). They cannot be rebased normally. For each orphan the review's primary job was to determine whether the fix/feature **already landed on main** (retire if superseded) or is still absent (reimplement / `git rebase --onto`, with full contributor credit) - not a normal rebase-conflict review.

- **Orphans** (no common ancestor): #3563, #3564, #3618, #3694, #3699, #3734, #3759
- **Based** (normal correctness + rebase-scope review): #3632, #3710, #3717

## Method

Workflow fan-out, one reviewer per PR (sonnet; haiku for the 1-line #3699), each doing its own supersession search against `upstream/main` and the PR head fetched at `refs/prtmp/<pr>`. Adversarial verify (opus, high effort) on every retire/reject/request-changes recommendation and every blocker/major supersession claim. Concurrent-safety gate before posting: re-checked each PR was still open, head SHA unchanged since review, and no new maphew feedback had landed. ~410k workflow tokens for the reviews + verify pass. All comments posted as **plain comments, not blocking formal reviews**, per the maintainer policy that treats request-changes as a last resort.

## Results

| PR | Author | Kind | Triage | Recommendation | Verify | Summary |
|---|---|---|---|---|---|---|
| [#3563](https://github.com/gastownhall/beads/pull/3563) | shaunc | orphan | needs-review | **cherry-pick** | CONFIRMED | Dolt host-config server-mode inference (#3545/#3518) confirmed absent from main; reimplement onto a fresh branch reconciled with merged #3533 dolt.mode fallback. |
| [#3564](https://github.com/gastownhall/beads/pull/3564) | shaunc | orphan | fix-merge | **cherry-pick** | - | Docker/external-server hint on port-conflict errors (#3516); absent from main, small and well-tested, sibling to merged #3568. |
| [#3618](https://github.com/gastownhall/beads/pull/3618) | quad341 | orphan | easy-win | **cherry-pick** | - | Converges `bd dolt clean-databases` prefix list with the SQL firewall (adds beads_test, benchdb_; drops overbroad beads_t); absent from main, trivial line-drift. |
| [#3632](https://github.com/gastownhall/beads/pull/3632) | quad341 | based | easy-win | **merge** | - | AD-01 defense-in-depth (isProductionPort + DB-name firewall); CI green, exactly one mechanical merge-tree conflict, resolved by taking the PR's `isProductionPort(cfg)`. |
| [#3694](https://github.com/gastownhall/beads/pull/3694) | abnersajr | orphan | fix-merge | **cherry-pick** | - | `bd unclaim` command (#3693), well-designed and fully tested; confirmed missing from main, needs reimplement onto current main. |
| [#3699](https://github.com/gastownhall/beads/pull/3699) | sabotenhanmer-bot | orphan | easy-win | **retire** | UNCERTAIN→corrected | plugin.json `agents` validation fix already resolved on main (v1.1.0) via file relocation + auto-discovery. Verify caught a false commit attribution in the draft; corrected before posting (end-state retire stands, specific commit ref removed). |
| [#3710](https://github.com/gastownhall/beads/pull/3710) | quad341 | based | fix-merge | **merge-fix** | CONFIRMED | Real 2-line perf fix (timeout + RO probe); the PR narrative's third "Layer 1" federation.go change isn't in the diff and its target funcs no longer exist on main (12s path already closed by #4259 work). Merge the real diff, ignore the stale narrative. |
| [#3717](https://github.com/gastownhall/beads/pull/3717) | kevglynn | based | needs-review | **hold (fix-merge)** | CONFIRMED | Sync-audit-log feature; coffeegoddd asked to defer until the storage-layer reimpl lands (#3894 open, main at migration 0054). Real CI fixes listed (migration collision, nondeterministic uuid() default, 3 errcheck). Framed as hold-then-rebase, not a blocking request-changes. |
| [#3734](https://github.com/gastownhall/beads/pull/3734) | quad341 | orphan | easy-win | **merge** | - | Silent-data-loss fix (`bd close` ignored actor/assignee mismatch); absent from main, well tested, applies cleanly despite orphan flag. |
| [#3759](https://github.com/gastownhall/beads/pull/3759) | aphexcx | orphan | needs-review | **cherry-pick** | - | `linear.exclude_id_prefix` / `exclude_id_patterns` union filter; absent from main, core diff applies cleanly aside from stale generated docs. |

## Verify highlights

- **#3699**: verify confirmed the retire end-state (main's plugin.json has no `agents` key, task-agent.md at conventional path) but **refuted** the draft's cited superseding commit `1cfb6e5d9` (not in v1.1.0/main). Body corrected to describe the end-state without the false attribution before posting.
- **#3710**: verify confirmed `syncCLIRemotesToSQL`/`migrateServerRootRemotes` exist nowhere on main - the PR's "Layer 1" narrative targets already-removed code; the actual 2-file diff still merges and adds value.
- **#3717**: verify confirmed coffeegoddd's defer request, the 0033 migration collision, #3894 still open, and the active storage reimpl (#4414 merged 2026-07-02).

## Follow-through

- Bead **mybd-y7u0**.
- Cherry-pick / reimplement candidates worth a maintainer follow-up (contributor value confirmed present and absent from main): #3563, #3564, #3618, #3694, #3759, plus #3632 (near-direct merge) and #3734 (clean merge).
- Remaining oldest-band PRs beyond this batch of 10 are still unreviewed - next sweep should continue forward from ~#3770.
