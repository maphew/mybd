# Independent Review: Plugin System for Beads

Date: 2026-05-20
Reviewer: Codex GPT-5.5
Scope: `proposals/plugin-system.md` only. I did not read or rely on sibling `plugin-system-*.md` files in `proposals/`.

## Verdict

The proposal is directionally right: Beads should move tracker integrations and unsafe local automation behind explicit extension boundaries, and the three strongest principles are the right ones: no implicit PATH discovery, storage stays in-tree, and no plugin runs without a recorded trust decision.

I would not approve this as a v0.1 implementation plan yet. It combines too many large changes into one architecture: Cobra construction refactor, trust and grants, OCI distribution, MCP tracker providers, Notion extraction, WASM automation, hook deprecation, and AI provenance wrapping. Several of those are good ideas, but the current document underspecifies the contracts that would keep them safe and compatible with today's Beads code.

My recommendation is: approve an exploration/pilot, not the full architecture. Start with a root command factory plus a local-only MCP tracker provider pilot behind an experimental flag. Defer WASM automations, OCI distribution, curated index, and default JSON envelope changes until the provider contract has survived one real tracker.

## What Looks Strong

- The proposal correctly identifies the current extension pressure points: global `rootCmd` plus `init()` registration in `cmd/bd`, global tracker registration in `internal/tracker/registry.go`, executable `.beads/hooks/on_*` hooks, and tracker-specific command code.
- Keeping storage out of the plugin data plane is the right default. The storage interface is broad and hot, and the project charter explicitly warns against turning Beads into a storage engine or leaking storage internals.
- Rejecting implicit PATH discovery is correct. Beads handles tracker credentials and local database state; PATH auto-discovery would make command execution too ambient.
- Digest pinning as a non-optional trust primitive is the right bar.
- Using one pilot tracker is the right migration shape. Extracting all trackers at once would be too much risk.

## Required Changes Before Approval

### 1. Split The Proposal Into Smaller Approval Units

The current proposal is a program, not a design slice. The smallest credible slice should be:

1. `NewRootCmd` / explicit command construction, no plugin behavior.
2. A typed provider protocol and host adapter, local development install only.
3. One tracker pilot using that protocol.
4. Trust/distribution hardening after the protocol is proven.
5. Automations as a separate ADR.

This matters because each layer changes a different risk surface. A Cobra factory is a testability and construction refactor. MCP providers are a compatibility and latency problem. WASM automations are a sandbox and binary-size problem. OCI/cosign is supply-chain infrastructure. Combining them makes it too easy to approve unresolved details by association.

### 2. The MCP Provider Contract Is Not Specified Enough

The proposal says `internal/tracker/mcp_adapter.go` can wrap an MCP client behind `tracker.IssueTracker`, but today's interface is not a wire contract:

- `TrackerIssue.Raw interface{}` and `FieldMapper` methods use Go-native `interface{}` shapes.
- The sync engine relies on optional Go interfaces: `BatchPushTracker`, `BatchPushDryRunner`, and `PullStatsProvider`.
- Commands add tracker-specific hooks outside the tracker implementation, such as Notion push filtering, GitHub/GitLab ID generation, ADO link reconciliation, and Linear sync locking/staleness behavior.
- Errors, warnings, dry-run previews, conflict metadata, rate limits, and partial batch failures all need stable schemas.

Before implementation, define a provider protocol with explicit methods, JSON schemas, capability negotiation, error classes, timeout behavior, and compatibility rules. Do not treat `IssueTracker` as the external ABI; treat it as the host-side adapter target.

### 3. Command Plugins Are Ambiguous

The document says there are exactly two paradigms, Providers and Automations, but also says "plugin subcommands resolved at construction" and "The Cobra command tree" is not a plugin. Those statements conflict.

