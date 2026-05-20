# Independent Assessment — Plugin System Proposal

> Reviewer: Claude (Sonnet 4.5 via Kilo CLI)
> Subject: `proposals/plugin-system.md` (2026-05-13 draft)
> Date: 2026-05-20
> Scope: Independent technical review. Other plugin-system-*.md files in this folder were deliberately not consulted.
> Verification: Grounded in direct reading of `bd-main/` source.

Editor's note: The chat that started this review was Opus Latest xhigh in Kilocode vscode extension, but it delegated to Sonnet 4.5 and then compiled this final report, which is why there both Sonnet and Opus signatures.

## TL;DR

The proposal is **architecturally sound and security-thoughtful**, easily the most rigorous extensibility design I've seen for a CLI of this size. The two-tier split (Provider/Automation), the trust layer (lock+grants+audit), the frozen command tree, and the migration debt register are all good calls. The author has clearly done the homework and survived two rounds of council review.

That said, after grounding the proposal against the actual `bd-main/` codebase, **four specific claims do not hold up to inspection**, and **three architectural assumptions deserve harder evidence before committing engineering effort**:

1. The `IssueTracker` interface is meaningfully heavier than the proposal implies (23 methods + 17-field intermediate struct + deferred-dependency import semantics), which materially affects whether MCP-stdio is the right wire protocol for it.
2. The "factory refactor is mechanical" framing understates the scope: 136 `init()` functions across 205 non-test files in `cmd/bd/`, with a 1,318-line `main.go` whose `PersistentPreRun` alone is ~490 lines.
3. Notion is the wrong pilot. It's the most idiosyncratic tracker by design (per the proposal itself) and is ~10% larger than the proposal claims (1,892 production + 677 CLI; 4,187 with tests).
4. The "existing Go SDK example" cited in the references section is a tombstone that explicitly directs readers to the subprocess `bd --json` pattern — which is the *opposite* RPC direction from what the proposal advocates.

Recommendation: **LGTM with revisions.** Do the factory refactor and the trust layer in v0.1 as proposed; defer the tracker pilot until the trust layer is in production and choose a different pilot tracker.

## What the proposal gets right

These are not faint praise — getting any of these right is unusual.

### Security-first design with default-deny everywhere

Principles 1–2 (`§Design principles`, lines 26–27) — explicit user grant before any plugin executes; content-addressed digests verified before every launch — are the right defaults. The Gatekeeper/Android first-use prompt model is well-understood by users.

The audit log at `~/.beads/audit.log` (line 110) and the per-plugin KV namespacing for Automations (line 95) close two specific failure modes (post-incident forensics, plugin-to-plugin lateral movement) that most plugin systems get wrong.

### Frozen command tree as a security property

`§Cobra refactor` (lines 122–127) calls out the frozen tree explicitly as a security property: "a compromised dependency cannot silently shadow `bd push`" (line 30). This is correct and rare. Most CLI plugin systems allow runtime command registration and end up with a `git-foo` style PATH-shadowing surface.

This decision is also self-consistent with the rejection of implicit PATH discovery in `§Alternatives considered` (line 203).

### Storage stays in-tree

`§What is not a plugin` (lines 167–170) is the most important paragraph in the proposal. The author correctly identifies that JSON-RPC over stdio is unsuitable for hot-path data plane reads, and that the right escape hatch — if one is ever needed — is a binary-packed protocol via `go-plugin`. This aligns with the project charter's `§Storage Boundary` policy at `bd-main/AGENTS.md` and `bd-main/docs/PROJECT_CHARTER.md`, which states that beads "should not become a storage engine" and prescribes "widen the interface or route the issue to the driver" rather than adding a plugin layer.

The proposal is in fact *under-selling* this: my reading of `internal/storage/storage.go:39-117` finds the storage interface to be ~50 methods spread across 12 composed sub-interfaces (`DoltStorage` at lines 147-160), with a parallel `Transaction` interface (lines 251-290) of ~25 more methods, plus 10 optional capability interfaces. Anything calling itself a "storage plugin" would be a multi-hundred-method ask. The proposal's instinct to keep this in-tree is correct and, if anything, should be stated more emphatically.

