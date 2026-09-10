> Historical document recovered on 2026-09-10 from source branch codex-architecture-analysis, commit 62522ff4b53a175e14c60337881160f838149479. Original author: matt wilkie; agent signature: codex-unknown-model-unknown-reasoning. This June 22 analysis predates the maintainer step-down and is not current policy or an active task plan. Markdown trailing whitespace was normalized.

# Beads Phase 2 Maintainer Roadmap

Date: 2026-06-22

Scope: This roadmap converts `reports/beads-project-analysis-2026-06-22.md` into an action plan for Beads maintainers. It is not implementation of the roadmap and does not create `bd` issues yet.

## Executive Summary

Phase 2 should protect the thing Beads already does best: a durable, local-first issue graph with dependency-aware readiness and an agent-friendly CLI.

The project is close to that center in the core paths. The risk is that adjacent systems keep pulling the product outward: orchestration behavior, schema expansion, command sprawl, integration scope, storage repair work, and stale architecture docs.

The next phase should not be a broad feature push. It should be a tightening pass:

- define the non-negotiable core,
- tier the public CLI surface,
- stop first-classing workflow policy in schema by default,
- choose the canonical storage path,
- measure hot paths,
- repair stale docs,
- keep integrations as bridges,
- make advanced vocabulary optional.

## Success Criteria

Phase 2 is successful when maintainers can answer these questions without debate or archaeology:

- Which commands and data fields are core product surface?
- Which commands are advanced, integration, maintenance, or experimental?
- When is a schema change acceptable, and when should metadata be used instead?
- Which storage architecture should new work extend?
- Which local checks prove the issue-graph hot paths are still safe?
- Which docs are current sources of truth?
- What must integrations not become?

## Work Package 1: Core Contract

### Intended Outcome

Beads has a short, explicit core contract that maintainers can use to accept, reject, or redirect new work.

The core contract should say that Beads owns:

- issue identity and lifecycle,
- dependency edges and readiness,
- ready/blocked/claim semantics,
- labels,
- comments,
- events or audit history,
- metadata,
- workspace init/bootstrap/prime,
- sync/backup/restore,
- recovery tooling for Beads state.

### Maintainer Actions

- Add a concise "Core Contract" section to the charter or a linked architecture note.
- Define the minimum stable CLI set around create, show, list/search, update, close, ready, dependency operations, label/comment operations, init/bootstrap/prime, sync/backup/restore, and doctor/recovery.
- State that workflow scheduling, agent routing, model choice, retry policy, cross-system orchestration, and full project-management behavior are outside core.
- Add a short PR-review checklist item: "Is this core, metadata, integration, maintenance, or external orchestration?"

### Acceptance Criteria

- A maintainer can classify a proposed feature into one of the core/non-core categories in under a minute.
- The charter clearly says what Beads owns and what it intentionally does not own.
- New feature discussions can cite the core contract instead of re-arguing product boundaries.

### Non-Goals

- Do not remove existing features in this work package.
- Do not rename public commands yet.
- Do not create a governance process heavier than a short checklist.

## Work Package 2: CLI Surface Tiers

### Intended Outcome

Users and contributors can tell which commands are stable core surface and which are advanced, integration, maintenance, experimental, or legacy.

### Maintainer Actions

- Define command tiers:
  - Core: ordinary issue-graph workflows.
  - Advanced: useful but specialized graph/workflow operations.
  - Integration: external tracker bridges and correlation tools.
  - Maintenance: doctor, migration, repair, backup, restore, and support commands.
  - Experimental or deprecated: surfaces that should not shape new product work.
- Update help text and docs to reflect tiers without breaking command names.
- Mark high-risk exploratory commands clearly before adding new behavior to them.
- Prefer improving discoverability over adding new top-level commands.

### Acceptance Criteria

- `bd --help` and docs make the core work loop visually obvious.
- Maintenance and experimental commands no longer appear to have the same product status as core commands.
- Contributors know where a new command belongs before implementing it.

### Non-Goals

- Do not delete commands as part of the first tiering pass.
- Do not make backward-incompatible CLI changes.
- Do not hide emergency recovery commands from users who need them.

## Work Package 3: Schema And Metadata Policy

### Intended Outcome

Schema growth slows down. Workflow-specific policy moves to metadata unless it is required for issue identity, lifecycle, dependency readiness, handoff, sync, or recovery.

### Maintainer Actions

- Add a schema-change policy to the architecture or metadata docs.
- Require every new issue column, dependency column, built-in type, or status to justify why metadata is insufficient.
- Classify existing non-core fields as core, advanced, legacy, or internal.
- Prefer metadata keys for agent execution hints, local workflow policy, routing hints, and integration-specific state.
- Avoid migrating existing fields immediately unless a migration removes real complexity and has a clear compatibility path.

### Acceptance Criteria

- New schema PRs include a short metadata-vs-schema justification.
- The metadata docs become the default extension guide for workflow policy.
- Existing non-core fields are documented as such, even if they remain in place.

### Non-Goals

- Do not attempt a broad schema cleanup before the policy is documented.
- Do not break existing databases for conceptual purity.
- Do not move hot-path readiness data to metadata when typed columns are required for correctness or performance.

## Work Package 4: Storage Architecture Consolidation

### Intended Outcome

Maintainers know which storage path is canonical for new work, and older paths stop expanding except for compatibility fixes.

### Maintainer Actions

- Decide whether the newer UnitOfWork/domain path is the target architecture.
- Document the intended storage stack in one current architecture page.
- Mark older storage interfaces as compatibility surfaces if they are not the target.
- Route new feature work through the canonical write/read path.
- Keep Dolt-specific repair and migration behavior behind narrow adapters where possible.
- Track duplicated ID/adaptive-length logic and choose one owner for future changes.

