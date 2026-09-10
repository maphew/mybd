# Cleanup follow-through - 2026-09-10

Scope authorized: completed branch pruning, retained-work disposition, optional remote repair/retirement, redundant backup consolidation, and old Linux database backup removal. Windows host A:/dev/mybd.

## Completed actions

- Retired optional remote silvanshade after GitHub could not resolve the repository and no public replacement appeared. All five cached refs were copied to refs/archive/retired-remotes/silvanshade before removing the remote. git fetch --all --prune then passed for origin, upstream, quad341, maxinflection and sjarmak.
- Removed five more source worktrees: j97q-history-null, pr-4858-f103632, pr-3837-review, pr-4284-review and pr-4376-review. Seven source checkouts remain.
- Before retiring dirty duplicates, copied every modified and untracked file, binary patch and manifest into tmp/local-work-recovery-20260910.zip. SHA-256 comparisons of ZIP entry streams against original files all passed.
- Verified PR4858 staged changes equal committed range 0cf3b3c..36d9af7 byte-for-byte. Kept review/pr-4858-f103632 and review/pr-4858-36d9af7 as recovery refs. The history-null patch is semantically superseded by current COALESCE projections.
- Recovered the May1 report from work/mk1 into reports/2026-05-01-pr-3317-review-recovered.md. Did not replay historical tracker changes. Full original branch is backed up in tmp/mybd-work-mk1-recovery-20260910.bundle, which passed git bundle verify.
- Recovered two Markdown documents from codex-architecture-analysis: reports/beads-project-analysis-2026-06-22.md and reports/beads-project-phase-2-plan-2026-06-22.md. They are labeled historical and pre-step-down; old HTML twins remain only in the recovery bundle.

## Verification and preserved value

Branch pruning uses exact expected SHA checks and refuses current worktree branches. Every pruned tip must be advertised under its original branch name in the verified full bundle tmp/beads-all-worktree-heads-20260910.bundle. The primary manifest received independent read-only review. Deletion uses git update-ref -d with expected old SHA, then removes only that branch configuration section.

Unique patches were preserved unchanged, with exact Git state and safe next steps in reports/2026-09-10-retained-patches-handoff.md:

- mybd-erj71: config-only reset patch in b8ht-reset-config. Original task recorded a destructive wrong-target incident, so future work needs isolated target-coherence evidence before reuse.
- mybd-d44xi: GNU Make3.81 host-detection commit e250ea4b8. Retains Amp coauthor credit.
- Deferred backend registry and its review snapshot remain under mybd-hr4t.3. Active owned PR5202 and PR5243 review checkouts remain.

No implementation was changed and no source test suite was run. Validation consists of backup restore/coverage, cryptographic file comparisons, exact ref/worktree checks, successful all-remotes fetch, report whitespace checks and the session-close backstop.

## Cleanup blocked externally

Linux backup mybd-d65mi: owner approval is now supplied by this session. ssh -o BatchMode=yes -o ConnectTimeout=10 matt@framation reached the host but failed authentication (publickey/gssapi/password). No remote files were changed. Remaining next step: execute on the Linux host or use working SSH authentication, verify the exact backup target, then remove the obsolete database backup.

Redundant backups mybd-wvkjg: unbundled the newest full source bundle into a fresh isolated bare repository and checked all158 advertised commit tips from the two older bundles. Zero tips were missing. This establishes coverage independently of the live source object store. Coverage manifest: tmp/consolidated-bundle-manifest-20260910.json.

Automatic approval review rejected the deletion command with only blocked by policy. No redundant bundle or temporary verification repository was removed. Preserved targets:

- A:/dev/mybd/tmp/beads-pre-housekeeping-2026-08-28.bundle (127.3MiB).
- A:/dev/mybd/tmp/beads-pre-prune-20260910.bundle (127.5MiB).
- A:/dev/mybd/tmp/bundle-coverage-20260910.git (disposable isolated coverage repository).