If third parties can contribute CLI commands, that is a third extension surface and needs its own contract: help text, flags, completions, `--json`, output provenance, command shadowing, config access, and trust prompts. If third parties cannot contribute commands, the proposal should say so explicitly and keep plugin UX under built-in `bd plugin ...` plus built-in tracker command shims.

For v0.1, I recommend no third-party Cobra command contribution. Keep `bd jira`, `bd notion`, etc. as host-owned commands that call provider capabilities.

### 4. WASM Automations Need A Separate Justification

The automation tier is plausible, but not ready to ship in this proposal. Beads previously removed the wazero WASM runtime for performance and distribution reasons; the changelog records binary size dropping from 168 MB to about 41 MB and a Linux/Windows startup penalty being eliminated after dropping `dolthub/driver` and wazero. Reintroducing wazero/Extism needs fresh measurements and a stronger reason than "hooks should be safer."

The legacy hook system is small, understandable, and already has platform-specific timeout/process handling. Replacing executable hooks with WASM changes authoring, debugging, filesystem access, process execution, shell integration, Windows `.bat` workflows, and migration behavior.

Recommendation: remove WASM automations from the provider v0.1 path. Write a separate automation ADR with measured binary size, cold start, memory, authoring UX, migration tooling, and compatibility targets.

### 5. The Trust Layer Needs A More Precise Model

The proposed trust layer has the right intent, but important details are missing:

- How global `~/.beads/plugins/lock.json` and project `.beads/plugins.lock` compose when they disagree.
- Whether grants are per digest, per package identity, per version, per project, or per user.
- What happens on plugin update: do grants carry forward, narrow automatically, or require review of changed capabilities?
- How non-interactive agents and CI behave when a first-use prompt is required.
- How local development plugins get pinned without weakening the "no digest, no execution" rule.
- How audit logs are protected from local tampering, truncation, or accidental deletion.
- How capability names map to real enforcement for env, network, filesystem, host functions, and tracker writes.

The capability vocabulary also needs to be narrower. For example, `env:JIRA_TOKEN` is not enough if the plugin can also request broad network or filesystem access. Network grants should be host-scoped, normalized, and resistant to DNS/symlink/path bypasses. Filesystem grants need path normalization and symlink rules.

### 6. OCI Distribution Is Premature For The First Slice

OCI artifacts may be a good long-term distribution story, but making OCI mandatory in v0.1 adds registry auth, ORAS behavior, offline installs, cache layout, signature UX, and dependency surface before the provider ABI is proven.

Start with local folder installs and explicit digest-pinned GitHub release assets. Add OCI once the manifest, lockfile, and update model have real users. Cosign should be required for official/curated plugins before it is required for every hobbyist plugin.

### 7. The Performance Gates Need Baselines And Cold/Warm Separation

The proposed gates are good instincts, but not yet enforceable:

- "MCP tracker fetch p95 overhead under +50 ms" is likely unrealistic for cold Python/Node providers.
- The proposal itself notes startup tax may be 100-300 ms, so the success criteria should distinguish cold start, warm long-lived process, and no-plugin CLI startup.
- Plugin scan time should be lazy and command-sensitive; ordinary `bd ready` should not pay provider discovery unless it needs plugins.
- WASM memory and instantiation targets should be measured against the current binary without reintroducing the previous startup penalty.

The v0.1 benchmark suite should first establish current baselines for no-plugin startup, `bd --help`, representative read commands, and a local fake provider.

### 8. The Notion Pilot Is More Complex Than The Proposal Implies

Notion is a reasonable pilot because it is smaller than Linear/ADO, but it is not a trivial extraction:

- `cmd/bd/notion.go` has host command behavior for `init`, `connect`, `status`, JSON output, config persistence, auth resolution, and sync rendering.
- `runNotionSync` creates host-side pull/push hooks and filtering outside the tracker.
- `internal/notion.Tracker` depends on store config, environment fallback, local issue indexes, batch push, and Notion-specific unsupported-type filtering.
- Existing tests will not remain "unchanged" if the behavior moves out of process. They need either a provider test harness or a host/provider contract test suite.

