# Plugin System Review Synthesis

> Combined synthesis of independent reviews for `proposals/plugin-system.md`
> Date: 2026-05-20
> Sources: `proposals/plugin-system-review-*.md`

This document consolidates the independent reviews of the Beads plugin-system
proposal. It intentionally covers only the `plugin-system-review*.md` files. The
separate `plugin-system-recommendation-kilo.md` is a companion proposal, not one
of the review inputs synthesized here.

## Source Reviews

| File | Signature |
|---|---|
| `plugin-system-review-claude-opus-47.md` | _Claude-Opus-4.7-high on behalf of maphew, using claude code cli_ |
| `plugin-system-review-codex-gpt-55.md` | _codex-gpt-5.5-xhigh on behalf of maphew_ |
| `plugin-system-review-kilo-gpt-55.md` | _kilocode-openai/gpt-5.5-xhigh on behalf of maphew_ |
| `plugin-system-review-kilo-opus-47.md` | _kilocode-claude-opus-4.7-max on behalf of matt_ |
| `plugin-system-review-kilo-sonnet-45.md` | _kilocode-claude-opus-latest on behalf of maphew_ |

## Common Ground

The reviews converge on the following points.

### Direction: approve the goal, not the implementation plan as written

All reviewers agree that Beads needs a real extension boundary and that the
proposal is directionally strong. None recommend abandoning the plugin-system
work. The shared verdict is closer to:

> Proceed with a narrowed, better-specified pilot and treat the current draft as
> architecture direction, not an implementation contract.

The most common approval conditions are:

- Specify the Provider protocol before implementation.
- Separate the command-construction refactor from executable plugins.
- Rework performance gates around real cold-start behavior.
- Fill in trust lifecycle details before executing untrusted code.
- Treat WASM Automations and OCI distribution as later or separately approved
  slices unless their costs are measured.

### Security principles are the right foundation

The reviewers agree that these are correct default positions:

- No plugin should execute without an explicit trust decision.
- Digest pinning should be mandatory from the beginning.
- Implicit `bd-*` PATH discovery should not be the primary plugin mechanism.
- Subprocess environment should be scrubbed and allowlisted.
- Plugin output that crosses an AI-facing trust boundary needs provenance.
- Capabilities, grants, lockfiles, and audit events belong in the core design.

Several reviewers caution that the proposal overstates what is enforceable for
native subprocess Providers. Environment allowlists and RPC scopes are
enforceable by the host. Filesystem and network capabilities for native
subprocesses are mostly consent and audit metadata unless Beads adds an OS
sandbox, broker, container boundary, or platform-specific restrictions.

### Storage should stay in-tree for v1

All reviews agree that storage must not be part of the first plugin system.
The storage API is broad, hot-path, and central to Beads' data integrity.
JSON-RPC over stdio is the wrong shape for storage reads and writes.

There is mild disagreement over whether the proposal should mention a possible
future Storage Provider at all. Even the reviews that allow a future mention
frame it as a separate ADR or charter-level decision, not a v1 extension point.

### The Provider contract is the largest underspecified area

Every review identifies the MCP Provider adapter as underdesigned. The proposal
says an MCP adapter can wrap `tracker.IssueTracker`, but today's tracker
boundary is not an external ABI:

- `FieldMapper()` returns a live Go interface and traffics in `interface{}`.
- Optional capabilities such as `BatchPushTracker`, `BatchPushDryRunner`, and
  `PullStatsProvider` are discovered with Go type assertions.
- `Init(ctx, store storage.Storage)` hands an in-process tracker a live storage
  handle.
- Tracker-specific commands currently contain concrete integration behavior,
  filtering, ID generation, lock/staleness checks, config handling, dry-run
  behavior, and JSON output details.
- Error classes, rate limits, warnings, conflict metadata, partial failures, and
  batch semantics need stable wire schemas.

