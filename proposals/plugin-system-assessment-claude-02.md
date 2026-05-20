# Independent Assessment: Plugin System Proposal for Beads

> Reviewer: Kilo (claude-opus-4.7) on behalf of matt
> Date: 2026-05-20
> Subject: `proposals/plugin-system.md` (dated 2026-05-13)
> Method: Independent review. Verified proposal claims against `bd-main/` source tree. Did NOT read other reviewer assessments in `proposals/`.

## TL;DR

**Verdict: LGTM with material concerns.** The two-tier split (out-of-process MCP for Providers, in-process WASM for Automations) is the right shape. The trust layer (manifest + lockfile + grants + audit) is comprehensive and the right defaults. The "frozen Cobra tree" property is a strong security guarantee.

However, the proposal under-states the actual scope of the work, has at least one quantitative claim that's off by ~2-3x, soft-pedals real cold-start regressions, hedges on the storage non-goal in a way that contradicts the project charter, and has measurable gaps in:
- The privilege boundary that out-of-process trackers cross (storage write surface)
- The host SDK story for tracker plugin authors (retry/backoff/sanitization)
- The hook event surface mismatch (3 events today vs the much larger surface implied for Automations)
- MCP version negotiation
- The collision with the existing meaning of "plugin" in `plugins/beads/`
- Revocation, air-gap distribution, and project-vs-user lockfile conflict semantics

None of these are fatal. All are addressable inside the proposed architecture. They should be resolved before code lands, not after.

## What the proposal gets right

These are non-trivial decisions that the proposal calls correctly:

1. **Two paradigms, not one, not many.** Out-of-process for high-latency I/O (network calls, schema-rich integrations) and in-process WASM for hot-path lifecycle work is the standard answer for a CLI host that needs both. Picking one (everything subprocess, or everything WASM) would force a bad trade somewhere.
2. **MCP-stdio for Providers.** The protocol Beads' agent users already speak. Free SDK ecosystem in TS/Python/Go/Rust/C#. Concrete, not aspirational.
3. **Wazero, CGO-free.** Preserves Beads' static-binary distribution invariant. The proposal's note that "anyone who proposes a different WASM runtime breaks our static-binary distribution" is correct and worth elevating to an ADR as suggested.
4. **Default-deny grants + content-addressed lockfile.** This is the only model that survives a hostile-plugin scenario. The Gatekeeper/Android first-use-prompt analogy is apt.
5. **Frozen `*cobra.Command` tree after construction.** Strong, simple property. Means a compromised dependency can't shadow `bd push`. Worth its own design note even if no plugins shipped.
6. **Storage data plane stays in-tree.** Correct — JSON-RPC per row read is fatal. The fact that `internal/storage/storage.go` defines 11 interfaces (not just `Storage`) makes this even more correct than the proposal claims.
7. **OCI mandatory digest pinning from v0.1, cosign opt-in then required by v1.** Right ratio. Required-from-day-one would create a chicken-and-egg ecosystem problem.
8. **Migration debt register with named removal milestones.** Mature project hygiene. Most plugin proposals omit this and leave fallbacks fossilized.
9. **CI-enforced SLO gates.** Disciplines the work. Especially `<+50 ms` cold-start and `<150 ms` 100-entry scan.
10. **Provenance envelope on plugin output.** `{"source": "plugin:X", "trust": "external", "data": ...}` is cheap and consumable. Always-wrap is the right policy. Prompt-injection mitigation is a real concern given Beads' AI-supervised use case.
11. **Killing implicit `bd-*` PATH discovery.** PATH hijack is a trivial arbitrary-code-exec for a CLI that handles tracker tokens. Right call.

## Material concerns

These need answers before implementation, in rough order of importance.

### 1. The "tracker has the fat `storage.Storage` interface" privilege boundary is unaddressed

Today, every tracker's `Init(ctx, store storage.Storage) error` (`bd-main/internal/tracker/tracker.go:25`) hands the tracker a reference to the full `Storage` interface. During sync, trackers can directly mutate any beads issue. There are no guard rails. Out-of-process MCP trackers cannot have this — a subprocess does not share Go pointers — so the host must mediate writes via RPC.

