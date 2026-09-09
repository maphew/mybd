# Upstream Beads Activity

Repository: [gastownhall/beads](https://github.com/gastownhall/beads). Window: May 1, 4:18 PM to May 3, 4:18 PM America/Whitehorse, generated from GitHub PR/issue APIs and `git log` on upstream `main`.

- **68** Commits on main — Commit-date filtered from upstream main

- **28** Merged PRs — Merged during window

- **47** New PRs — 23 still open, 1 closed unmerged

- **12** Issues opened — 9 still open

- **11** Issues closed — Closed during window

- **49%** New-PR merge rate — Merged among PRs opened in window

## Executive Read

**Throughput was high.** Maintainers merged 28 PRs and upstream main received 68 commits in 48 hours. A large share was cleanup and integration work rather than isolated feature work.

**Dolt/storage is the active pain center.** Fresh issues cluster around shared-server behavior, SQL/CLI remote divergence, auto-import regressions, and init remote semantics.

**Linear integration moved fast.** OAuth, idempotency, per-workspace locks, Retry-After handling, and staleness signals landed, while batch/audit-log follow-ups remain open.

## Category Mix

| Category | Issues opened | Issues closed | New PRs | Merged PRs | Total signal |
|---|---|---|---|---|---|
| CLI behavior | 4 | 3 | 13 | 6 | 26 |
| Dolt/storage/sync | 4 | 2 | 8 | 4 | 18 |
| Export/privacy/data boundaries | 3 | 2 | 5 | 4 | 14 |
| Linear integration | 0 | 0 | 8 | 6 | 14 |
| Docs/agent/plugin/release | 1 | 0 | 4 | 2 | 7 |
| GitHub sync | 0 | 2 | 2 | 2 | 6 |
| Other | 0 | 1 | 3 | 2 | 6 |
| Graph/UI output | 0 | 1 | 3 | 2 | 6 |
| Jira integration | 0 | 0 | 1 | 0 | 1 |

## Hotspots

### Files and subsystems

- **plugins**: 53 distinct commit-file touches

- **cmd/bd**: 49 distinct commit-file touches

- **internal/linear**: 35 distinct commit-file touches

- **internal/storage**: 24 distinct commit-file touches

- **internal**: 21 distinct commit-file touches

- **docs/process**: 12 distinct commit-file touches

- **internal/github**: 6 distinct commit-file touches

- **scripts**: 5 distinct commit-file touches

Counts are commit-file touches, so broad plugin/doc drops inflate by changed-file fanout rather than line volume.

### Review pressure

- 23 of 47 newly opened PRs are still open.

- 29 new PRs had Codecov patch-coverage warnings in fetched PR comments.

- Several fixes are follow-ups to recent fixes: graph HTML #3648 followed by #3671, CLI contrast #3643 followed by #3672, and auto-import #3630 followed by #3690/#3691.

## Pain Points

**Dolt/shared-server correctness:** issues [#3685](https://github.com/gastownhall/beads/issues/3685), [#3687](https://github.com/gastownhall/beads/issues/3687), [#3688](https://github.com/gastownhall/beads/issues/3688), and [#3689](https://github.com/gastownhall/beads/issues/3689) describe misleading shared-server status, remote synthesis gaps, and SQL/CLI state divergence.

**Auto-import regression loop:** new PRs [#3690](https://github.com/gastownhall/beads/pull/3690) and [#3691](https://github.com/gastownhall/beads/pull/3691) target fallout from the recently merged auto-import/concurrency work.

**Privacy boundary hardening:** #3649/#3650 closed after export defaults were changed to exclude wisps and memories; related federation filtering landed in #3653.

**Agent/docs discoverability:** #3677 and #3683 indicate user-facing friction around `bd prime`, memory visibility, and command documentation despite the new plugin/agent work.

### Coverage Warnings On New PRs

| PR | Title | Patch coverage | Missing/partial lines |
|---|---|---|---|
| [#3676](https://github.com/gastownhall/beads/pull/3676) | perf(graph): replace N+1 dependency queries with bulk fetch (GH#3520) | 0% | 42 lines |
| [#3674](https://github.com/gastownhall/beads/pull/3674) | fix(dolt): suppress DOLT_COMMIT no-op warnings on read-only commands (GH#3529) | 0% | 17 lines |
| [#3673](https://github.com/gastownhall/beads/pull/3673) | fix(list): deduplicate issues with multiple blocks dependencies (GH#3567) | 0% | 4 lines |
| [#3672](https://github.com/gastownhall/beads/pull/3672) | fix(cli): swap CommandStyle colors for correct light/dark contrast (GH#3611) | 0% | 1 line |
| [#3666](https://github.com/gastownhall/beads/pull/3666) | fix(dolt): batch wisp-ID partition in bulk hydrators (GH#3414) | 0% | 141 lines |
| [#3663](https://github.com/gastownhall/beads/pull/3663) | fix(dolt): PURGE dropped databases after DROP (bench leak fix) | 0% | 7 lines |
| [#3659](https://github.com/gastownhall/beads/pull/3659) | fix(export): exclude ephemeral wisps from bd export by default | 0% | 6 lines |
| [#3643](https://github.com/gastownhall/beads/pull/3643) | fix(cli): swap CommandStyle LightDark arguments for light terminals (GH#3611) | 0% | 1 line |
| [#3653](https://github.com/gastownhall/beads/pull/3653) | fix(federation): respect ephemeral/wisp type filters during sync | 7.84314% | 47 lines |
| [#3641](https://github.com/gastownhall/beads/pull/3641) | fix(comments): reject bd comments list with helpful hint (GH#3542) | 11.11111% | 8 lines |

## Merged PRs

| PR | Merged | Category | State | Author | Title | Files | Delta |
|---|---|---|---|---|---|---|---|
| [#3242](https://github.com/gastownhall/beads/pull/3242) | May 3, 2:42 PM | Dolt/storage/sync | MERGED | Bella-Giraffety | fix: repair shared-server bootstrap and doctor metadata drift | 6 | +542/-40 |
| [#3671](https://github.com/gastownhall/beads/pull/3671) | May 3, 10:52 AM | Graph/UI output | MERGED | kevglynn | fix(graph): emit [] not null for empty links in HTML output (GH#3592) | 2 | +39/-2 |
| [#3672](https://github.com/gastownhall/beads/pull/3672) | May 3, 10:50 AM | CLI behavior | MERGED | kevglynn | fix(cli): swap CommandStyle colors for correct light/dark contrast (GH#3611) | 1 | +2/-1 |
| [#3661](https://github.com/gastownhall/beads/pull/3661) | May 2, 7:31 PM | Linear integration | MERGED | kevglynn | feat(linear): OAuth client-credentials support for service identity | 9 | +883/-42 |
| [#3669](https://github.com/gastownhall/beads/pull/3669) | May 2, 7:24 PM | Linear integration | MERGED | kevglynn | feat(linear): ambient staleness signal — bd prime auto-pull + --pull-if-stale | 7 | +578/-4 |
| [#3657](https://github.com/gastownhall/beads/pull/3657) | May 2, 7:05 PM | Linear integration | MERGED | kevglynn | feat(linear): add per-workspace concurrency lock on sync | 7 | +444/-0 |
| [#3655](https://github.com/gastownhall/beads/pull/3655) | May 2, 7:05 PM | Linear integration | MERGED | kevglynn | feat(linear): parse Retry-After headers and add rate-limit circuit breaker | 6 | +488/-24 |
| [#3653](https://github.com/gastownhall/beads/pull/3653) | May 2, 7:05 PM | Export/privacy/data boundaries | MERGED | kevglynn | fix(federation): respect ephemeral/wisp type filters during sync | 4 | +352/-12 |
| [#3646](https://github.com/gastownhall/beads/pull/3646) | May 2, 7:04 PM | CLI behavior | MERGED | kevglynn | fix(list): --deferred returns complete deferred set (GH#3571) | 4 | +27/-3 |
| [#3559](https://github.com/gastownhall/beads/pull/3559) | May 2, 7:04 PM | Dolt/storage/sync | MERGED | kevglynn | feat(setup): omit bd dolt push from template when no remote configured | 9 | +233/-25 |
| [#3667](https://github.com/gastownhall/beads/pull/3667) | May 2, 6:25 PM | CLI behavior | MERGED | maphew | fix(create): handle dependency aliases in --deps | 3 | +92/-20 |
| [#3666](https://github.com/gastownhall/beads/pull/3666) | May 2, 6:25 PM | Dolt/storage/sync | MERGED | harry-miller-trimble | fix(dolt): batch wisp-ID partition in bulk hydrators (GH#3414) | 10 | +668/-130 |
| [#3660](https://github.com/gastownhall/beads/pull/3660) | May 2, 5:46 PM | Export/privacy/data boundaries | MERGED | kevglynn | fix(export): exclude memories from bd export by default | 4 | +174/-22 |
| [#3659](https://github.com/gastownhall/beads/pull/3659) | May 2, 5:41 PM | Export/privacy/data boundaries | MERGED | kevglynn | fix(export): exclude ephemeral wisps from bd export by default | 4 | +142/-9 |
| [#3656](https://github.com/gastownhall/beads/pull/3656) | May 2, 5:41 PM | Linear integration | MERGED | kevglynn | feat(linear): add idempotency markers to prevent duplicate issue creation | 5 | +746/-17 |
| [#3647](https://github.com/gastownhall/beads/pull/3647) | May 2, 2:25 PM | CLI behavior | MERGED | kevglynn | fix(dep): show dependency type in bd dep tree output (GH#3565) | 4 | +141/-14 |
| [#3624](https://github.com/gastownhall/beads/pull/3624) | May 2, 2:24 PM | GitHub sync | MERGED | seanb4t | github: classify rate-limit 403s and stop the push loop when one hits | 7 | +673/-55 |
| [#3651](https://github.com/gastownhall/beads/pull/3651) | May 2, 2:24 PM | Linear integration | MERGED | kevglynn | feat(linear): add type mappings for decision, spike, story, milestone | 2 | +77/-1 |
| [#3631](https://github.com/gastownhall/beads/pull/3631) | May 2, 2:02 PM | Docs/agent/plugin/release | MERGED | maphew | fix(release): ship beads-release formula | 4 | +936/-7 |
| [#3648](https://github.com/gastownhall/beads/pull/3648) | May 2, 2:02 PM | Graph/UI output | MERGED | kevglynn | fix(graph): merge components for bd graph --all --html (GH#3592) | 3 | +106/-5 |
| [#3643](https://github.com/gastownhall/beads/pull/3643) | May 2, 2:02 PM | CLI behavior | MERGED | kevglynn | fix(cli): swap CommandStyle LightDark arguments for light terminals (GH#3611) | 1 | +1/-1 |
| [#3641](https://github.com/gastownhall/beads/pull/3641) | May 2, 2:02 PM | CLI behavior | MERGED | kevglynn | fix(comments): reject bd comments list with helpful hint (GH#3542) | 2 | +35/-1 |
| [#3639](https://github.com/gastownhall/beads/pull/3639) | May 2, 2:02 PM | GitHub sync | MERGED | kevglynn | fix(github): map decision, spike, story, milestone type labels (GH#3604) | 2 | +24/-0 |
| [#3664](https://github.com/gastownhall/beads/pull/3664) | May 2, 1:48 PM | Docs/agent/plugin/release | MERGED | ebrevdo | Add shared Beads plugin package | 63 | +185/-40 |
| [#3652](https://github.com/gastownhall/beads/pull/3652) | May 2, 1:45 PM | Other | MERGED | kevglynn | fix(config): refuse to write secret keys to git-tracked config.yaml | 6 | +304/-20 |
| [#3665](https://github.com/gastownhall/beads/pull/3665) | May 2, 1:21 PM | Other | MERGED | maphew | Add maintainer PR guidelines | 5 | +78/-1 |
| [#3614](https://github.com/gastownhall/beads/pull/3614) | May 1, 6:13 PM | Dolt/storage/sync | MERGED | coffeegoddd | Remove file-system locking in embedded mode | 14 | +51/-319 |
| [#3634](https://github.com/gastownhall/beads/pull/3634) | May 1, 5:42 PM | Export/privacy/data boundaries | MERGED | coffeegoddd | atomicfile: fix JSONL export concurrency safety | 4 | +423/-18 |

## Issues

### Opened

| Issue | Opened | Category | State | Author | Title |
|---|---|---|---|---|---|
| [#3689](https://github.com/gastownhall/beads/issues/3689) | May 3, 2:36 PM | Dolt/storage/sync | OPEN | mieubrisse | bd dolt remote: SQL/CLI state diverges; display and JSON output misrepresent both |
| [#3688](https://github.com/gastownhall/beads/issues/3688) | May 3, 1:46 PM | Dolt/storage/sync | OPEN | mieubrisse | feat(init): synthesize Dolt remote pointing at git origin (refs/dolt/data) instead of DoltHub |
| [#3687](https://github.com/gastownhall/beads/issues/3687) | May 3, 1:43 PM | Dolt/storage/sync | OPEN | mieubrisse | bd dolt stop falsely reports 'server not running' in shared-server mode |
| [#3686](https://github.com/gastownhall/beads/issues/3686) | May 3, 1:43 PM | CLI behavior | OPEN | mieubrisse | --repo flag on create fails when cwd has no .beads/ workspace, despite claiming to override routing |
| [#3685](https://github.com/gastownhall/beads/issues/3685) | May 3, 1:39 PM | Dolt/storage/sync | CLOSED | mieubrisse | bd dolt stop reports "not running" against externally-hosted/shared Dolt servers |
| [#3684](https://github.com/gastownhall/beads/issues/3684) | May 3, 12:20 PM | CLI behavior | OPEN | dawidmachon | one command suggesting depracated command |
| [#3683](https://github.com/gastownhall/beads/issues/3683) | May 3, 12:11 PM | Docs/agent/plugin/release | OPEN | dawidmachon | Lacking docs (bd prime, remember, dream, edit) |
| [#3681](https://github.com/gastownhall/beads/issues/3681) | May 3, 11:15 AM | CLI behavior | OPEN | rileywhite | bd close --force bypasses dep-check on parent beads with open children |
| [#3680](https://github.com/gastownhall/beads/issues/3680) | May 3, 7:18 AM | CLI behavior | OPEN | scruffymongrel | CLI: expose Checkout, Merge, and DeleteBranch (mirror existing Branch surface) |
| [#3677](https://github.com/gastownhall/beads/issues/3677) | May 3, 1:56 AM | Export/privacy/data boundaries | OPEN | alexmensch | bd prime memories silently lost at Claude Code session start when output exceeds the inline preview cap |
| [#3650](https://github.com/gastownhall/beads/issues/3650) | May 1, 9:30 PM | Export/privacy/data boundaries | CLOSED | kevglynn | bug: bd export includes memories in JSONL — private agent context leaks to git |
| [#3649](https://github.com/gastownhall/beads/issues/3649) | May 1, 9:30 PM | Export/privacy/data boundaries | CLOSED | kevglynn | bug: bd export includes wisps in JSONL by default — privacy boundary violation |

### Closed

| Issue | Closed | Category | State | Author | Title |
|---|---|---|---|---|---|
| [#3685](https://github.com/gastownhall/beads/issues/3685) | May 3, 1:48 PM | Dolt/storage/sync | CLOSED | mieubrisse | bd dolt stop reports "not running" against externally-hosted/shared Dolt servers |
| [#3571](https://github.com/gastownhall/beads/issues/3571) | May 2, 7:04 PM | CLI behavior | CLOSED | deg | bd list --deferred misses most |
| [#3414](https://github.com/gastownhall/beads/issues/3414) | May 2, 6:25 PM | Dolt/storage/sync | CLOSED | harry-miller-trimble | auto-export hydrate-labels query times out (~10-15s, context canceled) on Dolt remote backend |
| [#3650](https://github.com/gastownhall/beads/issues/3650) | May 2, 5:46 PM | Export/privacy/data boundaries | CLOSED | kevglynn | bug: bd export includes memories in JSONL — private agent context leaks to git |
| [#3649](https://github.com/gastownhall/beads/issues/3649) | May 2, 5:41 PM | Export/privacy/data boundaries | CLOSED | kevglynn | bug: bd export includes wisps in JSONL by default — privacy boundary violation |
| [#3565](https://github.com/gastownhall/beads/issues/3565) | May 2, 2:25 PM | CLI behavior | CLOSED | Wermeling | bd dep tree: parent-child and blocks dependencies render identically, causing false [BLOCKED] display |
| [#3623](https://github.com/gastownhall/beads/issues/3623) | May 2, 2:24 PM | GitHub sync | CLOSED | seanb4t | bd github sync: secondary-rate-limit 403s burn through retries in ~7s, then warn for every remaining issue |
| [#3592](https://github.com/gastownhall/beads/issues/3592) | May 2, 2:02 PM | Graph/UI output | CLOSED | nafg | `bd graph --all --html` produces invalid HTML that renders blank |
| [#3611](https://github.com/gastownhall/beads/issues/3611) | May 2, 2:02 PM | Other | CLOSED | DannyBen | Avoid white or black colors in the usage text |
| [#3542](https://github.com/gastownhall/beads/issues/3542) | May 2, 2:02 PM | CLI behavior | CLOSED | marcdhansen | bd comments list — 'list' parsed as issue ID instead of subcommand |
| [#3604](https://github.com/gastownhall/beads/issues/3604) | May 2, 2:02 PM | GitHub sync | CLOSED | bdelanghe | bd github sync: typeMapping is incomplete (missing decision, spike, story, milestone) — type:: labels silently default to task |

## New PRs

| PR | Opened | Category | State | Author | Title | Files | Delta |
|---|---|---|---|---|---|---|---|
| [#3691](https://github.com/gastownhall/beads/pull/3691) | May 3, 3:03 PM | Dolt/storage/sync | OPEN | scotthamilton77 | fix(auto-import): restore empty-DB guard regressed by #3630, plus a test repair | 3 | +153/-14 |
| [#3690](https://github.com/gastownhall/beads/pull/3690) | May 3, 2:57 PM | Dolt/storage/sync | OPEN | realies | fix: auto-import: skip non-embedded fallback when store is populated | 1 | +18/-0 |
| [#3682](https://github.com/gastownhall/beads/pull/3682) | May 3, 11:44 AM | Dolt/storage/sync | OPEN | quad341 | fix(schema): widen events/wisp_events value columns to LONGTEXT | 15 | +950/-16 |
| [#3679](https://github.com/gastownhall/beads/pull/3679) | May 3, 4:46 AM | Dolt/storage/sync | OPEN | jdelic | honor BEADS_DOLT_SERVER_TLS during init | 1 | +1/-0 |
| [#3678](https://github.com/gastownhall/beads/pull/3678) | May 3, 3:30 AM | Jira integration | OPEN | medhatgalal | Add Jira custom field support for push | 5 | +332/-13 |
| [#3676](https://github.com/gastownhall/beads/pull/3676) | May 2, 11:09 PM | Graph/UI output | OPEN | kevglynn | perf(graph): replace N+1 dependency queries with bulk fetch (GH#3520) | 1 | +65/-49 |
| [#3675](https://github.com/gastownhall/beads/pull/3675) | May 2, 10:58 PM | CLI behavior | OPEN | kevglynn | fix(dep): distinguish blocks vs parent-child in dep tree output (GH#3565) | 2 | +15/-5 |
| [#3674](https://github.com/gastownhall/beads/pull/3674) | May 2, 10:55 PM | Dolt/storage/sync | OPEN | kevglynn | fix(dolt): suppress DOLT_COMMIT no-op warnings on read-only commands (GH#3529) | 4 | +40/-20 |
| [#3673](https://github.com/gastownhall/beads/pull/3673) | May 2, 10:53 PM | CLI behavior | OPEN | kevglynn | fix(list): deduplicate issues with multiple blocks dependencies (GH#3567) | 2 | +84/-0 |
| [#3672](https://github.com/gastownhall/beads/pull/3672) | May 2, 10:46 PM | CLI behavior | MERGED | kevglynn | fix(cli): swap CommandStyle colors for correct light/dark contrast (GH#3611) | 1 | +2/-1 |
| [#3671](https://github.com/gastownhall/beads/pull/3671) | May 2, 10:46 PM | Graph/UI output | MERGED | kevglynn | fix(graph): emit [] not null for empty links in HTML output (GH#3592) | 2 | +39/-2 |
| [#3670](https://github.com/gastownhall/beads/pull/3670) | May 2, 8:14 PM | Docs/agent/plugin/release | OPEN | ebrevdo | Add explicit Codex skill setup | 14 | +827/-55 |
| [#3669](https://github.com/gastownhall/beads/pull/3669) | May 2, 5:09 PM | Linear integration | MERGED | kevglynn | feat(linear): ambient staleness signal — bd prime auto-pull + --pull-if-stale | 7 | +578/-4 |
| [#3668](https://github.com/gastownhall/beads/pull/3668) | May 2, 2:57 PM | Docs/agent/plugin/release | OPEN | julianknutsen | fix(release): harden shipped release formula adoption | 8 | +309/-32 |
| [#3667](https://github.com/gastownhall/beads/pull/3667) | May 2, 2:08 PM | CLI behavior | MERGED | maphew | fix(create): handle dependency aliases in --deps | 3 | +92/-20 |
| [#3666](https://github.com/gastownhall/beads/pull/3666) | May 2, 1:28 PM | Dolt/storage/sync | MERGED | harry-miller-trimble | fix(dolt): batch wisp-ID partition in bulk hydrators (GH#3414) | 10 | +668/-130 |
| [#3665](https://github.com/gastownhall/beads/pull/3665) | May 2, 11:44 AM | Other | MERGED | maphew | Add maintainer PR guidelines | 5 | +78/-1 |
| [#3664](https://github.com/gastownhall/beads/pull/3664) | May 2, 11:00 AM | Docs/agent/plugin/release | MERGED | ebrevdo | Add shared Beads plugin package | 63 | +185/-40 |
| [#3663](https://github.com/gastownhall/beads/pull/3663) | May 2, 10:53 AM | Dolt/storage/sync | OPEN | quad341 | fix(dolt): PURGE dropped databases after DROP (bench leak fix) | 12 | +838/-14 |
| [#3662](https://github.com/gastownhall/beads/pull/3662) | May 2, 10:49 AM | Dolt/storage/sync | OPEN | quad341 | perf(schema): D4v2 composite (status, updated_at) + defer_until indexes | 10 | +702/-8 |
| [#3661](https://github.com/gastownhall/beads/pull/3661) | May 2, 6:35 AM | Linear integration | MERGED | kevglynn | feat(linear): OAuth client-credentials support for service identity | 9 | +883/-42 |
| [#3660](https://github.com/gastownhall/beads/pull/3660) | May 1, 10:28 PM | Export/privacy/data boundaries | MERGED | kevglynn | fix(export): exclude memories from bd export by default | 4 | +174/-22 |
| [#3659](https://github.com/gastownhall/beads/pull/3659) | May 1, 10:25 PM | Export/privacy/data boundaries | MERGED | kevglynn | fix(export): exclude ephemeral wisps from bd export by default | 4 | +142/-9 |
| [#3658](https://github.com/gastownhall/beads/pull/3658) | May 1, 10:06 PM | Linear integration | OPEN | kevglynn | feat(linear): add persistent sync audit log | 5 | +816/-2 |
| [#3657](https://github.com/gastownhall/beads/pull/3657) | May 1, 10:03 PM | Linear integration | MERGED | kevglynn | feat(linear): add per-workspace concurrency lock on sync | 7 | +444/-0 |
| [#3656](https://github.com/gastownhall/beads/pull/3656) | May 1, 10:01 PM | Linear integration | MERGED | kevglynn | feat(linear): add idempotency markers to prevent duplicate issue creation | 5 | +746/-17 |
| [#3655](https://github.com/gastownhall/beads/pull/3655) | May 1, 9:55 PM | Linear integration | MERGED | kevglynn | feat(linear): parse Retry-After headers and add rate-limit circuit breaker | 6 | +488/-24 |
| [#3654](https://github.com/gastownhall/beads/pull/3654) | May 1, 9:55 PM | Linear integration | OPEN | kevglynn | feat(linear): adopt issueBatchCreate/issueBatchUpdate for 50x efficiency | 5 | +1386/-0 |
| [#3653](https://github.com/gastownhall/beads/pull/3653) | May 1, 9:54 PM | Export/privacy/data boundaries | MERGED | kevglynn | fix(federation): respect ephemeral/wisp type filters during sync | 4 | +352/-12 |
| [#3652](https://github.com/gastownhall/beads/pull/3652) | May 1, 9:37 PM | Other | MERGED | kevglynn | fix(config): refuse to write secret keys to git-tracked config.yaml | 6 | +304/-20 |
| [#3651](https://github.com/gastownhall/beads/pull/3651) | May 1, 9:37 PM | Linear integration | MERGED | kevglynn | feat(linear): add type mappings for decision, spike, story, milestone | 2 | +77/-1 |
| [#3648](https://github.com/gastownhall/beads/pull/3648) | May 1, 9:25 PM | Graph/UI output | MERGED | kevglynn | fix(graph): merge components for bd graph --all --html (GH#3592) | 3 | +106/-5 |
| [#3647](https://github.com/gastownhall/beads/pull/3647) | May 1, 9:22 PM | CLI behavior | MERGED | kevglynn | fix(dep): show dependency type in bd dep tree output (GH#3565) | 4 | +141/-14 |
| [#3646](https://github.com/gastownhall/beads/pull/3646) | May 1, 9:19 PM | CLI behavior | MERGED | kevglynn | fix(list): --deferred returns complete deferred set (GH#3571) | 4 | +27/-3 |
| [#3645](https://github.com/gastownhall/beads/pull/3645) | May 1, 9:17 PM | Export/privacy/data boundaries | OPEN | kevglynn | docs(doctor): align interactions.jsonl policy with bd audit (GH#3622) | 2 | +3/-5 |
| [#3644](https://github.com/gastownhall/beads/pull/3644) | May 1, 9:14 PM | CLI behavior | OPEN | kevglynn | fix(list): emphasize tree truncation warning with WarnStyle (GH#3580) | 2 | +3/-5 |
| [#3643](https://github.com/gastownhall/beads/pull/3643) | May 1, 9:12 PM | CLI behavior | MERGED | kevglynn | fix(cli): swap CommandStyle LightDark arguments for light terminals (GH#3611) | 1 | +1/-1 |
| [#3642](https://github.com/gastownhall/beads/pull/3642) | May 1, 8:43 PM | Docs/agent/plugin/release | OPEN | kevglynn | fix(setup): remove stale bd sync from Mux hook; warn in claude check (GH#3546) | 3 | +81/-1 |
| [#3641](https://github.com/gastownhall/beads/pull/3641) | May 1, 8:42 PM | CLI behavior | MERGED | kevglynn | fix(comments): reject bd comments list with helpful hint (GH#3542) | 2 | +35/-1 |
| [#3640](https://github.com/gastownhall/beads/pull/3640) | May 1, 8:37 PM | CLI behavior | OPEN | kevglynn | fix(worktree): repair permissive .beads/ after worktree create (GH#3593) | 2 | +55/-0 |
| [#3639](https://github.com/gastownhall/beads/pull/3639) | May 1, 8:34 PM | GitHub sync | MERGED | kevglynn | fix(github): map decision, spike, story, milestone type labels (GH#3604) | 2 | +24/-0 |
| [#3638](https://github.com/gastownhall/beads/pull/3638) | May 1, 5:16 PM | GitHub sync | OPEN | app/dependabot | chore(deps): bump github.com/go-sql-driver/mysql from 1.9.3 to 1.10.0 | 2 | +6/-6 |
| [#3637](https://github.com/gastownhall/beads/pull/3637) | May 1, 5:16 PM | CLI behavior | OPEN | app/dependabot | chore(deps): bump DeterminateSystems/update-flake-lock from 3d82c7e1a46ddcc239881a2ac62b0d9d970dc96b to 203e2eb079eca40abff70ea3189192e9adeca500 | 1 | +1/-1 |
| [#3636](https://github.com/gastownhall/beads/pull/3636) | May 1, 5:15 PM | CLI behavior | OPEN | app/dependabot | chore(deps): bump actions/setup-go from 5.6.0 to 6.4.0 | 1 | +1/-1 |
| [#3635](https://github.com/gastownhall/beads/pull/3635) | May 1, 5:15 PM | CLI behavior | OPEN | app/dependabot | chore(deps): bump DeterminateSystems/determinate-nix-action from 3.18.1 to 3.19.0 | 3 | +3/-3 |
| [#3634](https://github.com/gastownhall/beads/pull/3634) | May 1, 5:06 PM | Export/privacy/data boundaries | MERGED | coffeegoddd | atomicfile: fix JSONL export concurrency safety | 4 | +423/-18 |
| [#3633](https://github.com/gastownhall/beads/pull/3633) | May 1, 4:43 PM | Other | CLOSED | coffeegoddd | Db/test merge | 17 | +469/-337 |

## Commits

All 68 commits on upstream main in the window

| Commit | Committed | Author | Subject | Files | Top touched paths |
|---|---|---|---|---|---|
| [5a2fc61f7](https://github.com/gastownhall/beads/commit/5a2fc61f7a0d49994d97aebfdf6729c9e19ae3ad) | May 3, 2:42 PM | Bella-Giraffety | fix: repair shared-server bootstrap and doctor metadata drift (#3242) | 6 | cmd/bd |
| [772a65688](https://github.com/gastownhall/beads/commit/772a656888d35aedab5a8c070fc042205db17a97) | May 3, 10:52 AM | Harry Miller | Merge pull request #3671 from kevglynn/fix/3592-graph-html-single-document | 0 | merge/no files listed |
| [59686ce1a](https://github.com/gastownhall/beads/commit/59686ce1a90e5b7f48be3ccb4a3a3e6556db9707) | May 3, 10:50 AM | Harry Miller | Merge pull request #3672 from kevglynn/fix/3611-usage-text-colors | 0 | merge/no files listed |
| [1ebee7fd4](https://github.com/gastownhall/beads/commit/1ebee7fd48dfa53c24b5cb1f8c26830b14c732eb) | May 2, 10:46 PM | kev | fix(cli): swap CommandStyle colors for correct light/dark contrast (GH#3611) | 1 | internal |
| [dccfa2082](https://github.com/gastownhall/beads/commit/dccfa2082938739445a99b006d4ff61e66f01d6a) | May 2, 10:46 PM | kev | fix(graph): emit [] not null for empty links in HTML output (GH#3592) | 2 | cmd/bd |
| [890950f38](https://github.com/gastownhall/beads/commit/890950f388dd425e285d55b88c84713f8991fc18) | May 2, 7:31 PM | matt wilkie | Merge pull request #3661 from kevglynn/pr3-oauth-client-credentials | 0 | merge/no files listed |
| [b42646f10](https://github.com/gastownhall/beads/commit/b42646f10333109e6ba8166f5b2697fe8e7a271b) | May 2, 7:24 PM | matt wilkie | Merge pull request #3669 from kevglynn/feat/ambient-staleness-signal | 0 | merge/no files listed |
| [425ae2068](https://github.com/gastownhall/beads/commit/425ae2068308852adb470db529cd3df6db7700e2) | May 2, 7:14 PM | maphew | Merge main into OAuth client credentials branch | 0 | merge/no files listed |
| [f4a1a211d](https://github.com/gastownhall/beads/commit/f4a1a211dfc4d3bfec7dcfb4a8ad03e4788ffb74) | May 2, 7:09 PM | maphew | Merge main into staleness signal branch | 0 | merge/no files listed |
| [9c41669cf](https://github.com/gastownhall/beads/commit/9c41669cf425cc71ef52946b20454b3b1fa557e9) | May 2, 7:05 PM | matt wilkie | Merge pull request #3657 from kevglynn/feat/linear-sync-concurrency-lock | 0 | merge/no files listed |
| [a9e437a0a](https://github.com/gastownhall/beads/commit/a9e437a0a8a15e19b1928fd70d4dc4efe8b8b280) | May 2, 7:05 PM | matt wilkie | Merge pull request #3655 from kevglynn/feat/linear-retry-after-adaptive-backoff | 0 | merge/no files listed |
| [d9d0d1ddb](https://github.com/gastownhall/beads/commit/d9d0d1ddb788ae154f777eb496e31c0c9dc92ca1) | May 2, 7:05 PM | matt wilkie | Merge pull request #3653 from kevglynn/fix/federation-wisp-privacy | 0 | merge/no files listed |
| [7d5e9650a](https://github.com/gastownhall/beads/commit/7d5e9650ab5834face013302d4724b5c19c51aba) | May 2, 7:04 PM | matt wilkie | Merge pull request #3646 from kevglynn/fix/list-deferred-complete | 0 | merge/no files listed |
| [acd2b7d97](https://github.com/gastownhall/beads/commit/acd2b7d97d97fdaf1acfc843ef11d5e7b3678a55) | May 2, 7:04 PM | matt wilkie | Merge pull request #3559 from kevglynn/feat/conditional-dolt-push-template | 0 | merge/no files listed |
| [f11830374](https://github.com/gastownhall/beads/commit/f11830374181c8ff4ccfa869579f9b4c139352ed) | May 2, 6:40 PM | maphew | Merge main into OAuth client credentials branch | 0 | merge/no files listed |
| [d33687481](https://github.com/gastownhall/beads/commit/d33687481e54c65583a3da6e87d31ce74b8cb93e) | May 2, 6:38 PM | maphew | fix(linear): clean staleness lint | 2 | cmd/bd, internal/linear |
| [cb1a0700b](https://github.com/gastownhall/beads/commit/cb1a0700b0caa41b3e13b67fb4d4c169eaa1d61a) | May 2, 6:38 PM | maphew | fix(linear): clean sync lock lint | 3 | cmd/bd, internal/linear |
| [dc4cd8b64](https://github.com/gastownhall/beads/commit/dc4cd8b6490065246dd1fbb65997685587eca45d) | May 2, 6:38 PM | maphew | fix(linear): clean rate-limit lint | 1 | cmd/bd |
| [860ddb206](https://github.com/gastownhall/beads/commit/860ddb20651e0eb75832fa2128b92fd9329feb54) | May 2, 6:38 PM | maphew | fix(config): format wisp privacy changes | 1 | internal |
| [22e9ca37d](https://github.com/gastownhall/beads/commit/22e9ca37dd301a69fd7fabb6c943a957d5b26d54) | May 2, 6:38 PM | maphew | fix(list): format deferred filter tests | 1 | internal/storage |
| [261fdbb99](https://github.com/gastownhall/beads/commit/261fdbb996d24b30aaa1d0799b490a8b686287a5) | May 2, 6:38 PM | maphew | fix(setup): format conditional push template | 1 | cmd/bd |
| [10bf49025](https://github.com/gastownhall/beads/commit/10bf490252bf84c8e2cd114d370ca3d487a10254) | May 2, 6:38 PM | maphew | fix(config): format OAuth config changes | 1 | internal |
| [6fa7549c8](https://github.com/gastownhall/beads/commit/6fa7549c8cfb701b121ca89870cf1b510a8ff623) | May 2, 6:25 PM | matt wilkie | Merge pull request #3667 from maphew/fix/3560-cli-deps-only | 0 | merge/no files listed |
| [886c67e58](https://github.com/gastownhall/beads/commit/886c67e5843aa4d4a731a4ea37ddd1f908fcc027) | May 2, 6:25 PM | matt wilkie | Merge pull request #3666 from harry-miller-trimble/fix/3414-bulk-wisp-partition-v2 | 0 | merge/no files listed |
| [e1f4c048a](https://github.com/gastownhall/beads/commit/e1f4c048a7ef64914d683f3856d633650acb63b9) | May 2, 5:46 PM | matt wilkie | Merge pull request #3660 from kevglynn/fix/export-exclude-memories | 0 | merge/no files listed |
| [ea9fa3efc](https://github.com/gastownhall/beads/commit/ea9fa3efca8c0b3a63ce4878313ac54aa68af1bb) | May 2, 5:44 PM | maphew | Merge remote-tracking branch 'origin/main' into fix/export-exclude-memories | 0 | merge/no files listed |
| [32b4430e3](https://github.com/gastownhall/beads/commit/32b4430e394a3b28a9989900daf037c059d32e51) | May 2, 5:41 PM | matt wilkie | Merge pull request #3659 from kevglynn/fix/export-exclude-wisps | 0 | merge/no files listed |
| [8cc3fea9a](https://github.com/gastownhall/beads/commit/8cc3fea9a3b1b16a1e2c028fb666a12f6371b7e4) | May 2, 5:41 PM | matt wilkie | Merge pull request #3656 from kevglynn/feat/linear-idempotency-markers | 0 | merge/no files listed |
| [6584ff8f8](https://github.com/gastownhall/beads/commit/6584ff8f8f9ffd77a019fab60e74f7180aa7251b) | May 2, 5:08 PM | kev | feat(linear): add ambient staleness signal for auto-fresh data | 7 | cmd/bd, internal/linear, docs/process |
| [226e7f255](https://github.com/gastownhall/beads/commit/226e7f2554b886da6fc9354d6743a47bc95b1625) | May 2, 4:07 PM | kev | fix(export): include NoHistory beads when Ephemeral=&false filter is active | 1 | internal/storage |
| [46584d822](https://github.com/gastownhall/beads/commit/46584d8222e6e029c298a84754c2984c05aaec14) | May 2, 4:04 PM | kev | fix(linear): address maintainer feedback on OAuth client-credentials PR | 5 | internal/linear, .golangci.yml, cmd/bd |
| [609dce0ad](https://github.com/gastownhall/beads/commit/609dce0ad98abab8872a7e3c3643d865c1b85841) | May 2, 4:00 PM | kev | test(export): add export globals to saveAndRestoreGlobals for isolation | 1 | cmd/bd |
| [3e804cd39](https://github.com/gastownhall/beads/commit/3e804cd39f276a3fd7d0128e0d5ddb3df921c7b8) | May 2, 4:00 PM | kev | fix(linear): address maintainer feedback on PR #3655 | 6 | internal/linear, cmd/bd, internal |
| [b8e7562f0](https://github.com/gastownhall/beads/commit/b8e7562f0f30576e60dae3ce4edba42866743b42) | May 2, 3:59 PM | kev | fix(linear): address maintainer blockers on idempotency PR | 4 | internal/linear |
| [175bc23d1](https://github.com/gastownhall/beads/commit/175bc23d1feced20ef156136971a4a2cd0d54de0) | May 2, 3:55 PM | kev | fix(linear): keep lock file stable across Release cycles | 2 | internal/linear |
| [2f854001b](https://github.com/gastownhall/beads/commit/2f854001b075c0798971916ae3ef60aad324b574) | May 2, 2:25 PM | matt wilkie | Merge branch 'main' into fix/3560-cli-deps-only | 0 | merge/no files listed |
| [f0b6d4973](https://github.com/gastownhall/beads/commit/f0b6d4973f3be45a28a33b33b2bb2d486839c021) | May 2, 2:25 PM | Kevin Glynn | fix(dep): show dependency type in bd dep tree output (GH#3565) (#3647) | 4 | cmd/bd, internal/storage, internal |
| [45324cead](https://github.com/gastownhall/beads/commit/45324cead22cbae677fdcb3339a8c9db9c0b8312) | May 2, 2:25 PM | matt wilkie | Merge branch 'main' into fix/3560-cli-deps-only | 0 | merge/no files listed |
| [b78a62cf1](https://github.com/gastownhall/beads/commit/b78a62cf10343bfad09dc755e754178d88080772) | May 2, 2:24 PM | Sean Brandt | github: classify rate-limit 403s and stop the push loop when one hits (#3624) | 7 | internal/github, internal |
| [cffb4e80d](https://github.com/gastownhall/beads/commit/cffb4e80d0ec97bc2686d7b077ebbd87df73df19) | May 2, 2:24 PM | matt wilkie | Merge branch 'main' into fix/3560-cli-deps-only | 0 | merge/no files listed |
| [06d385edf](https://github.com/gastownhall/beads/commit/06d385edf9edc5e1008a84f69243a48646d8cf34) | May 2, 2:24 PM | Kevin Glynn | feat(linear): add type mappings for decision, spike, story, milestone (#3651) | 2 | internal/linear |
| [21c55f489](https://github.com/gastownhall/beads/commit/21c55f489fe96008e3d6872389b7e7da81d598a3) | May 2, 2:08 PM | maphew | fix(create): handle dependency aliases in --deps | 3 | cmd/bd, internal |
| [f3d57da63](https://github.com/gastownhall/beads/commit/f3d57da63ac0698287ec84c11ce6d78a98b0bea6) | May 2, 2:02 PM | matt wilkie | fix(release): ship beads-release formula (#3631) | 4 | internal, .beads, scripts |
| [a028506ec](https://github.com/gastownhall/beads/commit/a028506ec64802badaee8a5180a3b30cb58d02e6) | May 2, 2:02 PM | Kevin Glynn | fix(graph): merge components for bd graph --all --html (GH#3592) (#3648) | 3 | cmd/bd |
| [60cbf83a5](https://github.com/gastownhall/beads/commit/60cbf83a5fcdacf318eda005319e344595a3ac80) | May 2, 2:02 PM | Kevin Glynn | fix(cli): swap CommandStyle LightDark arguments for light terminals (GH#3611) (#3643) | 1 | internal |
| [0c5199720](https://github.com/gastownhall/beads/commit/0c51997203e76061d5d81198745e6e535e5851d0) | May 2, 2:02 PM | Kevin Glynn | fix(comments): helpful error for misplaced bd comments list (GH#3542) (#3641) | 2 | cmd/bd |
| [b3241665f](https://github.com/gastownhall/beads/commit/b3241665f373dd9fb6e868361a41b26322c038a4) | May 2, 2:02 PM | Kevin Glynn | fix(github): map decision, spike, story, milestone GitHub type labels (GH#3604) (#3639) | 2 | internal/github |
| [58ac2dee7](https://github.com/gastownhall/beads/commit/58ac2dee7218411b4ccd482bf4b8a9df59036ed8) | May 2, 1:48 PM | matt wilkie | Merge pull request #3664 from ebrevdo/codex-plugin-slice1 | 0 | merge/no files listed |
| [918eb8e4c](https://github.com/gastownhall/beads/commit/918eb8e4c549e8fb5142548537b2f4dee8ad9c92) | May 2, 1:45 PM | Kevin Glynn | fix(config): refuse to write secret keys to git-tracked config.yaml (#3652) | 6 | cmd/bd, internal, docs/process |
| [fbcdb908b](https://github.com/gastownhall/beads/commit/fbcdb908b4694fc23fd7718be9843c943e0fb4bd) | May 2, 1:35 PM | maphew | fix(dolt): preserve label hydration wisp-set callers | 1 | internal/storage |
| [be65f59cd](https://github.com/gastownhall/beads/commit/be65f59cd0b840a2eb40b84d87284b9284d99648) | May 2, 1:27 PM | Harry | fix(dolt): batch wisp-ID partition in bulk hydrators (GH#3414) | 10 | internal/storage |
| [46be5594d](https://github.com/gastownhall/beads/commit/46be5594d64f6e3d14b6268db878a327fe16639f) | May 2, 1:21 PM | matt wilkie | Add maintainer PR guidelines (bd-k0j) (#3665) | 5 | docs/process |
| [43715adde](https://github.com/gastownhall/beads/commit/43715adde7eef947a2b1e86280e1efe3194a0a5d) | May 2, 10:59 AM | Eugene Brevdo | Add shared Beads plugin package | 63 | plugins, docs/process, scripts |
| [097ed1cf1](https://github.com/gastownhall/beads/commit/097ed1cf168b2f28f2a7cd715363a823813de8a0) | May 2, 6:35 AM | kev | feat(linear): add OAuth client-credentials support | 6 | internal/linear, cmd/bd, internal |
| [61e85bc31](https://github.com/gastownhall/beads/commit/61e85bc31979f1bc1c3a1394aa8068c305d10d0e) | May 1, 10:28 PM | kev | fix(export): exclude memories from bd export by default (GH#3650) | 3 | cmd/bd |
| [7978fae1a](https://github.com/gastownhall/beads/commit/7978fae1adf333e0f246274210edd81686ac5961) | May 1, 10:25 PM | kev | fix(export): exclude ephemeral wisps from bd export by default (GH#3649) | 3 | cmd/bd |
| [989d0f949](https://github.com/gastownhall/beads/commit/989d0f94960dfa8e9b3abf75273adeaf7e9a5a84) | May 1, 10:02 PM | kev | feat(linear): add per-workspace concurrency lock on sync | 7 | internal/linear, cmd/bd |
| [0ec4a99ea](https://github.com/gastownhall/beads/commit/0ec4a99ea08aba9de7ad0e7efa6d74c0b3af9103) | May 1, 10:00 PM | kev | feat(linear): add idempotency markers to prevent duplicate issue creation | 4 | internal/linear |
| [c67e41e35](https://github.com/gastownhall/beads/commit/c67e41e355d15d373deb558c0e652b89d5c8f44a) | May 1, 9:53 PM | kev | fix(federation): respect ephemeral/wisp type filters during sync | 4 | internal, internal/storage |
| [a845bc4eb](https://github.com/gastownhall/beads/commit/a845bc4ebacb6f3784410285b8dde6dec968ee61) | May 1, 9:42 PM | kev | feat(linear): parse Retry-After headers and add rate-limit circuit breaker | 3 | internal/linear |
| [3d9a01220](https://github.com/gastownhall/beads/commit/3d9a01220ccff21c82e89847a7b0f4fc641934ac) | May 1, 9:19 PM | kev | fix(list): --deferred returns complete deferred set (GH#3571) | 4 | internal/storage, internal |
| [0fa5f210f](https://github.com/gastownhall/beads/commit/0fa5f210f41af9f03b1888480ce5c7ec97c03eb4) | May 1, 6:13 PM | Dustin Brown | Merge pull request #3614 from coffeegoddd/db/fs-locking | 0 | merge/no files listed |
| [6c938415c](https://github.com/gastownhall/beads/commit/6c938415cb04a3d78c39a0d9c7009e2bb1ee8797) | May 1, 5:50 PM | coffeegoddd☕️✨ | changelog: document OpenBestAvailable breaking change and flock removal | 1 | docs/process |
| [a58228d7d](https://github.com/gastownhall/beads/commit/a58228d7d23a04f0214ee67a17256e122723708c) | May 1, 5:46 PM | coffeegoddd☕️✨ | /cmd/bd/main.go: remove promote gate | 1 | cmd/bd |
| [e97532ab5](https://github.com/gastownhall/beads/commit/e97532ab5e297ee2c6f0de718d7742af00bb0fc7) | May 1, 5:46 PM | coffeegoddd☕️✨ | :remove uneccessary locking | 14 | cmd/bd, internal/storage, beads_cgo.go |
| [1781ed422](https://github.com/gastownhall/beads/commit/1781ed422efc39d3b6152fb7781fc11bb8338d89) | May 1, 5:42 PM | Dustin Brown | Merge pull request #3634 from coffeegoddd/db/atomic-export | 0 | merge/no files listed |
| [916c1631f](https://github.com/gastownhall/beads/commit/916c1631fdc252b2d231c22dbb2b7d7545b76090) | May 1, 5:03 PM | coffeegoddd☕️✨ | /internal/atomicfile/atomicfile.go: use io.Copy | 1 | internal |
| [2f1cd4f81](https://github.com/gastownhall/beads/commit/2f1cd4f81863109877996a57fe55742eefbecade) | May 1, 4:42 PM | coffeegoddd☕️✨ | /cmd/{cmd, internal}: make exports atomic writes | 4 | cmd/bd, internal |
