> Historical document recovered on 2026-09-10 from source branch codex-architecture-analysis, commit 62522ff4b53a175e14c60337881160f838149479. Original author: matt wilkie; agent signature: codex-unknown-model-unknown-reasoning. This June 22 analysis predates the maintainer step-down and is not current policy or an active task plan. Markdown trailing whitespace was normalized.

# Beads Project Analysis

Date: 2026-06-22

Scope: `bd-main/`, the Beads source tree, not the surrounding `mybd` coordination repository. This analysis is based on the current checked-out `main` branch, local source inspection, CLI help, core docs, migrations, and hot-path Go code.

## Evidence Base

This report is grounded in the following local inspection:

- Core docs: `README.md`, `docs/PROJECT_CHARTER.md`, `docs/ARCHITECTURE.md`, `docs/METADATA.md`, `docs/MOLECULES.md`, `docs/INTEGRATION_CHARTER.md`, `docs/SETUP.md`, `docs/TESTING.md`, and related testing/audit docs.
- CLI surface: `bd --help`, especially the breadth of issue, dependency, sync, setup, maintenance, memory, molecule, formula, mail, and integration commands.
- Core code paths: `cmd/bd/main.go`, `cmd/bd/create.go`, `cmd/bd/update.go`, `cmd/bd/close.go`, `cmd/bd/ready.go`, `cmd/bd/show.go`, `cmd/bd/store_factory.go`, and `cmd/bd/uow_factory.go`.
- Storage and graph internals: `internal/types/types.go`, `internal/storage/storage.go`, `internal/storage/dolt/*`, `internal/storage/embeddeddolt/*`, `internal/storage/issueops/*`, `internal/storage/uow/*`, and `internal/storage/schema/migrations/*`.
- Approximate size signals from the checked-out tree: 69 Go packages from `go list ./...`, 1404 tracked Go files, 729 tracked Go test files, and schema migrations through `0052`.

## Executive Thesis

Beads is trying to be a local-first, distributed issue graph for AI-supervised software work. Its strongest product idea is simple and valuable: replace drifting markdown task lists with durable, queryable, dependency-aware work state that can be used equally by humans and coding agents.

The project is already close to that aim in the load-bearing places. It has a real CLI, real Dolt-backed persistence, dependency and readiness semantics, structured JSON for agents, atomic claim paths, metadata extension points, bootstrap/setup workflows, and a serious recovery and testing culture. This is not a toy or just a wrapper around a TODO file.

It is also farther from its aim than it looks if measured by balance. The current system has accumulated a much larger public surface than the core idea requires: orchestration-flavored fields, molecule/wisp/gate/swarm/mail/formula surfaces, many integrations, several storage modes, legacy compatibility paths, and stale documentation about old architectures. Some of that work is useful. Some is repair scaffolding. Some is product exploration. But taken together, it makes the project harder to understand, harder to maintain, and easier to steer away from the chartered center.

The maintainers' central job is not to add ambition. It is to protect the small, durable issue-graph core from being diluted by adjacent workflow machinery.

## What Beads Aims To Do

The clearest statement of purpose appears in the charter and README:

- Beads is an issue tracker for AI-supervised development.
- Work is represented as issues and dependency edges.
- The tracker is local-first and repo-adjacent.
- State is durable, queryable, syncable, and mergeable through Dolt.
- Humans and agents share the same work graph.
- Agents get structured, stable JSON and dependency-aware "ready" queries.
- Workflow-specific policy should live in metadata or outside Beads, not in core schema.
- Tracker integrations should be bridges for adoption, not a second product.

The best mental model is:

> Beads is the durable work graph. It should know what work exists, what blocks what, who is doing it, what state it is in, and enough context to resume safely. It should not become the scheduler, agent router, policy engine, chat system, or universal project-management suite.

That distinction matters because Beads' value is strongest when it is boring in the right ways: stable state, reliable readiness, simple commands, explainable storage, and predictable sync.

## How Near It Is To That Aim

Beads is near the aim in the following ways.

### The Core Model Exists

The essential graph is present:

- `issues` as the durable unit of work.
- `dependencies` as blocking and structural relationships.
- `labels`, `comments`, and `events` as human and agent handoff context.
- `metadata` JSON as an extension point.
- status, priority, type, assignee, owner, timestamps, external refs, and source repo identity.

