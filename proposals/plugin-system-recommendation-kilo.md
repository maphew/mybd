# Recommendation: Beads Plugin Architecture

> Companion proposal to `plugin-system.md`
> Status: recommendation draft for council deliberation
> Date: 2026-05-18
> Author: Kilo Code
> Signature: _kilocode-openai/gpt-5.5-xhigh on behalf of maphew_

## Purpose

This document is a second proposal, not a rewrite of `plugin-system.md`.

It treats the existing plugin-system draft as useful back-of-napkin design input, but not as steering. The goal here is to recommend a lower-maintenance architecture based on battle-tested plugin systems, especially VS Code, Terraform providers, Git-style executable plugins, and language-server-style protocols.

The central recommendation is conservative:

```text
Manifest first.
Lazy activation.
External provider processes first.
Small versioned protocols.
Strong diagnostics.
Declarative packs where code is unnecessary.
WASM automation later, only if hooks justify it.
```

## Executive Summary

Beads should adopt a plugin architecture based on the most proven parts of Git, Terraform, VS Code, Kubernetes-style tooling, and language-server ecosystems:

1. **Manifest-declared plugins** with explicit contribution points, activation events, protocol versions, and requested permissions.
2. **External provider processes** for service integrations such as Jira, Linear, GitHub, GitLab, Azure DevOps, Notion, and future trackers.
3. **Lazy activation** so normal `bd` startup reads only local metadata and does not execute plugin code.
4. **Host-owned extension surfaces** so plugins contribute to well-defined places instead of mutating internals.
5. **Digest-pinned installation** with clear enable, disable, update, remove, logs, and doctor commands.
6. **Declarative extension formats** wherever code is unnecessary.
7. **Sandboxed automation**, likely WASM, only after the provider path is proven and only for hooks/transforms where arbitrary executable scripts are currently the problem.

The recommended first release should be intentionally narrow: **provider plugins only**, plus enough manifest, trust, diagnostics, and conformance tooling to make one extracted tracker integration reliable. A plugin ecosystem is more likely to survive if the initial boundary is boring, explainable, and enforced than if Beads tries to support every extension shape at once.

## Design Goal

The goal is not maximum extensibility. The goal is **low-maintenance extensibility**.

Beads should make it possible for third parties and AI agents to add integrations without forking the core repository, while preserving the qualities that make a local CLI trustworthy:

- Fast startup.
- Predictable behavior.
- Static Go binary distribution.
- Clear failure modes.
- Explicit credential handling.
- Small public APIs.
- Minimal maintainer burden.

The plugin system should be explainable in one paragraph:

> A Beads plugin is an explicitly installed package with a manifest. The manifest declares what the plugin contributes, when it runs, which protocol it speaks, and which permissions it needs. Beads verifies the plugin before execution, starts it only when needed, and exposes plugin functionality through stable host-owned interfaces.

## Non-Goals

These should stay out of the first plugin architecture unless a later design proves otherwise.

- **No native Go dynamic plugins.** The Go `plugin` package is not portable, complicates static distribution, and creates version-coupling problems.
- **No arbitrary mutation of internal state.** Plugins should not receive a general `App`, `Store`, `RootCommand`, or service-locator object.
- **No implicit `PATH` discovery as the primary mechanism.** Executable plugins are a good primitive; ambient discovery is not a good security model for a CLI handling credentials.
- **No storage plugins in the first design.** Storage is a hot data plane with migration and performance consequences. Keep it in-tree.
- **No marketplace requirement for v1.** A registry or curated index can come later. The first system should work with local paths, explicit URLs, and checked-in project locks.
- **No broad plugin SDK before the protocol stabilizes.** Start with schemas, conformance tests, and examples. Add SDKs only after the boundary has survived real usage.

## What Successful Plugin Systems Teach Us

### VS Code

VS Code feels solid as a consumer because it combines declarative metadata, lazy activation, stable contribution points, diagnostics, and easy install/update UX.

The lessons Beads should copy:

