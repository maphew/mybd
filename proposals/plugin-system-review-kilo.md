# Review: Plugin System for Beads

> Review of `plugin-system.md`
> Status: Maintainer/design feedback for council consideration
> Date: 2026-05-18
> Reviewer: Kilo Code
> Signature: _kilocode-openai/gpt-5.5-xhigh on behalf of maphew_

## Verdict

Approve the direction, but request revisions before treating this as an implementation-ready plan.

The two-tier split, storage non-goal, and default-deny trust model are well aligned with Beads. The current proposal needs tighter boundaries around Provider isolation, plugin subcommands, MCP tracker semantics, and migration sequencing.

## Strengths

- The proposal matches real Beads seams. The CLI currently uses global Cobra construction and `init()` side-effect registration in `cmd/bd/main.go:491` and `cmd/bd/main.go:584`.
- The tracker seam is real. `IssueTracker` already exists in `internal/tracker/tracker.go:13`, and the six bundled integrations register through `tracker.Register(...)`.
- Keeping storage in-tree is correct. The storage interface is broad and hot-path-oriented in `internal/storage/storage.go:36`, and `docs/PROJECT_CHARTER.md:44` explicitly keeps storage-engine concerns out of Beads core.
- The hook replacement target is real. Current hooks are executable scripts in `.beads/hooks/` and run asynchronously by default from `internal/hooks/hooks.go:47`.
- Digest pinning, explicit grants, no implicit PATH discovery, audit events, and provenance wrapping are the right default posture for a CLI that handles tracker credentials and feeds AI agents.

## Blocking Concerns

1. Provider capabilities overclaim sandboxing.

MCP Providers are native subprocesses. Beads can enforce environment allowlists and RPC method scopes, but manifest capabilities such as `network:jira.example.com` and `fs.read:/path` are not enforceable without an OS sandbox, container boundary, brokered network layer, or platform-specific restriction mechanism. As written, Provider capabilities are consent and audit metadata, not isolation.

2. Plugin subcommands look like a third extension paradigm.

The proposal says there are exactly two paradigms, Provider and Automation, but also says plugins can contribute commands during `NewRootCmd(...)` construction. That needs a hard rule. Either third-party commands are out of scope for v1, or commands are manifest-declared host shims that dispatch to Provider MCP tools without arbitrary Cobra mutation.

3. `NewRootCmd` is broader than a mechanical refactor.

There are many `cmd/bd` files with `init()` registration and shared package globals. A quick scan found 132 `func init()` occurrences under `cmd/bd`. Cobra also does not provide true runtime immutability, so "frozen command tree" should be specified as "no exposed registration API after construction" rather than a complete security boundary.

4. The MCP tracker adapter is under-specified.

`IssueTracker` includes `FieldMapper()` and there are optional capabilities such as batch push and pull stats in `internal/tracker/tracker.go:61`. Current sync commands also import concrete tracker packages directly, for example `cmd/bd/sync_push_pull.go:9`, and construct trackers directly, for example `cmd/bd/sync_push_pull.go:238`. A generic `internal/tracker/mcp_adapter.go` is plausible, but not sufficient without a plan for config, field mapping, custom flags, batch/dry-run behavior, and JSON compatibility.

5. Startup and performance SLOs mix different paths.

No-plugin startup, lockfile scan, Provider cold start, warm in-command RPC, and long-lived daemon/broker startup are different measurements. A cold `bd jira sync` spawning a Node or Python MCP server will not satisfy a `+50 ms` p95 overhead target unless that target excludes cold process startup or a broker is introduced.

6. The audit log is not truly append-only against native Providers.

The host can append audit records and WASM Automations can be denied direct writes. Native subprocess Providers can still tamper with user-writable files unless OS sandboxing exists. Use "host append-only" or "tamper-evident hash-chained" wording unless stronger isolation is added.

7. Hook migration is too abrupt as written.

Default-deny unsafe hooks is the right end state, but flipping executable-script hooks behind `--allow-unsafe-hooks` immediately when WASM ships will break existing users. The migration should include `bd doctor` warnings, a detection/reporting phase, `bd plugin migrate-hook`, Windows-specific guidance, and one explicit warning release before default-deny.

## Decision Recommendations

- Storage should stay in-tree for v1. Add a short future carve-out saying a Storage Provider would require a separate ADR, binary protocol, and performance evidence.
- Keep Jira, Linear, GitHub, GitLab, and ADO bundled through v1. Do not remove integrations early for binary-size reasons until plugin install, update, and support paths are proven.
- Keep the aggressive hook security destination, but stage the breaking behavior through warnings and migration tooling.
- Keep the vocabulary: `provider`, `automation`, and umbrella `plugin`. Retire `extension`.
- Require digest pinning from day one. Make signatures required for official or curated plugins first; allow unsigned local/community plugins with install-time and doctor-time warnings.
- Push a hosted plugin index to v1.x. URI install plus lock/grant/audit is enough for v1.
- Always provenance-wrap plugin output for MCP and AI-facing surfaces. Avoid breaking existing `bd --json` schemas unless the schema is versioned or the output is plugin-specific.
- Make `bd plugin quickstart` built in. Shipping quickstart as a plugin creates unnecessary bootstrapping friction.

## Requested Proposal Revisions

- Add a Provider isolation truth table distinguishing enforceable controls from advisory controls.
- Specify whether plugin commands exist in v1 and, if so, define a manifest-only command schema.
- Define grant inheritance across updates, including re-prompting when a plugin digest or requested capability set changes.
- Define global and project lockfile precedence. Project locks should pin shared plugin versions without bypassing per-user grants.
- Split SLOs into no-plugin startup, plugin scan, Provider cold start, Provider warm RPC, and WASM instantiation.
- Make the Notion pilot prove the full tracker contract, including field mapping, config migration, custom command flags, batch/dry-run behavior, parity tests, and JSON compatibility.
- Clarify that the audit log is host-controlled or tamper-evident, not protected from native subprocess tampering unless OS isolation is introduced.

## Source Grounding

- `cmd/bd/main.go:491` initializes root flags and groups through package-level `init()`.
- `cmd/bd/main.go:584` defines the global `rootCmd`.
- `internal/tracker/tracker.go:13` defines `IssueTracker`.
- `internal/tracker/registry.go:17` defines the global tracker registry registration path.
- `cmd/bd/sync_push_pull.go:9` imports concrete tracker packages in command code.
- `cmd/bd/sync_push_pull.go:238` constructs a concrete tracker directly.
- `internal/hooks/hooks.go:47` runs executable hooks from `.beads/hooks/` asynchronously.
- `cmd/bd/main.go:1049` initializes the hook runner and wraps storage with `HookFiringStore`.
- `internal/storage/storage.go:36` defines the core storage boundary.
- `docs/PROJECT_CHARTER.md:44` defines the storage boundary policy.