The common request is to define a versioned Provider protocol first. The host
should treat `IssueTracker` as an internal adapter target, not as the external
contract. A paper mapping from current tracker methods and optional capabilities
to explicit RPC methods should precede the pilot.

### Command plugins are ambiguous and should not mutate Cobra directly

The proposal says there are exactly two paradigms, Providers and Automations,
but also implies plugin-contributed subcommands during `NewRootCmd`
construction. Reviewers consistently flag this as either a third extension
surface or an ambiguity.

The shared direction is:

- For v0.1, keep third-party arbitrary Cobra mutation out of scope.
- Prefer host-owned commands and manifest-declared shims that dispatch to
  Provider capabilities.
- If command contributions exist later, define their own contract for help,
  flags, completions, `--json`, provenance, no-db/read-only metadata, conflict
  prevention, and trust prompts.

### `NewRootCmd` is valuable but not a trivial refactor

Reviewers agree that replacing global `rootCmd` plus `init()` side effects with
explicit construction is worthwhile. The "frozen tree" property is valuable for
testability and security.

They also agree the proposal understates the work:

- Multiple reviews found more than 130 `init()` registrations under `cmd/bd`.
- Existing command globals, allowlists, `PersistentPreRun`, store setup,
  hook setup, molecule loading, and command metadata make this more than a
  simple mechanical change.
- Cobra cannot enforce true immutability by itself. The realistic property is
  "no exposed registration API after construction."

The recommended validation is help-tree, flag-list, command-set, and startup
snapshot testing, not just "existing tests still pass."

### Performance gates need cold/warm separation

All reviews object to mixing no-plugin startup, lockfile scan, cold Provider
startup, warm RPC, daemon/broker startup, and WASM instantiation into one set of
SLOs.

The common revision is to split benchmarks into at least:

- No-plugin CLI startup.
- `bd --help` and help rendering.
- Plugin metadata/lockfile scan.
- Provider cold start.
- Provider warm RPC.
- Full tracker sync cold path.
- WASM instantiation and memory, if Automations remain in scope.
- Binary size impact from new dependencies.

The `+50 ms` Provider overhead target is repeatedly called unrealistic unless
it excludes cold startup or Beads adds a daemon/long-lived provider strategy.

### The trust model needs lifecycle rules

The reviews broadly agree the trust layer has the right intent but needs
specific lifecycle semantics:

- Global lockfile vs project lockfile precedence.
- User grants vs project-pinned digest conflicts.
- Whether grants are per digest, package identity, version, project, user, or
  capability set.
- Re-prompt behavior on digest changes or expanded capabilities.
- Capability narrowing and grant cleanup.
- First-use behavior in non-TTY, CI, and AI-agent-supervised contexts.
- Local development plugin pinning without weakening "no digest, no execution."
- Revocation as a first-class operation.
- Audit log integrity, tamper evidence, and reuse of existing audit code.
- Capability grammar for env, network, filesystem, tracker read/write, and
  host functions.

### Hosted plugin index should wait

All reviewers who answered the question recommend deferring a hosted or curated
plugin index to v1.x. URI/local install plus lock/grant/audit is enough for the
first release. A curated index adds trust, moderation, and product obligations
that should not block the core runtime.

### `bd plugin quickstart` should be built in

All reviewers who answered the question recommend making quickstart a built-in
host command. It must work before the user has installed or trusted any plugin.
Dogfooding should happen through sample plugins, not through the onboarding
command itself.

### Digest pinning now, signatures phased in

All reviewers support mandatory digest pinning from day one. Most recommend
cosign/signature verification as optional or official-plugin-only early on, with
warnings for unsigned plugins and stronger requirements later.

The common rationale is that digest pinning prevents silent tag swaps, while
publisher identity and signing workflows can be phased in without blocking early
community experimentation.

## Consolidated Required Revisions

These are the revisions that appear across the reviews strongly enough to treat
as shared review output.

1. Rewrite the status of the current draft as an architecture direction and
   pilot plan, not an implementation-ready spec.
