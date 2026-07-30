# Issue sweep — theme:sync-remote (solo-sweep run 5, 2026-07-30)

Unattended lane. Nothing published, nothing closed — every row below is a
**proposal** recorded on the stub via `solo-bd note` (label
`solo-sweep:proposed`). Batch: `bd list -l solo-sweep:proposed`.

8 open stubs in the theme (the strategy report's count of 17 predates earlier
dispositions). All 8 swept — under the 12 cap, nothing deferred.

## Dispositions

| stub | upstream | p | proposed | evidence |
|------|----------|--:|----------|----------|
| mybd-j2v39 | [#3547](https://github.com/gastownhall/beads/issues/3547) | 2 | **close** | Fixed by #4190 (merged 2026-06-19, `352bdb3c2`) + #4412 (merged 2026-06-20, `387959695`); both verified `merged=true` and verified reachable from `upstream/main`. Read both backends at main: `dolt/federation.go` `Sync` calls `commitBeforePull`, `embeddeddolt/federation.go` `Sync` calls `CommitPending` before Fetch/Merge. Upstream timeline is empty — #4190 was filed against #3852, so this is an unlinked stale-open. |
| mybd-ec9bm | [#3463](https://github.com/gastownhall/beads/issues/3463) | 2 | **close** + follow-up | Fixed as filed by #3446 (merged 2026-04-24T16:00:05Z, `456a66071`, verified on main) — auto-push is now opt-in via `dolt.auto-push`. It merged ~2h *before* the issue was filed. Residual gap filed as **mybd-l07hc**. |
| mybd-uhpr | [#5068](https://github.com/gastownhall/beads/issues/5068) | 1 | **flesh-out** | Live on main, no fix PR anywhere. `adoptGitOriginRemoteForPush()` (cmd/bd/dolt.go ~411) still called unconditionally from `doltPushCmd.RunE` (~519): adds the remote, persists+commits `sync.remote`, pushes — no prompt, no flag. Engineering bead **mybd-fjc1o** (p1). |
| mybd-co9w9 | [#3594](https://github.com/gastownhall/beads/issues/3594) | 2 | **flesh-out** (rescope) | Auto path fixed (#3568, merged, `0a61a566b`); push/pull fixed (#4236, merged, `d00b890a3`). Live gap is now only `bd backup init/add/sync`: `resolveDoltBackupURL` (cmd/bd/backup_dolt.go ~187-207) builds `file://` with no `clientServerShareFilesystem()` check. Fix PR **#3595 is open, merged=false**. |
| mybd-guvk | [#4861](https://github.com/gastownhall/beads/issues/4861) | 2 | **keep-open** | Live: cmd/bd/init.go ~728 hardcodes `earlyRemoteHasDoltData = true` when `sync.remote` is configured, no `refs/dolt/data` probe. Fix in **PR 5136, open, merged=false**, unstable CI. |
| mybd-6kxhw | [#4961](https://github.com/gastownhall/beads/issues/4961) | 2 | **keep-open** | Live: `internal/ado/links.go:95-106` matches `"parent"`, but the canonical constant is `"parent-child"` (types.go:1022), so it falls to `RelRelated`. Pull side also miscasts (engine.go:1218,1255). Fix in **PR 5129, open, merged=false** (mergeable_state clean ≠ merged). |
| mybd-v479b | [#4977](https://github.com/gastownhall/beads/issues/4977) | 2 | **keep-open** | Live: `checks_nocgo.go` stubs 10 checks, `migration_validation_nocgo.go` stubs 3 = the 13 in the title. Fix in **PR 5132, open, merged=false** — not linked from the issue, found only by targeted PR search. Also mis-themed; belongs in `theme:doctor`. |
| mybd-g1sl | [#5080](https://github.com/gastownhall/beads/issues/5080) | 2 | **keep-open** | Live: `remoteAuthUser()` (embeddeddolt/version_control.go) still returns only `os.Getenv("DOLT_REMOTE_USER")`. Fix in **PR 5085, open, approved by maphew 2026-07-28, merged=false**. |

Counts: close 2, flesh-out 2, keep-open 4, consolidate 0.
New beads: mybd-fjc1o (p1), mybd-e4x2x (p2), mybd-l07hc (p3).

## Root-cause map

**Group A — "the fix is an open contributor PR, not on main" (4 of 8).**
mybd-guvk/#5136, mybd-6kxhw/#5129, mybd-v479b/#5132, mybd-g1sl/#5085. Every one
is live on `upstream/main` *and* already fixed in review. None is independently
actionable — picking one up duplicates a PR in a maintainer lane
(vishnujayvel: mybd-php3l; arcaven: mybd-94l2i / mybd-457m0). But bd can't see
that: mybd-guvk and mybd-6kxhw have open pr-mirror beads (mybd-n5dul,
mybd-si7kh) with **no dependency edge**; mybd-v479b has **no mirror bead at
all**; mybd-g1sl's only edge points at **mybd-irb5m, which is closed** — so a
closed blocker leaves it reading as ready work while another session owns the
PR. Filed as **mybd-e4x2x**. The general defect: triage mirrors issues and PRs
as separate beads and links them only sometimes.

**Group B — implicit remote targets, no confirmation (2 of 8).**
mybd-uhpr (#5068) and mybd-co9w9 (#3594) are different code paths with one
shape: bd derives a remote target from purely local context and acts on it with
no check that it is the right target. `bd dolt push` adopts git origin and
uploads private issue history to it; `bd backup init/sync` hands a
client-absolute `file://` path to a remote Dolt server. Both auto-variants of
this class have already been fixed once (#3568 for auto-backup, #3446 for
auto-push) — the survivors are the **explicit** commands, where the fix pattern
was never applied. Worth a maintainer pass over the remaining `DOLT_*` remote
call sites for the same omission; I did not do that inventory.

**Group C — fixed, stale-open, unlinked (2 of 8).** mybd-j2v39, mybd-ec9bm.
Both have empty upstream timelines: the fixing PRs referenced other issues or
predated the report. Full-text search alone would have missed both.

## Confidence and caveats

- **Two proposed closes, both verified to the required bar.** For each I named
  the PR, confirmed `merged=true` + `merged_at` + `merge_commit_sha` via the
  REST API, *and* confirmed the commit is reachable from `upstream/main` by
  `git log --grep`. For mybd-j2v39 I additionally read the fixed code at
  `upstream/main` in **both** federation backends, because the proxied path
  alone would have left the reported CLI route unfixed.
- **The near-miss worth knowing about.** PR 5085 (fix for mybd-g1sl, a live p2)
  returns `merge_commit_sha=62d4de302…` while `merged=false`. On an open PR
  that field is GitHub's *speculative test-merge* SHA. Reading it as evidence
  would have closed a live issue — the same failure class the strategy report
  records. `merged` / `merged_at` are the only authoritative fields.
- **A recon claim I had to correct.** The first pass on mybd-guvk/mybd-6kxhw
  reported fix commits present in the local object store but absent from
  `upstream/main`, and concluded they were orphaned local WIP never turned into
  PRs. Wrong: a targeted PR search found them as PRs 5136 and 5129, fetched
  locally. Direction of the finding held (not on main) but the conclusion did
  not. Cause: the timeline enumeration was empty for both issues, and
  `commits/<sha>/pulls` returns empty for a fork-branch SHA. **Timeline + commit
  lookup is not sufficient to establish "no PR exists"** — a title/number PR
  search is a required third check. That is a procedure gap in the strategy
  report's step 1.
- All code claims are against `upstream/main` (HEAD `84431ee5c` at recon time),
  read via `solo-recon show/log`. I did not read the `bd-main` working tree and
  did not build or run anything, so nothing here is a runtime repro — the two
  closes rest on merged-commit verification plus code reading, and for
  mybd-co9w9 on maphew's own 2026-07-08 repro comment on the issue.
- Unverified, flagged on the stubs rather than acted on: #5068's claim that a
  configured `sync.remote` doesn't prevent adoption; the `gh 5033`
  cross-reference in that issue's body; whether PR 5129 covers the pull-side
  cast in `engine.go` or only the push mapping.
- No blocks. `solo-recon`'s endpoint allowlist rejects `+` in query strings, so
  the PR search needed `%20` — worth noting for the next run, not a defect.
- Collision check: none of the 8 stubs is referenced by an in-progress bead.
  Adjacent lanes to respect on execution: mybd-php3l, mybd-94l2i, mybd-457m0.
