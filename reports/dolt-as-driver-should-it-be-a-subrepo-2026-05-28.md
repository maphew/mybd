# Is Dolt "a driver" to beads — and if so, why does it live inside the beads repo?

**Question owner:** maphew · **Related beads:** mybd-ethh (enforcement follow-up), mybd-t7mk (CGO epic) · **Related report:** [cgo-enabled-build-divergence-root-cause-and-solution-2026-05-29.md](cgo-enabled-build-divergence-root-cause-and-solution-2026-05-29.md) · **Date:** 2026-05-28 · **Status:** analysis complete; recommendation = do **not** split into a separate git repo; cheap mechanical-enforcement option filed as mybd-ethh.

## TL;DR

The premise hides a conflation. **"Dolt" is not inside the beads repo — beads' *adapter to* Dolt is.** Dolt-the-engine already lives in its own repo (the `dolthub` org), pulled in through `go.mod`. What sits in `internal/storage/dolt/` is ~48k lines of *beads code that knows how to talk to Dolt*, i.e. the driver **client**, not the database.

Once you separate those, the rest falls out:

- **Is it really a driver?** In **server mode** (today's default) it isn't *"as if"* a driver — it **literally is** one: `bd` talks to a separate `dolt sql-server` process over the MySQL wire protocol via `go-sql-driver/mysql`, pure Go, no CGO. In **embedded mode** (legacy, CGO-only) it's a driver-shaped API (`github.com/dolthub/driver`) that statically links the whole engine into the binary — that's the mode that "feels welded in," and it's the source of the CGO pain documented in the companion report.
- **What else could use "dolt-the-driver"?** The genuinely reusable pieces — `go-sql-driver/mysql` and `dolthub/driver` — **already exist, already live outside beads, and already serve other consumers.** What remains inside beads is the *non-reusable* part by definition (issue→SQL mapping), so it has no external audience and thus no strong reason to be its own repo.
- **Sub-repo it?** A separate **git repo** is over-engineering for a single backend with a single consumer, and would *not* reduce the storage maintainer's cognitive load (his domain is already in separate repos). A separate **Go module in the same repo** plus an **import-linter** is the cheap 80% if mechanical boundary enforcement is the actual goal. The boundary is already clean on the *code* axis; the only live leak is the *build* (CGO) axis, which a repo split would not fix.

## 1. The reframe: two different things both called "Dolt"

| "Dolt" | Where it lives | What it is | In beads repo? |
|---|---|---|---|
| **Dolt the engine** | `github.com/dolthub/dolt`, `dolthub/driver`, `dolthub/go-mysql-server` (the `dolthub` GitHub org) | The versioned SQL database + its `database/sql` driver | **No** — a `go.mod` dependency |
| **Beads' Dolt adapter** | `internal/storage/dolt/`, `embeddeddolt/`, `doltutil/`, `dbproxy/`, `internal/doltserver/` | ~48k LOC of beads code mapping the issue model onto Dolt | **Yes** |

So the directory that triggers the question — `internal/storage/dolt/` — is the **driver client**, not Dolt itself. Dolt-the-database is already as separated from beads as PostgreSQL is from an app that queries it. coffeegoddd's (DoltHub's) actual domain — the engine and the driver — is **already in its own repos**, outside `gastownhall/beads`.

The instinct behind the question is, however, correct and has a name: **ports & adapters** (hexagonal architecture / dependency inversion). The Go `Storage` interface is the "port"; the Dolt code is the "adapter." That is exactly how an engineer frames this; the question arrives at the right model from the smell.

## 2. What is actually in the tree (evidence)

### 2.1 The port (interface)

`internal/storage/storage.go` (354 lines) defines the base **`Storage`** interface — 57 methods of issue CRUD, dependency/label/comment/work-queue queries, plus `RunInTransaction` and `Close`. This base port is reasonably engine-agnostic; you could plausibly back it with Postgres/SQLite.

But the interface the application actually consumes is the composite **`DoltStorage`** (lines ~200–213):

```go
type DoltStorage interface {
    Storage
    VersionControl
    HistoryViewer
    RemoteStore
    SyncStore
    FederationStore
    BulkIssueStore
    DependencyQueryStore
    AnnotationStore
    ConfigMetadataStore
    CompactionStore
    AdvancedQueryStore
}
```

**The name is the tell.** It is not `Store` (a role); it is `DoltStorage` (a vendor). And the sub-interfaces it bundles — `VersionControl`, `HistoryViewer`, `RemoteStore`, `SyncStore`, `FederationStore` — are **Dolt's distinctive capabilities**: versioned SQL, branch/merge, native push/pull. Those are surfaced straight through to users as `bd dolt push`, history, and federation. You could never drop SQLite behind `DoltStorage` — SQLite has no `dolt push`.