The proposal mentions capabilities like `tracker.read`, `tracker.write`, but doesn't spec what subset of `Storage` operations are exposed over RPC. This is the heart of the Provider design. Concrete questions the proposal needs to answer:

- Does a Provider plugin call `bd_create_issue`, `bd_update_issue`, `bd_create_dependency` host functions, or does it return a *patch set* the host applies?
- If patch set: how is conflict resolution handled (the existing engine has last-write-wins / beads-wins / tracker-wins strategies — see `INTEGRATION_CHARTER.md`)?
- If host functions: what's the RPC chattiness during a 1000-issue sync? Existing trackers do batch operations against a Go pointer.

A Provider RFC inside this design — naming the RPC surface concretely — should land before the Notion pilot starts. Without it, the migration is exposed to scope creep.

### 2. Host SDK / shared operational helpers for plugin authors

The Integration Charter (`bd-main/docs/INTEGRATION_CHARTER.md`) requires every tracker to implement: retry with exponential backoff and jitter, response size limits, context cancellation, pagination guards, and terminal sanitization. Today these come from shared Go helpers in `internal/tracker/`.

If trackers move to plugins authored in arbitrary languages (TS, Python, Rust, etc.), each author re-invents these wheels at varying quality. Result: a plugin ecosystem of trackers that don't behave consistently — exactly the inconsistency Beads currently avoids by keeping trackers in-tree.

The proposal should commit to one of:

- **A reference host SDK** for at least Go and TypeScript (the two MCP server bootstrap paths) that wraps retry/backoff/sanitization, distributed alongside the manifest schema.
- **A capability-test harness** (`bd plugin test`) that exercises the rate-limit / pagination / response-size invariants and refuses to publish a manifest claiming `tracker.*` capabilities without passing.
- Ideally both.

Without this, trackers-as-plugins will be a quality regression versus the bundled six.

### 3. The hook event surface is silently expanding

Current hook surface (`bd-main/internal/hooks/hooks.go`): exactly three events — `on_create`, `on_update`, `on_close` — hardcoded. The proposal describes Tier A Automations as covering "lifecycle hooks, formatters, lint rules, content transforms — anything event-triggered or invoked frequently in-process." That's a much larger surface than three events.

Either (a) the WASM Automation runtime ships with the same three events, in which case "formatters, lint rules, content transforms" is aspirational and shouldn't be in scope copy, or (b) the migration silently adds new events (`on_sync`, `on_push`, `on_label_change`, `on_dep_change`, `on_transaction_commit`, formatter pipeline hooks, etc.), in which case that's a significant separate design question — what events, in what order, with what data, with what error semantics — that the proposal hasn't done.

The honest answer is probably (b). If so, surface it as an explicit deliverable: "Automation event catalog v1" alongside the runtime.

### 4. Storage non-goal vs charter: pick one

The proposal says storage is an explicit non-goal. Good. But it also says HashiCorp `go-plugin` is "kept on the shelf for a future Storage Provider." That hedge contradicts `bd-main/docs/PROJECT_CHARTER.md:46`:

> Beads should not become a storage engine. Dolt provides storage, versioning, sync, merge behavior, concurrency, and crash safety.

A future-Storage-Provider carve-out is a charter amendment in disguise. Either:

- Drop the carve-out. Storage stays in-tree, period. The proposal becomes simpler. (Recommended.)
- Or propose the charter amendment explicitly so the project can decide whether it's becoming a storage engine.

Hedging both ways is the worst option — it tells future contributors "storage plugins are eventually fine" without admitting the policy change.

### 5. Cold-start regression is real and the SLO doesn't cover it

The proposal lists "MCP tracker fetch p95 overhead vs in-tree call: under +50 ms" as a gate. This is the *warm-subprocess* path. Buried in "Open risks" is the admission:

> A cold `bd jira sync` invocation now pays a Node/Python/whatever startup tax (~100-300 ms) that the in-tree Go path avoids.

For a CLI tool used in batch scripts, automation pipelines, and ad-hoc agent invocations, **cold-start is the path that matters**. Every `bd jira sync` invocation in CI today is cold. Adding 100-300 ms per invocation per tracker is a real UX regression that the SLO doesn't gate.