The core issue/dependency model is not hypothetical. It is implemented in storage, surfaced in commands, exported in JSON, and used by hot commands such as `bd ready`, `bd show`, `bd create`, `bd update`, `bd close`, and dependency commands.

### The Readiness Loop Is Real

The key agent workflow is present:

1. Find ready work.
2. Claim it atomically.
3. Inspect enough context to act.
4. Update or close it.
5. Recompute what is ready next.

`cmd/bd/ready.go`, `internal/storage/dolt/queries.go`, and `internal/storage/issueops/blocked.go` show that readiness is not just a display filter. It is backed by dependency semantics, blocked-state computation, and a claim path.

This is the product's center of gravity. If `bd ready --json`, `bd ready --claim`, `bd show --json`, dependency updates, and close/unblock behavior are correct and fast, Beads is useful even if much of the surrounding feature surface disappeared.

### Dolt Is Doing Meaningful Work

Dolt is not decorative. It gives Beads:

- durable SQL state,
- history,
- branching and merging,
- remotes,
- clone/bootstrap workflows,
- sync semantics that JSONL export cannot provide.

The source shows serious effort around Dolt integration: embedded mode, server mode, retry classification, migration checks, remote migration gates, backup/restore, bootstrap, and doctor/repair flows. These are hard operational problems, and Beads has clearly paid attention to them.

### The CLI Is Practical

The CLI already covers the real loop:

- initialize and discover a workspace,
- create and update work,
- model blockers,
- list/search/query,
- show structured context,
- claim ready work,
- close work,
- sync/backup/restore,
- prime an agent session.

The `bd prime` and `bd setup` surfaces are especially important. They turn Beads from "a CLI with commands" into "a working protocol for agents entering a repository."

### The Project Has Strong Self-Knowledge

The charter documents the right boundaries:

- issue tracking primitives belong in core,
- orchestration policy does not,
- metadata should be preferred before schema,
- integrations should not become full replicas of external systems,
- Dolt should own storage/versioning/sync behavior.

That is unusually clear. The weakness is not that the project lacks a good compass. The weakness is that implementation and product exploration have often moved faster than that compass can constrain.

## How Far It Is From That Aim

The distance from the aim is mostly about scope, layering, and freshness.

### The Public Surface Is Too Large For The Mental Model

The top-level help exposes a very broad command set: issue operations, views, dependencies, sync, setup, maintenance, integrations, memory, molecules, formulas, gates, mail, audit, rules, shipping, worktrees, and more.

Some commands are useful. Some are support tooling. Some are experiments. But the total surface makes the product harder to explain than the core model warrants. A new maintainer or contributor can reasonably ask: is Beads an issue tracker, an agent runtime, a workflow engine, a memory system, an integration hub, or a Dolt administration tool?

The answer should be "issue tracker." The current surface does not always make that answer obvious.

### The Issue Type Has Become A Magnet

`internal/types/types.go` contains a large `Issue` struct. It includes the core fields Beads needs, but also fields for compaction, messaging, ephemeral state, templates, gates, formulas, events, molecules, work type, bonding, source locations, and other workflow-specific concepts.

This is the most visible architectural pressure point. The charter says to prefer metadata before schema for workflow-specific concepts. The current issue record shows repeated exceptions to that rule.

Some of these fields may now be too embedded to remove cheaply. That is not the immediate problem. The immediate problem is that every new first-class field makes Beads less like a small issue graph and more like an application platform. Future schema additions should face a high bar.

### Storage Boundary Pressure Is High

The charter says Dolt should own storage/versioning/sync/merge/concurrency/crash safety. In practice, Beads has a lot of Dolt-adjacent machinery:

- embedded and server stores,
- shared server setup,
- proxied-server and UnitOfWork paths,
- retry and circuit-breaker logic,
- migration gates,
- local/remote schema checks,
- backup and restore details,
- repair/doctor logic,
- legacy lock and mode handling.

Some of this is necessary because Beads needs to be dependable on real developer machines. Still, the amount of storage support code is a sign that Dolt integration is one of the largest sources of product complexity.

The risk is not that this code is bad. Much of it is careful. The risk is that Beads gradually becomes responsible for hiding every rough edge of its storage engine. That pulls effort away from issue-tracking semantics.

### There Are Multiple Architectural Generations In The Tree

The codebase contains overlapping layers:

