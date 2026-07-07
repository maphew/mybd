# Decision memo: mybd-pdvy - escalate #4249 vs fork-carry pure-Go releases

Date: 2026-07-07. Owner decision due: **2026-07-12**. Prepared read-only; nothing posted upstream.

## Executive summary

gastownhall/beads#4249 (the build-tagged zstd seam proposal) has had zero maintainer response in 39 days, while the fork-carry path is already built, staged, and verified locally as of this morning. **Recommendation: Option C - start fork-carried pure-Go releases now, and keep the upstream ask alive by redirecting it to the storage owner (coffeegoddd / DoltHub) at the driver or Dolt level rather than re-pinging the beads issue.** The seam lives in `dolthub/dolt` `store/nbs`, so the durable fix is upstream of beads anyway; carrying the fork buys immediate release relief without foreclosing that path.

## What #4249 proposes

Issue (not PR) gastownhall/beads#4249, opened 2026-05-29 by maphew, title "Proposal: a build-tagged zstd seam so embedded Dolt can build without cgo (pure-Go bd is proven)". Core claim: beads' entire cgo burden traces to one transitive dependency, `github.com/dolthub/gozstd`, imported only by `dolthub/dolt/go/store/nbs`. A ~120-line shim over `klauspost/compress/zstd` plus a `nocgo` tag migration yields a statically linked `bd` that runs embedded Dolt end to end. The ask: would Dolt accept a build-tagged seam in `store/nbs`, defaulting to cgo/gozstd so existing users are unaffected. Evidence in the issue: static binary, `bd init/create/list` round-trip in embedded mode, full federation help at CGO=0, both embedded suites passing (storage 59s, CLI 239s), all test packages compiling, with only two compression-ratio fixtures regressing.

## Timeline of #4249

| Date | Event |
|------|-------|
| 2026-05-29 05:43Z | Issue opened; coffeegoddd @-mentioned and auto-subscribed at open |
| 2026-06-14 | Cross-referenced from PR #4408 (seam evidence PR, opened same day) |
| 2026-06-14 to 2026-07-07 | No comments, no reactions, no labels, no assignee |
| 2026-07-07 12:21Z | `updatedAt` bumped, but comments=0, reactions=0, no visible timeline event: a cross-reference bump, **not a reply** |

Companion PR #4408 ("pure-Go zstd seam evidence for embedded Dolt"): OPEN, MERGEABLE, 0 reviews, 2 comments, both by maphew (latest 2026-07-07, noting the nocgo stack was regenerated fresh on current main). Silence is non-engagement, not absence: coffeegoddd merged #4489 (db/sql) into beads main today and landed dolt driver/min-version bumps in late June.

## Demand signal

- #3312 and #3338 (both OPEN since April): `go install ...@latest` broken by the `go-mysql-server` replace directive; users repeatedly hit the install/build tangle.
- #4587 (OPEN, 2026-07-05): the `gms_pure_go` tag omission is "the single most common per-session build trap"; asks for auto-tagging and a doctor-build preflight. This is recurring cost of the cgo split that the seam removes.

## Option A: escalate upstream

Concrete channels, in rough order of expected value:

1. **File the seam ask at the Dolt/driver level.** coffeegoddd (DoltHub) owns the storage boundary, and the roadmap direction is explicit that beads-side workarounds against storage are the wrong layer. The seam is a `dolthub/dolt` `store/nbs` change; an issue or small PR in the Dolt repo (or against `dolthub/driver`) reaches the actual owner in his own tracker, where a 193-line shim proposal is more legible than inside beads' queue.
2. **One direct follow-up ping on #4249 naming coffeegoddd**, citing his storage ownership and linking the regenerated evidence (#4408 now MERGEABLE on current main). Cheap, but he was already mentioned at open and has been active without engaging.
3. **Offer to split the PR smaller**: the shim alone (5 files, 193 insertions) is independently reviewable; explicitly decouple it from the 287-file tag migration so a reviewer can say yes to something small.

Expected latency: unknown and unbounded. 39 days of silence against an active maintainer suggests low priority, not oversight. Risk: it stays silent through another release cycle and the weekly build pain (#4587-class traps, #3312/#3338-class installs) continues with no local relief.

## Option B: fork-carry pure-Go releases

Staged branches on the fork (`maphew/beads`), stacked in this order:

| Branch | Head | Contents |
|--------|------|----------|
| `mybd-hli9-zstd-seam` | 31cbf8be7 | Seam evidence: `gozstd-shim/` (139-line shim.go over klauspost zstd) + go.mod wiring + Nix vendorHash; backs PR #4408 |
| `mybd-hli9-nocgo-build-tags` | c6506a998 | Single regenerated commit migrating `cgo`/`!cgo` tags to `!nocgo`/`nocgo`, 287 files, sitting on current main |
| `mybd-hli9-purego-release` | 57e843257 | Collapses `.goreleaser.yml` from per-platform cgo builds (zig sysroots, CC/CXX wiring, verify-cgo hooks) to one `CGO_ENABLED=0 -tags gms_pure_go` build id covering linux/windows/android/freebsd, amd64+arm64; net -116/+29 across `.goreleaser.yml` and `release.yml` |

**Verified** (verify-queue, 2026-07-07, head c6506a998): `CGO_ENABLED=0 -tags gms_pure_go` full embedded suites pass - `internal/storage/embeddeddolt` ok 535s, `cmd/bd` ok 585s, doctor/protocol/setup ok - with one skip: `TestEmbeddedInitConcurrent` failed twice (init race, "repo_state.json: no such file"; 9 of 10 expected outcomes) before the third run passed with it skipped.

**Pending**: disposition of `TestEmbeddedInitConcurrent` (flaky vs a real pure-Go init race); the release branch (57e843257) has no verify-queue run and no goreleaser dry-run evidence; no cross-platform smoke of the produced artifacts; branch base is already 29 commits behind upstream/main tip.

**Ongoing cost per upstream release**: upstream velocity is high. The 287-file migration cannot be rebased through drift; it was already regenerated once after ~90 commits (per the #4408 comment), so each sync means re-running the sweep on new main plus resolving occasional go.mod/shim conflicts, then re-verifying. Budget roughly one regeneration + one verify-queue cycle per carried release.

**Exit criteria for dropping the carry**: (a) Dolt lands a build-tagged zstd seam in `store/nbs` (or the driver ships pure-Go), and (b) beads main builds embedded at CGO=0, at which point the fork branches collapse to at most the goreleaser change, or to nothing.

## Option C: do both (recommended)

The evidence supports it: the carry is ready now and the escalation costs one issue filing plus one ping. Carry releases from `mybd-hli9-purego-release` (after clearing the two pending items above), keep #4249 and #4408 open as the exit path, and move the real ask to the Dolt repo where the storage owner lives. Re-ping cadence: monthly, referencing shipped fork releases as field evidence.

## Comparison

| | A: escalate only | B: carry only | C: both |
|---|---|---|---|
| Release pain relief | none until upstream acts | immediate | immediate |
| Latency | unbounded (39 days silent so far) | ~days (2 pending checks) | ~days |
| Ongoing cost | ~zero | regen + verify per release | same as B + trivial ping cost |
| Durable fix | yes, if it lands | no, permanent divergence risk | yes, carry is explicitly temporary |
| Risk | silence continues | drift compounds, exit never comes | mitigated both ways |

## Decision line

**Decide by 2026-07-12. Default if no decision: Option C** - proceed with the fork-carry release after resolving the `TestEmbeddedInitConcurrent` disposition and a goreleaser dry-run, and file the Dolt-level seam issue; #4249 stays open as the exit path.