### Migration debt register with removal milestones

`§Migration debt register` (lines 158–164) is the most disciplined version of this section I've seen in any plugin proposal. Treating expired fallbacks as defects rather than trade-offs is the right mental model.

### SLO-driven success criteria

`§Measurable success criteria` (lines 130–142) gives benchmarks teeth by tying them to CI gates. The 50ms cold-start delta is a reasonable budget; 150ms for 100 lockfile entries is generous and probably achievable.

## Concerns that warrant revision

### 1. The `IssueTracker` interface is heavier than implied — and its shape may be a poor fit for MCP-stdio

The proposal frames the Provider tier as "wrap an MCP client behind the existing `tracker.IssueTracker` interface" (line 83). This sounds light, but the actual interface at `bd-main/internal/tracker/tracker.go:13-59` is:

- **15 methods on `IssueTracker`**: `Name`, `DisplayName`, `ConfigPrefix`, `Init`, `Validate`, `Close`, `FetchIssues`, `FetchIssue`, `CreateIssue`, `UpdateIssue`, `FieldMapper`, `IsExternalRef`, `ExtractIdentifier`, `BuildExternalRef`.
- **8 methods on `FieldMapper`** (`tracker.go:81-107`): bidirectional `PriorityToBeads`/`PriorityToTracker`, `StatusToBeads`/`StatusToTracker`, etc., all trafficking in `interface{}`.
- **3 optional capability interfaces** (`BatchPushTracker`, `BatchPushDryRunner`, `PullStatsProvider`) discovered by type assertion.
- **A 17-field intermediate `TrackerIssue` struct** including `Raw interface{}` and `Metadata map[string]interface{}` (`internal/tracker/types.go:17-53`).
- **Deferred-dependency import semantics**: `IssueConversion` returns issues *plus* a separate `[]DependencyInfo` for second-pass linking.

MCP's tool model is request/response over JSON-RPC. Translating 23 methods + bidirectional field mapping + capability detection + deferred-dependency import into MCP tools is not trivial. Specifically:

- **What does `FieldMapper` look like as MCP tools?** A tool per direction per field type? A single `map_field` tool with discriminated input? The proposal does not show.
- **How do capability interfaces (`BatchPushTracker` etc.) survive the protocol boundary?** MCP's tool discovery is flat. There's no "this server implements optional capability X" idiom that I'm aware of in MCP.
- **`Raw interface{}` and `Metadata map[string]interface{}` are forms of "I don't know what's in here, just preserve it."** Over JSON-RPC these collapse to `any`, which loses the in-process aliasing semantics that conflict-resolution code probably depends on.

**Concrete ask**: before committing to MCP-stdio, write a paper exercise mapping every method in `tracker.go:13-107` to a specific MCP tool definition with its input/output schema, and identify which mappings are lossy. This may take a day; it will either validate the choice or surface that the right wire protocol for Tier P is `go-plugin` with gRPC + protobuf. The proposal acknowledges `go-plugin` as a fallback (line 87, 202) — that fallback may be the primary.

### 2. The MCP architectural direction is backward from what already works in-tree

The existing MCP integration at `bd-main/integrations/beads-mcp/src/beads_mcp/bd_client.py` is **MCP-wraps-bd**: the MCP server is the front-door for AI agents, and it shells out to `bd --json` (lines 319-328 in that file). This is the direction the deprecated `examples/bd-example-extension-go/README.md` *explicitly recommends* (lines 11-14): "Current Dolt-backed beads workflows should prefer standalone integration tools that call `bd --json` commands or use `bd query` for SQL access."

The proposal goes the other direction: **bd-wraps-MCP-servers**, with bd as the host and trackers as MCP server subprocesses. The "free agent ecosystem reuse" claim (line 87) is then weakened, because:

- Existing MCP servers in the wild are designed for AI consumption (a small set of tools, optimized for LLM tool-calling), not for the bidirectional CRUD + field-mapping + bulk-ops + capability-detection workload `IssueTracker` represents.
- The proposal's MCP servers will speak a *new* dialect of MCP — not the JSON-RPC tool-discovery shape, but a structured set of method calls matching `IssueTracker`. That's fine, but it's effectively a private RPC protocol that happens to use MCP's framing. The ecosystem reuse argument ("inherit a marketplace of existing MCP servers and SDKs in TS/Python/Go/Rust/C#") is less compelling once you realize beads-MCP plugins will not be drop-in compatible with non-beads MCP clients.