Keep the newest full bundle, local-work recovery ZIP and separate coordination recovery bundle. The ZIP staging directory is also retained as an additional recovery copy.

## Final branch disposition

Final pruning manifest and retained ref list follow below.

Removed 66 source branches from the original75, leaving9. Both pruning sets and final pr-3550 squash equivalence received independent read-only review. The exact pruned refs and reasons follow.

| Branch | Backed-up HEAD | Completion evidence |
|---|---|---|
| codex/cli-docgen-speed | 9b59d139af6db6e9af6c712c58d88be416ebfb3f | Matching completed PR(s): gastownhall/beads#4474 MERGED. |
| codex/homebrew-single-source | 07d58129993459e93d235e9e4e277305624b897c | Matching completed PR(s): gastownhall/beads#4478 MERGED. |
| codex/release-homebrew-procedure | 0748c360c2d64048aca6eb49eac9791e0cc24e5c | Matching completed PR(s): gastownhall/beads#4571 MERGED. |
| dependabot/go-alerts | a1b067bd3a982ecd1a3a7e311f05d7fff5f4fa50 | Matching completed PR(s): gastownhall/beads#3855 MERGED. |
| dependabot/python-mcp-alerts | 3e107ba9bfbc95f213dfbb103d03aaca5106579f | Matching completed PR(s): gastownhall/beads#3856 MERGED. |
| dependabot/website-npm-alerts | cc4e594609e58cd9d61698e45dbab8232b52156c | Matching completed PR(s): gastownhall/beads#3857 MERGED. |
| docs/24ld-troubleshooting | 94d5a996eadd55a63653dc63d8537e15674a5c5e | Matching completed PR(s): gastownhall/beads#4973 MERGED. |
| docs/4k3v-worktrees | a7882d210fc9401913e402ca94c312dd0f04d701 | Matching completed PR(s): gastownhall/beads#4972 MERGED. |
| docs/5dtq-export-status | 1c3554ad3d29515d3ff62c5f10f7a3e88eb8c4d6 | Matching completed PR(s): gastownhall/beads#4970 MERGED. |
| docs/advanced-public-surface | e52abeb5adc028b946473a81a7af24b2ce1ee027 | Matching completed PR(s): gastownhall/beads#4582 MERGED. |
| docs/bm4d-worktree-sync-docs | 0f2089419420a8fc519a67f0cfa0b64696941dd2 | Matching completed PR(s): gastownhall/beads#4593 MERGED. |
| docs/f5jk-sync-removed | 8474a06e2dca4291c3d92107a88f19fe8523ce55 | Matching completed PR(s): gastownhall/beads#4975 MERGED. |
| docs/lb4i-import-current | d458bed6e73382a05b520be9623e361b8c557153 | Matching completed PR(s): gastownhall/beads#4976 MERGED. |
| docs/mybd-7po-integrations | 4dc6bae9f7191857edf9408f12017e8638a41c88 | Matching completed PR(s): gastownhall/beads#3899 MERGED. |
| docs/observability-log-export | ada0133179cdbdd649d5ca12bf7f9795c1a64247 | Matching completed PR(s): gastownhall/beads#4588 MERGED. |
| docs/project-scope-boundaries | ce7c91cbbf7d6f0f7f6d6ad4b46142d1b5d19a91 | Matching completed PR(s): gastownhall/beads#3842 MERGED. |
| docs/resolve-extending-reference | 221d7e8f1031d5085467c1371b54d5e43f6f661f | Matching completed PR(s): gastownhall/beads#3810 MERGED. |
| feat/dk2w-schema-newer-failfast | 58d76114b29686332c2dae5da0f630c518d8775c | Matching completed PR(s): gastownhall/beads#4531 MERGED. |
| fix/2760-event-poll-inf-cast | 628d4afea943b244688f1fc409327973d9dd16b2 | Matching completed PR(s): gastownhall/beads#2877 MERGED. |
| fix/2858-list-blocked-status | 07fda058b5369b3aa64767b7011835a07224070e | Matching completed PR(s): gastownhall/beads#2878 MERGED. |
| fix/3fvn-4304-auto-import | 24dc3af683f005cacc38b1cbcf6d98e429041bcd | Matching completed PR(s): gastownhall/beads#4595 MERGED. |
| fix/75zv-config-apply-autostart | 683aa99fb847c6509bf6893b641831c1cbbb4ba7 | Matching completed PR(s): gastownhall/beads#4955 MERGED. |
| fix/be-doc-freshness-cgo | 472896bef655ede9cea7cda19a9a6ab2a95c3f05 | Matching completed PR(s): gastownhall/beads#4243 CLOSED. |
| fix/bwpm-global-create-prefix | 5c5fc928d82c80db6644912e7f4f5180ddc20955 | Matching completed PR(s): gastownhall/beads#4957 MERGED. |
| fix/c6la-config-drift-shared-pid | b12e6ae8754be76bee8a5dc3e74160ff8ee8901a | Matching completed PR(s): gastownhall/beads#4952 MERGED. |
| fix/ci-prune-perf | ebaaafea848d97f34e2ca28bd0832fc23ee18071 | Matching completed PR(s): gastownhall/beads#4599 MERGED. |
| fix/closeissue-errnotfound | 008c3206063f608df68aa4dbf0ae2b57b52aca0e | Matching completed PR(s): gastownhall/beads#4525 MERGED. |
| fix/do91-plugin-argument-hints | 2765df75d5ea78fc99920e1c542a012b86451610 | Matching completed PR(s): gastownhall/beads#4969 MERGED. |
| fix/docs-extending-xref | 87d1d1b7983b20668e23ab7b650a5cb7a8cbc369 | Matching completed PR(s): gastownhall/beads#4526 MERGED. |
| fix/dolt-transaction-event-parity | 03146aab970f5066c453ec218cf720fafdb3f4b9 | Matching completed PR(s): gastownhall/beads#4580 MERGED, gastownhall/beads#3803 CLOSED. |
| fix/foug-codex-hook-migration | 6a0f6d694ba9893f0e36f4a9b5b75e23c94d7f4c | Matching completed PR(s): gastownhall/beads#4953 MERGED. |
| fix/gh-4555-migration-wisp-deps | 9f3bb798da8e4f922a69d40b64e7b5fe01661a66 | Matching completed PR(s): gastownhall/beads#4558 MERGED. |
| fix/kj2v-bootstrap-cleanup | 9b8934270f874abcb6bdd2d7649cb46b7e7fb08c | Matching completed PR(s): gastownhall/beads#4598 MERGED. |
| fix/mybd-ay8-terminology | fb2534498ebc861ee58cb7ac8aab96c86e259547 | Matching completed PR(s): gastownhall/beads#3900 MERGED. |
| fix/n5gg-windows-test-home | cf9fc71ca35143458ae545876b9338dfa410111a | Matching completed PR(s): gastownhall/beads#4950 MERGED. |
| fix/nghh-search-status | 4eb8b3bfcd18fef44462d47a6e465be8373f2c85 | Matching completed PR(s): gastownhall/beads#4951 MERGED. |
| fix/obc1-init-server-diagnostics | 14ce746a49b052902f6b5a227f99fd6199b31105 | Matching completed PR(s): gastownhall/beads#4954 MERGED. |
| fix/q6cz-sqlserver-reaper | 4858394f53a81bf262192a69dd23136b9c96e141 | Matching completed PR(s): gastownhall/beads#4591 CLOSED. |
| fix/regression-tempdir-cleanup | b6cd2ab43d3e6e3b9afca8f7ba019ceb3404ea53 | Matching completed PR(s): gastownhall/beads#3854 MERGED. |
| fix/suxn1-cross-prefix-import | 956244b2093f82efe575ad1051cc0f44c58f2a84 | Matching completed PR(s): gastownhall/beads#4963 MERGED. |
| fix/suxn2-orphan-child-counter | adbbfb6cfadb288f9be1c75e5cf874d7c866adff | Matching completed PR(s): gastownhall/beads#4964 MERGED. |
| fix/w7f5-explicit-parent-edge | d006176d86cba02d4db7b3133bc3d32d0be88729 | Matching completed PR(s): gastownhall/beads#4956 MERGED. |
| maint/pr-3640-fix | d15d4f03e1a325297715ccb25a340a3d6af57ad7 | Approved completed worktree branch with exact head. |
| maint/pr-4329-fix | 04add8b70b4c05b5d3b916eb075b98b487a41628 | Approved completed worktree branch with exact head. |
| mybd-8chd-1-windows | 974894a9655697e0f5ac963d170a2f624914e1f3 | Matching completed PR(s): gastownhall/beads#4600 MERGED. |
| pr-4373-rig-durability | 747c3a25db52fa7d4d8d0d328db183022173bb00 | Approved completed worktree branch with exact head. |
| pr-4406-minfix | b54847e39f45272fad855eb3934127f434303f08 | Approved completed worktree branch with exact head. |
| pr-4422-maintainer | 11b8511179bdb79f0cc8465791366fdd2f7bc659 | Approved completed worktree branch with exact head. |
| pr-4461-maintainer | 521fc7692d5df460229a1381983cc56cad31cf4c | Approved completed worktree branch with exact head. |
| repair/pr-4537-lease | fae8ad8a14f9e856353518a5cd3697289ee93442 | Approved completed worktree branch with exact head. |
| revert-4476-rc-release-safety | e6e6298ae31d1cd699533bc1d52527460af53688 | Matching completed PR(s): gastownhall/beads#4477 MERGED. |
| smart-migrate-gate-4516 | bf9c193c387b1b955cd7d7df61bab8e4b5802171 | Matching completed PR(s): gastownhall/beads#4524 MERGED. |
| fix/j97q-history-null-text | 873e3040bf0f0974f9ebc24e7d11afb4b989c092 | Now-free branch; HEAD is ancestor of upstream/main; dirty checkout archived and retired |
| review/pr-4858-stacked-44e278e | 44e278e5311291874e2b9f0baeb4a475a076d5a2 | Now-free branch; HEAD is ancestor of upstream/main; dirty checkout archived and retired |
| codex-architecture-analysis | 62522ff4b53a175e14c60337881160f838149479 | Single 2026-06-22 documentation/report commit; no source-code changes or active worktree. Full bundle retains the report snapshot. |
| maint/pr-4778-fix | 5588d981553d55d965789b62b2872faa26244c41 | PR gastownhall/beads#4778 merged 2026-07-14; this branch is the maintained five-commit implementation range, superseded by merge commit 50b061740. |
| maintain/pr-3781-formula-primitives | 6f040386bd0d0882e066a7a95ea98f4d7b94aa01 | PR gastownhall/beads#3781 merged 2026-07-07; audit records this exact maintainer follow-up as part of the merged PR. |
| pr-3679-fix | ff55a0494b11575086eab885296178ca1692a512 | Exact PR gastownhall/beads#3679 head; PR merged 2026-07-04. |
| pr-3770-head | f85fb65a2cb8014f20cd134cf14322920fc83185 | PR gastownhall/beads#3770 merged 2026-07-06 after recorded stacked validation. |
| pr-3771-head | c7bedb2715cfdce802f4bdccb4b2b4fb45039454 | PR gastownhall/beads#3771 merged 2026-07-06 after recorded stacked validation; branch last commit is a CI retrigger, not ongoing work. |
| pr-4309-review | 2c2eed479a7188d052bae21e2705fab9791c8b8b | PR gastownhall/beads#4309 merged 2026-06-07; related durable task closed as merged. |
| pr-4373-ci-fix | 66f5ef33861a73dc8a4cf29a578bf553fef9442b | Exact PR gastownhall/beads#4373 head; PR merged 2026-06-23 and fix-merge task closed. |
| pr-4382-ci-fix | 5e50073bad556eb14f1e9ade26a73e6c34c74595 | Exact PR gastownhall/beads#4382 head; PR merged 2026-06-20 and task closed as landed. |
| pr-4552-review | ff7e0391981b7fd3b20dd7c01cece5d6127bb383 | Exact PR gastownhall/beads#4552 head; PR merged 2026-07-02. |
| pr-4558 | bf4c7568ca5e715f1c96a290bfca613d135357d0 | Completed PR gastownhall/beads#4558 validation snapshot; cleanup approval records it as an ancestor of the merged PR head. |
| pr-3550 | 15bdcd09b407fc5a075e399b73fd9d37df7367e7 | PR gastownhall/beads#3550 squash-merged with the full original and post-review-nit content; the divergent local commits contain no remaining semantic work. |

