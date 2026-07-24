# Beads Release PR Scan

Date: 2026-05-28
Repository: `gastownhall/beads`
Purpose: identify open PRs that should land before cutting the next release.

## Summary

I scanned the open PR backlog with `gh pr list` and targeted `gh pr view` checks for release-facing candidates. I did not merge anything.

Open PR inventory:

| Merge state | Count |
|---|---:|
| CLEAN | 99 |
| UNSTABLE | 35 |
| DIRTY | 38 |
| DRAFT | 9 |
| Total | 181 |

Recommendation: do not try to drain the backlog before release. Land a focused batch of green, runtime-affecting fixes first, then cut the release after main CI is green.

## Minimal Land-First Batch

These are the PRs I would land before the release unless a final maintainer review finds a concrete defect. When a maintainer rebase/cherry-pick exists for contributor work, treat the contributor PR as the preferred merge path and the maintainer PR as a fallback integration vehicle only.

| PR | Why before release |
|---|---|
| [#4197](https://github.com/gastownhall/beads/pull/4197) | Prevents duplicate schema migration versions from silently under-applying migrations; green CI. |
| [#4152](https://github.com/gastownhall/beads/pull/4152) | Adds a forward schema-skew hard fail so older binaries do not operate on newer DBs blindly; green CI. |
| [#4154](https://github.com/gastownhall/beads/pull/4154) | Runs migrations on a connection without read timeout; important for large or slow migrations; green CI. |
| [#4027](https://github.com/gastownhall/beads/pull/4027) | Migrates large content columns to LONGTEXT; release-facing data capacity fix; green CI. |
| [#3682](https://github.com/gastownhall/beads/pull/3682) | Widens event and wisp event value columns to LONGTEXT; pairs well with #4027; green CI. |
| [#3994](https://github.com/gastownhall/beads/pull/3994) | JSONL import skips metadata/header lines; direct import correctness fix; green CI. |
| [#4085](https://github.com/gastownhall/beads/pull/4085), fallback [#4097](https://github.com/gastownhall/beads/pull/4097) | Stops repeated auto-import of unchanged JSONL. Prefer repairing/landing the contributor PR; use the maintainer cherry-pick only if in-place repair is not practical. |
| [#4112](https://github.com/gastownhall/beads/pull/4112), fallback [#4198](https://github.com/gastownhall/beads/pull/4198) | `bd create --defer <future>` correctly creates deferred issues. Prefer the contributor PR; fallback rebase preserves the original commit and adds tests. |
| [#4113](https://github.com/gastownhall/beads/pull/4113), fallback [#4199](https://github.com/gastownhall/beads/pull/4199) | Re-closing an already-closed issue is idempotent. Prefer the contributor PR; fallback rebase preserves the original commit and adds tests. |
| [#4115](https://github.com/gastownhall/beads/pull/4115), fallback [#4200](https://github.com/gastownhall/beads/pull/4200) | MCP validate/detect-pollution routes to `bd doctor`. Prefer the contributor PR; fallback rebase preserves the original commit and adds tests. |
| [#4201](https://github.com/gastownhall/beads/pull/4201) | Hardens setup symlink follow-up handling; green CI. |
| [#4172](https://github.com/gastownhall/beads/pull/4172) | Bounds `bd prime` and hook waits; avoids hangs in agent workflows; green CI. |
| [#4046](https://github.com/gastownhall/beads/pull/4046) | Widens audit `newID` entropy; low-risk correctness/safety fix; green CI. |
| [#3950](https://github.com/gastownhall/beads/pull/3950) | Routes tracker secret keys through `config.yaml` for Jira/GitLab/ADO/Notion; green CI. |
| [#3568](https://github.com/gastownhall/beads/pull/3568) | Skips auto-backup `file://` registration on external Dolt server; directly relevant to remote-server users; green CI. |

## Good Second Batch

These are clean and useful, but I would land them after the minimal batch only if there is time for another CI cycle.

| PR | Why it is useful |
|---|---|
| [#3626](https://github.com/gastownhall/beads/pull/3626) | Skips git hooks in `commitBeadsConfig` to avoid embedded Dolt re-entry deadlock. |
| [#3599](https://github.com/gastownhall/beads/pull/3599) | Adds `--no-verify` to `commitBeadsConfig` auto-commit. |
| [#3775](https://github.com/gastownhall/beads/pull/3775) | Preserves server mode on `--reinit-local`. |
| [#3774](https://github.com/gastownhall/beads/pull/3774) | Makes `bd create --repo` work when cwd has no `.beads/` workspace. |
| [#4186](https://github.com/gastownhall/beads/pull/4186) | Propagates dependent/comment iterator errors in `bd show`. |
| [#4163](https://github.com/gastownhall/beads/pull/4163) | Improves cross-table duplicate handling and CGO-free duplicate checks. |
| [#4077](https://github.com/gastownhall/beads/pull/4077) | Replaces undirected sibling checks with directed ancestor queries. |
| [#4066](https://github.com/gastownhall/beads/pull/4066), fallback [#4096](https://github.com/gastownhall/beads/pull/4096) | Graph import parent/estimate/external_ref/deps fix. Prefer the contributor PR; maintainer cherry-pick is a fallback. |
| [#4065](https://github.com/gastownhall/beads/pull/4065), fallback [#4095](https://github.com/gastownhall/beads/pull/4095) | FIFO ordering within same ready priority tier. Prefer the contributor PR; maintainer cherry-pick is a fallback. |
| [#3813](https://github.com/gastownhall/beads/pull/3813) | Fixes partial ID resolution for wisps on PostgreSQL path. |
| [#3710](https://github.com/gastownhall/beads/pull/3710) | Removes a 12s Dolt slow path when `.local_version` is stale. |
| [#4114](https://github.com/gastownhall/beads/pull/4114), fallback [#4158](https://github.com/gastownhall/beads/pull/4158) | List output truncation when stdout is piped. Prefer the contributor PR; maintainer test-fix branch is a fallback. |
| [#4161](https://github.com/gastownhall/beads/pull/4161) | Documents schema-version guard behavior in README/CHANGELOG. |
| [#4213](https://github.com/gastownhall/beads/pull/4213) | Makes the domain/fs test suite hermetic from linked worktrees. |

## Attribution-First Integration

Do not let maintainer branches replace contributor PRs by default. For each original/fallback pair:

1. Try to land the contributor PR directly if it is correct and green enough for the release.
2. If it needs small fixes and maintainer edits are allowed, push the fix commits to the contributor branch.
3. If the branch cannot be edited or repaired without unreasonable risk, merge the maintainer fallback only when it preserves the contributor commits or includes explicit co-author attribution and PR references.
4. When closing the other PR, explain exactly which commits, tests, design, or bug report were preserved and link the merged PR.

| Contributor PR | Maintainer fallback |
|---|---|
| [#4112](https://github.com/gastownhall/beads/pull/4112) | [#4198](https://github.com/gastownhall/beads/pull/4198) |
| [#4113](https://github.com/gastownhall/beads/pull/4113) | [#4199](https://github.com/gastownhall/beads/pull/4199) |
| [#4115](https://github.com/gastownhall/beads/pull/4115) | [#4200](https://github.com/gastownhall/beads/pull/4200) |
| [#4085](https://github.com/gastownhall/beads/pull/4085) | [#4097](https://github.com/gastownhall/beads/pull/4097) |
| [#4066](https://github.com/gastownhall/beads/pull/4066) | [#4096](https://github.com/gastownhall/beads/pull/4096) |
| [#4065](https://github.com/gastownhall/beads/pull/4065) | [#4095](https://github.com/gastownhall/beads/pull/4095) |
| [#4114](https://github.com/gastownhall/beads/pull/4114) | [#4158](https://github.com/gastownhall/beads/pull/4158) |

## Do Not Block Release

I would not hold the release for these groups:

- Draft PRs: skip for release unless the author explicitly marks them ready.
- Dirty PRs: require rebasing/conflict resolution, so not first-pass release candidates.
- Broad performance or feature stacks such as [#4021](https://github.com/gastownhall/beads/pull/4021), [#3906](https://github.com/gastownhall/beads/pull/3906), [#3458](https://github.com/gastownhall/beads/pull/3458), and [#4150](https://github.com/gastownhall/beads/pull/4150). Valuable, but too broad for a quick release gate.
- New CI wrapper surface [#4211](https://github.com/gastownhall/beads/pull/4211): useful infrastructure, but currently unstable/pending and broad.
- [#4168](https://github.com/gastownhall/beads/pull/4168) MySQL 8 compatibility: likely useful, but no checks were reported on the branch. Treat as a fix-merge candidate after local or CI verification.
- [#4141](https://github.com/gastownhall/beads/pull/4141) server-mode redundant auto-commits: release-relevant idea, but it currently has a differential regression failure.

## Suggested Release Sequence

1. Merge the minimal land-first batch.
2. Let main CI complete once after the batch, because several PRs touch schema/migration and storage paths.
3. Optionally merge the good second batch and run another main CI cycle.
4. Resolve original/fallback PR pairs with the attribution-first integration rule above.
5. Cut the release from the green main branch.
