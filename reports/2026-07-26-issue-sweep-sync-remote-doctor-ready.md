# Issue sweeps 4+5: sync-remote (16) + doctor/deps-ready/hooks-install (17) — 2026-07-26

Fourth and fifth theme-clustered tri:claim drain sweeps (epic mybd-xmx7),
run as one synthesis pass over two delegated recons.

## Sync-remote dispositions (16 stubs)

| bd | gh | disposition | reason |
|----|----|-------------|--------|
| mybd-ir63d | 4070 | consolidated → **mybd-uxuju** | backup subsystem: non-atomic manifest/chunk ordering |
| mybd-udkv2 | 3522 | consolidated → mybd-uxuju | backup: per-command registration retry storm |
| mybd-75kql | 3501 | consolidated → mybd-uxuju | backup: ignores backup.enabled=false |
| mybd-je476 | 3878 | consolidated → mybd-uxuju | backup: fork-race design ask (flock fix #3869 merged, design remains) |
| mybd-a7y4m | 4258 | consolidated → **mybd-gfxhb** | dangling-chunk push failure family |
| mybd-dew9x | 3358 | consolidated → mybd-gfxhb | dangling-reference push failure family |
| mybd-g1sl | 5080 | dep-gated | blocked-by mybd-irb5m (fix PR #5085, in mybd-8nq5s review lane) |
| mybd-rj9ow | 3702 | tri:defer | Linear-integration niche, cold 50-60d |
| mybd-9mxx6 | 3299 | tri:defer | S3 checksum WARNs — upstream-dolt-shaped, cold 90d+ |
| mybd-7p9i6 | 3619 | tri:defer | bd flatten history shape, cold, no demand signal |
| mybd-gacel | 4992 | keep | vc merge --strategy theirs broken; recent (3d) |
| mybd-co9w9 | 3594 | keep | DOLT_BACKUP sends local FS paths to remote servers |
| mybd-j2v39 | 3547 | keep, noted | federation uncommitted state; re-check after #5085 |
| mybd-ec9bm | 3463 | keep | no-git-ops/stealth mode still pushes — owner-relevant |
| mybd-6kxhw | 4961 | keep | ADO dependency mapping; recent |
| mybd-guvk | 4861 | keep | init/reinit remote-history guard false positive; recent |
| mybd-uhpr | 5068 | keep (fresh) | push-remote derivation without confirmation; related to mybd-gfxhb root cause |

## Doctor/ready/hooks dispositions (17 stubs)

| bd | gh | disposition | reason |
|----|----|-------------|--------|
| mybd-yc8c | 4475 | dep-gated + **PR 4933 handed to patrol** | fix PR approved; branch updated; tail = mybd-bbvaz |
| mybd-i7de | 4769 | dep-gated | blocked-by mybd-hb3lo (fix PR #4753, open, awaiting approval) |
| mybd-j6iml | 3896 | consolidated → **mybd-usy15** | cold ready-correctness audit (post-#4752 verify) |
| mybd-use07 | 3887 | consolidated → mybd-usy15 | same |
| mybd-6nbjc | 3268 | consolidated → mybd-usy15 | same |
| mybd-y06g | 5036 | keep (fresh), cross-ref'd | sibling of 5069: "ready ignores relationship class X" |
| mybd-i9x0 | 5069 | keep (fresh), cross-ref'd | same pair |
| mybd-v479b | 4977 | keep | cgo gate stubs 13 doctor checks silently |
| mybd-uh8q | 4993 | keep | --fix recommended without schema-version check |
| mybd-kr0i | 5025 | keep | pollution check false-positives on real work |
| mybd-rnjr | 5026 | keep | stale-molecules double-count |
| mybd-8bse | 4814 | keep | child-parent check one-directional |
| mybd-7vyw | 4539 | keep | orphaned child_counters detection (relates to gh 4750 family) |
| mybd-1yi6x | 3705 | keep | bare-repo/worktree false positives |
| mybd-b8ht | 4440 | keep, verify-first | v1.0.4 hooksPath survival; hooks reworked since; relates mybd-ukt3 |
| mybd-v42x4 | 4272 | keep | hook-skip coverage gap (#3724 follow-up) |
| mybd-d3f7j | 3962 | keep | pre-commit auto-export staging interaction |

Net across both sweeps: 33 stubs → 9 closed by consolidation into 3 new
engineering beads (mybd-uxuju backup, mybd-gfxhb push-dangling, mybd-usy15
ready-audit), 3 deferred, 3 dep-gated (one with its approved fix PR handed to
the merge patrol), 18 confirmed-live kept.

## Observations

- The doctor subsystem is untouched upstream since mid-June while 6 distinct
  check-quality reports accumulated — a coherent future sweep could bundle
  them as one "doctor reliability" upstream conversation, but the checks are
  mechanically independent; no forced consolidation.
- The ready subsystem is the opposite: heavy churn (#4752 WorkFilter et al.)
  under cold correctness reports — hence audit-not-trust (mybd-usy15).
- Recon quality note (repeat of sweep 2's lesson): the sync-remote recon
  found "no cross-referenced PRs" for all 16 — for 5080 that was wrong-ish
  (fix PR #5085 exists, found via the PR-mirror stubs instead). Timeline
  cross-refs miss PRs that don't link the issue; the theme-label pr-mirror
  inventory is the better join key.