- legacy storage interfaces,
- Dolt store implementations,
- embedded Dolt store implementations,
- newer UnitOfWork/domain paths,
- issue operation helpers shared across stores,
- old docs still describing SQLite-era or RPC-era designs.

This is expected in a maturing project, but it creates friction. Maintainers need to know which path is canonical before changing behavior. In several areas the code answers "both, for now."

The most important consolidation question is whether the newer UnitOfWork/domain direction is the target architecture. If yes, new feature work should stop expanding older storage interfaces except for compatibility fixes.

### Documentation Freshness Is Uneven

The best docs are strong: the charter, metadata guidance, setup guidance, UI philosophy, integration charter, and the current testing guide all communicate useful product constraints.

But several docs still carry stale concepts or path references:

- architecture docs mention code paths that no longer appear to exist,
- some docs still talk about SQLite support or SQLite test structure,
- README/help references appear to include older daemon-mode wording,
- adaptive ID docs point at paths that no longer match current layout.

Stale architecture docs are more dangerous than missing docs because they create false confidence. Beads has enough moving parts that docs need freshness checks as part of maintenance, not occasional cleanup.

### The Test Contract Is Still Settling

The repository has substantial tests and many test files. It also has a documented awareness that local, CI, release, integration, no-CGO, Docker, and non-Go surfaces are not yet governed by one canonical contract.

This does not mean testing is weak. It means the testing story is broad and uneven. The most important thing for maintainers is not "more tests everywhere"; it is a clear gate model:

- what every PR must run,
- what storage-sensitive PRs must run,
- what release candidates must run,
- what non-Go or integration changes must run,
- what failures are known skips versus real regressions.

Without that, a large surface plus storage complexity will keep producing uncertainty.

## Essential Skeletal Features

These are the features and data structures without which Beads stops being Beads.

### Workspace Identity And Configuration

Beads needs a discoverable workspace with stable local configuration:

- `.beads` location and metadata,
- database identity and prefix,
- actor/user identity,
- storage mode,
- repo association,
- safe startup checks.

Without this, commands cannot reliably know which graph they are editing or syncing.

### Issue Records

The irreducible issue fields are:

- ID,
- title,
- description or body,
- status,
- priority,
- type,
- assignee or owner,
- created and updated timestamps,
- closed timestamp when applicable,
- external reference when imported or correlated,
- source repository/prefix identity,
- metadata JSON.

Design notes, acceptance criteria, and comments are highly valuable, but the essential unit is still a durable issue with identity, state, and enough content to act.

### Dependency Edges

Dependencies are the second half of the product. At minimum Beads needs:

- source issue,
- target issue or external target,
- relationship type,
- metadata,
- cycle prevention or cycle detection,
- readiness semantics.

Without dependencies, Beads is only a local issue list. The issue graph is what makes it suitable for multi-agent and interrupted work.

### Labels, Comments, And Events

Labels are needed for filtering and lightweight classification. Comments are needed for human and agent handoff. Events are needed for auditability and reconstruction.

Comments may look secondary compared with issues and dependencies, but for agent-supervised development they are close to skeletal. The ability to preserve why something changed is part of safe resumption.

### Stable ID Generation

The ID scheme is load-bearing. It needs to be:

- deterministic enough to avoid avoidable conflict,
- compact enough for command-line work,
- prefix-aware,
- stable across sync/import/export,
- safe for child IDs and issue moves.

The existing hash/adaptive/hierarchical ID work serves this need. The presence of multiple ID implementations and duplicated adaptive calculations is a maintainability concern, but the feature itself is core.

### Readiness And Claiming

Beads must answer:

- what can be worked now,
- why something is blocked,
- who has claimed a ready item,
- whether claiming was atomic.

This makes `ready`, blocked-state recomputation, denormalized blocked flags, dependency updates, and claim transactions central hot paths.

### Storage, Transactions, And Migrations

Beads needs durable storage and schema evolution. It also needs transaction boundaries for create/update/claim/close/dependency operations.

Dolt is the current storage engine and source of sync/history truth. The exact adapter shape can evolve, but the abstraction must preserve:

- local reads,
- durable writes,
- commits/history,
- sync/bootstrap,
- migration safety,
- recoverability.

### Structured CLI And JSON Contract

The CLI is not just UI. It is the protocol agents use. The skeletal commands are:

