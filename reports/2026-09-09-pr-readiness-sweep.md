# Owned PR readiness sweep, 2026-09-09

Scope: maphew-authored open PRs in `maphew/mybd` and
`gastownhall/beads`. Trillium was an initial naming mistake, corrected by the
owner before the inventory. The owner authorized review fixes, base updates,
conflict resolution, validation, and promoting completed drafts. Comments are
limited to substantive changes. Tracking: `mybd-gzzti`, with review fixes in
`mybd-koabx.5` and the historical import review in `mybd-cebxh`.

## Inventory and decisions

GitHub returned zero owned open PRs in `maphew/mybd` and sixteen in
`gastownhall/beads`. All sixteen were already non-draft. All were behind
`main`, by 3 to 515 commits at inventory time. Base used for the refresh:
`a690b0a8c` (`upstream/main`).

The review inventory found no Kilo-authored review findings in the retrieved
GitHub reviews, threads, or issue comments. The actionable latest reviews were
by `bee-ghosttrack`. These observations cover GitHub, not private Kilo Cloud
session state.

| PR | Finding and action |
| --- | --- |
| [5986](https://github.com/gastownhall/beads/pull/5986) | Latest review approved; merged current base using GitHub update-branch. |
| [5974](https://github.com/gastownhall/beads/pull/5974) | Correct effective-limit wording and the documented test selector. Piped query still defaults to 50. |
| [5651](https://github.com/gastownhall/beads/pull/5651) | Recognize SQL lookup misses, preserve post-write failure classification, make test-seam cleanup conditional, and document HTTP behavior. The existing exported test seam still needs an upstream maintainer decision. |
| [5648](https://github.com/gastownhall/beads/pull/5648) | Move dependency-type changelog paragraphs from released 1.2.1 into Unreleased/Changed. |
| [5645](https://github.com/gastownhall/beads/pull/5645) | Approved; merged current base. |
| [5642](https://github.com/gastownhall/beads/pull/5642) | Verify metadata-only fallback already omits tasklists, pin that behavior, document first-push body updates and pull-side footer stripping. |
| [5641](https://github.com/gastownhall/beads/pull/5641) | Pin proxied escape-scanner regression, conservatively classify DOLT functions, scope dynamic read-only state to SQL, and document skipped auto-import. |
| [5636](https://github.com/gastownhall/beads/pull/5636) | Approved with old failed storage/UOW checks; merged current base to obtain fresh CI evidence. |
| [5635](https://github.com/gastownhall/beads/pull/5635) | Approved; merged current base. |
| [5634](https://github.com/gastownhall/beads/pull/5634) | Approved; merged current base. |
| [5633](https://github.com/gastownhall/beads/pull/5633) | Fully superseded by merged [6411](https://github.com/gastownhall/beads/pull/6411), commit `2298c65173cbfea35b263636ae0bdeb0b96f70e9`. No unique correction remains. Owner asked whether to close or leave open. |
| [5632](https://github.com/gastownhall/beads/pull/5632) | Correct lint-script path and qualify the local-hook/CI comparison. |
| [5630](https://github.com/gastownhall/beads/pull/5630) | Apply greeting-drain readiness behavior to the sibling proxy probe. |
| [5316](https://github.com/gastownhall/beads/pull/5316) | No review findings; merged current base. |
| [5243](https://github.com/gastownhall/beads/pull/5243) | Prior provenance findings already addressed; merged current base. |
| [5202](https://github.com/gastownhall/beads/pull/5202) | All four historical formal review requests and hard-link protection already implemented. Merged current base. Still needs a new upstream review decision; no nudge posted. |

## Evidence and validation environment

Raw inventory data is under `/tmp/mybd-pr-sweep-a` and
`/tmp/mybd-pr-sweep-b`. Refresh preflights and expected-head update results are
under `/tmp/mybd-pr-sweep-refresh`. GitHub updates used
`PUT repos/gastownhall/beads/pulls/<PR>/update-branch` with
`expected_head_sha`, preserving branch history and detecting concurrent head
changes. The preflight's merge/close blocks on 5636 and 5202 did not prohibit
updating their branches to repair readiness.

PR 5651 red-capable reproduction:
`./scripts/test.sh -run '^TestCloseRefusalStaysPerItemPhaseOutranksSentinel$' ./internal/storage/issueops`.
The added assertions failed for both plain and wrapped `sql.ErrNoRows` before
the fix. The affected issueops, HTTP API, and public issueops packages passed
after the fix, including post-write rejection and conditional-disarm tests.
Logs: `/tmp/mybd-pr-sweep-5651/red.log` and `affected.log`.

PR 5651's full `make test` completed with all packages passing except
`internal/config`. Three failures reproduced unchanged on `bd-main`
(`c0d8da42d`) and under pinned Go 1.26.5 on the PR:

- `TestSetYamlConfig_WorktreeFallbackUsesMainRepoConfig`: missing config.
- `TestFindConfigYAMLPath_WorktreeFallbackUsesMainRepoConfig`: missing config.
- `TestFindProjectBeadsDir_NonGitTreeWithoutConfig`: unexpectedly discovers
  `/var/home/matt/.beads`.

The configuration package is identical on both trees and current upstream
main. The causal experiment identified scratch-directory ancestry: Go 1.26's
`testing.TempDir` uses `GOTMPDIR` (`src/testing/testing.go`, lines 1420 and 1460),
and the home scratch directory places test fixtures beneath the real
`/var/home/matt/.beads`. Changing only `GOTMPDIR` to
`/var/tmp/mybd-sweep-gotmp` makes the entire config package pass. Explicitly
changing only `TMPDIR`, or selecting only the three failing tests, leaves them
red. Both scratch variables are moved outside home for final full-suite runs;
`/var/tmp` is disk-backed on this host. Follow-up `mybd-87jil` tracks a mechanical
guard against scratch roots with ambient `.beads` ancestors. No unrelated
product fix or expanded skip list was added. Logs:
`/tmp/mybd-pr-sweep-5651/full.log`, `config-base.log`, and `config-pinned.log`.
The decisive green run is `config-nonhome-gotmp.log`.

Final reruns with pinned Go 1.26.5, home-disk `GOCACHE`, and both scratch
variables under disk-backed `/var/tmp` passed `make test` on the exact pushed
heads for PR 5651 and PR 5641 (exit 0). Logs:
`/tmp/mybd-pr-sweep-5651/full-final.log` and
`/tmp/mybd-pr-sweep-5641/full-final.log`. Their substantive review-response
comments were updated in place with the passing result. No test skip was added.

PR 5641's direct proxied scanner assertion failed when only the quote-escape
scanner fix was temporarily reverted and passed after restoration. New tests
also failed before the DOLT-function and command-name scoping fixes. Nine
affected classifier/export/push/prune tests, pinned native/Windows lint,
generated-doc checks, docsync, and doc freshness passed. The full suite failed
the same three config tests plus `TestFindBeadsRepoRoot_WorktreeFallback` in
`cmd/bd`; the fourth failure was independently reproduced on unchanged
`bd-main` as well. Logs: `/tmp/mybd-pr-sweep-5641/scanner-regression-red.log`,
`new-tests-red.log`, `affected-tests.log`, `final-ci-pr-lint.log`,
`cli-docs-check.log`, `make-test.log`, and `baseline-worktree-fallback.log`.

PR 5642's focused mapper tests passed before any behavioral renderer change:
the existing nil-list rendering already emits only the ID/Source footer and
no tasklist sections. This satisfies the reviewer's metadata-only alternative.
The change adds regression assertions and clarifying comments rather than a
new renderer. The upgrade note is in the maintained `docs/reference/faq.md`.
Independent review caught an initial direct edit to the generated CLI reference;
moving it to the FAQ restored `./scripts/generate-cli-docs.sh --check` to a pass.
`./scripts/test.sh ./internal/github ./internal/tracker ./test/docsync`
and `./scripts/check-doc-freshness.sh` passed. Logs:
`/tmp/mybd-pr-sweep-5642/affected-docs.log` and `freshness.log`.

Local default Go 1.27.1 and golangci-lint 2.13.2 differed from the repository's
Go 1.26.5 and golangci-lint 2.10.1. The newer formatter wanted to rewrite three
base-identical fixture files, and the newer linter reported three G602 findings
in base conformance code. With the exact pinned tools, PR 5651's required lint
passed with zero findings on native Linux and Windows. No unrelated formatting
changes were retained. Exact-tool log:
`/tmp/mybd-pr-sweep-5651/lint-exact.log`.

Each concurrent lint/commit uses a separate home-disk `TMPDIR`, because
golangci-lint locks `os.TempDir()/golangci-lint.lock`. Full-suite workers also
need a distinct `TEST_COVERPROFILE`; the test runner otherwise writes
`/tmp/beads.coverage.out` regardless of `TMPDIR`. These findings are recorded in
Beads memory `pr-sweep-validation-on-framation-global-go-1`.

## Workspace ownership

Review-fix worktrees used new local branches `sweep/20260909-<PR>` under
`/var/home/matt/dev/mybd/.worktrees/beads/sweep-<PR>`. Existing PR worktrees were
clean at inventory and were preserved. GitHub-only base updates advance their
remote branches without moving those existing local checkouts.

After pushing, all seven temporary source worktrees were verified clean with
`HEAD` equal to their pushed remote branch, then removed with
`git worktree remove`. Only their temporary local branch aliases were deleted;
the PR branches remain on the fork. There were no pending git operations or
uncommitted edits in these completed worktrees.

This report is authored in the coordination worktree
`/var/home/matt/dev/mybd/.worktrees/mybd/pr-sweep-20260909`, branch
`report/pr-sweep-20260909`. It is landed directly to coordination `main`; no
coordination PR is needed for this report.

## Independent review

A separate read-only reviewer checked the maintenance diffs, challenged the
upstream findings against the code, and rechecked corrections. Final verdict:
no remaining correctness findings. The review identified and resolved the two
generated-doc edits, the SQL FAQ wording precision, and a proxy concurrency
fixture that bypassed shared setup. It did not approve the upstream API-policy
question about PR 5651's exported failure-injection seam.

| PR | Exact reviewed and pushed maintenance head | Git tree |
| --- | --- | --- |
| 5974 | `c7b9f05581bacec25147e8d447d256113c83d42a` | `e60dd194874766a1b823197c5d2a2fd4ed57b8d8` |
| 5648 | `707b098e90e0e8f3f7e6918c0f95bbe247923c39` | `ae69628730c58ecf9b8a096c3820ff6ac792201b` |
| 5632 | `a9118f461db4e8d5f04c57d624d453841e268833` | `1be007743fd0fc6311f793eb073cc14768d39981` |
| 5642 | `08551e71cde2a08552571efda3fc38994bf270b0` | `79c29413974f31780acfe830cdde942c66eb8f93` |
| 5651 | `b818ff34e40efc6bd4e1af5f79205b5486ddc36f` | `2d6bede6a53c607a88fd0611d1825fea617424f8` |
| 5641 | `0db6905075a04160e634a814e318d6869f352ab5` | `b05a3a726ce0c7b3e66047ccf39ac8e5747f5c5d` |
| 5630 | `2f497712ee2ab94e6b7faf9350363388a17c8a19` | `796538316ee50e8bef1082ea17aa047f1aada394` |

The final frozen proxy tree is `796538316ee50e8bef1082ea17aa047f1aada394`,
based on merge commit `ab07a0d477561e39f28f621a1f958ddd5c485567`.
The reviewer ran both proxy and server packages under the race detector and
the readiness tests for twenty repetitions; all passed. The one-shot greeting
defaults to disabled, is copied and consumed under the fixture mutex only
after successful dial, and does not alter payload counters.

PR 5630's final `make test` also passed with non-home scratch (exit 0), as did
pinned native/Windows lint. Evidence:
`/tmp/mybd-pr-sweep-5630/make-test-var-tmp.log` and `ci-pr-lint-final.log`.
The committed tree exactly matches the independent-review fingerprint above.

## Final GitHub state and remaining gates

Observed at `2026-09-10T04:52:58.190446+00:00`. All fifteen retained implementation PRs
are conflict-free, non-draft, and contain current `main` (`a690b0a8c`).
Their aggregate checks are still pending, so this sweep does not claim they
are all merge-ready. The earlier paginated check inventory had no failures.

| PR | Final head | Aggregate checks | Mergeability |
| --- | --- | --- | --- |
| [5986](https://github.com/gastownhall/beads/pull/5986) | `3d0edd2a44f08a70e666b26ba0b9924265ccfb7c` | PENDING | MERGEABLE |
| [5974](https://github.com/gastownhall/beads/pull/5974) | `c7b9f05581bacec25147e8d447d256113c83d42a` | PENDING | MERGEABLE |
| [5651](https://github.com/gastownhall/beads/pull/5651) | `b818ff34e40efc6bd4e1af5f79205b5486ddc36f` | PENDING | MERGEABLE |
| [5648](https://github.com/gastownhall/beads/pull/5648) | `707b098e90e0e8f3f7e6918c0f95bbe247923c39` | PENDING | MERGEABLE |
| [5645](https://github.com/gastownhall/beads/pull/5645) | `6fc6b118a4788c65393a0526492165ebe3414998` | PENDING | MERGEABLE |
| [5642](https://github.com/gastownhall/beads/pull/5642) | `08551e71cde2a08552571efda3fc38994bf270b0` | PENDING | MERGEABLE |
| [5641](https://github.com/gastownhall/beads/pull/5641) | `0db6905075a04160e634a814e318d6869f352ab5` | PENDING | MERGEABLE |
| [5636](https://github.com/gastownhall/beads/pull/5636) | `9befe30af9a76ab97d02909d18f97cbb06284baa` | PENDING | MERGEABLE |
| [5635](https://github.com/gastownhall/beads/pull/5635) | `669c5db41ede2dcec8f05e39f4c069b77f5598cf` | PENDING | MERGEABLE |
| [5634](https://github.com/gastownhall/beads/pull/5634) | `d7e950d2cc5311806e720fe8b0928ba15a07758e` | PENDING | MERGEABLE |
| [5633](https://github.com/gastownhall/beads/pull/5633) | `eb4a3d991f1740e76a3e62823b4ccbc9d17b28e3` | SUCCESS | CONFLICTING |
| [5632](https://github.com/gastownhall/beads/pull/5632) | `a9118f461db4e8d5f04c57d624d453841e268833` | PENDING | MERGEABLE |
| [5630](https://github.com/gastownhall/beads/pull/5630) | `2f497712ee2ab94e6b7faf9350363388a17c8a19` | PENDING | MERGEABLE |
| [5316](https://github.com/gastownhall/beads/pull/5316) | `76dd5e3774944f65fb91b34b45b620a0a289b4dd` | PENDING | MERGEABLE |
| [5243](https://github.com/gastownhall/beads/pull/5243) | `03345df3a0428e8c02bb06b07d204522366807a0` | PENDING | MERGEABLE |
| [5202](https://github.com/gastownhall/beads/pull/5202) | `7671f7e57eb61eaf6479d13cb96e04356d1f6394` | PENDING | MERGEABLE |

PR 5633 remains open and conflicting, intentionally untouched because its full
change already landed through PR 6411. The owner was asked whether to close it
with a substantive supersession link; no answer arrived during the sweep.

The external decisions remain PR 5202's historical requested-changes review
(all requested implementation is already present) and PR 5651's exported test
seam. The seven review-fix comments explain actual changes and validation;
no nudge comments were posted. The PR 5974 description now uses the real test
selector and separates historic evidence from current validation.

`mybd-koabx.5` is closed for completed implementation. `mybd-gzzti` remains open
for final CI/review readiness and the superseded-PR choice. `mybd-87jil` tracks
mechanical scratch-root protection. The active `index-babysit.timer` flags
regressions on `mybd-ykt9f`; it does not merge or repair PRs.

The next safe action is to read `bd show mybd-gzzti`, inspect the latest PR
checks and review responses at these exact heads, and address new concrete
failures. Do not merge or close other contributors' upstream PRs, force-push
these histories, silently remove the exported seam, or close PR 5633 without
resolving the owner's pending choice.

The session's unlisted finding was that the prescribed home-disk scratch
layout itself defeated test isolation after Go 1.26 began using `GOTMPDIR` for
`testing.TempDir`. Toolchain pinning, separate lint locks/coverage paths, and
non-home disk scratch are now durable Beads memories rather than chat-only
workarounds. No surviving Dolt server was observed after the final suites.