### 2.2 The adapter (implementations)

| Package | Path | Role | Files | ~LOC | Build |
|---|---|---|---|---|---|
| `dolt` | `internal/storage/dolt/` | **Server-mode** backend (MySQL client to `dolt sql-server`) | 90 | 37,656 | pure Go |
| `embeddeddolt` | `internal/storage/embeddeddolt/` | **Embedded-mode** backend (in-process engine) | 36 | 6,532 | `//go:build cgo` |
| `doltutil` | `internal/storage/doltutil/` | DSN/remote/file helpers | 6 | 451 | — |
| `dbproxy` | `internal/storage/dbproxy/` | server process lifecycle | 21 | 3,872 | — |

Plus `internal/doltserver/` for server lifecycle. **~48,500 LOC across ~153 files** of beads-side, Dolt-aware code. There is exactly **one** backend (Dolt); no SQLite/in-memory/Postgres alternative exists.

### 2.3 The dependency (go.mod)

```
github.com/dolthub/driver           v1.88.1                  // required (embedded engine, CGO)
github.com/go-sql-driver/mysql      v1.9.3                   // required (server-mode wire protocol)
github.com/dolthub/dolt/go          v0.40.5-...              // indirect
github.com/dolthub/go-mysql-server  v0.20.1-...              // indirect
github.com/dolthub/vitess           ...                      // indirect
github.com/dolthub/gozstd           ...                      // indirect (the lone CGO holdout)
```

Single Go module. Dolt is a dependency, not checked-in source.

### 2.4 The three runtime modes

1. **ServerModeOwned** (default): `bd` spawns a `dolt sql-server` subprocess and connects over MySQL protocol. **Separate process. Pure Go. No CGO.**
2. **ServerModeExternal**: `bd` connects to a user-managed `dolt sql-server`. Same wire protocol.
3. **ServerModeEmbedded** (legacy): `bd` links the engine in-process via `dolthub/driver`. **CGO required.**

Modes 1–2 are the textbook driver relationship. Mode 3 is the in-process outlier.

### 2.5 Boundary cleanliness (the code axis is already good)

The cross-boundary reaches the Charter warns about are mostly already *absent* in practice:

- **`flock`**: only in `dbproxy/util/flock.go` and `doltserver/` (legitimate server-lifecycle locking), not in user-facing storage code.
- **`.dolt/` filesystem access**: a *single* `os.Stat` of `.dolt/noms` for an fsck pre-push check (`dolt/store.go:1972`), wrapped in an explicit "DO NOT remove/modify Dolt-internal files" warning (`:1591–1593`).
- **`dolt` CLI invocation** (`exec.Command("dolt", ...)`): isolated to the `dolt/` package.
- Non-storage packages (`issueops`, `domain`, `versioncontrolops`) already depend only on the interface.

The boundary is **not leaking code**. It is leaking **build configuration** — see §6.

## 3. So — is it really a driver, or does it belong inside beads?

Both, on different layers, and that is the honest answer to the original musing:

- The **base `Storage` port** (CRUD/query) is genuinely driver-shaped, and **in server mode the relationship is a real driver** — separate process, wire protocol, swappable in principle.
- The **`DoltStorage` capabilities** (versioning / sync / federation) are *why beads chose Dolt in the first place*, and beads exposes them as product surface. **You cannot abstract away the very feature you picked the engine for.** That part legitimately lives close to beads.

This also explains why there is exactly one backend: the interface is **co-designed around one engine's superpowers**, not a lowest-common-denominator driver contract. That is a product decision honestly reflected in code, not a layering failure.

## 4. "What else does or could use dolt-the-driver?"

The reusable, general-purpose driver pieces already exist *and already have other users*:

- **`go-sql-driver/mysql`** — used across the Go ecosystem; beads uses it to speak to `dolt sql-server`.
- **`dolthub/driver`** — DoltHub's general-purpose `database/sql` driver for embedding Dolt, published for *anyone*; beads is one consumer.

What remains inside beads — `internal/storage/dolt/` — is the **issue-tracker-specific mapping**, which is **non-reusable by definition**. A repository earns independent existence by serving multiple consumers or shipping on an independent release cadence. The adapter has **one consumer (beads)** and **no independent release reason**. That is the textbook signal to *not* split it out.

## 5. The sub-repo question, as a ladder