### Acceptance Criteria

- A contributor changing create/update/ready behavior knows the correct storage layer to edit.
- Docs no longer imply multiple equal architectures without explaining why.
- New storage-sensitive work does not expand legacy interfaces unless required for compatibility.

### Non-Goals

- Do not rewrite storage wholesale in Phase 2.
- Do not remove embedded or server mode support.
- Do not weaken migration, backup, restore, or doctor behavior.

## Work Package 5: Hot-Path Quality Gates

### Intended Outcome

The most important issue-graph paths are measured and protected by repeatable checks.

### Maintainer Actions

- Define a small hot-path suite for:
  - `ready`,
  - `ready --claim`,
  - `show --json`,
  - dependency add/remove,
  - blocked-state recomputation,
  - create/update/close,
  - bootstrap/sync recovery.
- Use realistic generated graphs with thousands of issues and dependencies.
- Track both correctness and rough performance envelopes.
- Make the hot-path suite part of the documented local gate for storage or query changes.
- Keep output stable enough that agents can depend on JSON shape.

### Acceptance Criteria

- There is a documented command or script for hot-path validation.
- Storage/query PRs know when the hot-path suite is required.
- A regression in ready/blocked/claim behavior is caught before release.

### Non-Goals

- Do not make every PR run the slowest suite.
- Do not block small doc-only or packaging-only changes on heavy graph tests.
- Do not optimize before correctness and repeatability are in place.

## Work Package 6: Documentation Repair

### Intended Outcome

Architecture and testing docs stop misleading contributors with stale SQLite-era, RPC-era, daemon, adaptive-ID, or test-contract references.

### Maintainer Actions

- Audit architecture docs for paths and concepts that no longer match current code.
- Mark historical docs explicitly or remove obsolete guidance.
- Update the adaptive ID documentation to point at current code owners.
- Make the testing guide the canonical source for local, CI, release, integration, and storage-sensitive checks.
- Add a lightweight doc-freshness step to release or preflight work.

### Acceptance Criteria

- Current architecture docs describe the actual Dolt-backed implementation.
- SQLite-era and absent RPC/daemon references are removed or marked historical.
- The testing contract tells contributors which checks to run for ordinary, storage-sensitive, integration, and release work.

### Non-Goals

- Do not write exhaustive internals documentation for every package.
- Do not preserve stale docs simply because they may be historically interesting.
- Do not let docs cleanup block urgent correctness fixes.

## Work Package 7: Integration Boundaries

### Intended Outcome

Integrations remain adoption bridges rather than becoming a second project-management platform.

### Maintainer Actions

- Reaffirm the integration charter in contributor docs.
- Keep integration scope to import, export, external references, attribution, explicit comments, and drift checks.
- Avoid full webhook orchestration, full comment mirroring, attachment stores, credential vaults, or UI parity with remote trackers.
- Prefer metadata for integration-specific state.
- Require new integration features to state the remote tracker behavior they intentionally do not implement.

### Acceptance Criteria

- Integration PRs can be reviewed against a clear boundary.
- Beads remains useful without any external tracker configured.
- External tracker behavior does not leak into core issue lifecycle semantics.

### Non-Goals

- Do not remove useful existing bridges.
- Do not make Beads depend on hosted tracker availability for local issue work.
- Do not turn drift detection into automatic cross-system orchestration.

## Work Package 8: Product Language And Advanced Concepts

### Intended Outcome

The project leads with plain issue-graph language. Advanced vocabulary stays available but no longer obscures the core model.

### Maintainer Actions

- Update overview docs to lead with issues, dependencies, ready work, and metadata.
- Treat molecule, wisp, gate, formula, swarm, and mail vocabulary as advanced or layered concepts.
- Make docs explain how advanced concepts reduce to the issue/dependency graph where possible.
- Avoid introducing new metaphor-heavy terms for core behavior.

### Acceptance Criteria

- A new user can understand the core product without learning advanced vocabulary.
- Advanced docs clearly say when a concept is optional.
- Product language reinforces that Beads is an issue graph, not an orchestrator.

### Non-Goals

- Do not rename existing concepts immediately.
- Do not remove advanced workflows that are actively used.
- Do not flatten useful domain concepts into vague generic terms when they clarify behavior.

## Recommended Execution Order

1. Core Contract.
2. Schema And Metadata Policy.
3. Storage Architecture Consolidation.
4. Documentation Repair.
5. CLI Surface Tiers.
6. Hot-Path Quality Gates.
7. Integration Boundaries.
8. Product Language And Advanced Concepts.

The first three work packages should happen early because they constrain the rest. Documentation repair should follow quickly so contributors stop working from stale maps. CLI tiering and hot-path gates can proceed in parallel once the core contract is explicit.

## First Follow-Up Issues To File

When maintainers are ready to turn this roadmap into `bd` issues, file one issue per work package. Suggested initial titles:

- Define Beads core contract and PR classification checklist
- Document schema-vs-metadata policy
- Choose and document canonical storage architecture
- Repair stale architecture and testing docs
- Tier CLI commands by product surface
- Add hot-path validation suite for ready/show/dependency paths
- Reaffirm integration boundaries in contributor docs
- Recenter overview docs on issue graph language

## Final Guidance

Phase 2 should be judged by whether it makes future decisions easier. The best outcome is not a larger Beads. It is a Beads whose core is easier to protect, whose extension points are clearer, and whose maintainers can say no to attractive adjacent work without losing confidence in the product.