Add an explicit cold-start SLO before declaring success: e.g., `bd <plugin-tracker> sync` cold p95 under +250 ms vs current. If that's unrealistic, the proposal needs a daemon-mode story (long-lived plugin host process the CLI talks to), not just "we'll see during the pilot."

### 6. The word "plugin" already has two meanings in this codebase

`bd-main/plugins/beads/` is an existing top-level directory containing AI-tool plugin manifests (Claude Code, Codex, GitHub Copilot CLI). It's imported as `beadsplugin "github.com/steveyegge/beads/plugins/beads"` from `internal/recipes/recipes.go`. Doctor checks reference `enabledPlugins["beads@beads-marketplace"]`.

Adding a second meaning of "plugin" (this proposal's runtime plugin system) creates ambiguity:
- "Plugin marketplace" — which one?
- `bd plugin install ...` — wires through which subsystem?
- `bd doctor` checks for plugins — are runtime plugins now part of doctor?

The proposal must explicitly disambiguate. Two reasonable options:

- Rename `plugins/beads/` to `agent-plugins/beads/` (or `marketplace/beads/`) before this proposal lands.
- Or scope this proposal's vocabulary: `bd extension`, `bd ext`, or similar. (The proposal explicitly retires "extension," but reclaiming it for the runtime tier might be the cleanest collision avoidance.)

The proposal acknowledges naming as a feedback question (#4). The bigger naming problem is `plugin`-the-word, not `provider`/`automation`.

### 7. Storage decorator non-composability

`internal/storage/hook_decorator.go` exists *because* decorating `Storage` doesn't compose cleanly with the optional capability interfaces (`StoreLocator`, `BackupStore`, `Flattener`, etc.). The public `UnwrapStore(s)` helper is the smoking gun — callers explicitly type-assert through decorators because the decorator hides type-asserted capabilities.

If WASM Automations are added as additional storage decorators (the natural place to fire `on_*` events into wazero), the decorator chain grows. The proposal should specify:

- Whether Automations attach to the storage layer (HookFiringStore-style) or to a separate event bus.
- How the existing `UnwrapStore` contract evolves.
- Whether the hook event source moves out of `internal/storage/` decorators entirely (cleaner, but a bigger refactor).

### 8. MCP version churn is named but not specced

The proposal lists MCP version negotiation under "Open risks":

> The MCP protocol is still moving (revisions 2024-11-05 → 2025-06-18 → ...). We need explicit `protocol_version` in the manifest plus host-side compatibility logic, otherwise old plugins break on `bd` upgrade.

This is a known and recurring pain in the MCP ecosystem. It belongs in the design, not in open risks. Concrete spec needed:

- Manifest field: `protocol_version: "<semver-or-mcp-revision>"`
- Host policy: range of MCP revisions supported per `bd` release.
- Compatibility shim policy: how long does the host carry adapters for old MCP revisions?
- Failure mode: hard-fail with actionable error vs degrade with warning vs silent compat shim.

### 9. Revocation flow is implied but not enumerated

The grants model implies revocation, but the listed subcommands `bd plugin {install, list, remove, trust, audit, doctor}` don't include `revoke`. If a plugin turns malicious post-grant, what's the kill-switch?

- `bd plugin revoke <plugin> [--capability <cap>]` should be a first-class command.
- The audit log should record revocations.
- A revoked plugin should fail-closed at next launch with an actionable error.

### 10. Project-vs-user lockfile/grant conflict semantics

Project-scoped pin at `.beads/plugins.lock` plus user-scoped grants at `~/.beads/plugins/grants.json` is a reasonable model, but conflicts aren't specified:

- Project pins `bd-jira@digest-A`. User has only granted `bd-jira@digest-B`. Outcome?
- Project pins `bd-jira` requiring `network:jira.example.com`. User has granted `network:jira-test.example.com`. Outcome?
- User trusts `bd-jira` globally; new project pins it with new capabilities. Re-prompt or auto-grant within the trust scope?

Without these, a multi-repo workflow becomes a grant-prompt-fest, or worse, silently broken.

### 11. Air-gap / enterprise distribution

`bd plugin install ./local-folder` is mentioned as a fallback. For air-gapped enterprise environments that can't reach `ghcr.io`, what's the trust path? Specifically:

- Does cosign verification still apply to `./local-folder` installs?
- Is the manifest schema validation identical?
- Is there a `bd plugin export <plugin>` that produces a transferable bundle for offline install?

This is the difference between "Beads has a plugin system" and "Beads has a plugin system enterprises can use." The proposal punts.

## Quantitative discrepancies between proposal and source

The proposal makes several numeric claims that don't survive verification against `bd-main/`. None invalidate the design, but cumulatively they undermine the "we've done our homework" tone.

| Proposal claim | Verified actual | Delta |
|---|---|---|
| Tracker integrations "~15k LOC across `internal/` and `cmd/bd/`" | ~36k LOC including tests; ~19k LOC non-test (internal + cmd/bd) | **2-3x undercounted** |
| `internal/notion` "~1.7k LOC" | 1,892 LOC non-test; 2,994 LOC total | ~10-75% undercounted |
| `cmd/bd/notion*` CLI "~613 LOC" | 677 LOC non-test (`notion.go`); 1,193 LOC including `notion_test.go` | 10-95% undercounted |
| "~100 files in `cmd/bd/`" with init() side effects | 132 files have init(); 149 init blocks total; 103 files call `rootCmd.AddCommand`; 485 .go files in `cmd/bd/` total | "100" matches AddCommand callers; init count is 30%+ higher; total file count is 5x larger |

If the 15k LOC number was the basis for "maintenance burden is too high" — the actual number is worse, which strengthens the case. But the inaccuracy means reviewers can't trust the numbers without verifying. Recommend re-running the LOC tally pre-merge.

Two additional precision points that affect the design:

- **`bd-example-extension-go/` is two storage generations behind.** The proposal frames it as the deprecated in-process Go SDK. Its README explicitly targets *SQLite-backed* beads, which is the prior storage era. The example doesn't even work against current Dolt-backed beads. So "retire `extension`" is fine, but "the deprecated in-process Go SDK story" understates how stale this artifact is — there's effectively no working in-process SDK to retire, only a fossil that already redirects users to `bd --json`.
- **`internal/recipes` + `internal/molecules` + `internal/formula` are at very different complexity levels.** Recipes is install-time content writer (~600 LOC). Molecules is JSONL template loader (~555 LOC). Formula is a small DSL with parser, conditions, control flow, range expansion (~9.7k LOC). Lumping all three as "declarative content packs" undersells `formula`. The proposal's "not a third paradigm" claim is reasonable in principle, but `formula` already *is* a kind of plugin paradigm — DSL execution against beads data — and the design should note whether `formula` modules might one day be an Automation tier consumer of WASM helpers.

## Answers to the proposal's specific feedback questions

The proposal explicitly asks for these. Direct answers:

1. **Storage non-goal carve-out for future `go-plugin`?** No — drop the carve-out. The Project Charter is firm that Beads is not a storage engine. Hedging in the v1 docs invites future scope creep that contradicts charter. If the project ever does want a storage plugin, that's a charter amendment, separately argued.

2. **Bundled-by-default vs plugin-from-day-one for the five remaining trackers?** Drop one or two sooner. Maintaining all six bundled trackers through v1 means the migration is invisible to most users — the plugin system ships and nothing changes. Pick one additional tracker (Linear is the next-sized after Notion at ~7.8k LOC, GitHub is the most-used) and migrate it alongside Notion. Two pilots stress-test the architecture more honestly than one. v2 then drops the remaining four, with telemetry data on which trackers users actually configure.

3. **Hook breaking change appetite — aggressive (`--allow-unsafe-hooks` immediately) vs silent grace period?** Aggressive is correct. A loud, visible-on-every-run banner forces migration awareness. A silent grace period across two releases means nobody migrates and the second release breaks them with no warning. Council security is right; ship aggressive. Plan for a `bd plugin migrate-hook` tool that can convert simple shell scripts; accept that complex scripts require manual rewrite. Provide a 2-3 week public beta channel before the change so alpha-tester users can complain loudly.

4. **Naming — `provider` / `automation` / `plugin` umbrella, retire `extension`?** Acceptable for the new tiers. The bigger naming problem is the existing `plugins/beads/` directory, which means "plugin" as the umbrella term collides with existing AI-tool manifest semantics. Resolve this collision before the proposal lands. Two options: rename `plugins/beads/` to `agent-plugins/beads/` (or `marketplace/`), or scope the new system as `bd extension` / `bd ext` (reclaiming the retired vocabulary).

5. **Distribution channel — cosign opt-in for v0.1, default-required by v1?** Right ratio. Required-from-day-one creates a chicken-and-egg problem (no plugins to attract authors → authors don't bother with cosign tooling). Make the opt-in case loud — "unsigned plugin" warnings on every invocation, not just install. By v1, the warnings become refusals.

6. **Hosted plugin index in v1?** Push to v1.x. The OCI registry **is** the index for v1. `bd plugin search` against a curated index is a separate community-management problem; conflating it with the runtime delays the runtime. Ship plugin install/run/audit in v1; ship search/browse in v1.x once there's enough plugin volume to make a curated index meaningful.

7. **Provenance envelope — always-wrap in `bd --json`?** Yes, always-wrap. Consumers parse structured output; an extra `{"source", "trust", "data"}` layer is trivial. The cost of selectively-wrapping (only under MCP) is a fragmented schema that's harder to test and harder to audit. Always-wrap is also future-proof for the eventual case where multiple plugins contribute to one output.

8. **`bd plugin quickstart` built-in vs sample plugin?** Built-in. Bootstrap matters more than dogfooding purity — users new to plugins need a smooth on-ramp without first installing a plugin to learn how to install plugins. Ship the dogfooding sample plugin separately, after the built-in path works.

## Open risks the proposal does not raise

In addition to the proposal's own "Open risks" section, these need attention:

1. **Plugin uninstall leaves residue.** When `bd plugin remove bd-jira` runs, what happens to:
   - Issues already synced from Jira that have `external_ref` pointing to Jira IDs?
   - Field mappings stored in beads metadata that referenced Jira-specific values?
   - Hooks that referenced the plugin's KV namespace?
   The proposal doesn't address state cleanup or "soft uninstall" semantics.

2. **Plugin updates and capability creep.** When `bd-jira@v1.0` is updated to `v1.1` that adds a `network:new-host.example.com` capability, the user's existing grant for `v1.0` capabilities — does `v1.1` auto-elevate (bad), or re-prompt (good but noisy), or fail-closed (safest but high-friction)? Capability diff prompts on update should be a first-class flow.

3. **Plugin telemetry / "is this plugin behaving?".** The audit log records install/grant/exec events. But suspicious post-install behavior — a plugin opening 1000 outbound connections, calling host functions at unusual rates, or holding the subprocess open past a sync — has no surfaced signal. The codebase already has `internal/hooks/hooks_otel.go`; the plugin runtime should integrate OTel from day one, not as a follow-up.

4. **Plugin author signing identity model.** Cosign verifies a signature, but the proposal doesn't specify *whose* signature. Identity options:
   - GitHub OIDC (keyless cosign) — easy for hobbyists, weak identity assertion.
   - Cosign with a known key registry — strong identity, ecosystem cold-start problem.
   - Public-good third-party CA (Sigstore Fulcio) — hybrid.
   This is a v1 decision, not a v0.1 one, but the manifest should accommodate either model from day one.

5. **WASI capability vocabulary lock-in.** `fs.read:/path`, `network:host`, `env:NAME` are reasonable initial capabilities. But the WASI Preview 2 standardization is shifting the WASI capability model under the runtime. wazero's WASI implementation will track upstream. The proposal should pin a WASI revision in the manifest just as it pins MCP revisions, otherwise the same version-skew problem hits Tier A.

6. **Plugin discovery for AI agents.** AI agents are mentioned as a primary user. But how does an agent discover what plugins are installed? `bd plugin list --json` is implied but not specified. Output schema (capability list, version, last-execution-time, granted-capabilities subset) needs to be designed alongside the install flow.

7. **Notion is not the right pilot.** The proposal flags this as a possible concern. To take a position: agreed, Linear or GitHub is a more honest stress test. Notion's API has the most idiosyncratic field model (database schemas, block-tree content, etc.) but is also the smallest tracker. Linear (7.8k LOC, ~3-5x bigger than Notion) tests batch sync, complex state machines, and team-scoped semantics — closer to "how Beads is actually used." GitHub (the most-used tracker) tests rate-limiting at scale. Recommend two pilots: Notion proves the architecture works on the easy case; Linear proves it works at realistic scale.

8. **Reproducible builds for plugin artifacts.** OCI digest pinning is only as good as the build process behind it. For Tier A WASM plugins especially, a deterministic build chain (Bazel, Nix, or a documented `wasm-tools` invocation) should be at least an aspirational direction. Otherwise "verified by digest" means "verified to be the same opaque blob," not "verified to correspond to the published source."

9. **Charter compliance for the new commands.** Adding `bd plugin {install,list,remove,trust,audit,doctor}` is a new feature surface area. The charter says "Before adding new feature surface area, read PROJECT_CHARTER.md." The proposal should explicitly cite charter compliance: yes, this is a documented extension point per the orchestration boundary section, and the integration boundary mentions "plugins" as a target for boundary-crossing work. Worth saying out loud rather than implying.

## Recommended path forward

Adopt the proposal's overall architecture. Block on the following before implementation begins:

1. **Resolve naming collision** with `plugins/beads/` — pick a vocabulary and rename one or the other.
2. **Spec the Provider RPC surface** — concrete host functions, batch semantics, conflict-resolution path. This is the heart of the design and currently the largest gap.
3. **Spec the Automation event catalog v1** — exact list of events Automations can subscribe to. Either confirm "same 3 events as today" or expand explicitly.
4. **Drop the storage `go-plugin` carve-out** — or amend the charter, but don't hedge.
5. **Add cold-start SLO** — `bd <plugin-tracker> sync` cold p95 under some specified bound (suggest +250 ms). If unrealistic, design a daemon-mode mitigation now.
6. **Spec MCP version negotiation** — manifest field, host range, compatibility shim policy.
7. **Add `bd plugin revoke` to subcommand list** — with audit-log recording.
8. **Spec project-vs-user lockfile/grant precedence** — rules for digest mismatch, capability mismatch, scope inheritance.
9. **Commit to a host SDK + capability test harness** for tracker plugins, so the Integration Charter's operational requirements aren't lost when trackers leave the tree.
10. **Re-run LOC tallies** pre-merge so the proposal's numbers match the tree.

Then proceed with the migration order as proposed, except: **two tracker pilots, not one** — Notion plus Linear (or GitHub). Two pilots stress-test the design honestly; one allows pilot-specific shortcuts.

The proposal is sound architecture and disciplined product hygiene. The above are not reasons to reject — they're the boring-but-load-bearing details that decide whether the system is genuinely shippable in v0.1 or quietly slips to v0.3.

## References

- Verified against `bd-main/` source tree (commit-state at time of review).
- `bd-main/internal/tracker/tracker.go` — `IssueTracker` interface (107 lines, 14 methods + 3 optional capability interfaces + `FieldMapper`).
- `bd-main/internal/tracker/registry.go` — factory map registry (52 lines).
- `bd-main/internal/hooks/hooks.go` — exactly 3 hardcoded events (create/update/close).
- `bd-main/internal/storage/storage.go` — 11 interfaces, not 1; `UnwrapStore` helper at `hook_decorator.go`.
- `bd-main/cmd/bd/main.go:584` — `var rootCmd = &cobra.Command{...}` (unexported); 132 files with `init()`, 103 files with `rootCmd.AddCommand`.
- `bd-main/plugins/beads/` — existing AI-tool plugin manifest namespace (Claude/Codex/Copilot).
- `bd-main/docs/PROJECT_CHARTER.md` — Storage Boundary, Schema Boundary, Integration Boundary; "Beads should not become a storage engine."
- `bd-main/docs/INTEGRATION_CHARTER.md` — design guidelines for new tracker integrations (retry, backoff, jitter, pagination, sanitization).
- `bd-main/examples/bd-example-extension-go/README.md` — explicitly targets SQLite-backed (prior-generation) beads; redirects to `bd --json`.

---
_kilocode-claude-opus-4.7 on behalf of matt_