- Put as much as possible in a manifest.
- Let the host know what a plugin contributes without executing plugin code.
- Activate plugins only on specific events.
- Keep contribution points host-owned.
- Provide excellent plugin diagnostics.
- Let users disable plugins globally or per workspace/project.
- Treat compatibility and deprecation as product features.

The lesson Beads should not copy directly:

- Desktop VS Code extensions are not a strong capability sandbox. Beads should use stricter defaults because it handles local repositories, tracker credentials, and AI-agent workflows.

### Terraform Providers

Terraform is the closest Go-native precedent for service integrations. Providers are external processes with versioned protocols, independent release cadence, and conformance expectations.

The lessons Beads should copy:

- Integrations should live behind external provider processes.
- The host should own orchestration and state transitions.
- Providers should expose schemas and capabilities.
- Protocol compatibility needs first-class versioning.
- Provider failures need named, actionable diagnostics.

The lesson Beads should avoid:

- Terraform-scale provider SDK and registry machinery is too heavy for Beads v1.

### Git, kubectl, Docker, and Helm

These systems prove the value of executable plugin primitives: any language can participate, crashes are isolated, and the mental model is simple.

The lessons Beads should copy:

- Plugins should be ordinary artifacts that can be built, tested, signed, and run outside the host.
- Stdin/stdout/stderr, exit codes, and logs are useful operational boundaries.
- A plugin should be debuggable without embedding into Beads.

The lesson Beads should avoid:

- Ambient executable discovery invites path hijacking and inconsistent UX.

### Language Server Protocol and Debug Adapter Protocol

LSP and DAP demonstrate that complex tool integrations can work well when the protocol is small enough, versioned, and domain-shaped.

The lessons Beads should copy:

- Prefer a small protocol over a large in-process API.
- Keep the host model stable even as individual integrations vary.
- Use request/response plus notifications where needed.
- Build conformance tests around protocol behavior rather than implementation details.

## Recommended Architecture

### Core Concept: Manifest First

Every plugin should have a manifest that Beads can read without executing plugin code.

The manifest should declare:

- Stable plugin ID.
- Human name and description.
- Version.
- Artifact digest.
- Plugin kind.
- Supported Beads plugin API version.
- Runtime command or module entrypoint.
- Contribution points.
- Activation events.
- Requested permissions.
- Configuration schema.
- Minimum and maximum compatible Beads versions, if needed.

Example shape:

```json
{
  "id": "com.example.bd-notion",
  "name": "Notion",
  "version": "0.1.0",
  "kind": "provider",
  "api": "provider.tracker.v1",
  "entrypoint": {
    "type": "process",
    "command": "bd-notion-provider"
  },
  "contributes": {
    "trackers": [
      {
        "id": "notion",
        "displayName": "Notion",
        "capabilities": ["read", "write", "sync"]
      }
    ]
  },
  "activationEvents": ["onTracker:notion"],
  "permissions": [
    "env:NOTION_TOKEN",
    "network:api.notion.com"
  ],
  "configuration": {
    "database_id": {
      "type": "string",
      "required": true
    }
  }
}
```

This is the VS Code lesson: contribution metadata should be cheap, inspectable, and available before code runs.

### Plugin Kinds

The first design should define only one executable plugin kind:

- **Provider:** an external process that implements a Beads protocol for an integration domain.

Future plugin kinds may be added after the provider path is proven:

- **Automation:** a sandboxed module, likely WASM, for hooks, formatters, lint rules, and content transforms.
- **Pack:** a declarative content bundle for recipes, molecules, formulas, templates, or recommended configuration.

The naming should stay plain:

- Use `plugin` as the umbrella term.
- Use `provider` for service integrations.
- Use `automation` only if/when code-running hooks become a supported tier.
- Use `pack` for declarative content, not arbitrary code.

### Provider Plugins

Providers are the recommended first plugin surface.

Use providers for:

- Tracker integrations.
- External service integrations.
- Long-running or schema-rich API clients.
- Anything that may need its own dependencies, release cadence, or credentials.

Provider properties:

- Runs out of process.
- Communicates over a versioned protocol.
- Has explicit startup, request, idle, and shutdown timeouts.
- Receives only an allowlisted environment.
- Cannot mutate the Beads command tree at runtime.
- Cannot access storage directly.
- Returns domain-shaped responses, not arbitrary host internals.