- `init` or bootstrap,
- `create`,
- `show`,
- `list` or `search`,
- `ready`,
- `update`,
- `close`,
- dependency add/remove/list,
- label/comment operations,
- sync/backup/restore,
- `prime`.

JSON output for agent-facing commands is not optional. It is part of the product contract.

### Metadata As Escape Valve

The metadata JSON field is essential because it protects the core schema from workflow churn. The more Beads serves agents and heterogeneous teams, the more important this escape valve becomes.

The project should treat metadata as a pressure-release mechanism, not as an afterthought.

## Hot Paths

These paths deserve disproportionate care because they define daily user experience and correctness.

### Startup And Store Opening

Every command pays the cost of discovery, config loading, storage selection, schema checks, and read/write mode setup. Regressions here make the whole CLI feel unreliable.

Files and areas to keep in view:

- `cmd/bd/main.go`
- `cmd/bd/store_factory.go`
- `cmd/bd/uow_factory.go`
- `internal/storage/dolt/open.go`
- `internal/storage/embeddeddolt/open.go`

### Create And Batch Create

Create is a heavy write path:

- parse user input or markdown/graph batches,
- validate statuses/types/prefixes,
- generate IDs,
- insert issues,
- insert labels/comments/dependencies,
- update parent/blocked state,
- commit through Dolt where applicable.

Important files:

- `cmd/bd/create.go`
- `internal/storage/issueops/create.go`
- `internal/storage/dolt/issues.go`

This path also shows scope pressure because many non-core concepts appear as create flags.

### Update, Close, And State Transitions

State transitions are where trust is won or lost. `close` in particular touches blockers, children, gate satisfaction, molecule auto-close behavior, suggestions, and optional claim-next flows.

Important files:

- `cmd/bd/update.go`
- `cmd/bd/close.go`
- `internal/storage/dolt/issues.go`

These commands should stay conservative. Clever behavior here can surprise users and agents.

### Ready, Blocked, And Claim

This is the central work-selection loop:

- compute unblocked items,
- apply filters,
- explain blocked state,
- optionally claim atomically,
- keep counts and JSON stable.

Important files:

- `cmd/bd/ready.go`
- `internal/storage/dolt/queries.go`
- `internal/storage/issueops/blocked.go`

If maintainers benchmark only a few commands, benchmark `ready`, `ready --claim`, `show --json`, and dependency updates on large graphs.

### Show, List, Search, And Query

These are context-loading paths for both people and agents. They must be fast, stable, and predictable.

Important files:

- `cmd/bd/show.go`
- `cmd/bd/list*.go`
- `cmd/bd/search*.go`
- `internal/storage/dolt/queries.go`

Large output and hydration options need careful defaults. The product should make the common context load cheap and the expensive context load explicit.

### Dependency Mutation And Blocked-State Recompute

Dependencies drive readiness, so adding/removing dependencies must maintain invariants:

- no invalid references,
- no unintended cycles,
- correct parent-child relationships,
- correct blocked cache,
- correct commit/history behavior.

This path is one of the most likely sources of subtle regressions.

### Sync, Bootstrap, Backup, Restore, And Doctor

These are not part of the core work loop, but they are core to trust. If users lose work or cannot recover a repo, the product fails.

Important areas:

- `cmd/bd/bootstrap*`
- `cmd/bd/backup*`
- `cmd/bd/restore*`
- `cmd/bd/doctor`
- Dolt remote and migration code

The support surface is justified here, but it should remain support. It should not become the product identity.

### Prime And Setup

`bd prime` and `bd setup` are adoption hot paths. They make Beads usable by agents without requiring every agent to rediscover local conventions.

These commands should be treated as product-critical even though they do not mutate ordinary issue state.

## Strengths To Preserve

### The Issue Graph Is The Right Primitive

The project has chosen a strong primitive. Issues plus dependencies are enough to model a large amount of software work without committing to one orchestrator or planning methodology.

The graph is also legible to humans. That matters. A tool for agents that humans cannot inspect will eventually fail in real repositories.

### Local-First Durability Is A Differentiator

Beads does not rely on a hosted service to be useful. That makes it attractive for private repos, offline work, agent sandboxes, and branch-specific planning.

Dolt is complex, but the product value of local durable state plus remote sync is real.

### JSON As A First-Class Contract Is Correct

