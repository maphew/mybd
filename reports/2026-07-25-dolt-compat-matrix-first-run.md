# Dolt CLI compatibility matrix — first empirical run (mybd-5zvr)

Date: 2026-07-25. Harness: `scripts/dolt-compat-matrix` (new this session,
committed). Purpose: replace the policy-vs-evidence gap the psxg.4 design
review flagged — the docs promise "dolt 2.2.0+", code enforces nothing, and
the review predicted the real boundary sits near 1.85/2.0.

## Setup

- bd under test: built from upstream/main `5a88c2b48` with
  `CGO_ENABLED=1 -tags gms_pure_go`; embedded dolt module pin
  `v0.40.5-0.20260715172757-a6690826d767` (verified via `go version -m` —
  `bd --version` reports workspace HEAD, not build provenance).
- dolt CLIs: official linux-amd64 release tarballs, isolated
  `DOLT_ROOT_PATH` per version.
- Probes: P1 version parse; P2 `bd init --proxied-server` + create + list
  (real proxy + spawned dolt sql-server); P3 reopen; P4 `dolt gc
  --archive-level 0` (CLI flag); P5 `CALL DOLT_GC('--archive-level','0')`
  (SQL proc); P6 `CALL DOLT_STATS_GC()`; P7 cross-read of a database
  written by the bd-under-test's embedded module; P8 file:// remote
  push/clone round trip.

## Results

| dolt | P1 parse | P2 proxied init | P3 reopen | P4 gc flag | P5 gc SQL | P6 stats | P7 cross-read | P8 sync |
|------|----------|-----------------|-----------|------------|-----------|----------|---------------|---------|
| 1.52.1 | PASS | **FAIL** (server never listens; connection refused) | FAIL (cascade) | PASS | soft-fail ("no changes since last gc") | artifact | **FAIL** ("table has unknown fields") | PASS |
| 1.85.0 | PASS | PASS | PASS | PASS | PASS | artifact | **FAIL** ("table has unknown fields") | PASS |
| 2.0.0 | PASS | PASS | PASS | PASS | PASS | artifact | PASS | PASS |
| 2.2.2 | PASS | PASS | PASS | PASS | PASS | artifact | PASS | PASS |

P6 "stats issuer is paused" fails identically on every version including
the CI-pinned 2.2.2 → probe artifact of running the proc through offline
`dolt sql` rather than a running sql-server; not a version signal. P5 on
1.52.1 errors where newer dolts no-op successfully — a behavior difference
worth a capability note, not a blocker.

## Conclusions (preliminary, single-run, linux-amd64)

1. **The decisive probe is P7 (cross-read)**: only dolt ≥ 2.0.0 can read a
   database written by the current pinned embedded module. 1.85.0 —
   despite upstream release notes calling it the oldest 1.x line
   understanding 2.x storage — fails on *schema-level* content ("table has
   unknown fields"), not chunk format. Any embedded↔proxied migration or
   mixed embedded/CLI workflow hard-requires ≥ 2.0.0.
2. **Serving floor**: 1.85.0 fully serves current bd's proxied mode; 1.52.1
   does not (spawned sql-server never listens — root cause not yet dug out
   of server.log; the archive_level config key should be accepted at
   1.52.1 per its own floor constant, so something else in the generated
   config or init path breaks).
3. **Recommended enforceable floor for psxg.4 C2: `2.0.0`**, with 2.2.x as
   the documented/tested-through version. This converts the design's
   "likely 1.85 or 2.0" into evidence: 1.85 serves but cannot cross-read,
   and a floor that permits silently unreadable embedded databases is not
   a support floor.

## Remaining for the bead (harness refinement)

- P6 probe must run against a live sql-server session (or accept the
  paused-issuer response as N/A); P5 should treat "no changes since last
  gc" as pass.
- Root-cause 1.52.1's proxied serve failure (keep-workspace run + server.log).
- Add: schema-migration-on-old-db probe, reopen-after-CLI-write-by-each-
  version (write-compat, not just read), arm64/macOS/Windows lanes,
  multiple runs for flake margin, wire into CI as the psxg.4 "tested-
  through" producer.
