# Completed worktree cleanup - 2026-09-10

Windows host: A:/dev/mybd. Tracking: mybd-56128.

## Scope and evidence

Audited 72 Beads source worktrees. The removal manifest selects 60 clean worktrees whose implementation merged, whose proposal was explicitly retired/superseded, or whose review task is closed. An open third-party PR does not keep a completed review checkout active. No upstream PRs are closed or otherwise changed by this cleanup.

Backups verified before removal:

- `tmp/beads-pre-prune-20260910.bundle`: all 75 local source branches.
- `tmp/beads-all-worktree-heads-20260910.bundle`: complete history, all refs and every detached worktree HEAD; 194,176,635 bytes. Temporary `refs/housekeeping/20260910/worktrees/*` references made detached heads explicit before bundling.
- Existing local branches are retained, including reference-only retired work. Detached history remains recoverable from the bundle by the HEADs listed below.

Removal uses `git worktree remove` without force, after checking the resolved path is below `.worktrees/beads` or `_working_on`, the HEAD has not moved, and tracked/untracked status remains clean. The ignored files observed in candidates were build executables and website build/node_modules directories. No database or unowned ignored data was found.

## Completed worktrees selected for removal

Paths below are relative to A:/dev/mybd.

| Worktree | HEAD | Completion evidence |
|---|---|---|
| `.worktrees/beads/cli-docgen-speed` | `9b59d139af6db6e9af6c712c58d88be416ebfb3f` | Merged PR 4474; exact head, ancestor, or patch equivalence verified |
| `.worktrees/beads/fv7r-close-errnotfound` | `008c3206063f608df68aa4dbf0ae2b57b52aca0e` | Merged PR 4525; exact head, ancestor, or patch equivalence verified |
| `.worktrees/beads/gh-4243-doc-freshness` | `472896bef655ede9cea7cda19a9a6ab2a95c3f05` | PR4243 explicitly retired as superseded by pure-Go docgen approach |
| `.worktrees/beads/homebrew-single-source` | `07d58129993459e93d235e9e4e277305624b897c` | Merged PR 4478; exact head, ancestor, or patch equivalence verified |
| `.worktrees/beads/mybd-hli9-zstd-seam` | `6701270ef54f668245ffbc1adba637de11200150` | mybd-hli9 closed as superseded; owner withdrew fork-carry; reference history backed up |
| `.worktrees/beads/q6cz-sqlserver-reaper` | `4858394f53a81bf262192a69dd23136b9c96e141` | mybd-q6cz closed; PR4591 superseded by merged PR4592 |
| `.worktrees/beads/q71-docs-xref` | `87d1d1b7983b20668e23ab7b650a5cb7a8cbc369` | Merged PR 4526; exact head, ancestor, or patch equivalence verified |
| `.worktrees/beads/revert-4476-rc-release-safety` | `e6e6298ae31d1cd699533bc1d52527460af53688` | Merged PR 4477; exact head, ancestor, or patch equivalence verified |
| `.worktrees/beads/verify-mybd-5tz0-bf4c7568ca5e-20260703T043357Z` | `bf4c7568ca5e715f1c96a290bfca613d135357d0` | mybd-5tz0 closed; PR4558 merged; validation snapshot is ancestor of merged PR head |
| `.worktrees/beads/verify-mybd-suxn.1-956244b2093f-20260723T003113Z` | `956244b2093f82efe575ad1051cc0f44c58f2a84` | mybd-suxn.1 closed; PR4963 merged at exact snapshot head |
| `.worktrees/beads/zstd-nocgo-build-tags` | `8e24f7b24b5ca2055c5ea2f694ad93cfd319b73e` | mybd-hli9 closed as superseded; owner withdrew fork-carry; reference history backed up |
| `.worktrees/beads/zstd-seam-evidence` | `aa973eb1a5d9bf88cdba4f8d1a1d2eb11d3e584e` | mybd-hli9 closed as superseded; owner withdrew fork-carry; reference history backed up |
| `_working_on/dep-npm` | `cc4e594609e58cd9d61698e45dbab8232b52156c` | Merged PR 3857; exact head, ancestor, or patch equivalence verified |
| `_working_on/mybd-ay8-terminology` | `fb2534498ebc861ee58cb7ac8aab96c86e259547` | Merged PR 3900; exact head, ancestor, or patch equivalence verified |
| `.worktrees/beads/pr-3458-review` | `e46e82504a1842ff1be145a575efeb84b9d9b230` | Completed review mybd-v5xdy; upstream PR 3458 remains open and unchanged |
| `.worktrees/beads/pr-3640-fix` | `d15d4f03e1a325297715ccb25a340a3d6af57ad7` | PR 3640 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-3777-review` | `2cffa2387377d2a2ac179e8bf73655050c15f61c` | Completed review mybd-4fngg; upstream PR 3777 remains open and unchanged |
| `.worktrees/beads/pr-3778-validate` | `98e2b3eabf10d6ef687b6c31e913ad35ec470661` | PR 3778 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4206-clean` | `e37fd76a28a41dfaacb4ccee1c74e11790a40ceb` | PR 4206 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4206-merge-test` | `1ab5078b94f2f9f9506b420191df4e35d55bf167` | PR 4206 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4206-review` | `f9296b45e3f70fee7dc6b232c5fe0cb59a5dad8b` | PR 4206 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4329-fix` | `04add8b70b4c05b5d3b916eb075b98b487a41628` | PR 4329 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4329-review` | `04add8b70b4c05b5d3b916eb075b98b487a41628` | PR 4329 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4373-rig-durability` | `747c3a25db52fa7d4d8d0d328db183022173bb00` | PR 4373 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4406-minfix` | `b54847e39f45272fad855eb3934127f434303f08` | PR 4406 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4407-review` | `1cfdd2099680160198920403ee2e0ab9884c4845` | PR 4407 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4408-merge-test` | `f43c0c2a239219a1097e741a28f30965f6a6857e` | PR 4408 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4408-review` | `31cbf8be7904672e20d30058e9c4dcb455e9d0a2` | PR 4408 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4415-review` | `8e3659257ad495ba3a9160d5146bb419d22183ae` | Completed review mybd-ive00; upstream PR 4415 remains open and unchanged |
| `.worktrees/beads/pr-4422-maintainer` | `11b8511179bdb79f0cc8465791366fdd2f7bc659` | PR 4422 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4439-validate` | `182ad118fae192784d7ef28096306039680c42e6` | PR 4439 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4461-maintainer` | `521fc7692d5df460229a1381983cc56cad31cf4c` | PR 4461 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4486-review` | `03114906c72a10ccbb16ed7a368f1f2957a4d236` | PR 4486 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4493-review` | `ea2bd68264de6221529db29200595c8b605f21a2` | PR 4493 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4514-review` | `4ca274012ad1cdc27ecf79fab6af1c71b3503bef` | PR 4514 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4515-review` | `ef04eb44083a0a051a930ea8b597ed9b20cd10b6` | PR 4515 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4524-review` | `bf9c193c387b1b955cd7d7df61bab8e4b5802171` | PR 4524 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4529-review` | `caabffdf51abce93beec8e3d251b8d4d3b657b18` | PR 4529 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4531-review` | `58d76114b29686332c2dae5da0f630c518d8775c` | PR 4531 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4537-lease` | `fae8ad8a14f9e856353518a5cd3697289ee93442` | PR 4537 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4537-review` | `ab015ef542e1c0aa82661de1971deed37155eabc` | PR 4537 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4753-rereview` | `f5adb8c2b0ee24ee79f3440a1b0c38dcf02920ee` | PR 4753 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4753-review` | `f5adb8c2b0ee24ee79f3440a1b0c38dcf02920ee` | PR 4753 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4804-review` | `3a017a89b9caab632023894c1ddafb2bdf4a9043` | PR 4804 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-4806-review` | `537ded792fa4ca1f851fe0ef1beff74cfcfbfbe4` | Completed review mybd-95g15; upstream PR 4806 remains open and unchanged |
| `.worktrees/beads/pr-4828-review` | `f0315ad0fcac2bae0997939fc5c264495a01e47c` | Completed review mybd-5e8pi; upstream PR 4828 remains open and unchanged |
| `.worktrees/beads/pr-4844-review` | `134565c333035a420aa7a0f97e16af78c874fa0c` | Completed review mybd-gutwo; upstream PR 4844 remains open and unchanged |
| `.worktrees/beads/pr-5064-review` | `2fd873e47ba210b38c27e5fe4f1e779f9ab79ae9` | PR 5064 merged; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-5086-review` | `103d0948e2dd49449824a9ae92a30fc7b62da904` | PR 5086 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-5087-review` | `33c05bbc89570ed9e7b08b094031e6d550b80a7c` | Completed review mybd-g4o6h; upstream PR 5087 remains open and unchanged |
| `.worktrees/beads/pr-5133-review` | `144f11c85d44735eba60a12fa49ca4a6293c40d3` | Completed review mybd-1e2yl; upstream PR 5133 remains open and unchanged |
| `.worktrees/beads/pr-5137-review` | `52430ecc174c0944aff225df6040aa41c2156c41` | Completed review mybd-54zj9; upstream PR 5137 remains open and unchanged |
| `.worktrees/beads/pr-5138-review` | `18b79ec7abd0d96c664965e03167593c425d7a2b` | Completed review mybd-kj8rp; upstream PR 5138 remains open and unchanged |
| `.worktrees/beads/pr-5139-review` | `3cc41743036966111884548b7047fa13a63ee912` | Completed review mybd-snge6; upstream PR 5139 remains open and unchanged |
| `.worktrees/beads/pr-5140-review` | `911a38b24e06dfbd482a5d13203182eb296f1d8e` | Completed review mybd-xc43b; upstream PR 5140 remains open and unchanged |
| `.worktrees/beads/pr-5145-review` | `164e82978c5e5cf967066154fa02a2d09502acc7` | Completed review mybd-dcdfw; upstream PR 5145 remains open and unchanged |
| `.worktrees/beads/pr-5182-review` | `0a3fe0f9bd8dd3d5a71b5c57fcec6e554cb9463f` | PR 5182 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |
| `.worktrees/beads/pr-5214-review` | `adead21160c97d0b54d0f66449cc5c63aa971ca7` | Completed review mybd-fv4wv; upstream PR 5214 remains open and unchanged |
| `.worktrees/beads/pr-5215-review` | `575154c3204f62097fcb9c2988ad3f3a5e1e92e1` | Completed review mybd-ln5p1; upstream PR 5215 remains open and unchanged |
| `.worktrees/beads/pr-5241-review` | `9dbdddfed01c0c7e7c95e69dffbed66bc8e0ed21` | PR 5241 closed/retired; completed review/fix snapshot, historical commits preserved in verified bundle |

## Retained work

| Worktree | Reason |
|---|---|
| `bd-main` | Main source checkout. |
| `.worktrees/beads/b8ht-reset-config` | Uncommitted reset code/tests/docs; original bead closed, but these local edits are not established as disposable. |
| `.worktrees/beads/j97q-history-null` | Uncommitted history code/tests; original bead closed, local edits preserved. |
| `.worktrees/beads/pr-4858-f103632` | Nine staged tracked changes; PR still open. |
| `.worktrees/beads/hr4t3-backend-registry` | Deferred mybd-hr4t.3 explicitly parked, not completed. |
| `.worktrees/beads/make-381-host` | Unique local commit e250ea4b8; no matching completed task or PR identified. |
| `.worktrees/beads/pr-3837-review` | PR open; direct completed-review evidence absent. |
| `.worktrees/beads/pr-4284-review` | PR open; direct completed-review evidence absent. |
| `.worktrees/beads/pr-4376-review` | PR open; direct completed-review evidence absent. |
| `.worktrees/beads/pr-4561-review` | PR open; related registry work explicitly deferred. |
| `.worktrees/beads/pr-5202-review` | Active owned PR, mybd-cebxh/mybd-itgj in progress. |
| `.worktrees/beads/pr-5243-review` | Active owned PR tracked by fleet. |

Coordination branch `work/mk1` at `c28fad7` remains: it contains a review report absent from main and is not a registered worktree. It is outside the completed-worktree removal set.

Some retired snapshots contain history that differs from the final PR head. Patch equivalence confirmed the PR4206-clean and PR4486-review changes. The remaining historic test/merge stacks and superseded proposals are preserved in the complete bundle; their removal does not claim every historic commit merged unchanged.

## Verification and handoff

Final removal outcome and checks are recorded below. No implementation changes were made, so a source test suite is not applicable. Whitespace validation and the session-close backstop cover the report and durable handoff.

Residual provenance and orphan-branch work is tracked by open bead `mybd-ehrmz`. Active PR work remains under its existing fleet/import beads, and the backend registry remains deferred under `mybd-hr4t.3`.

Independent read-only review found all 60 manifest entries matched the baseline path and HEAD, were clean, excluded unsafe roots and active work, and cited closed completion beads where applicable.

Final outcome: all 60 removals returned exit 0. All removed paths are absent; Git registers exactly 12 remaining source worktrees, including main. The three dirty worktrees have the same tracked/untracked status as before. All local branch refs remain; temporary snapshot/fetch refs were cleaned after the full bundle was verified. The audit bead `mybd-56128` is complete; remaining uncertainty is tracked by `mybd-ehrmz`.

Local evidence: `tmp/worktree-audit-20260910.json`, `tmp/worktree-removal-approved-20260910.json`, `tmp/worktree-removal-results-20260910.json`. Historical review stacks and reference proposals can be restored from the full bundle. For example, fetch `refs/housekeeping/20260910/worktrees/pr-4206-merge-test` from that bundle into a new local recovery branch, then use `git worktree add` with an absolute path.
