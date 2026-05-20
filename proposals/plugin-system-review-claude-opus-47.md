# Independent Assessment: Plugin System for Beads

> Reviewer: Claude Code (Opus 4.7, high reasoning)
> Date: 2026-05-20
> Subject: `proposals/plugin-system.md` (Draft, dated 2026-05-13)
> Method: Independent review. I did **not** read the other `plugin-system-*.md`
> files in this folder. I verified the proposal's claims against the beads
> source tree at `bd-main/` (HEAD `0bf33da63`).

---

## Verdict

**Strong proposal. Architecturally sound spine, security-first by design, and
honest about its own risks. Approve the *direction* and the pilot-first
migration plan — but three claims need correction and two design gaps need
closing before this becomes an implementation contract.**

The two-tier split (out-of-process MCP Providers / in-process WASM Automations),
the default-deny trust layer, the frozen command tree, and the "storage stays
in-tree" non-goal are all well-judged. The author has clearly thought about the
threat model harder than most plugin proposals do, and the explicit
debt-register-with-removal-criteria discipline is excellent.

What stops this from being a clean LGTM:

1. **The "CGO-free invariant" is factually wrong as stated** — beads already
   ships with `CGO_ENABLED=1` by default. (§ Concern 1)
2. **The MCP adapter cannot "wrap an MCP client behind the existing
   `tracker.IssueTracker` interface" as cleanly as claimed** — the interface
   leaks live Go types (`FieldMapper`, optional capability interfaces) that an
   out-of-process server can't return. (§ Concern 2)
3. **The host has zero MCP *client* infrastructure today** — the "we already
   speak MCP" framing conflates the existing `beads-mcp` *server* (which wraps
   the bd CLI for agents) with a *client* that consumes MCP trackers. The latter
   is greenfield. (§ Concern 3)

None of these are fatal. They change scope estimates and one design principle's
wording, not the verdict.

---

## Claim verification (against `bd-main/` @ `0bf33da63`)

| Proposal claim | Finding | Verdict |
|---|---|---|
| "~15k LOC across `internal/` and `cmd/bd/`" for six trackers | Non-test code: six tracker `internal/` dirs = **13,157 LOC**, + `internal/tracker` pkg = 1,888, + `cmd/bd/*` tracker CLI = 4,165. ~15k for the `internal/` portion is a fair approximation; total is closer to ~19k non-test, ~45k with tests. | ✅ Roughly accurate |
| Six tracker integrations baked in | `internal/{jira,linear,github,gitlab,ado,notion}` all present | ✅ Confirmed |
| Notion is "~1.7k LOC + ~613 LOC CLI" | `internal/notion` = 1,892 non-test LOC; `cmd/bd/notion.go` exists. Close. | ✅ Confirmed |
| Hooks are executable scripts in `.beads/hooks/on_*` | `internal/hooks/hooks.go:2` documents exactly this; `hooks_unix.go:54` / `hooks_windows.go:50` use `exec.CommandContext(ctx, hookPath, issue.ID, event)` | ✅ Confirmed |
| `init()`-based registration "across ~100 files" | **132** files in `cmd/bd/` define `func init()`; 271 `AddCommand` call sites; `NewRootCmd` does **not** exist yet | ✅ Confirmed (under-counted, if anything) |
| `tracker.Registry` factory map | `internal/tracker/registry.go` — global `registry = make(map[string]TrackerFactory)`, mutated by `Register()` | ✅ Confirmed |
| Five "plugin-shaped surfaces" already exist | tracker registry ✅, hooks ✅, `integrations/beads-mcp` ✅, `internal/storage` driver seam ✅, `recipes`+`molecules`+`formula` ✅ | ✅ All five confirmed |
| AGENTS.md documents a "Storage Boundary" | `AGENTS.md:59` "## Storage Boundary" — exists and says talk to storage through a driver interface | ✅ Confirmed |
| `internal/storage/hook_decorator.go` exists | 356 LOC | ✅ Confirmed |
| "CGO-free invariant … static-binary distribution" | `Makefile:32` `export CGO_ENABLED := 1`; `release.yml` builds macOS with `CGO_ENABLED=1` "for embedded Dolt support." A *separate* pure-Go path exists (`Makefile:189`, `gms_pure_go` tag). | ❌ **Inaccurate** |
| "MCP is the protocol agents already speak; we inherit a marketplace" | No MCP client lib in `go.mod`; no Go MCP client code in `internal/`/`cmd/`. `beads-mcp` is a Python *server* wrapping the bd CLI — opposite direction. | ⚠️ **Misleading** |
| New `~/.beads/audit.log` | `internal/audit/` **already exists** (`Entry`, `Append`, `Path`, `EnsureFile`, `LogFieldChange`). Proposal neither references nor reuses it. | ⚠️ Overlap unaddressed |
| Companion plan `~/.cursor/plans/…` and council sessions | Local/agent-private paths; not in repo. | ⬜ Unverifiable |

