# Issue sweeps 6+7: test-ci (12) + cli-ux light pass (36) — 2026-07-26

Sixth and seventh theme-clustered tri:claim drain sweeps (epic mybd-xmx7).
cli-ux ran as a deliberate light pass (state + merged-fix signal only, no
comment digests) — appropriate for the bulk lane.

## test-ci dispositions (12)

| bd | gh | disposition | reason |
|----|----|-------------|--------|
| mybd-ix72 | 5031 | tri-close | closed upstream 07-25 |
| mybd-6r1w | 5034 | left gated | closed upstream, but bd-close blocked by mybd-82yzc (PR 5035 patrol tail) — closes via tri-sync when 5035 merges |
| mybd-op0f | 5070 | dep-gated | blocked-by mybd-26sq7 (fix PR #5073, ecuthiell/mybd-tm42 lane) |
| mybd-mj8b | 5071 | dep-gated | blocked-by mybd-wp68w (fix PR #5074, same lane) |
| mybd-5fbkt/nfvi1/2n1ns/u8vex/7cpd | 3805/3800/3796/3798/4638 | no action — already structured | each already dep-gated on its own open fix-PR mirror (1dhge/w6ahk/omuu8/st35d/x8bg); consolidation attempt reverted (mybd-7x26y closed as unnecessary) |
| mybd-cjcpt | 3811 | keep | CI-load flake (TestEmbeddedInitConcurrent), reproducible, no fix |
| mybd-xz76h | 4937 | keep, noted | external patch 290eee721 exists — absorb with attribution, don't re-derive |
| mybd-qx3f | 4860 | keep, noted | CI config blocks doctor Dolt tests AND open PR 4858 — PR-throughput value |

## cli-ux light-pass dispositions (36)

| bd | gh | disposition | reason |
|----|----|-------------|--------|
| mybd-d6rjw | 3893 | tri-close (was p0) | #4786 merged regression tests for --graph --dry-run — behavior fixed and CI-covered |
| mybd-uk10u | 3924 | tri-close | #4188 merged (ship codex-hook safely); post-v1.0.4 releases include the subcommand |
| mybd-v5ggz | 4094 | tri-close | #4158 merged — exactly the non-interactive truncation ask |
| mybd-ulmls | 3927 | keep, corrective note | #4191 "debug…" is diagnostics, not clearly the fix — verify-first |
| mybd-sfiw | 4816 | keep, corrective note | recon's #4820 suggestion was cross-ref noise (fixes gh 4817, not this); still live; family with mybd-tgqsj |
| remaining 31 | — | keep (bulk lane) | all open, no merged fix; no further action this pass |

## Recon-verification scoreboard (session cumulative)

Delegated recon claimed a "merged fix" 10 times across sweeps 2–7; in-session
verification confirmed 7 and rejected 3 (#3808 closed-unmerged, #4191 not a
fix, #4820 fixes a different issue). **The verify-before-close step is earning
its cost — a ~30% false-positive rate on recon fix-claims would have closed
three real bugs, one of them p0-adjacent.**

## Epic status after 7 sweeps

Swept: import-export, data-integrity, concurrency, migration-schema,
sync-remote, doctor, deps-ready, hooks-install, test-ci, cli-ux (light).
Remaining: misc (22 — needs reclassify pass first), server-mode (34 —
coordinate with the psxg campaign lanes), pr-mirror (43 — belongs to the PR
review sweep lane, not issue sweeps).