This is not fatal — using MCP-stdio framing is fine even if the contract is bd-specific — but the proposal should drop the "agent ecosystem reuse" framing and own that this is a private protocol with stdio framing.

### 3. The factory refactor is not "mechanical"

`§Cobra refactor` (line 127) says: "Migration is mechanical: collapse each `cmd/bd/*.go` `init()` into an explicit constructor function called by `NewRootCmd`. No behavior change. All existing tests pass unchanged."

Reality from `bd-main/`:

- `cmd/bd/` has **485 `.go` files** total, **205 production**, and **136** of those use `init()` for command registration.
- `cmd/bd/main.go` is **1,318 lines**. `PersistentPreRun` alone is **~490 lines** of store discovery, env loading, redirect resolution, server-mode detection, identity validation, hook setup, molecule loading.
- There's a `noDbCommands` allowlist (`main.go:712-738`) and a `readOnlyCommands` set (`main.go:111-126`) that hardcode command names. These will need a registration mechanism that plugin commands can opt into, otherwise plugins can't declare their no-db status.

"Mechanical" is wrong. This is a multi-week refactor that touches ~136 files, plus a redesign of how `PersistentPreRun` consumes its dependencies, plus a new mechanism for plugin commands to declare metadata that `main.go`'s allowlists currently encode in literals. "No behavior change" is a strong claim that needs property-based testing (snapshot-test the help tree, snapshot-test the command set, snapshot-test the flag set per command) to validate, not just "all existing tests pass" which only validates what's already covered.

**Concrete ask**: revise `§Migration smallest credible slice` step 1 to call this what it is — a several-thousand-line refactor with its own SLOs (no help-text drift, no flag-list drift, no startup-time regression) — and budget engineering time accordingly.

### 4. Notion is the wrong pilot

The proposal acknowledges this as a risk (`§Open risks`, line 192) but does not act on it. My reading agrees with the risk: Notion is the *worst* choice of pilot because:

- **Idiosyncratic API**: per `bd-main/internal/notion/client.go:17`, the API version is hardcoded to a date string (`DefaultNotionVersion = "2026-03-11"`) and the endpoint set (`/data_sources/{id}`, `/databases/{id}`, page CRUD) is unique to Notion. A successful Notion-MCP plugin proves nothing about whether the design works for Jira or Linear.
- **Larger than claimed**: the proposal says "~1.7k LOC + ~613 LOC CLI" (line 151). Actual: **1,892 production + 677 CLI = 2,569 production, plus 1,193 test = 3,762 total**. ~10% larger on both dimensions and the test surface is non-trivial.
- **Custom field-mapping complexity**: 365-line `mapping.go` plus a separate `fieldmapper.go`. This is exactly the surface that doesn't translate cleanly to MCP tools (see concern #1).
- **Worker-pool batch push** (`tracker.go:17`, `defaultBatchPushWorkers = 8`): translating concurrent batch push across an MCP stdio boundary is a real design problem. Worker pools in subprocess plugins mean either (a) the plugin manages its own concurrency and bd just calls `BatchPush` once, or (b) bd calls `CreateIssue` 8-at-a-time across the JSON-RPC boundary. Both options have trade-offs the proposal does not address.

**Concrete suggestion**: the right pilot is something *new* — a tracker that has never been in-tree. Pivotal Tracker, FogBugz successor, Asana, ClickUp, Plane.so. This forces the design to prove "can a third party write a tracker plugin from scratch using only the manifest, capability schema, and host-supplied helpers?" which is the actual product question. Migrating Notion answers a different question ("can we reproduce existing behavior?") that is not the project's most important risk.

If a migration pilot is required for political reasons, **Linear** is a better choice than Notion: smaller field model, common GraphQL SDK, well-understood by the wider AI-agent community, and the migration result generalizes to Jira (also field-mapping-heavy) more honestly.

## Architectural assumptions that need harder evidence

