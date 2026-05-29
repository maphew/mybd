# CGO_ENABLED in beads: root-cause and a real fix

**Epic:** mybd-t7mk · **Related beads:** mybd-rqtf, mybd-jvff, mybd-g36d · **Upstream:** gastownhall/beads#4203, #4243, #4211 · **Date:** 2026-05-29 · **Status:** analysis complete; fix plan proposed (T1–T5 in-repo, S1 upstream). **S1 empirically validated end-to-end** — a statically-linked, cgo-free `bd` builds *and runs* embedded Dolt (`bd init`/`create`/`list`) at `CGO_ENABLED=0` via a pure-Go zstd shim + a mechanical build-tag flip, with no upstream Dolt change (§7).

## TL;DR

`CGO_ENABLED` keeps causing trouble — doc churn, the "wrong build incantation,"
runtime "requires CGO" errors, lint disagreements, the release-CI zig/sysroot
fights — because **one** transitive dependency is cgo:

> Embedded Dolt links `github.com/dolthub/gozstd` (a cgo wrapper over the zstd C
> library) through a **single** package, `github.com/dolthub/dolt/go/store/nbs`.
> Once `-tags=gms_pure_go` removes the other C dependency (`go-icu-regex`),
> `gozstd` is the **only** cgo dependency left in a full `bd` binary. A pure-Go
> zstd (`github.com/klauspost/compress`) is **already** in the module graph.

That single dep forces the `//go:build cgo` / `//go:build !cgo` split, and the
split leaks `CGO_ENABLED` into four contracts it should never touch: the **build
command**, the **CLI/doc surface** (the `federation` command), **test
semantics**, and **lint results**. The doc-freshness failure that triggered this
investigation is just the newest leak.

**The fix** is to make those four boundaries CGO-invariant (T1–T5, all in-repo
and unilateral) and to erase the axis entirely upstream by getting embedded Dolt
onto pure-Go zstd (S1, a Dolt/driver concern). After T1–T5, `CGO_ENABLED`
controls exactly one thing — *is the embedded storage engine linked in?* — and
nothing else an agent or developer can trip over. After S1, it controls nothing.

## 1. Root cause (verified)

Embedded Dolt runs the Dolt engine in-process. Its storage layer (NBS, the Noms
Block Store) compresses chunks with zstd via `dolthub/gozstd`, which is cgo. The
import chain is exactly:

```
internal/storage/embeddeddolt  →  github.com/dolthub/driver
                               →  github.com/dolthub/dolt/go/store/nbs
                               →  github.com/dolthub/gozstd   (cgo)
```

`go mod why github.com/dolthub/gozstd` and a dependency-graph scan both confirm
**`nbs` is the sole direct importer** of `gozstd`. With `-tags=gms_pure_go`, the
complete cgo dependency set of `./cmd/bd` (excluding stdlib `net`, `os/user`,
`runtime/cgo`, which all have pure-Go fallbacks at `CGO_ENABLED=0`) is:

```
github.com/dolthub/gozstd
```