2. Define the Provider RPC schema before any tracker extraction. Include method
   schemas, capability negotiation, batch/dry-run/stats support, errors,
   partial failures, conflict metadata, rate limits, timeouts, compatibility,
   and field mapping.
3. Decide where field mapping lives. Avoid exposing `FieldMapper` as a live Go
   interface across the process boundary.
4. Define how Providers interact with storage. Prefer returning host-applied
   patch sets or a narrow host-mediated write API over handing plugins anything
   resembling `storage.Storage`.
5. Make third-party command contribution either explicitly out of scope for v0.1
   or define a manifest-only host-shim contract.
6. Reframe `NewRootCmd` as a significant standalone refactor with command-tree,
   help, flag, and startup regression tests.
7. Split performance SLOs by no-plugin startup, scan, cold Provider, warm RPC,
   full sync, WASM, and binary size.
8. Specify lockfile and grant precedence, update semantics, revocation, non-TTY
   behavior, and local development flow.
9. Clarify Provider capability enforcement: distinguish host-enforced controls
   from advisory consent/audit controls.
10. Reconcile the proposed plugin audit log with existing audit facilities and
    state whether the log is host-controlled, append-only, tamper-evident, or
    merely best-effort.
11. Add a protocol-version policy for MCP and, if Automations remain, for WASI.
12. Add conformance tests or a `bd plugin test` harness for tracker plugins so
    retry/backoff, pagination, response limits, cancellation, and sanitization
    do not regress outside the tree.
13. Defer the hosted plugin index.
14. Keep `bd plugin quickstart` built in.

## Reviewer-Specific Additions

These points are not necessarily contradicted by other reviewers, but they are
distinctive enough to preserve under the reviewer's signature.

### _Claude-Opus-4.7-high on behalf of maphew, using claude code cli_

- The proposal's "CGO-free invariant" claim is factually wrong against the
  current tree: default builds use `CGO_ENABLED=1` for embedded Dolt, while a
  pure-Go build exists behind tags. The correct claim is that wazero preserves
  the existing `CGO_ENABLED=0` build path and does not add a new CGO dependency.
- Beads currently has an MCP server integration, not a host-side MCP client.
  Host-side MCP client infrastructure is greenfield.
- The proposal introduces `~/.beads/audit.log` without addressing the existing
  `internal/audit` package. Prefer one audit story.
- The warm-subprocess SLO has no mechanism unless Beads adds a plugin host
  daemon or explicitly accepts cold-per-invocation Providers.
- ORAS, wazero, Extism, MCP client libraries, and especially cosign/sigstore add
  a large dependency and binary-size surface. Add a binary-size budget and
  consider deferring or build-tagging signature verification.

### _codex-gpt-5.5-xhigh on behalf of maphew_

- The current proposal combines too many approval units: command refactor,
  trust, OCI, MCP Providers, Notion extraction, WASM, hook deprecation, and
  provenance wrapping. Split approval into smaller slices.
- The smallest credible slice should be command construction, typed Provider
  protocol, one local-only Provider pilot, then trust/distribution hardening.
- WASM Automations should move to a separate ADR because Beads previously
  removed wazero-related dependencies after binary size and startup regressions.
- OCI distribution is premature for the first slice. Start with local folder
  installs and explicit digest-pinned release assets.
- Always wrapping all existing `bd --json` output is a breaking change unless it
  is versioned or opt-in.
- A concrete threat model with hostile fixture plugins should precede execution.

### _kilocode-openai/gpt-5.5-xhigh on behalf of maphew_

- Provider capabilities overclaim sandboxing. Native subprocesses can ignore
  network and filesystem capability declarations unless Beads adds real OS-level
  controls or brokers.
- Audit wording should be softened from "append-only" to "host append-only" or
  "tamper-evident" unless stronger isolation is added.
- Cobra's frozen tree should be specified as no exposed post-construction
  registration API, not as a complete security boundary.
- Hook migration should include `bd doctor` warnings, a reporting phase,
  `bd plugin migrate-hook`, Windows guidance, and at least one explicit warning
  release before default-deny.
