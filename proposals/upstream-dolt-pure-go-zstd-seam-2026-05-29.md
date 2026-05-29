# Proposal: a build-tagged zstd seam so embedded Dolt can build without cgo (pure-Go bd is proven)

> **Posted as gastownhall/beads#4249** (2026-05-29), framed for @coffeegoddd
> (storage owner). This file is the source; the live issue is canonical.

## Summary

Beads' entire cgo maintenance burden traces to a **single** transitive
dependency: `github.com/dolthub/gozstd` (a cgo wrapper over libzstd), imported by
exactly one package, `github.com/dolthub/dolt/go/store/nbs`. Once
`-tags=gms_pure_go` removes the other C dependency (`go-icu-regex`), `gozstd` is
the **only** cgo dependency left in a full `bd` binary.

That one dep forces the `//go:build cgo` / `!cgo` split that ripples through
beads — embedded-storage stubs, the gated `federation` command, ~100 cgo-only
test files, nondeterministic doc generation (#4203), the pre-commit typecheck
trap (#3402), and a split release matrix where android/Termux ships without
embedded mode (#3538).

**I built a pure-Go `bd` and it works.** Replacing `gozstd` with a ~120-line shim
over `github.com/klauspost/compress/zstd` (already an indirect dep) and
decoupling beads' code from the `cgo` build tag yields a statically-linked,
cgo-free `bd` that builds and **runs embedded Dolt** end to end.

This issue asks whether Dolt would accept a **build-tagged seam** in
`store/nbs` so this can be done cleanly upstream — defaulting to cgo/gozstd so
prebuilt binaries and big-data Dolt users are completely unaffected.

## Evidence (reproducible)

In a worktree, `replace github.com/dolthub/gozstd => ./gozstd-shim` (klauspost
backend) plus flipping beads' `//go:build cgo/!cgo` tags to a CGO-independent
`nocgo` tag (reproducing today's CGO=1 file set), then at
`CGO_ENABLED=0 -tags gms_pure_go`:

- `go build ./cmd/bd` → **exit 0**; `file bd` → **statically linked**, `ldd` →
  *not a dynamic executable* (no libzstd / ICU / libc).
- `bd init` → `Backend: dolt, Mode: embedded`; `bd create` / `bd list`
  round-trip issues. **Embedded Dolt runs pure-Go.**
- `bd federation --help` → full subcommand tree at CGO=0.
- **All test packages compile**, and the **`internal/storage/embeddeddolt` suite
  passes** (create/query/deps/transactions/schema/version-control/federation).
- The only `store/nbs` test regressions are **two compression-ratio fixtures**
  (a hand-tuned `FixedBufferByteSink` size; a `±byte` window assertion at
  `archive_test.go:1176`) — klauspost lands within single-digit bytes of libzstd.
  Not format or correctness.

`gozstd`'s surface here is small and stable: **9 symbols** (`Compress`,
`Decompress`, `CompressDict`, `DecompressDict`, `BuildDict`, `NewCDict`,
`NewDDict`, `CDict`/`DDict`), all in `store/nbs/archive_*.go`, with no streaming.
Normal chunk writes already use snappy (pure-Go); `gozstd` only engages on the
archive/GC path.

## The ask: a build-tagged seam in `store/nbs`

Route the 9 `gozstd` calls through a tiny interface with two implementations
selected by build tag — `//go:build cgo` → gozstd (default, unchanged), a pure-Go
tag → klauspost. This mirrors two precedents already in the tree: the
`gms_pure_go` tag for go-mysql-server regex, and DoltHub's wazero/WebAssembly
approach for ICU. Prebuilt release binaries keep libzstd; only opt-in pure-Go
builds change.

Why the seam belongs upstream rather than a beads-side `replace`: a `replace`
directive in beads' `go.mod` **breaks `go install …@latest`** (#3338, #3312). A
build-tagged seam inside Dolt needs no replace, so `go install` keeps working.

## Questions for @coffeegoddd

1. Would you accept a build-tagged seam in `store/nbs` routing the ~9 gozstd
   calls through an interface, with a klauspost backend under a pure-Go tag,
   defaulting to gozstd so prebuilt binaries are unchanged?
2. **Dictionary format (the load-bearing risk):** the archive format stores
   `ZDICT_trainFromBuffer` dictionaries. Have you tested whether klauspost can
   decode dictionary-compressed frames produced by libzstd with those trained
   dicts — i.e., is on-disk archive interop expected to hold, or would a pure-Go
   reader need raw/content-only dicts?
3. `DecompBundle` already retains `rawDictionary []byte`. Is there a correctness
   reason the archive path needs libzstd's *trained* entropy tables, or would
   content-only (raw) dicts — which klauspost supports on both encode and decode
   — be acceptable, accepting some compression-ratio loss?
4. What compression-ratio / GC-throughput regression would be disqualifying for
   an opt-in pure-Go backend? Any archive-format benchmarks we could run against?
5. Roadmap: is shrinking the cgo surface (toward a single
   `CGO_ENABLED=0` build, which would also collapse the cross-platform release
   matrix to plain `GOOS/GOARCH`) something Dolt wants long-term, or is cgo-zstd a
   permanent performance decision beads should design *around* (carry the seam in
   a fork)?

## What beads gets

A single pure-Go `CGO_ENABLED=0` build erases the `cgo/!cgo` split entirely:
embedded + federation always present (no doc drift, #4203), the ~100 cgo-only
test files always run, no pre-commit typecheck trap (#3402), embedded mode on
android/Termux (#3538), and the release pipeline collapses to plain cross-builds
(no zig sysroots, mingw/clang cross-toolchains, or `verify-cgo` hooks).

---

*Drafted by _claude-opus-4-8-max on behalf of maphew_. Full analysis + repro:
mybd `reports/cgo-enabled-build-divergence-root-cause-and-solution-2026-05-29`,
experiment branch `experiment/cgo-purego-shim`.*