| Option | What it is | Enforcement | Cost | Verdict |
|---|---|---|---|---|
| **A. Status quo** | one module; boundary held by `PROJECT_CHARTER` + review + roadmap memory | social | none | Fine in practice — boundary is already clean on the code axis (§2.5) |
| **B. Import-linter** (depguard) | golangci-lint rule forbidding `dolthub/*` imports outside `internal/storage/**` | **mechanical (lint/CI)** | **very low** | **Recommended** if you want hard enforcement — this is the cheap 80% |
| **C. Separate Go *module*** (same repo) | own `go.mod`/workspace for `internal/storage`; core depends on it | mechanical (import graph) | medium | Reasonable escalation; also the natural seam to quarantine embedded-Dolt CGO |
| **D. Separate *git repo*** | adapter in its own repository | mechanical + org separation | **high** (version skew, two PRs per logical change, release dance) | **Not recommended** — over-engineering for 1 impl / 1 consumer |

The leap most people imagine is A→D. The high-value, low-cost move is actually **A→B**: a depguard rule turns "reaching across the storage boundary" from a review catch into a CI failure, with no restructuring. Filed as **mybd-ethh**.

## 6. The boundary that *is* leaking: build config, not code

Per the companion CGO report, the storage boundary's only active leak is `CGO_ENABLED`: embedded Dolt's lone C dependency (`gozstd`, via `dolt/go/store/nbs`) forces a `cgo`/`!cgo` build-tag split that bleeds into the `federation` CLI surface, doc generation, the test set, lint, and the release matrix. **A repo split would not fix this** — the deps still come in wherever the adapter is imported. The fixes that matter are:

- **S1** (upstream, in `dolthub/driver`): get embedded Dolt onto pure-Go zstd — empirically validated as viable in the companion report. This is the *correct* "give the storage maintainer his own repo for storage": the work belongs in DoltHub's already-separate repo, not a new beads sub-repo.
- **Option C** above would let `bd` core stay pure-Go and import the embedded adapter only for the embedded build flavor — quarantining CGO structurally. That is the one concrete way a module boundary pays for itself here.

## 7. The maintainer cognitive-load angle

The hypothesis was that putting Dolt in its own repo would spare the storage maintainer from wading through 150+ PRs / 200+ issues. This targets the wrong repo:

- The storage maintainer's domain — engine + driver — is **already** in `dolthub/dolt` and `dolthub/driver`, separate from `gastownhall/beads`.
- The beads-side adapter is still *beads application code* (issue→SQL semantics). Splitting it out would create a **third** repo that is still beads' concern, splitting his attention across two beads repos rather than filtering one.
- The cheap fix for the firehose is **`CODEOWNERS` on `internal/storage/**` + storage labels + saved searches** — filtering, not fragmentation.

## 8. Recommendation

1. **Do not** extract the adapter into a separate git repo (Option D). Single impl, single consumer, non-reusable adapter, no maintainer-load benefit.
2. **Do** add a depguard import rule (Option B / **mybd-ethh**) if you want the boundary mechanically defended instead of socially. Cheapest durable win.
3. **Treat the CGO axis as the real target** (mybd-t7mk, esp. S1). That, not a repo split, is what dissolves the "embedded Dolt feels welded in" sensation — and it lives upstream where the engine already is.
4. Consider Option C (same-repo module) only as a follow-on *if* CGO quarantine (S1 declined) or stronger structural separation becomes worth the coordination cost.

Net: the driver-boundary instinct is right and worth defending mechanically, but the boundary is already clean on the code axis, the reusable driver is already external with other users, and the only live leak is the build axis — whose fix belongs upstream, not in a new repo.

## 9. Reproduction / evidence

```bash
# adapter size (beads-side, Dolt-aware)
tokei internal/storage/dolt internal/storage/embeddeddolt internal/storage/doltutil internal/storage/dbproxy

# the port and its Dolt-shaped composite
sed -n '39,213p' internal/storage/storage.go

# Dolt is a dependency, not vendored source
grep dolthub go.mod

# server mode = separate process over MySQL protocol (pure Go)
grep -rn 'sql-server' internal/doltserver/ | head
grep -rn 'go-sql-driver/mysql' internal/storage/ | head

# embedded mode = in-process via dolthub/driver, behind a cgo tag
head -3 internal/storage/embeddeddolt/store.go     # //go:build cgo
grep -rn 'dolthub/driver' internal/storage/embeddeddolt/ | head

# boundary cleanliness: the only .dolt/ reach + its warning
sed -n '1588,1595p;1970,1974p' internal/storage/dolt/store.go
```

---

*Authored by _claude-opus-4-8-max on behalf of maphew_.*