- Project locks should pin shared plugin versions without bypassing per-user
  grants.

### _kilocode-claude-opus-4.7-max on behalf of matt_

- The Provider privilege boundary should be centered on how a subprocess can
  affect Beads state: host functions vs patch sets, conflict resolution, and
  batch chattiness.
- Beads should provide a reference host SDK, a conformance harness, or both, so
  plugin authors do not reimplement retry/backoff, pagination guards, response
  limits, cancellation, and sanitization inconsistently.
- Automation scope silently expands today's three hook events into formatters,
  lint rules, transforms, and broader event handling. Add an Automation event
  catalog if this remains in scope.
- The word "plugin" already has another meaning in `bd-main/plugins/beads/`
  for AI-tool plugin manifests. Resolve this naming collision before landing
  the runtime plugin system.
- Storage decorators already compose poorly. If Automations attach at the
  storage layer, the proposal must address `UnwrapStore` and optional storage
  capability interfaces.
- Add first-class `bd plugin revoke`.
- Add air-gap and enterprise distribution semantics.
- Specify uninstall residue, telemetry/observability, plugin author signing
  identity, WASI revision pinning, AI-agent plugin discovery, reproducible build
  expectations, and charter compliance for new commands.

### _kilocode-claude-opus-latest on behalf of maphew_

- The `IssueTracker` to MCP mapping may be lossy enough that `go-plugin` with
  gRPC/protobuf should remain a live alternative, not just a future storage
  fallback.
- Existing `integrations/beads-mcp` is the inverse direction: MCP wraps `bd`,
  while the proposal makes `bd` wrap MCP servers. The "free agent ecosystem
  reuse" framing is therefore overstated.
- The proposal's "five plugin-shaped surfaces" framing is too generous. Hooks,
  recipes, formulas, storage seams, and the existing MCP server are different
  shapes; the proposal is adding a real plugin system more than consolidating
  existing ones.
- Notion is a poor pilot because it is idiosyncratic and does not prove the
  third-party author story.
- Cold-start behavior should be elevated to a design constraint, potentially
  requiring a daemon or warm subprocess strategy.
- Capability grammar must be specified before v0.1 because changing it later is
  a compatibility problem.
- Cross-tier cooperation is unsolved: for example, a Provider wanting to react
  to an Automation hook event.
- First-use prompts need a non-TTY, CI, and AI-agent supervision story.

## Open Arguments

These are meaningful disagreements or unresolved forks between the reviews.

### 1. How narrow should v0.1 be?

**Narrowest path.** _codex-gpt-5.5-xhigh on behalf of maphew_ recommends
approving only an exploration/pilot: root command factory, local-only typed
Provider protocol, fake/local Provider harness, and one experimental tracker
behind a flag. Defer WASM, OCI, curated index, and default JSON envelope changes.

**Trust-first path.** _kilocode-claude-opus-latest on behalf of maphew_
recommends doing the factory refactor and trust layer in v0.1, then deferring
the tracker pilot until the trust layer is in production.

**Architecture-with-revisions path.** _Claude-Opus-4.7-high on behalf of maphew,
using claude code cli_, _kilocode-openai/gpt-5.5-xhigh on behalf of maphew_, and
_kilocode-claude-opus-4.7-max on behalf of matt_ are more willing to keep the
two-tier architecture intact if the Provider contract, trust lifecycle,
performance, audit, and migration details are specified first.

### 2. Is MCP-stdio the right Provider wire protocol?

**Use MCP framing, but design a Beads-specific Provider schema.** This is the
dominant position across _Claude-Opus-4.7-high on behalf of maphew, using claude code cli_, _codex-gpt-5.5-xhigh on behalf of maphew_,
_kilocode-openai/gpt-5.5-xhigh on behalf of maphew_, and _kilocode-claude-opus-4.7-max on behalf of matt_.