### Subprocess startup amortization

`§Open risks` (line 189) acknowledges this but punts it to "needs measurement during the Notion pilot." The 50ms p95 SLO (line 135) "assumes warm subprocesses." This is a significant carve-out that should be promoted from open risk to design constraint.

For a CLI invoked dozens of times per work session by AI agents, cold-start tax on every invocation is brutal. The proposal needs a daemon/long-lived-subprocess strategy *before* the pilot, not as a post-pilot mitigation. Specifically:

- Will bd hold a connection pool of warm Provider subprocesses for the duration of the bd process? (This conflicts with bd's current "fork-and-exit" CLI shape.)
- Will there be a background `bd-pluginhost` daemon? (This is operationally heavy and may surprise users.)
- Will plugins be expected to be fast-start (e.g., compiled Go MCP servers, not Python)? If so, the "polyglot in TS/Python/Go/Rust/C#" benefit (line 82) is partly illusory.

This is the single biggest unknown in the proposal and should be elevated to a first-class design question.

### Capability granularity

`§The trust layer` (line 106) lists capabilities like `tracker.read`, `tracker.write`, `network:jira.example.com`, `env:JIRA_TOKEN`, `fs.read:/path`. These are the right *kinds* of capabilities, but the granularity question is unanswered:

- Is `tracker.write` per-tracker or global? If `bd-jira` has `tracker.write`, can it also write to `bd-linear`?
- Is `network:jira.example.com` literal-host-match, or does it support SNI / wildcards? What about `network:*.atlassian.net`?
- `env:JIRA_TOKEN` is a literal env var name. What about `env:JIRA_*`? Or scoped variants per environment (`env:JIRA_TOKEN if BD_PROFILE=prod`)?

The Android/iOS analogues the proposal invokes (line 108) have *years* of refinement on this exact question. The proposal needs to spec the capability grammar before v0.1 ships, because changing capability syntax later is a backward-compatibility nightmare.

### Cross-tier cooperation

The "two paradigms, no more" rule (`§Design principles` line 28) is right as a guardrail, but the proposal does not address the obvious cross-cutting use case: **a Provider that wants to fire on a hook event**.

Concrete example: `bd-jira` (Provider) wants to push to Jira when an issue closes. Today this would be:

- A hook on `EventClose` that calls `bd push --tracker=jira` — except hooks are now WASM Automations (Tier A), and the per-plugin KV namespace (line 95) means the Automation can't talk to `bd-jira`.
- A Provider method that bd calls automatically on close — except Providers don't subscribe to events; they're called explicitly by bd commands.

The proposal needs a story for "Provider subscribes to Automation events" or "Automation invokes a Provider RPC." Both involve crossing the tier boundary and the trust boundary. Without this, the system has the right shape but doesn't compose for the most common real-world use case.

### Audit log integrity

`§The trust layer` (line 110): "append-only JSONL ... not writable by plugins." How is this enforced? On a single-user Linux box, anything writing to `~/.beads/audit.log` can rewrite it. WASM Automations can be sandboxed away from the path; subprocess Providers cannot, because their environment includes whatever filesystem the user has access to.

Options:

- syslog forwarding (operationally heavy, breaks offline-first)
- a separate `bd-auditd` process owning the file (heavy)
- chmod 0444 + chattr +a on Linux (won't work cross-platform)
- HMAC-chained log entries with a key in the OS keyring (good for tamper detection, doesn't prevent deletion)

The proposal needs to pick one or explicitly note the threat model assumes "if an attacker has filesystem write to ~/.beads, they have already won."

## Specific feedback on the proposal's enumerated questions

The proposal asks 8 specific questions in `§Specific feedback I'm asking for`. My answers:

1. **Storage non-goal**: keep storage in-tree forever as the default, but add a single sentence to v1 docs noting that a future "Storage Provider via gRPC + go-plugin" is on the shelf if a binary-packed driver protocol is ever justified by data. This costs nothing and prevents future-you from re-litigating it.

2. **Bundled-by-default vs plugin-from-day-one**: keep all five bundled through v1. The "force users into six install commands" cost is real, and dropping any of the five in v0.1 increases the surface area of the pilot from "one tracker migration" to "one migration plus three deprecations." Defer the de-bundling until the plugin path has shipped one full minor cycle without incident.

3. **Hook breaking change appetite**: aggressive path is correct *if* the WASM Automation runtime ships with `bd plugin migrate-hook` working on common bash/python scripts on day one. If migration tooling lags, users will complain loudly and rightly. Make the migration tool a v0.1 deliverable, not a removal-criterion deliverable.

4. **Naming**: `provider`/`automation`/`plugin` is fine. Retiring `extension` is good. One nit: "Automation" is a very generic word that may confuse users who associate it with shell scripts, CI, or workflow automation. Consider `module` or `runner` if there's appetite. Not a blocker.

5. **Distribution channel**: cosign opt-in for v0.1 is correct. Required from day one would block most hobbyist plugin authors, who are exactly the audience you want for the v0.1 cohort. Keep the planned trajectory (opt-in v0.1, default-required v1).

6. **Hosted plugin index**: defer to v1.x. Building a curated index is its own product and competes for engineering time with the v0.1 trust layer. `bd plugin install oci://<digest>` is sufficient for the early adopter cohort.

7. **Provenance envelope**: always-wrap in `bd --json`. The proposal's reasoning is correct. Add a complementary thought: for non-JSON output (table, brief, text), prefix-stamp plugin-originated rows with a sigil (e.g., `[plugin:bd-jira]`) by default, with a config option to disable for users who pipe to grep. This is consistent with the security-first principle and costs nothing.

8. **Quickstart UX**: ship `bd plugin quickstart` as a built-in subcommand. Dogfooding via "the first sample plugin" is cute but slows down the "I just installed bd, show me how plugins work" path that the v0.1 audience needs.

## Risks not enumerated in the proposal

Three more worth flagging:

### Trust prompt UX in non-TTY contexts

`§The trust layer` (line 108) says "first-use prompt-or-deny (Gatekeeper / Android model)." Both Gatekeeper and Android have a GUI. bd is a CLI used by AI agents — many invocations are non-interactive. The proposal needs to spec:

- Non-TTY first-use behavior: deny by default, with `--auto-grant=path/to/grants.yaml` for headless contexts?
- Agent-mediated grants: when an AI agent installs a plugin, who grants the capabilities? The agent? The human supervisor of the agent?
- CI behavior: how does `bd-jira` work in a GitHub Action where there's no human and no TTY?

This is the kind of question that, unanswered, leads to hacky `BD_TRUST_ALL=1` env var workarounds that defeat the whole trust layer.

### MCP version negotiation as backward-compat gravity well

`§Open risks` (line 193) flags this but doesn't propose a mechanism. The proposal needs an explicit version-compat policy:

- Plugin manifest declares `protocol_version`.
- bd N supports plugin manifest versions M-K through M (where K is the documented compat window, e.g., K=2).
- On version mismatch, bd refuses to launch the plugin and explains.

Without this, every MCP spec revision becomes a forced flag day. With this, the compat window is engineering effort the project signs up for explicitly.

### Plugin update semantics

The proposal describes install/remove (line 149) but not update. Specifically:

- Does `bd plugin update bd-jira` re-prompt for capabilities? (It should, if the manifest's capability set has expanded.)
- Are grants revoked on capability-set narrowing? (They should be — narrowing is the only way to fix an over-grant.)
- What about silent capability transfer in compatible updates (same digest semantics, narrower capability set)? Is that an automatic no-op, or does it still prompt?

The "first-use grant" design is well-thought-out but the lifecycle of grants across updates is not specified. The Gatekeeper analogy partly answers this (re-prompt on changed signature) but the proposal needs to call it out explicitly.

## On the "five plugin-shaped surfaces" framing

`§Why now` (line 19) frames the proposal as consolidating five existing plugin-shaped surfaces. My grounded reading:

- **Tracker registry** (`internal/tracker/registry.go`): Is plugin-shaped, but only for in-tree adapters. 23-method interface; not a third-party load mechanism.
- **Hooks** (`internal/hooks/hooks.go`): 3 events, filesystem scripts, fire-and-forget. Calling this "plugin-shaped" is generous; it's "post-mutation script invocation."
- **integrations/beads-mcp**: Is **the inverse direction** of what the proposal proposes. MCP wraps bd, not bd wrapping MCP servers. Citing this as evidence that bd already has a subprocess plugin pattern is misleading.
- **Storage driver seam**: Is intentionally not a plugin point per the project charter. Including it in this list creates the wrong impression that storage is "almost a plugin."
- **Recipes/molecules/formulas**: Are declarative content packs, not code-loading systems. `grep -rn "plugin.Open" internal cmd` returns zero hits across the entire codebase. Calling these "plugin-shaped" conflates data with code.

A more honest framing: **bd has one in-tree extensibility pattern (the tracker registry) and one out-of-process extension pattern that already works (subprocess `bd --json`). Recipes/molecules/formulas are content, not code. Hooks are minimal. The proposal is to add a real plugin system, not to consolidate existing ones.**

This is not a hit on the proposal's quality — the conclusion is the same — but the framing affects how reviewers read it. Honest framing would also reduce the surface for reviewers to push back with "but recipes already does that."

## Overall verdict

**LGTM with revisions.** The architectural choices are right, the security posture is excellent, and the migration discipline is unusual in a good way. The proposal earns its claim that it's been through serious review.

The revisions I'd ask for before merge:

1. **Demonstrate the `IssueTracker` → MCP-tool mapping** for at least one tracker on paper. If the mapping is lossy in ways that affect FieldMapper or capability detection, switch Tier P's wire protocol to `go-plugin` with gRPC + protobuf and accept the polyglot-author cost.
2. **Reframe the factory refactor** as a real engineering project with its own SLOs (help-tree drift, flag-list drift, startup-time delta), not as "mechanical."
3. **Switch the pilot** to either a never-bundled tracker (forces the third-party-author proof) or to Linear (more representative of common tracker shape than Notion).
4. **Promote subprocess startup** from open risk to first-class design constraint with an explicit answer about warm subprocess pools or daemon strategy.
5. **Spec the capability grammar** (granularity, wildcards, host-match, env-name patterns) before v0.1 ships. Changing it later is a backward-compat nightmare.
6. **Address cross-tier cooperation** (Provider responding to Automation events) or explicitly declare it a non-goal for v0.1 with the use-case workaround documented.
7. **Spec the trust prompt UX** in non-TTY contexts and the grant lifecycle across updates.
8. **Add an MCP version compat policy** in the manifest schema, not just an "open risk" note.
9. **Drop the "agent ecosystem reuse" framing** for MCP-stdio. It's a private protocol with stdio framing; own that.
10. **Drop the "five plugin-shaped surfaces" framing** for honesty: there is one (tracker registry, in-tree-only) and the rest are different shapes.

None of these are blockers. All are tractable in a v0.1 pre-merge revision cycle. With these changes, this is a solid foundation for a multi-year extensibility story.

## References used in this review

- `bd-main/internal/tracker/tracker.go:13-107` — `IssueTracker` and `FieldMapper` interfaces
- `bd-main/internal/tracker/registry.go` — registration mechanism
- `bd-main/internal/tracker/types.go:17-53` — `TrackerIssue` shape
- `bd-main/internal/hooks/hooks.go` — hook event taxonomy and discovery
- `bd-main/internal/storage/storage.go:39-117, 147-160, 251-290` — storage interface composition
- `bd-main/internal/storage/hook_decorator.go` — `HookFiringStore` decorator
- `bd-main/cmd/bd/main.go` — `rootCmd`, `PersistentPreRun`, `noDbCommands`, `readOnlyCommands`
- `bd-main/integrations/beads-mcp/src/beads_mcp/bd_client.py:319-328` — existing MCP-wraps-bd pattern
- `bd-main/internal/notion/{client.go, mapping.go, tracker.go, fieldmapper.go}` — Notion size and shape
- `bd-main/examples/bd-example-extension-go/README.md:5,11-14` — explicit deprecation of in-process Go SDK
- `bd-main/AGENTS.md` — Storage Boundary policy
- `bd-main/docs/PROJECT_CHARTER.md` — Storage Boundary canonical text

---

_kilocode-claude-opus-latest on behalf of maphew_
