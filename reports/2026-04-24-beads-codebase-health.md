# Beads Codebase Health Assessment

Date: 2026-04-24
Scope: local checkout `./bd-main`, upstream `gastownhall/beads`

## Executive Summary

Beads is in a workable but stressed state. The project has real engineering assets: a strong test culture, broad CI, regression and migration gates, meaningful documentation, and a clear product thesis. It is not a throwaway prototype. It is also carrying the normal scars of a fast, model-heavy first year: a very large CLI package, transitional global state, broad interfaces, duplicated storage behavior across server and embedded Dolt modes, release and packaging complexity, and a backlog clustered around data safety.

Overall health: **C+ / B-**.

The codebase is shippable with discipline, but refactoring should now become a first-class program rather than opportunistic cleanup. The safest path is not a rewrite. It is a staged extraction from the current `cmd/bd` center of gravity into command services, storage capability boundaries, and executable scenario tests that protect the Dolt lifecycle.

## Evidence Snapshot

Local repository state:

- Local branch: `fix/admin-embedded-mode`
- Remote: `upstream` points at `git@github.com:gastownhall/beads.git`
- After fetching upstream main: local branch is **5 commits ahead and 3 commits behind** `upstream/main`
- Local dirty files in `bd-main`: `cmd/bd/dolt.go`, `cmd/bd/dolt_embedded_test.go`
- Local `bd-main/.worktrees`: **26** nested worktrees
- `bd-main` Beads database: **11 total issues**, **8 open**, **1 in progress**, **0 blocked**
- `bd stats` in `bd-main` triggered an auto-push failure: Dolt histories diverged with "no common ancestor"

Tracked codebase size:

- Tracked files: **1,566**
- Go files: **1,074**
- Go test files: **524**
- Markdown files: **252**
- Workflow YAML files: **18**
- Total Go lines from tracked files: **320,398**
- Go test lines: **178,429**
- Top-level file distribution: `cmd` 648 files, `internal` 512, `website` 92, `docs` 69
- `cmd/bd`: **613 Go files**, **343 test files**, about **182,931 lines**

Validation run:

```bash
go test -tags gms_pure_go -short -skip '^TestEmbedded' ./...
```

Result: **passed**. Slowest packages observed:

- `cmd/bd`: 102.152s
- `internal/gitlab`: 10.836s
- `internal/storage/dolt`: 5.982s
- `internal/storage/doltutil`: 5.014s

## What Is Healthy

### 1. Test Investment Is Real

The repository has a high ratio of tests to implementation. Large suites exist around CLI behavior, Dolt storage, migrations, issue operations, tracker integrations, regression scenarios, and embedded Dolt flows. CI also separates fast PR checks, embedded Dolt checks, nightly full tests, regression tests, migration tests, release checks, documentation deployment, and Nix builds.

This is the main reason the codebase can be refactored safely. It is also the reason a rewrite would be wasteful.

### 2. Product Boundaries Are Visible

Even with the large CLI package, the domain is visible:

- `internal/types` holds the issue model.
- `internal/storage` defines storage contracts and capability interfaces.
- `internal/storage/dolt`, `internal/storage/embeddeddolt`, `internal/storage/issueops`, and `internal/storage/versioncontrolops` show an intended storage split.
- `internal/tracker` plus `internal/github`, `internal/gitlab`, `internal/jira`, `internal/ado`, `internal/linear`, and `internal/notion` form an external tracker layer.
- `internal/ui`, `internal/validation`, `internal/configfile`, `internal/beads`, and `internal/doltserver` are natural extraction points.

The architecture is not absent. It is partially submerged under CLI orchestration.

### 3. Release Engineering Is Serious

The project has GoReleaser, npm packaging, PyPI integration for MCP, Docusaurus docs, winget metadata, Nix support, install scripts, checksum/security docs, and cross-version smoke tests. That is unusual for a purely vibe-coded project and indicates the project has crossed into product territory.

### 4. The Team Has Already Identified the Right Failure Clusters

The local issue tracker already captures the right high-risk themes:

- Embedded Dolt startup, recovery, lock lifecycle, watcher races, journal corruption, and migrations.
- Remote/sync data safety.
- Admin/status command regressions.
- Ready/list JSON and UX regressions.
- Packaging and cross-platform regressions.

That backlog aligns with the code evidence.

## Primary Risks

### 1. `cmd/bd` Is Too Large To Be the Main System Boundary

`cmd/bd` has 613 Go files and roughly 183k lines. It imports most internal packages directly and still contains global state, command lifecycle logic, storage selection, formatting, error exits, hooks, telemetry, profiling, and domain workflows.