**Re-evaluate MCP against `go-plugin`/gRPC.** _kilocode-claude-opus-latest on
behalf of maphew_ argues that the current `IssueTracker` shape may be a poor fit
for MCP tools and asks for a method-by-method mapping before committing. If the
mapping is lossy, `go-plugin` with gRPC/protobuf may be the better Provider
protocol despite the reduced polyglot story.

### 3. What should the tracker pilot be?

**Start with Notion after the contract is specified.** _Claude-Opus-4.7-high on
behalf of maphew, using claude code cli_, _codex-gpt-5.5-xhigh on behalf of
maphew_, and _kilocode-openai/gpt-5.5-xhigh on behalf of maphew_ treat Notion as
acceptable or reasonable, but only after the Provider contract is explicit and
with parity tests or a harness.

**Use two pilots.** _kilocode-claude-opus-4.7-max on behalf of matt_ recommends
Notion plus Linear or GitHub, arguing that one pilot allows shortcuts and does
not stress realistic tracker complexity.

**Do not use Notion as the main proof.** _kilocode-claude-opus-latest on behalf
of maphew_ recommends either a never-bundled tracker to prove third-party author
experience or Linear as a more representative migration.

### 4. Should existing bundled trackers stay bundled through v1?

**Keep them bundled through v1.** _Claude-Opus-4.7-high on behalf of maphew,
using claude code cli_, _codex-gpt-5.5-xhigh on behalf of maphew_,
_kilocode-openai/gpt-5.5-xhigh on behalf of maphew_, and
_kilocode-claude-opus-latest on behalf of maphew_ all favor keeping the current
trackers bundled until install/update/recovery UX is proven.

**Drop one or two sooner.** _kilocode-claude-opus-4.7-max on behalf of matt_
argues that keeping all bundled through v1 hides whether the plugin system is
really working. It recommends migrating an additional tracker, such as Linear or
GitHub, earlier.

### 5. How aggressive should hook migration be?

**Staged default-deny.** _codex-gpt-5.5-xhigh on behalf of maphew_ and
_kilocode-openai/gpt-5.5-xhigh on behalf of maphew_ prefer warning, migration,
and compatibility windows before flipping executable hooks behind
`--allow-unsafe-hooks`.

**Aggressive destination, gated by tooling.** _Claude-Opus-4.7-high on behalf of
maphew, using claude code cli_ and _kilocode-claude-opus-latest on behalf of
maphew_ accept the aggressive security destination if the WASM runtime, docs,
and `bd plugin migrate-hook` ship in the same release as the gate.

**Aggressive by default.** _kilocode-claude-opus-4.7-max on behalf of matt_
supports an aggressive visible banner and default-deny path, with a beta period
and migration tooling.

### 6. Should plugin-origin `--json` always be provenance wrapped?

**Always wrap.** _Claude-Opus-4.7-high on behalf of maphew, using claude code
cli_, _kilocode-claude-opus-4.7-max on behalf of matt_, and
_kilocode-claude-opus-latest on behalf of maphew_ support always wrapping
plugin-origin JSON output in a provenance envelope, arguing that a consistent
schema is easier to audit and safer for AI-agent contexts.

**Do not break existing `--json`.** _codex-gpt-5.5-xhigh on behalf of maphew_
and _kilocode-openai/gpt-5.5-xhigh on behalf of maphew_ warn that always
wrapping existing command JSON is a breaking change. They prefer wrapping only
MCP/AI-facing trust boundaries, plugin-specific result objects, or a versioned
or opt-in output mode.

### 7. Should WASM Automations be part of the first approval?

**Separate ADR / defer.** _codex-gpt-5.5-xhigh on behalf of maphew_ is the
strongest advocate for removing WASM Automations from the Provider v0.1 path,
especially given prior binary-size and startup concerns.

**Keep the tier, but specify it.** _kilocode-openai/gpt-5.5-xhigh on behalf of
maphew_, _kilocode-claude-opus-4.7-max on behalf of matt_, and
_kilocode-claude-opus-latest on behalf of maphew_ accept the Automation tier in
principle but require an event catalog, migration plan, capability grammar,
measurements, and binary-size gates.