The first provider API should be `provider.tracker.v1`.

It should be deliberately small:

- `handshake`
- `describe`
- `validateConfig`
- `listIssues`
- `getIssue`
- `createIssue`
- `updateIssue`
- `sync`, if Beads has a coherent tracker sync operation
- `shutdown`

The exact methods can change during implementation, but the principle should not: the protocol should describe tracker operations, not expose Beads internals.

### MCP, JSON-RPC, and go-plugin

MCP is vibrant and relevant to AI-agent workflows, but it should not be treated as the architectural foundation by default.

Recommended stance:

- Beads should define a small Beads provider contract.
- The transport can be MCP-compatible if that is useful.
- MCP should be an adapter or profile, not the domain model.
- A generic MCP server should not automatically become a trusted Beads tracker provider.

This keeps the door open to MCP ecosystem reuse without letting MCP protocol churn define Beads behavior.

If MCP proves unstable or too broad, a plain JSON-RPC protocol over stdio is likely sufficient for v1. If Beads later needs heavier bidirectional integration, HashiCorp `go-plugin` with gRPC remains a credible upgrade path for provider processes.

The protocol decision should be judged by implementation cost, conformance-test clarity, startup overhead, and compatibility stability, not by ecosystem fashion.

### Declarative Packs

Not everything should be a code plugin.

Recipes, molecules, formulas, templates, field mappings, report definitions, and recommended settings may be better as declarative packs.

Packs should be preferred when the extension can be represented as data:

- No subprocess.
- No permissions beyond file read of the installed artifact.
- Easy diffing and review.
- Easy project pinning.
- Easy AI generation and inspection.

This keeps the executable plugin surface smaller and safer.

### Automations and Hooks

Automation plugins should not be part of the first provider milestone unless hook security is urgent.

If Beads adds automations, the recommended runtime is WASM through a pure-Go runtime such as `wazero`, because it preserves static binary distribution and can provide a meaningful sandbox.

Use automations for:

- Lifecycle hooks.
- Formatters.
- Lint rules.
- Small content transforms.
- Policy checks.

Do not use automations for:

- Tracker integrations.
- Storage backends.
- Long-running services.
- Full CLI subcommand ecosystems.

Automation design principles:

- Default-deny capabilities.
- Small host-function surface.
- Per-plugin state namespace.
- Time and memory limits.
- Structured input/output.
- Clear migration path from unsafe executable hooks.

This should be a second design phase. Adding WASM at the same time as provider plugins creates two authoring stories, two runtime stories, and two diagnostic paths before either has proven itself.

## Command and CLI Integration

Beads should keep the command tree host-owned.

The host may expose plugin-related commands such as:

```text
bd plugin install
bd plugin list
bd plugin show
bd plugin enable
bd plugin disable
bd plugin remove
bd plugin update
bd plugin doctor
bd plugin logs
bd plugin audit
bd plugin trust
bd plugin untrust
```

Plugin-contributed commands should be declarative and constrained.

Recommended rules:

- Plugins may declare commands under plugin-owned namespaces.
- Plugins may not shadow core commands.
- Plugins may not mutate commands after root construction.
- Help text is generated from manifest metadata where possible.
- Invoking a plugin command activates only that plugin.

Example:

```text
bd notion sync
```

This command can exist because the Notion provider manifest declares it. The actual provider process starts only when the command is invoked.

## Activation Model

Activation should be explicit and lazy.

Supported activation events for v1 should be minimal:

- `onTracker:<id>`
- `onCommand:<command-id>`
- `onPluginDoctor:<plugin-id>`

Future events can include:

- `onHook:<event>`
- `onFormat:<format>`
- `workspaceContains:<path-pattern>`

Startup behavior should be:

1. Read project and user plugin metadata.
2. Verify lockfile records and manifest compatibility.
3. Build command/help surfaces from manifests.
4. Execute no plugin code unless the current command requires activation.

This is central to making the system feel solid.

## Trust and Permissions