---

## Strengths

- **Security-first, and it shows.** Default-deny, content-addressed digest
  pinning, first-use capability grants, scrubbed subprocess env, append-only
  audit. The seven non-negotiable principles give the design a real spine, and
  the explicit "name the principle by number if you push back" framing is the
  right way to keep a review focused.
- **The frozen command tree is the standout call.** Treating
  `NewRootCmd(...) → immutable *cobra.Command` as *both* an engineering and a
  security property (a compromised dep can't shadow `bd push`) is exactly right
  for a CLI that holds tracker tokens. This alone is worth doing even if the rest
  slips.
- **Storage non-goal is correctly drawn.** Refusing JSON-RPC on the hot read
  path, and pointing at `go-plugin`/gRPC + protobuf as the *only* reconsideration
  trigger, shows the author knows where the performance cliffs are.
- **Migration discipline.** "Smallest credible slice" + a debt register where
  every fallback has a removal milestone and removal *criteria* is the kind of
  rigor most plugin proposals skip. Expired fallbacks framed as defects is the
  correct posture.
- **Honest risk section.** Subprocess cold-start tax, Windows `.bat` migration,
  MCP version churn, Notion-as-pilot honesty — the author surfaced most of the
  things a reviewer would otherwise have to dig for.

---

## Material concerns (ranked)

### 1. The "CGO-free invariant" claim is wrong, and it weakens an argument that doesn't need it

The proposal states (Open risks, and Alternatives) that beads has a "CGO-free
invariant" and "static-binary distribution," that wazero "preserves it," and
that "anyone who proposes a different WASM runtime (wasmtime-go, wasmer) breaks
our static-binary distribution."

Reality from the tree:

- `Makefile:32`: `export CGO_ENABLED := 1` (the default build).
- `.github/workflows/release.yml`: macOS binaries built `CGO_ENABLED=1`
  "for embedded Dolt support."
- A pure-Go path *does* exist behind the `gms_pure_go` tag with
  `CGO_ENABLED=0` (`Makefile:189`, plus a CI job that guards it).

So beads is **not** CGO-free today; it has *two* build modes, and the primary
one uses CGO for embedded Dolt. The argument the author actually wants is:
"wazero keeps the *pure-Go* build viable and doesn't *add* a new CGO dependency"
— which is true and is a genuine point in wazero's favor over wasmtime-go/wasmer
(both CGO). But as written, the ADR premise ("lock in CGO-free") is false on its
face and an informed reviewer will bounce on it. **Fix:** restate as "wazero
adds no CGO dependency and preserves the existing `CGO_ENABLED=0` pure-Go build;
wasmtime-go/wasmer would force CGO into even the pure-Go build." Then the ADR
stands.

### 2. `tracker.IssueTracker` is not cleanly satisfiable by a thin MCP wrapper

Step 3 of the migration says `internal/tracker/mcp_adapter.go` "satisfies
`tracker.IssueTracker` by wrapping an MCP stdio client." The interface
(`internal/tracker/tracker.go:13`) is richer than a CRUD surface:

- `FieldMapper() FieldMapper` returns a **live Go interface** whose methods pass
  `interface{}` priorities/statuses bidirectionally
  (`PriorityToBeads(interface{}) int`, `StatusToTracker(types.Status) interface{}`,
  …). An out-of-process MCP server cannot hand back a Go `FieldMapper`. The
  mapping logic must therefore either move *entirely into the plugin* (host never
  calls `FieldMapper`) or be reimplemented host-side per plugin — and the
  proposal doesn't say which.
- Optional capability interfaces — `BatchPushTracker`, `BatchPushDryRunner`,
  `PullStatsProvider` — are discovered today via Go type assertions. Those don't
  cross a process boundary; capability negotiation has to move into the manifest
  + RPC method set, which is real protocol design work, not "wrapping."
- `Init(ctx, store storage.Storage)` hands the tracker a live storage handle.
  An out-of-process plugin can't take a `storage.Storage`. What does the adapter
  pass? This needs an answer.

This is the single biggest under-scoped item. The MCP adapter is not a wrapper;
it's an interface re-design plus a field-mapping relocation. **Recommendation:**
make "define the Provider RPC schema + decide where field mapping lives" an
explicit, named step *before* the Notion pilot, and budget for it. The Notion
pilot will otherwise discover this the hard way.

### 3. "We already speak MCP" is true for agents, not for the host

The proposal leans on MCP because "it's the protocol agents already speak" and
implies the host inherits an ecosystem for free. Two corrections:

- The bd binary has **no MCP client** today (no MCP lib in `go.mod`, no client
  code). `integrations/beads-mcp` is a Python MCP *server* that shells out to the
  `bd` CLI to expose beads *to* agents — the inverse data-flow. So host-side MCP
  client integration is greenfield, including connection lifecycle, version
  negotiation, and the timeout/heartbeat machinery the proposal lists.
- Notably, `beads-mcp`'s own README **recommends CLI+hooks over MCP** for
  shell-capable environments, citing ~1–2k vs 10–50k token cost. That cost is on
  the agent↔MCP path, not host↔plugin RPC, so it doesn't directly indict this
  design — but it's worth a sentence acknowledging it, because the provenance
  envelope deliberately pushes plugin output back *into* agents, where token
  cost and prompt-injection surface re-enter.

The ecosystem-reuse benefit is *real* for third-party plugin authors (they can
reuse existing MCP SDKs/servers). Just don't frame it as host-side reuse.

### 4. The proposed audit log duplicates an existing one

`internal/audit/` already implements an append-only audit trail (`Append`,
`Entry`, `Path`, `EnsureFile`). The proposal introduces `~/.beads/audit.log`
with overlapping semantics ("append-only JSONL … not writable by plugins") and
never mentions the existing package. Either reuse `internal/audit` (preferred —
one audit story, one format, one tamper-resistance argument) or justify a
parallel log. As written this risks two divergent audit subsystems.

### 5. The "warm subprocess" SLO has no host-side mechanism yet

The 50 ms p95 Provider-overhead SLO "assumes warm subprocesses," and cold start
is flagged as an open risk (good). But there's no described component that
*keeps* a Provider warm across `bd` invocations — each `bd jira sync` is a fresh
process. beads *does* have a long-lived server concept for Dolt
(`proxied_server.go`, `shared_server_integration_test.go`, `internal/doltserver`).
The proposal should either (a) state that Providers are cold-per-invocation and
move the SLO to the cold path, or (b) propose a plugin host-daemon and reference
the existing server pattern as prior art. Right now the headline SLO is measured
against a state the architecture doesn't yet produce.

### 6. cosign + ORAS + wazero + extism is a heavy dependency add

`go.mod` already carries ~248 require lines. Adding an MCP client lib, wazero,
the Extism host SDK, ORAS, and (especially) **cosign/sigstore** is a large
transitive surface — sigstore in particular pulls a notoriously deep tree and
will move the needle on binary size and supply-chain audit cost. This is
ironic given the security framing: the trust layer's own verifier becomes one of
the largest new attack surfaces. Worth: (a) a binary-size budget line in the
CI gates (the criteria list has memory/latency but not binary size, despite
binary size being raised in feedback Q2), and (b) considering whether cosign can
be deferred to v1 *and* kept behind a build tag so the pure-Go build doesn't pay
for it.

---

## Answers to the author's eight feedback questions

The proposal explicitly asks for these, so:

1. **Storage non-goal — forever, or carve out a future gRPC Provider?**
   Keep it in-tree; do **not** promise a future Storage Provider in v1 docs.
   Document the *trigger condition* instead (the `go-plugin` + protobuf path),
   not a roadmap commitment. A speculative carve-out invites someone to build
   against it. The hot-read-path argument is correct and sufficient.

2. **Bundle 5 trackers through v1, drop in v2?** The ratio is fine, but drive
   it by data, not a guess. The honest move: ship the Notion pilot, measure
   install success + cold-start, and let *that* decide whether GitHub/Linear
   leave the binary in v1.x. Don't drop two arbitrarily for binary size before
   you have the Provider RPC schema (Concern 2) proven on one real tracker.

3. **Hook breaking-change appetite (aggressive `--allow-unsafe-hooks` vs grace
   period)?** Lean aggressive but soften the *timing*, not the *default*. Keep
   default-deny on unsandboxed hooks, but ship the WASM runtime, the
   `bd plugin migrate-hook` tool, and docs *in the same release* you flip the
   gate — not before. Users with `.bat`/shell hooks in CI will complain loudly
   if the gate flips before a migration tool exists. The debt register already
   ties removal to "migration tool works on common scripts" — apply that same
   gate to *introduction*, not just removal.

4. **Naming (`provider`/`automation`/`plugin`, retire `extension`)?** Good.
   `provider`/`automation` are clear and map to the in-/out-of-process split.
   Retiring `extension` (the deprecated in-process Go SDK in
   `examples/bd-example-extension-go/`) avoids a third confusing term. Only
   caution: "provider" is overloaded in the cloud world; scope it as
   "tracker/integration provider" in user-facing help.

5. **cosign required from day one?** No — opt-in for v0.1 with the
   always-on warning (as proposed) is the right friction trade-off, *provided*
   digest pinning is mandatory from v0.1 (it is). Mandatory pinning already
   defeats silent tag-swap; signatures add publisher identity, which hobbyist
   authors will resist. Default-required by v1 is the right ramp. (See Concern 6
   re: keeping the cosign dep itself optional/build-tagged.)

6. **Hosted plugin index in v1?** Push to v1.x. `bd plugin install oci://…` and
   `gh:owner/repo` cover the bootstrap case. A curated index is a trust and
   moderation commitment (who vets entries? who's liable for a malicious one?)
   that shouldn't gate the core mechanism. Ship discovery-by-URL first.

7. **Always-wrap provenance envelope, or only under MCP?** Always-wrap. The
   cost is negligible, consumers unwrap trivially, and a *consistent* envelope
   is what makes the prompt-injection-resistance argument hold — an inconsistent
   one (sometimes wrapped, sometimes not) is worse than none because consumers
   stop trusting the marker. Just version the envelope schema from day one.

8. **`bd plugin quickstart` built-in or first sample plugin?** Built-in
   subcommand. Quickstart needs to work *before* the user trusts any plugin, and
   bootstrapping the trust UX through an untrusted plugin is a chicken-and-egg /
   first-grant-prompt problem. Dogfood elsewhere (e.g. ship `bd-needs-review-gate`
   from the appendix as the canonical sample), not on the onboarding path.

---

## Smaller issues / nits

- **SLO list omits binary size** despite binary size being raised in Q2 and the
  dependency add in Concern 6. Add a binary-size regression gate.
- **`grants.json` location drift:** principle 1 says
  `~/.beads/plugins/grants.json`; the trust-layer section and appendix agree, but
  the lockfile is variously `~/.beads/plugins/lock.json` and project-scoped
  `.beads/plugins.lock` vs `.beads/plugins/plugins.lock`. Pin one path scheme;
  the project-vs-home override precedence needs a sentence (which wins on
  conflict?).
- **Grant revocation / key rotation** is mentioned for audit events but not
  specified: when a plugin updates to a new digest, are prior capability grants
  carried over, or must the user re-grant? (Security-correct answer: re-prompt on
  digest change for any capability above read-only. Worth stating.)
- **WASI `network:host` for Automations** (`internal/automations/`) sits oddly
  next to "in-process, frequently invoked." If an Automation can open sockets,
  the cold-vs-hot and sandbox-escape calculus changes. Consider: do Automations
  *ever* need network, or is that exclusively a Provider capability? Narrowing it
  tightens the model.
- **`FieldMapper`'s `interface{}` signatures** are themselves a smell the plugin
  work could clean up; if mapping moves into plugins, the host-side interface
  could become concretely typed. Flag as a possible win, not just a cost.
- The mermaid diagram lists "Extism host SDK" inside the host box; confirm the
  Extism *host* SDK (not just the PDK) is CGO-free in the configuration you
  intend — it generally is with wazero as the runtime, but the ADR should assert
  it explicitly given Concern 1.

---

## Recommendation

**Proceed, with sequencing changes.**

1. **Do the `NewRootCmd` factory + frozen tree first, on its own.** It's
   mechanical, behavior-preserving, independently valuable, and the 132-`init()`
   refactor is the highest-confidence, lowest-risk piece. Land it before any
   plugin code.
2. **Insert a "Provider RPC schema + field-mapping relocation" design step
   before the Notion pilot** (Concern 2). This is the real unknown; resolve it on
   paper, then let Notion validate it.
3. **Correct the CGO-free framing** (Concern 1) and **reconcile the audit log
   with `internal/audit`** (Concern 4) before they harden into the spec.
4. **Re-baseline the Provider SLO to the cold path** or commit to a plugin
   host-daemon (Concern 5), and **add a binary-size gate** (Concern 6).

The security model and the overall two-tier shape are the right bet for a
token-handling, AI-agent-driven CLI. The gaps above are scope and accuracy
corrections, not a redesign. With them addressed, this is a build-worthy plan.

---

*Assessed by Claude-Opus-4.7-high on behalf of maphew, using claude code cli.*