**Proceed after sequencing corrections.** _Claude-Opus-4.7-high on behalf of
maphew, using claude code cli_ supports the two-tier shape and focuses more on
Provider schema, CGO wording, audit reuse, cold-start SLOs, and binary-size
budget.

### 8. Should the storage future carve-out remain?

**Drop the carve-out.** _codex-gpt-5.5-xhigh on behalf of maphew_ and
_kilocode-claude-opus-4.7-max on behalf of matt_ recommend no future Storage
Provider language in v1 docs, because it invites scope creep and conflicts with
the project charter.

**Mention only a trigger condition or separate ADR.** _Claude-Opus-4.7-high on
behalf of maphew, using claude code cli_ and _kilocode-openai/gpt-5.5-xhigh on
behalf of maphew_ allow a future note only if it is clearly a separate design
requiring binary protocol and performance evidence.

**Keep a small shelf note.** _kilocode-claude-opus-latest on behalf of maphew_
supports a single sentence saying a future Storage Provider via gRPC/go-plugin
could be reconsidered if justified by data.

### 9. Is the CGO/static-binary argument factually correct?

**Incorrect as written.** _Claude-Opus-4.7-high on behalf of maphew, using
claude code cli_ verifies that the default build currently uses `CGO_ENABLED=1`
for embedded Dolt, with a separate pure-Go path. The proposal should not claim a
blanket CGO-free invariant.

**Accepted by one review.** _kilocode-claude-opus-4.7-max on behalf of matt_
accepts the proposal's "Wazero, CGO-free" argument as preserving Beads' static
binary distribution invariant.

**Synthesis.** Treat this as a factual item to re-check in the source before the
proposal is updated. The safer wording is that wazero does not add a new CGO
requirement and preserves any existing pure-Go build path.

### 10. Is "plugin" the right umbrella term?

**Mostly acceptable.** _Claude-Opus-4.7-high on behalf of maphew, using claude code cli_, _codex-gpt-5.5-xhigh on behalf of maphew_,
_kilocode-openai/gpt-5.5-xhigh on behalf of maphew_, and _kilocode-claude-opus-latest on behalf of maphew_ broadly
accept `provider` / `automation` / `plugin`, with minor naming cautions.

**Resolve an existing collision first.** _kilocode-claude-opus-4.7-max on behalf
of matt_ argues that `bd-main/plugins/beads/` already uses "plugin" for AI-tool
manifest packages, so the runtime plugin proposal must either rename that
directory or use a different umbrella term such as `extension` / `ext`.

## Suggested Maintainer Decision Order

The reviews imply the following decision order for the proposal revision:

1. Decide the v0.1 slice: Provider-only pilot, trust-first, or full two-tier
   architecture with narrowed implementation gates.
2. Decide the Provider protocol direction: MCP framing with Beads-specific
   schema vs `go-plugin`/gRPC.
3. Decide whether third-party command contributions exist in v0.1.
4. Decide the tracker pilot: Notion, Linear/GitHub, a new tracker, or two
   pilots.
5. Decide hook migration timing and whether WASM Automations are part of v0.1.
6. Decide provenance-envelope compatibility policy for `--json`.
7. Resolve naming collision and storage carve-out wording.
8. Re-run source-grounded factual checks: LOC counts, CGO build modes, existing
   audit package, current MCP direction, and command registration counts.

## Short Combined Recommendation

The combined review position is:

> Keep the architecture direction, but revise the proposal before implementation.
> Land the command factory as its own tested refactor, specify the Provider
> protocol and trust lifecycle in detail, keep storage in-tree, avoid arbitrary
> command mutation, split performance gates by cold/warm paths, defer index
> work, and treat WASM/OCI/provenance-breaking behavior as separately gated
> decisions unless the revision supplies measurements and compatibility plans.