Beads should use a stricter model than VS Code desktop extensions.

Recommended trust primitives:

- Installed plugins are recorded in a lockfile with content digests.
- Plugin execution requires a verified digest.
- Permissions are declared in the manifest.
- Sensitive permissions require explicit user or project grant.
- Environment variables are allowlisted.
- Network destinations are declared.
- File access is denied unless specifically granted for plugin kinds that support it.
- Install, grant, revoke, update, remove, and execute events are audit logged.

The UX must stay simple. A scary capability model that users cannot understand will not help.

Good prompt:

```text
The Notion plugin requests:

env:NOTION_TOKEN        Read your Notion API token
network:api.notion.com  Connect to Notion

Grant these permissions for this project? [y/N]
```

Bad prompt:

```text
Grant requested capabilities? [y/N]
```

The permission model should initially cover only what Beads can actually enforce. Do not declare unenforced permissions as security theater.

## Installation and Distribution

The first implementation should support explicit installation sources:

- Local directory or archive.
- Direct URL with digest.
- OCI artifact, if implementation cost is acceptable.
- GitHub release artifact, if that is simpler for early plugin authors.

Beads should not require a hosted marketplace for v1.

Recommended install behavior:

- Resolve artifact.
- Read manifest.
- Verify digest or require digest pinning before first execution.
- Store artifact in a user plugin cache.
- Record installed version and digest in a user lockfile.
- Optionally record project-required plugins in a project lockfile.

Project-level files should support team reproducibility:

```text
.beads/plugins.lock
.beads/plugins.recommended.json
```

The exact filenames can change, but the distinction matters:

- A lock says "this project uses this exact plugin artifact."
- A recommendation says "users working here may want this plugin."

## Diagnostics and Operability

Plugin systems fail in practice when they are hard to debug. Beads should treat diagnostics as part of the v1 feature, not polish.

Required diagnostics:

- `bd plugin doctor` checks manifests, digests, compatibility, permissions, config, executable presence, startup handshake, and provider health.
- `bd plugin logs <id>` shows recent provider stderr and host lifecycle events.
- `bd plugin audit` shows install, update, grant, revoke, enable, disable, and execution records.
- `bd --no-plugins ...` runs a command with plugins disabled.
- `bd plugin disable <id>` provides a fast escape hatch.

Provider errors should always name the plugin and phase:

```text
bd-notion failed during startup after 2s: missing env grant NOTION_TOKEN
```

Avoid generic errors:

```text
plugin failed
```

## Compatibility and Lifecycle

A plugin API is a maintenance promise. Keep it small.

Recommended compatibility rules:

- Version plugin APIs independently from the Beads CLI version.
- Use explicit API identifiers such as `provider.tracker.v1`.
- Require every provider to return its supported API version during handshake.
- Reject incompatible major versions with a clear error.
- Add fields compatibly where possible.
- Gate experimental APIs behind explicit manifest flags.
- Provide conformance tests for every stable API.

The conformance suite is more important than an SDK in v1.

Plugin authors should be able to run:

```text
bd plugin test-provider ./bd-notion-provider
```

or an equivalent command that verifies handshake, schema, error handling, and basic tracker operations against fixtures.

## Recommended Implementation Sequence

### Phase 1: Host Preparation

Refactor Beads so the command tree and dependencies are constructed explicitly rather than through global side effects.

Outcomes:

- Root command construction is deterministic.
- Plugin metadata can be included during construction.
- Plugins cannot mutate the command tree after construction.
- No user-visible behavior changes are required.

### Phase 2: Manifest, Lock, and Plugin Commands

Implement the local plugin management substrate before running third-party code.

Outcomes:

- Manifest schema.
- User plugin directory.
- User lockfile.
- Optional project lockfile.
- Install, list, show, enable, disable, remove, doctor, audit commands.
- Digest verification.
- Basic permission grants.

### Phase 3: Tracker Provider Protocol

Implement `provider.tracker.v1` with one transport.

Outcomes:

- Provider handshake.
- Describe/config validation.
- Issue read/write methods.
- Timeouts and cancellation.
- Env allowlist.
- Structured provider errors.
- Conformance test harness.