Use Notion if the goal is to prove a smaller tracker extraction. Use GitHub or Linear if the goal is to stress a more common provider contract. I would still start with Notion, but only after the protocol contract is explicit.

### 9. Always Wrapping `--json` Plugin Output Is A Breaking Change

The provenance envelope is useful for AI-facing surfaces, but applying it to all `bd --json` output would break existing scripts and MCP consumers that parse stable command JSON.

Recommendation: wrap plugin-origin data at trust boundaries, not every command by default. Options:

- Add `--json-envelope` or a versioned output mode.
- Wrap only MCP/tool output.
- Include provenance fields inside plugin-specific result objects where backwards compatibility permits.

If the proposal wants "always wrap," it needs a versioned JSON-output migration plan.

### 10. Threat Modeling Should Precede Implementation

The proposal lists many good controls, but it still needs a concrete threat model before execution:

- Malicious provider exfiltrates granted tracker tokens.
- Compromised plugin update expands capabilities.
- Plugin output injects instructions into agent context.
- Local plugin path changes between hash verification and execution.
- WASM host function mutates issues beyond the user's intent.
- Filesystem/network grants are bypassed through symlinks, redirects, DNS, or child processes.
- Audit logs are deleted or rewritten.

The trust layer should be tested with hostile fixture plugins from day one.

## Answers To The Proposal's Specific Questions

1. **Storage non-goal:** keep storage in-tree for v1. Mention a future storage-provider possibility only as an explicit non-goal, not as a promised extension point.
2. **Bundled vs plugin from day one:** keep current trackers bundled through v1. Do not drop any until install/update/recovery UX is proven.
3. **Hook breaking change appetite:** the aggressive hook break is too risky. Ship WASM automations separately, keep legacy hooks working through a migration window, and warn loudly before changing defaults.
4. **Naming:** `provider`, `automation`, and umbrella `plugin` are acceptable. Avoid saying command-tree contribution is a plugin unless it gets a real contract.
5. **Distribution:** digest pinning from day one; cosign required for official/curated plugins first, optional with warning for local/community plugins until the ecosystem matures.
6. **Hosted plugin index:** defer to v1.x. A curated index is useful only after install/update/trust semantics settle.
7. **Provenance envelope:** do not always wrap existing `--json` by default. Use an opt-in/versioned envelope or wrap only MCP/AI-facing plugin output.
8. **Quickstart UX:** make `bd plugin quickstart` built-in. It should work before any plugin system feature is already trusted.

## Recommended Revised Plan

1. Refactor command construction into `NewRootCmd` and explicit command constructors. Keep behavior identical and update in-process tests that currently mutate global `rootCmd`.
2. Introduce a non-executing plugin manifest parser, lockfile model, and doctor checks. No subprocess launch yet.
3. Define the provider protocol as a versioned schema, including optional capabilities for batch push, dry-run, stats, warnings, and tracker-specific config discovery.
4. Build a fake local provider test harness and benchmark cold/warm startup separately.
5. Extract Notion as an experimental local provider behind `BEADS_EXPERIMENTAL_MCP_TRACKERS=1` or equivalent. Keep the built-in Notion implementation as the normal path.
6. After parity and latency are acceptable, add trust prompts and digest-pinned installs.
7. Add OCI and a curated index only after one provider has shipped successfully outside the tree.
8. Revisit WASM automations in a separate ADR with measured binary/startup impact and hook migration details.

## Final Assessment

The architecture is promising but too broad and too optimistic as written. The provider direction is worth pursuing; the trust principles are sound; storage should remain in-tree. The proposal needs a sharper external provider ABI, a less ambitious first slice, and a separate decision process for WASM automations and OCI distribution.

I would mark this proposal "request changes" for implementation approval, while approving a narrowed experimental provider pilot.

_codex-gpt-5.5-medium on behalf of maphew_