Retained source refs:

| Branch | HEAD |
|---|---|
| claude/hr4t3-backend-registry | 737408491d65e8e54e48cf27386e8aab33924323 |
| fix/b8ht-reset-config | 873e3040bf0f0974f9ebc24e7d11afb4b989c092 |
| fix/make-381-host-detection | e250ea4b8b132cc3fd358fd59c8f837c3024386a |
| main | a690b0a8c4d1ddc4f0bd9bf767499625dd71bc96 |
| mybd-hli9-nocgo-build-tags | 8e24f7b24b5ca2055c5ea2f694ad93cfd319b73e |
| mybd-hli9-zstd-seam | 6701270ef54f668245ffbc1adba637de11200150 |
| mybd-hli9-zstd-seam-evidence | aa973eb1a5d9bf88cdba4f8d1a1d2eb11d3e584e |
| review/pr-4858-36d9af7 | 36d9af7351c2aaf2e7790bf6aa1b5e197fd572de |
| review/pr-4858-f103632 | f103632449e2e208c7d66e7259d946e887bfe187 |

Retained source worktrees:

    A:/dev/mybd/bd-main                                 a690b0a8c [main]
    A:/dev/mybd/.worktrees/beads/b8ht-reset-config      873e3040b [fix/b8ht-reset-config]
    A:/dev/mybd/.worktrees/beads/hr4t3-backend-registry 737408491 [claude/hr4t3-backend-registry]
    A:/dev/mybd/.worktrees/beads/make-381-host          e250ea4b8 [fix/make-381-host-detection]
    A:/dev/mybd/.worktrees/beads/pr-4561-review         d8de98723 (detached HEAD)
    A:/dev/mybd/.worktrees/beads/pr-5202-review         f284c6051 (detached HEAD)
    A:/dev/mybd/.worktrees/beads/pr-5243-review         7771c99c3 (detached HEAD)

The coordination orphan work/mk1 is retired after its recovered report lands; its original commit remains in the separate verified coordination bundle.

Closed cleanup tasks: mybd-ehrmz, mybd-t0v5r, mybd-u3sqy and resolved pr-3550 audit mybd-vo1fv. Unique implementation follow-ups remain open as mybd-erj71 and mybd-d44xi. External cleanup blockers remain open as mybd-d65mi and mybd-wvkjg. No new upstream PR, comment, review, or maintainer action was performed.

Local audit records: tmp/branch-prune-audit-20260910.json, tmp/branch-prune-extra-20260910.json, tmp/branch-prune-results-20260910.json. All recovery locations remain reachable from this report and open tracked work.

## What did I notice that was not on a list?

A per-commit git cherry result was insufficient evidence of unique work after squash merges. For pr-3550, direct comparison of the combined diff, byte-identical test blob and retained behavior showed the review nits had landed. Conversely, two uncommitted/committed patches with closed-looking provenance still had useful unique behavior; those now have explicit tracked owners and safe-next-step notes. Three orphaned Markdown reports were recovered rather than left accessible only through stale refs.