### Phase 4: One Real Pilot Provider

Extract exactly one existing tracker integration as the pilot.

Choose the pilot based on learning value, not easiest extraction.

Good candidates:

- **Notion** if the goal is lowest-risk extraction.
- **Linear or GitHub** if the goal is proving the provider surface under realistic usage.

The in-tree implementation should remain available during the pilot. Do not remove multiple integrations until install, diagnostics, compatibility, and support burden are understood.

### Phase 5: Decide on MCP Profile

After the pilot provider exists, decide whether the provider transport should be MCP-compatible, plain JSON-RPC, or `go-plugin`/gRPC.

This decision should be based on measured results:

- Startup overhead.
- Protocol clarity.
- Agent reuse.
- Compatibility stability.
- Implementation complexity.
- Quality of generated and handwritten plugin implementations.

### Phase 6: Automation Design, If Still Needed

Only after provider plugins are working should Beads design sandboxed automation.

Outcomes:

- Hook event schema.
- WASM runtime choice.
- Host functions.
- Permission model.
- Migration path from executable hooks.
- Time/memory limits.
- Automation conformance tests.

## Recommended First Public Milestone

The first milestone should not claim "Beads has plugins" broadly. It should claim:

> Beads supports experimental tracker provider plugins.

Acceptance criteria:

- Normal `bd` startup does not execute plugin code.
- One extracted provider passes the same behavioral tests as its in-tree predecessor.
- Plugin install/list/show/disable/remove/doctor work locally.
- Provider startup and request timeouts are enforced.
- Provider environment is allowlisted.
- Provider errors identify plugin, operation, and phase.
- Plugin API version compatibility is checked.
- Conformance tests exist for the provider protocol.
- The user can run Beads with plugins disabled.

This is enough to validate the architecture without committing to a full ecosystem.

## Risks and Mitigations

### Risk: too much architecture before proof

Mitigation: ship provider plugins first. Delay WASM automation, hosted index, cosign requirement, and storage extensibility.

### Risk: MCP churn leaks into Beads

Mitigation: define a Beads provider contract. Treat MCP as a possible transport/profile, not the domain API.

### Risk: plugin UX becomes security theater

Mitigation: only prompt for permissions Beads can enforce. Keep grants concrete and human-readable.

### Risk: third-party plugins become support burden

Mitigation: conformance tests, `doctor`, compatibility checks, structured errors, and a narrow API.

### Risk: startup becomes slow

Mitigation: manifest-only startup, no plugin execution during help/list/basic commands, benchmark gates.

### Risk: in-tree integrations and provider integrations diverge

Mitigation: use shared behavioral test suites and extract only one pilot before expanding.

## Decisions to Make Before Implementation

The following decisions should be made before code begins:

1. Which tracker is the pilot provider?
2. Is v1 transport plain JSON-RPC over stdio, MCP-compatible stdio, or `go-plugin`/gRPC?
3. What is the exact `provider.tracker.v1` method set?
4. Which permissions can Beads genuinely enforce in v1?
5. What is the minimum local install source: directory, archive, URL, OCI, or GitHub release?
6. What project-level files should be committed for locks and recommendations?
7. What startup overhead budget is acceptable with 0, 10, and 100 installed plugins?

## Final Recommendation

Beads should build a plugin system around a small, conservative core:

```text
Manifest first.
Lazy activation.
External provider processes.
Explicit install and digest pinning.
Small versioned protocols.
Strong diagnostics.
Declarative packs where code is unnecessary.
WASM automation later, only if hooks justify it.
```

This borrows the parts of VS Code that users experience as solid, the provider isolation model that Terraform proved in Go, and the operational simplicity of executable plugin systems. It avoids the fragile parts: native Go plugins, ambient discovery, broad host APIs, premature marketplaces, and multiple plugin paradigms before the first one works.

The first credible Beads plugin system should be boring on purpose. If one extracted tracker provider can be installed, verified, diagnosed, disabled, and run without slowing normal CLI usage, Beads will have a foundation worth expanding.