Agent workflows need stable machine-readable output. Beads has leaned into this with `--json`, structured commands, and `bd prime`.

This is one of the clearest ways Beads differs from ordinary human-only issue trackers.

### Metadata Gives The Project A Way To Stay Small

The metadata model is one of the most important design choices. It lets teams and agents attach routing hints, execution settings, foreign IDs, and local policy without requiring every workflow to become Beads schema.

Future maintainers should be stricter about using it.

### The Project Is Honest About Boundaries

The charter, integration charter, and metadata docs show unusually good product discipline. The problem is not lack of principles; it is enforcing them while the codebase evolves.

### Operational Repair Tools Are A Real Asset

Doctor, bootstrap, backup/restore, migration guards, and config checks are not glamorous, but they are what make a local-first stateful tool survivable.

Maintainers should keep this support layer strong while resisting its expansion into broad platform behavior.

## Support Roles And Accidents Of Implementation

The following areas are useful but should not define the product center.

### Setup Recipes And Agent Configuration

`bd setup` and generated agent instructions are adoption tools. They should stay focused on helping agents use Beads correctly. They should not become a general policy engine for how teams assign models, schedule work, or run multi-agent systems.

### Tracker Integrations

GitHub, GitLab, Jira, Linear, ADO, Notion, and similar integrations are bridges. They help teams adopt Beads without abandoning existing systems immediately.

They should not aim for full UI parity, webhook orchestration, attachment mirroring, credential vault behavior, or bidirectional project-management semantics unless the charter changes.

### Molecules, Wisps, Gates, Formulas, Swarms, Mail

These areas may represent useful experiments or real workflows, but they sit near the boundary with orchestration and messaging. They should be treated as layered features until proven otherwise.

The simple framing from the molecule docs is the right one: work is issues with dependencies. Everything else should either reduce to that model or stay clearly outside the core.

### Doctor, Repair, Migration, And Legacy Support

These are support functions. Some are essential because users have real data and old installs. But they are not the product promise. Their APIs should be conservative, and their documentation should make clear when they are emergency or maintenance tools.

### Packaging, Website, Release Plumbing

The website, npm package, release scripts, Nix/Homebrew/Winget-style packaging, and install scripts matter for adoption. They are secondary to the issue graph and should not consume architectural attention unless they block users from installing a working `bd`.

### Legacy SQLite, RPC, Daemon, And Old Path References

References to old or absent architecture are implementation drift. Even if compatibility code remains somewhere, stale docs should be cleaned aggressively because they confuse contributors about the current design.

## Friction And Balance Risks

### Schema Accretion

The biggest product risk is first-classing every workflow concept. Each new issue column, built-in type, or public flag makes Beads less adaptable, not more, because it turns local policy into global compatibility debt.

Recommended rule: if a concept is not required for issue identity, lifecycle, dependency readiness, human/agent handoff, sync, or recovery, it should start in metadata or an external layer.

### CLI Sprawl

The command set is now large enough that discoverability itself is a problem. More commands do not automatically make Beads more powerful. They can make the core harder to find.

Maintainers should define command tiers:

- core,
- advanced,
- integration,
- maintenance,
- experimental or deprecated.

Help output should make those tiers clear. The existence of a command should not imply it is part of the stable core.

### Storage Complexity

Embedded Dolt, server Dolt, shared server, proxied server, UnitOfWork, migrations, schema gates, locks, and retry classification all carry real cost.

Recommended direction:

- pick one target storage architecture,
- document it as canonical,
- route new feature work through it,
- freeze old interfaces except for bug fixes,
- move Dolt-specific repair behavior behind narrow adapters where possible.

### Documentation Drift

The project has many docs, but not all are equally current. Stale architecture docs create bad maintenance decisions.

Recommended direction:

- add a doc freshness audit to release or preflight work,
- mark historical docs explicitly,
- remove obsolete SQLite/RPC/daemon guidance,
- keep one concise architecture page current,
- link from older docs back to the current source of truth.

### Test Surface Ambiguity

The codebase has many tests, but the operational question is: what proves a change is safe?

Recommended direction:

- define a canonical local PR gate,
- define storage-sensitive and release gates,
- make CI call the same wrappers,
- make skipped tests explicit and owned,
- add hot-path performance checks for large graphs.

### Vocabulary Load