The code even has an explicit transitional context layer in `cmd/bd/context.go` that notes the historical "20+ globals" problem. That is a good sign because it names the problem, but it also means the transition is unfinished.

Risk:

- Small command changes can accidentally affect global lifecycle, store state, JSON mode, read-only mode, auto-commit, hooks, telemetry, or process exit behavior.
- Tests need heavy global reset logic.
- Command behavior is harder to reuse from MCP, libraries, and future UI layers.

Refactoring direction:

- Keep Cobra as the adapter.
- Move command behavior into injectable services with explicit input/output structs.
- Make process exit and terminal output adapter concerns, not business logic.

### 2. Storage Interfaces Are Broad and Capability Boundaries Are Blurry

`internal/storage.Storage` and `DoltStorage` expose a broad surface: issue CRUD, dependencies, labels, queries, wisps, comments, events, stats, config, transactions, merge slots, metadata slots, lifecycle, version control, remote sync, federation, bulk operations, annotations, compaction, and advanced queries.

That breadth is understandable for a CLI, but it makes every concrete store feel responsible for the whole product. The server Dolt and embedded Dolt implementations are forced to behave like one thing even though their lifecycle constraints are very different.

Risk:

- Embedded and server mode fixes drift from each other.
- Testing one capability often requires a large store fixture.
- Data-safety changes become cross-cutting.

Refactoring direction:

- Define narrow ports around use cases: `IssueReader`, `IssueWriter`, `DependencyStore`, `ConfigStore`, `VersionedStore`, `RemoteSyncStore`, `MaintenanceStore`.
- Keep `DoltStorage` only as a composition root compatibility interface while new code depends on narrow ports.
- Move shared SQL issue operations into `issueops` wherever server and embedded code should remain behaviorally identical.

### 3. Dolt Lifecycle Is the Highest Operational Risk

The most concerning live issues are all around Dolt lifecycle:

- Embedded startup and lock lifecycle.
- Journal corruption and recovery.
- Bootstrap stale server state.
- JSONL watcher races.
- Migration idempotence and compatibility.
- Server auto-start and stale locks.
- Remote push/pull safety and divergent histories.

This is reinforced locally: running `bd stats` in `bd-main` attempted an auto-push and failed because local and remote Dolt histories have no common ancestor.

Risk:

- Users can lose confidence even if actual issue data is recoverable.
- Recovery commands must work exactly when the system is least healthy.
- Auto behavior around push, bootstrap, and migration can create surprising side effects.

Refactoring direction:

- Treat Dolt lifecycle as its own subsystem with a small state machine.
- Make startup, bootstrap, migration, lock acquisition, recovery, auto-push, and shutdown observable and testable.
- Prefer explicit recovery recommendations over automatic destructive repair.

### 4. Process Exit and JSON Contracts Need Hardening

There are many `os.Exit` calls in command code, especially around Dolt administration. Direct exits make logic harder to test and make JSON/error contracts harder to preserve. Recent local changes to embedded `bd dolt status --json` show the kind of contract issue to watch: `running=false` could be misread as Dolt unavailable in embedded mode, so `server_running=false` is safer.

Risk:

- CLI behavior and machine-readable behavior diverge.
- Tests cannot easily assert failures without subprocesses or special seams.
- MCP and wrapper integrations inherit inconsistent error shapes.

Refactoring direction:

- Commands should return typed results and typed errors.
- A single CLI runner should map errors to text, JSON envelopes, and exit codes.
- Preserve existing flags, but define contract tests for JSON output.

### 5. Documentation Is Extensive but Likely Drifty

The repo has strong docs coverage, but there are multiple overlapping docs areas: root docs, Docusaurus versioned docs, integration docs, agent docs, generated CLI references, setup docs, testing docs, and old design notes. The README still references `steveyegge/beads` in some install examples while the requested canonical upstream is `gastownhall/beads`.

Risk:

- Agents and contributors follow stale instructions.
- Release changes require many doc updates.
- Documentation review becomes a hidden part of every code change.

Refactoring direction:

- Declare a docs source of truth for command reference, install methods, storage modes, and agent instructions.
- Generate or validate duplicated command flag references.
- Keep versioned docs, but make current docs visibly canonical.

## Recommended Refactoring Program

### Phase 0: Stabilize Before Large Refactors

Goal: stop compounding data-safety risk.

Do first:

- Resolve the Dolt history divergence for the `bd-main` Beads database.
- Land or explicitly reject the high-priority embedded/server lifecycle fixes.
- Make auto-push policy boring and predictable.
- Ensure admin, doctor, backup, bootstrap, status, and recovery commands work in both embedded and server modes.
- Keep `go test -tags gms_pure_go -short -skip '^TestEmbedded' ./...` green.

Exit criteria:

- Recovery commands have scenario tests.
- A local `bd stats` or read-only command does not surprise-push or hang.
- `bd-main` issue tracking can sync cleanly.

### Phase 1: Create a CLI Service Layer

Goal: make command behavior testable without process globals.

Do next:

- Introduce service packages for the highest-churn commands: `ready`, `list`, `show`, `create`, `update`, `close`, `dolt`, `doctor`.
- Each service gets an input struct, output struct, dependencies interface, and tests.
- Cobra commands become parsing and rendering adapters.
- Start with commands that already have regression pressure: `ready/list`, `dolt status/show`, and admin/doctor flows.

Exit criteria:

- New command behavior can be tested without mutating package globals.
- JSON and text rendering are separate from domain decisions.
- New code does not call `os.Exit` below the CLI adapter.

### Phase 2: Narrow Storage Capabilities

Goal: reduce the blast radius of storage changes.

Do next:

- Add narrow interfaces at use sites instead of expanding `DoltStorage`.
- Move common issue SQL behavior into `issueops`.
- Put server-only and embedded-only behavior behind explicit lifecycle interfaces.
- Add contract tests that run against both server and embedded implementations where behavior should match.

Exit criteria:

- A command that only reads issues cannot access remote push or compaction methods.
- Server and embedded divergence is intentional and documented.
- Storage tests can target capabilities instead of whole-store fixtures.

### Phase 3: Make Dolt Lifecycle a State Machine

Goal: make the highest-risk behavior explicit.

Model states such as:

- uninitialized
- initialized embedded
- initialized server
- server unavailable
- migration required
- migration failed
- lock held
- lock contended
- remote configured
- remote diverged
- recovery required

Do next:

- Centralize state detection.
- Centralize user-facing recovery guidance.
- Add scenario tests for bootstrap, stale server, lock contention, remote divergence, and migration retry.
- Make auto-start and auto-push decisions auditable.

Exit criteria:

- Recovery behavior is deterministic.
- Doctor output maps directly to lifecycle states.
- New Dolt bugs are represented as missing state transitions, not scattered conditionals.

### Phase 4: Clean Packaging and Docs Drift

Goal: make release confidence match test confidence.

Do next:

- Normalize repository URLs and install paths across README, package metadata, PyPI metadata, website, and scripts.
- Add release-blocking checks for package metadata consistency.
- Keep cross-version and migration tests as release gates.
- Treat installer checksum behavior as a contract.

Exit criteria:

- A release branch can be validated by one documented command.
- Package metadata points to the canonical repository.
- Docs generation catches stale flags and duplicated install commands.

## Refactoring Rules for GPT-5.5 Work

Use stronger models for narrow, evidence-backed changes rather than broad rewrites.

Recommended agent workflow:

1. Start from a Beads issue with a single behavioral objective.
2. Capture the existing behavior with a failing or characterization test.
3. Extract one boundary.
4. Preserve CLI output and JSON contracts unless the issue explicitly changes them.
5. Run targeted tests first, then the short suite.
6. File follow-up issues instead of expanding the patch.

Avoid:

- Rewriting `cmd/bd` wholesale.
- Replacing Dolt integration abstractions without scenario tests.
- Mixing docs, packaging, and storage lifecycle changes in one patch.
- Accepting model-generated cleanup that only moves code without reducing coupling.

## Top Follow-Up Issues To File

1. Extract `bd dolt status/show` into a service with JSON contract tests.
2. Replace direct `os.Exit` calls in `cmd/bd/dolt.go` with returned typed errors.
3. Define lifecycle state detection for embedded/server/recovery modes.
4. Add server and embedded contract tests for ready/list/show/create/update/close.
5. Split `DoltStorage` usage at command call sites into narrow capability interfaces.
6. Resolve `bd-main` Dolt remote divergence and document the recovery.
7. Normalize canonical repo URLs across Go docs, npm metadata, PyPI metadata, and install scripts.
8. Add a contributor PR intake checklist that protects existing contributor work while reducing backlog.

## Bottom Line

Beads is past the point where "vibe-coded" is the right operating model. It has enough users, storage complexity, tests, packaging, and recovery surface that it needs product-grade maintenance. The good news is that the foundations are much better than a typical one-year prototype: the tests and CI are strong enough to support careful refactoring.

The right next move is a stabilization and extraction campaign, not a rewrite.
