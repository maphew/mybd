# Decision memo: mybd-pdvy - escalate #4249 vs fork-carry pure-Go releases

Date: 2026-07-07. Owner decision due: **2026-07-12**. Prepared read-only; nothing posted upstream.

**UPDATED 2026-07-07 evening**: maintainer engagement arrived on #4249 hours after this memo was drafted. Read the Addendum below first; it supersedes the executive summary's recommendation. The original analysis is retained unchanged below it.

## Addendum (2026-07-07T18:38Z): maintainer engagement changes the premise

[macneale4](https://github.com/gastownhall/beads/issues/4249#issuecomment-4907243168) (Dolt storage team, DoltHub) replied on #4249 — the first maintainer response in 39 days, and from exactly the audience Option A's step 1 proposed to reach by filing at the Dolt level. Substance:

- **Answers Q2 (the load-bearing dictionary risk)**: DoltHub already tested klauspost-produced dictionaries and found them "sufficiently bad" — no compression improvement over snappy. This kills the naive seam-as-proposed (klauspost as a drop-in encode backend with trained dicts).
- **Path (a)**: a generic dictionary embedded in the binary, klauspost-encoded. Prototyped by DoltHub; better than snappy, worse than a custom trained dict.
- **Path (b), his suggestion**: *disable zstd entirely for beads and use snappy alone* — "for the beads use case the database size is rarely a problem."

### Why this changes the calculus

1. **The silence premise is gone.** The memo's Option A latency estimate ("unknown and unbounded") rested on 39 days of non-engagement. There is now an active conversation with the storage owner's team, on our issue, proposing a path.
2. **Both offered paths are pure-Go-compatible, and (b) is simpler than our ask.** Path (a) is klauspost (pure Go) with an embedded generic dict; path (b) is snappy (already pure Go — normal chunk writes use it today). Our goal was never compression ratio, it was CGO elimination. A snappy-only beads profile needs *no zstd encode backend at all* — less code than the seam #4249 proposed.
3. **The load-bearing caveats were resolved empirically the same evening** (experiments run against the beads-pinned dolt `45335d44ad79`, using a stock cgo/libzstd `bd` from the hli9 merge-base and the pure-Go klauspost-shim `bd` from `mybd-hli9-nocgo-build-tags`; 5,000-issue store, `bd gc` → `CALL DOLT_GC()` at the default archive level):
   - **Build-time vs runtime (source-confirmed)**: disabling zstd at runtime does not remove the direct `gozstd` API references in `store/nbs` (5 files, `archive_*.go`, none behind build tags), which fail under `CGO_ENABLED=0` unless tagged out or replaced. Path (b) only reaches `CGO_ENABLED=0` if it includes that.
   - **Existing stores contain zstd trained-dict archives (proven, with a threshold)**: default GC writes zstd only past the stream writer's `maxSamples = 1000` chunk threshold (`store/nbs/archive_writer.go`); below it, `.darc` files are snappy-only. Real stores cross it: the GC'd 5,000-issue test store produced a 15.6 MB archive with 15,656 zstd frames, and our own production `mybd` store already holds two zstd-bearing archives (4,565 + 2,584 frames). Decode capability for existing stores is a hard requirement.
   - **Forward interop PROVEN**: the pure-Go klauspost build fully read the libzstd-GC'd store — `bd export` of all 5,000 issues byte-identical to the cgo build's export. A pure-Go binary needs only zstd *decode*, and klauspost's decode of libzstd ZDICT-trained frames works in practice.
   - **Reverse interop BROKEN (new finding)**: a store GC'd by the pure-Go build is rejected by the cgo build with `decompression error: Dictionary mismatch` — klauspost's `BuildDict` output yields frames carrying dictID 1 where libzstd's ZDICT emits content-derived IDs (1383496744 in our run). Any fork-carried pure-Go release that runs default GC would write stores **unreadable by official cgo binaries** — a one-way door for users mixing binaries or syncing via Dolt remotes. Mitigation exists: GC with `--archive-level 0`, or fix/neuter the shim's `BuildDict`. Tracked as its own bead (see below).
   - **Where the switch lives (partially answered)**: `DOLT_GC` already accepts `--archive-level`; `0` = `NoArchive` = snappy `CmpChunkTableWriter`. beads' single GC call site (`internal/storage/versioncontrolops/gc.go`) could pass it today as a one-line change — an immediate stop-the-bleeding step that needs no Dolt change. The durable tag-out of `gozstd` in `store/nbs` remains a Dolt-level decision, per the storage-driver roadmap.
   - Compression delta on the test data: klauspost trained-dict archive 10.7% larger than libzstd's — consistent with macneale4's "worse, but usable" prototype result.

### Revised recommendation: engage now, hold the carry

- **Reply to macneale4 promptly** — endorse path (b), and lead with evidence instead of questions: the interop experiments above answer what the first draft asked. The revised draft is staged at [`reports/mybd-pdvy-4249-reply-draft-2026-07-07.md`](mybd-pdvy-4249-reply-draft-2026-07-07.md); **not posted** — owner to approve/adjust/post. It offers a concrete one-line beads PR (`--archive-level 0` at the GC call site) and asks one design question: would Dolt take a tag-out of `gozstd` paired with klauspost decode-only for legacy archives. Maintainer engagement windows are short; this is the time-critical piece of the 2026-07-12 decision.
- **Do not start shipping fork-carried releases yet.** The carry's value was relief from unbounded upstream silence; silence just ended, and the per-release cost (287-file tag regen + verify cycle, compounding drift) buys little while a simpler upstream path is live. The reverse-interop finding adds a **new pre-release blocker**: a fork build running default GC writes stores unreadable by official binaries. Original Option C's "start now" is superseded twice over.
- **Keep the hli9 stack staged and fresh.** It remains the implementation vehicle under every outcome: the `nocgo` tag migration and goreleaser collapse are beads-side and needed regardless of which zstd path Dolt picks; the shim shrinks to decode-only (proven sufficient for existing stores) or to nothing under path (b). Before any fork release, the shim's write path must be neutered (`--archive-level 0` GC or `BuildDict` fix). #4249 and #4408 stay open.
- **New fallback checkpoint: 2026-07-21.** If by then the thread has not produced a concrete direction (who implements what, at which layer), fall back to original Option C — begin fork-carried releases after clearing the pending items (TestEmbeddedInitConcurrent disposition, goreleaser dry-run, and the reverse-interop mitigation above).

### Revised decision line

The 2026-07-12 owner decision becomes: (1) approve/adjust/post the reply draft, (2) confirm holding fork-carry releases, (3) confirm 2026-07-21 as the fallback checkpoint for reverting to Option C.

---

*The sections below are the original 2026-07-07 morning analysis, retained for the record. The "zero maintainer response" premise and the Option C "start fork-carried releases now" recommendation are superseded by the Addendum above.*

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