Chemistry-inspired terms and agent-specific terms can be memorable, but they also raise the cost of entry. "Issue graph" and "ready work" are clearer than most special vocabulary.

Recommended direction: lead with plain issue/dependency language. Keep specialized vocabulary as aliases or advanced concepts, not as prerequisites for understanding the system.

### Orchestration Leakage

Fields and commands related to gates, swarms, formulas, roles, rigs, agent hints, and event/message flows can pull Beads toward being an agent orchestration framework.

That may be tempting because Beads sits at the exact point where orchestration wants durable state. But the charter is right: Beads should provide the work graph and metadata; orchestrators should consume it.

## Maintainer Direction

### 1. Define The Non-Negotiable Core

Maintain a short list of core surfaces:

- issue create/show/list/search/update/close,
- dependency add/remove/query,
- ready/blocked/claim,
- labels/comments/events,
- metadata,
- init/bootstrap/prime,
- sync/backup/restore,
- doctor for recovery.

Everything else should be classified as advanced, integration, support, or experimental.

### 2. Use A Core-Charter Gate For New Work

For every feature PR, require a short answer:

- Is this issue-tracking core?
- Is this storage/recovery support?
- Is this an integration bridge?
- Is this orchestration policy?
- Can this live in metadata?
- Does this require schema?

This does not need bureaucracy. It needs a lightweight habit that keeps Beads from absorbing every adjacent workflow.

### 3. Freeze Schema Expansion By Default

Do not add issue columns for new workflow concepts unless the feature cannot be implemented correctly with metadata and existing graph semantics.

For existing non-core fields, do not rush removal. Instead:

- document which are core and which are legacy/advanced,
- stop increasing their blast radius,
- consider migration-to-metadata only when it reduces real complexity.

### 4. Consolidate Storage Architecture

Choose and document the intended storage path. If UnitOfWork/domain layering is the future, make that explicit and route new changes through it. If not, explain why.

Avoid expanding old interfaces simply because they are nearby. The storage layer already has enough compatibility pressure.

### 5. Make Hot Paths Measurable

Add or strengthen performance/correctness checks for:

- `ready`,
- `ready --claim`,
- `show --json`,
- dependency mutation,
- blocked recomputation,
- create/update/close,
- bootstrap/sync recovery.

Use realistic large graphs. A dependency-aware issue tracker must remain calm at thousands or tens of thousands of issues.

### 6. Simplify The Newcomer Story

The first-page explanation should be:

1. Beads stores work as issues.
2. Dependencies determine what is ready.
3. Dolt makes the graph local, durable, and syncable.
4. Agents use JSON and `bd prime`.
5. Workflow-specific policy belongs in metadata or external tools.

Do not lead with every advanced feature. Make the core obvious first.

### 7. Treat Integrations As Imports, Exports, And Correlations

Keep integration scope narrow:

- import issues,
- link external refs,
- export or comment when explicitly asked,
- detect drift,
- preserve attribution.

Avoid full remote tracker replication unless maintainers intentionally choose to make Beads a different product.

### 8. Repair Documentation As Architecture Work

Fix stale docs with the same seriousness as stale code. The highest priority cleanup:

- remove or mark SQLite-era guidance,
- remove or mark obsolete RPC/daemon references,
- update architecture paths,
- update adaptive ID references,
- make the testing contract current and canonical.

### 9. Keep Recovery Tools, But Do Not Let Them Set The Product Shape

Doctor and repair commands should remain excellent. But they should not normalize fragile internal states. If a recurring repair is needed often, treat it as evidence of an invariant problem.

## Bottom Line

Beads has a strong center: a durable, local-first issue graph with dependency-aware readiness and an agent-friendly CLI. That center is worth protecting. It is useful, differentiated, and technically substantial.

The main weakness is gravitational pull from adjacent systems. The project is close enough to agent orchestration, tracker integration, local database administration, and workflow automation that it can accidentally become all of them. If that happens, the core will become harder to trust and harder to explain.

The healthiest future for Beads is disciplined:

- keep the issue graph small and sharp,
- keep Dolt integration reliable but contained,
- keep metadata as the extension path,
- keep integrations bridge-like,
- keep docs honest,
- measure the hot paths,
- resist schema and command sprawl.

If maintainers do that, Beads can remain what it is best positioned to be: the dependable work-state substrate for humans and agents sharing software projects.