Without `gms_pure_go` you additionally get
`github.com/dolthub/go-icu-regex/internal/icu`. So historically there were two C
dependencies; `gms_pure_go` already eliminated the regex one (gastownhall/beads#3066). **`gozstd`
is the last C holdout, and `klauspost/compress v1.18.5` — a mature pure-Go zstd —
is already an indirect dependency.**

## 2. How one dependency fans out

Because embedded Dolt cannot link at `CGO_ENABLED=0`, the codebase carries a
`cgo` / `!cgo` build-tag split at every layer that touches it:

| Layer | `//go:build cgo` | `//go:build !cgo` | Leak it causes |
|---|---|---|---|
| Storage open | `internal/storage/embeddeddolt/open.go`, `store.go` | `open_stub.go`, `store_stub.go` → `errors.New("embeddeddolt: requires CGO (build with CGO_ENABLED=1)")` | runtime errors |
| Public API | `beads_cgo.go` (`OpenBestAvailable` → embedded) | `beads_nocgo.go:27` → `"embedded Dolt requires CGO; use server mode (bd init --server)"` | runtime errors |
| Store factory | `cmd/bd/store_factory.go` | `cmd/bd/store_factory_nocgo.go` | runtime errors |
| **CLI surface** | `cmd/bd/federation.go` (5 subcommands, rich help) | `cmd/bd/federation_nocgo.go` (stub command, `Short: "… (requires CGO)"`, different `Long`) | **doc churn** |
| Doctor internals | `cmd/bd/doctor/maintenance.go`, `migration_validation.go` | `…/checks_nocgo.go`, `migration_validation_nocgo.go` | (no help impact) |
| Test suite | ~100 `cmd/bd/*_embedded_test.go` + `internal/.../​*_test.go` | (absent) | green ≠ green |

`federation` is the **only top-level command whose help text and subcommand tree
differ by build mode** — verified by enumerating every build-tagged non-test file
for `AddCommand` / `cobra.Command` / `Short:` / `Long:`. The doctor stubs share
signatures and register no subcommands, so `bd help` is structurally identical
for everything except `federation`.

The CLI docs are generated from the **live** command tree (`cmd/bd/help_all.go`:
`writeAllHelp`, `listAllCommands`, `writeSingleCommandDoc`; there is no
`cobra/doc.GenMarkdown` anywhere), so the generated markdown is a direct function
of how the binary was compiled.

## 3. The full trip-point taxonomy ("not just docs")

Every recurring failure traces to the same split. Doc-gen is item 3; it is not
the whole disease.

1. **Tag omission → cryptic C-linker failure.** A bare `go build/test ./...`
   *without* `-tags=gms_pure_go` tries to link ICU and dies. The only protection
   is *remembering to source `.buildflags`* (or that CI's `check-build-tags.sh`
   catches it after the fact). This is the most common per-session agent trap.
2. **Build-time CGO → runtime surprise.** Build `bd` at `CGO_ENABLED=0` (or on a
   host without a C compiler) and you get a binary that errors at *runtime* —
   *"embedded Dolt requires a CGO build"* — the moment it touches storage,
   discovered far from the build command.
3. **CGO → different CLI surface → doc churn.** `bd help --all` differs by build
   mode (federation). Docs regenerate differently for every agent and every
   environment.
4. **CGO → different test set.** A green `CGO_ENABLED=0 go test ./...` skips ~100
   embedded-Dolt test files. "Tests pass" means two different things.
5. **Lint divergence.** `.githooks/pre-commit` lints at `CGO_ENABLED=0`, no tags
   (`pre-commit:23`); CI lints at cgo + `gms_pure_go` (`ci.yml:501`);
   `.pre-commit-config.yaml` inherits whatever is in the environment. Findings
   differ between local hook and CI.
6. **Non-deterministic doc generator.** `scripts/generate-cli-docs.sh` silently
   *reuses an existing `./bd`* of unknown provenance (`:31`), else builds one at
   `CGO_ENABLED=0` (`:37`). Output depends on how you last built.
7. **Split release matrix.** linux/win-amd64/darwin ship cgo (embedded +
   federation); android/win-arm64/freebsd ship nocgo (server-only). Same release,
   different feature sets — hence the `cmd/bd/info.go` "FIX: … n=0 server mode
   only" / zig-sysroot notes.

**Plus a second, CGO-independent doc bug feeding the current failure.**
`scripts/generate-llms-full.sh` concatenates `*.md` in **shell glob order**, so
`website/static/llms-full.txt` drifts (`init-safety` vs `init`, `rename` vs
`rename-prefix`, `statuses` vs `status`) regardless of CGO. Per the codex review,
that ordering drift — not CGO — is what is currently failing CI on **#4243**.

> Bonus sighting during this work: creating the tracking beads hit
> `Error 1105: column "depends_on_id" could not be found` when inserting
> dependency edges — the committed `bd` 1.0.4-dev binary against the migrated
> 1.0.5 dependencies-split schema. Another flavor of build/version drift; tracked
> separately (see `reports/release-gate-1.0.5-dependencies-migration-2026-05-28`).

## 4. The reframe

`CGO_ENABLED` should control **exactly one thing**: *is the embedded storage
engine linked in?* Today it also silently changes four things it has no business
changing:

| Boundary | Should depend on CGO? | Today | Fix |
|---|---|---|---|
| Build command (`go …` invocation) | No | Yes — forget `-tags=gms_pure_go` → ICU link error | **T1** |
| CLI / doc surface (`bd help`) | No | Yes — `federation` tree present/absent | **T2** |
| Test pass semantics & lint | No | Yes — embedded tests skipped; lint surface differs | **T3 (doc determinism), T4** |
| Runtime capability (embedded available?) | **Yes — legitimate** | Yes, but *silent* and discovered late | **T5** (make it loud & self-describing) |

After T1–T5 the four illegitimate leaks are closed and the one legitimate
difference is observable and self-explaining. S1 then removes even that.

## 5. The fix

### Tactical, in-repo, unilateral (closes leaks 1–6)

**T1 — make the tag automatic, not remembered.** `go env -w
GOFLAGS=-tags=gms_pure_go` in the devcontainer / `setup.sh`, plus a one-line
documented step for bare clones. Every subsequent `go` command then carries the
tag across all shells with no sourcing. Add a `make doctor-build` (or
`scripts/check-env.sh`) preflight that reports tag / cgo / C-compiler state and
prints the exact remedy instead of an ICU linker dump. *Closes #1.*

**T2 — make the `federation` CLI surface build-invariant.** Move the command
*definitions* (`Use` / `Short` / `Long` / flags / the five subcommands) into a
single untagged file; keep only the `Run` bodies behind `//go:build cgo`, with a
small stub `Run` (returns a clear runtime error) for `!cgo`. Then
`bd help --all/--list/--doc` is **byte-identical** across modes, doc generation
stops depending on the build, and the doc-freshness check no longer cares which
binary CI built. This is strictly better than #4243's "build the doc-check with
CGO," which only flips *which* mode is canonical and leaves the surface
mode-dependent. *Closes #3; neutralizes #6 for federation.*

**T3 — make the doc generators deterministic.** Sort the file list in
`generate-llms-full.sh` (kills the glob-order drift that is failing #4243), and
make `generate-cli-docs.sh` pin its build (or refuse to silently reuse a stray
`./bd`). *Closes #6; unblocks #4243's actual failure — independent of CGO.*

**T4 — make verification honest.** Unify the three golangci-lint invocations
(`.githooks/pre-commit`, `.pre-commit-config.yaml`, CI) to one mode + one tag
set. Have the test harness announce its mode/subset ("embedded tests: ENABLED
(cgo)" vs "SKIPPED — run `make test` for the full suite"). *Closes #4, #5.*

**T5 — make the binary self-describing.** `bd version` deliberately dropped its
`cgo` field (`version_test.go:76`: "no CGO bifurcation") to keep version output a
stable contract — correct, but it removed diagnosability. Put the mode back where
it belongs: have `bd doctor` report `cgo: on/off` + `embedded:
available/unavailable`, and make the `!cgo` runtime stub error quote the exact
rebuild command. *Closes #2.*

### Strategic, upstream — erases the axis entirely (closes all of 1–7)

**S1 — get embedded Dolt onto pure-Go zstd.** `gozstd` is the sole cgo holdout
and `klauspost/compress` is already present, so a pure-Go embedded build is *one
dependency away*. If embedded links at `CGO_ENABLED=0`, every split in §2
collapses into a single universal build and T1–T5 become unnecessary scaffolding.

But storage is the driver's domain — coffeegoddd / DoltHub own it, and the
storage-driver roadmap is explicit that beads must not reach across the boundary.
So S1 is a **Dolt-side build option / driver request**, not a beads-side hack,
framed as: *"beads' entire cgo maintenance burden derives from this one dep — is
a pure-Go zstd build path something Dolt has or would accept?"* The make-or-break
technical risk is zstd **dictionary** support and exact on-disk frame
compatibility in NBS (standard zstd frames interoperate between libzstd and
`klauspost/compress`; Dolt's *specific* usage is the real question). Feasibility
assessment is in §7.

## 6. Relationship to in-flight work (coordinate, do not collide)

| Item | Owner | State | This plan's relationship |
|---|---|---|---|
| gastownhall/beads#4203 (issue) | coffeegoddd | open | Root issue. T2 resolves it more durably than its chosen Option 1. |
| gastownhall/beads#4243 (PR, Option 1) | maphew | open, **CI failing** on llms ordering | T3 fixes the actual blocker (glob order). T2 makes the CGO-flip in this PR unnecessary. Decide: redirect to T2, or land #4243 + T3 now and do T2 next. |
| gastownhall/beads#4211 (CI wrapper) | julianknutsen | open, deferred (mybd-g36d) | Carries the same `CGO_ENABLED=0` doc build; with T2 the mode no longer matters. Whichever lands second must inherit the fix. |
| mybd-rqtf | — | open (P2) | The #4203 tracker. T2/T3 supersede its "build doc-check with CGO" framing. |
| mybd-jvff | — | open (P3) | "agent doc-regen trap." T1 (+ T2) is the structural answer to it. |

Per AGENTS.md, run `bd-main/scripts/pr-preflight.sh --search "cgo federation doc"
--repo gastownhall/beads` before implementing T2/T3 upstream, and coordinate with
the #4243 author rather than opening a competing PR.

## 7. S1 feasibility — empirically validated (the centerpiece result)

This was not left as theory. A throwaway worktree
(`.worktrees/beads/cgo-purego-shim`, branch `experiment/cgo-purego-shim`, local
do-not-merge) replaced `gozstd` with a ~120-line pure-Go shim over
`klauspost/compress/zstd` (the 9 symbols `nbs` uses: `Compress`, `Decompress`,
`CompressDict`, `DecompressDict`, `BuildDict`, `NewCDict`, `NewDDict`, and the
`CDict`/`DDict` handles), wired via `replace github.com/dolthub/gozstd =>
./gozstd-shim`.

**Result at `CGO_ENABLED=0 -tags gms_pure_go`:**

- `go build dolt/go/store/nbs` → **exit 0** — the sole `gozstd` importer compiles
  pure-Go.
- **10 / 12 NBS archive tests pass**, including the load-bearing ones:
  `TestArchiveDictDecompression` (dictionary compress/decompress round-trip),
  `TestArchiverMultipleChunksMultipleDictionaries`, `TestArchiveConjoinAll` /
  `…Comprehensive` / `…MixedCompression` (the GC / archive-merge path),
  `TestArchiveSingleZStdChunk`, and content-addressing.
- The **2 failures are compression-ratio test fixtures, not format or
  correctness**: `TestArchiveMixedTypesToChunkers` overruns a hand-tuned 16 KB
  `FixedBufferByteSink` (`archive_test.go:367`; the comment at `:366` admits the
  sizes are compressor-tuned), and `TestArchiveChunkGroup` asserts compressed
  size within ±byte windows (`:1176`, e.g. *"Expected 8726 to be between 8690 and
  8720"* — six bytes over). klauspost lands within single-digit bytes of libzstd.

**Then the whole binary, end to end.** Flipping beads' 36 `//go:build cgo/!cgo`
source files to a CGO-independent `nocgo` tag (`cgo`→`!nocgo`, `!cgo`→`nocgo` —
reproducing today's CGO=1 file set so embedded + federation always compile) and
building with the shim produced a **statically-linked, cgo-free `bd`** (`ldd`:
*not a dynamic executable*; no libzstd / ICU / libc) that **runs embedded Dolt**:
`bd init` creates `.beads/embeddeddolt/`, and `bd create` / `bd list` round-trip
issues — all at `CGO_ENABLED=0`, no C toolchain. `bd federation --help` shows the
full subcommand tree, so the doc-churn source is gone too.

**Conclusion: the pure-Go embedded path is viable end to end — `bd` builds,
links static, and runs embedded Dolt at `CGO_ENABLED=0` with no upstream change.**
The new-write path is proven; the full test tree compiles at CGO=0 and **both**
the `internal/storage/embeddeddolt` (59s) **and the `cmd/bd` CLI-layer embedded
(239s) suites pass** — comprehensive validation across the storage and CLI
layers, not a smoke test. **Legacy decode is verified too:** pure-Go klauspost
decodes frames the cgo libzstd build compressed with `ZDICT`-trained dictionaries
(round-trip match), so existing databases stay readable after the switch — no
read-path rewrite needed (the shim's `NewDDict` loads trained dicts via
`WithDecoderDicts`).

**Carry caveat (found in preflight):** the fork-side mechanism is a `go.mod`
`replace`, which **breaks `go install …@latest`** (#3338, #3312) — fine for
release binaries and source builds, but the *durable* home for the swap is a
build-tagged seam inside Dolt. Hence the dual track: fork-carry now for releases,
plus the upstream proposal at
`proposals/upstream-dolt-pure-go-zstd-seam-2026-05-29.md` (posted as
gastownhall/beads#4249). The gap to production is (a) **compression ratio** — use klauspost
trained dictionaries / better raw-dict content / level tuning to match libzstd,
and relax the ratio-pinned test fixtures — and (b) **legacy-archive decode** —
verify a klauspost reader decodes an archive written by the real C-ZDICT build
(the one-way migration question). Both are bounded; bd controls its own DB, so
even a one-time archive rewrite on upgrade is acceptable. Full repro:
`gozstd-shim/RESULTS.md` on the experiment branch.

### Upstream context (research)

Dolt deliberately chose cgo `gozstd` for block-compression performance
([DoltHub, 2024-05-01](https://www.dolthub.com/blog/2024-05-01-cgo-tradeoffs/));
there is no existing no-cgo build tag and the trajectory is toward more cgo. But
DoltHub values cgo-free single binaries enough to have solved the *ICU* case by
running it as WebAssembly via wazero — a useful precedent. Strong prior art:
**BadgerDB migrated Datadog/zstd → klauspost/compress** (dgraph-io#1383, 2021),
with the klauspost author confirming bidirectional frame compatibility — though
Badger did not use dictionaries, which is Dolt's one differentiator.

### Drafted questions for the Dolt storage owner (coffeegoddd / DoltHub)

Framing: *bd's entire cgo maintenance burden — federation gating, embedded
stubs, ~100 cgo-only test files, nondeterministic docs, a split release matrix —
derives from this one dep. A pure-Go zstd build path: does Dolt have one, or
would it accept one?*

1. Would you accept a build-tagged seam in `store/nbs` routing the ~9 gozstd
   calls through an interface, with a klauspost backend under `CGO_ENABLED=0`,
   defaulting to cgo/gozstd so prebuilt binaries are unchanged? (Mirrors the
   `gms_pure_go` precedent and the wazero-for-ICU approach.)
2. Dictionary format: have you tested whether klauspost can decode
   dictionary-compressed frames produced by libzstd with `ZDICT`-trained dicts —
   i.e., is on-disk archive interop expected to hold, or would a pure-Go reader
   need raw / content-only dicts?
3. `DecompBundle` already retains `rawDictionary []byte`. Is there a correctness
   reason the archive path needs libzstd's *trained* entropy tables, or would
   content-only (raw) dicts be acceptable, accepting some ratio loss?
4. What compression-ratio / GC-throughput regression would be disqualifying for
   an opt-in pure-Go backend? Any archive-format benchmarks we could run against?
5. Roadmap: is shrinking the cgo surface something Dolt wants long-term, or is
   cgo-zstd a permanent decision bd should design *around* (e.g. maintain the
   shim in the fork)?

## 8. Tracking

- **mybd-t7mk** (epic) — Make `CGO_ENABLED` a runtime-only concern
  - **.1 T1** — automatic `gms_pure_go` tag + build preflight
  - **.2 T2** — build-invariant `federation` CLI surface (ext: gh-4203)
  - **.3 T3** — deterministic doc generators (ext: gh-4203)
  - **.4 T4** — unify lint + announce test mode
  - **.5 T5** — self-describing binary (doctor + runtime error)
  - **.6 S1** — validate pure-Go embedded Dolt + upstream ask

## 9. Reproduction (commands run for this analysis)

```bash
# sole cgo dep under the project's standard tag
CGO_ENABLED=1 go list -deps -tags gms_pure_go \
  -f '{{if .CgoFiles}}{{.ImportPath}}{{end}}' ./cmd/bd | \
  grep -v -E '^(net|os/user|runtime/cgo)$' | sort -u
# → github.com/dolthub/gozstd            (only line)

# without the tag, ICU reappears
CGO_ENABLED=1 go list -deps \
  -f '{{if .CgoFiles}}{{.ImportPath}}{{end}}' ./cmd/bd | … 
# → github.com/dolthub/go-icu-regex/internal/icu + github.com/dolthub/gozstd

# the single importer of gozstd
go mod why github.com/dolthub/gozstd
# embeddeddolt → dolthub/driver → dolt/go/store/nbs → gozstd

# pure-Go zstd already present
grep klauspost/compress go.mod   # → v1.18.5 // indirect

# CGO=0 compiles the STUB (so it "succeeds" — embedded silently absent)
CGO_ENABLED=0 go build -tags gms_pure_go ./internal/storage/embeddeddolt/   # exit 0
```

---

*Authored by _claude-opus-4-8-max on behalf of maphew_.*
