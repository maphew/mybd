# Design v2: supported local Dolt CLI install and version contract (mybd-psxg.4)

Status: v2 after adversarial review. v1 drafted in-session from Claude
Explore recon; reviewed by codex gpt-5.6-sol (high): 1 FATAL + 6 MAJOR +
3 MINOR, all adopted. Review transcript: session scratchpad
`psxg4-design-review.txt`. Base: gastownhall/beads main, 2026-07-25. Scope:
the `dolt` executable managed proxied-server mode spawns; distinct from
upstream #4512 (Go-module pin policy).

## 1. Problem (evidence, unchanged)

- Discovery is hardcoded `exec.LookPath("dolt")` (`cmd/bd/uow_factory.go:90`)
  with no override anywhere; ~15 bare `exec.Command("dolt", ...)` sites,
  two of which re-lookup after a path was resolved
  (`internal/doltserver/doltserver.go:1535,1619`).
- Version handling: one advisory capability probe
  (`MinDoltVersionForArchiveLevelConfig = 1.52.1`, `gc_config.go:11-22`);
  docs promise "2.2.0+" with zero code backing; CI pins 2.2.2 in one lane,
  `releases/latest` everywhere else.
- Missing dolt errors *after* `.beads/` creation with three phrasings; an
  incompatible dolt is spawned blind and dies as "exited before listener
  became ready" with the cause buried in server.log; readiness is TCP-only.
- `bd doctor` never checks the executable and is stubbed in proxied mode.
- The deep coupling: generated config.yaml serialized from the pinned
  module's `servercfg.YAMLConfig`, parsed by the external binary under
  `yaml.UnmarshalStrict`; only `archive_level` guarded; shutdown/gc/compact
  SQL `DOLT_GC('--archive-level','0')` + `DOLT_STATS_GC()` ungated
  (`dbproxy/server/doltserver.go:361-383`, `gc_proxied_server.go:162-169`,
  `compact_dolt_proxied_server.go:34-38`).
- Docs: proxied mode's dolt requirement undocumented; no Windows install
  instructions; `.beads/proxieddb` doc drift.

## 2. What the review changed from v1

| v1 | Review finding | v2 |
|---|---|---|
| `dolt_bin_path` in committed metadata.json | **FATAL trust-boundary violation**: committed repo data would select an executable that bd runs on open; repo precedent keeps credential *commands* env-only for exactly this reason (`configfile.go:417-426`); also a portability footgun (absolute paths don't travel) | Resolution order: `BEADS_DOLT_BIN` env → **clone-local gitignored sidecar** (the `ProxiedServerClientInfo` family, `proxied_server_client_info.go:11-54`, already gitignored per `doctor/gitignore.go:36-43`; its writes become atomic first) → PATH. Committed metadata never names executables |
| Hard floor `2.2.0` enforced at startup | Policy, not evidence: docs/CI pins show what's *tested*, not what's *required*; `driver/v2 v2.2.0` has no demonstrated mapping to CLI 2.2.0; dolt release notes place the actual storage boundary at 2.0 (new storage default) with 1.85 the oldest 1.x line reading 2.x storage; a hard 2.2.0 floor strands working setups the current code deliberately allows | v1 rollout: **no hard floor**. Warn below the docs-recommended version; keep capability gates. Establish the real floor empirically with a **cross-version matrix** (init, migrations, sync, reopen-after-write, DOLT_GC, DOLT_STATS_GC, cross-version storage read) — expected outcome ~1.85 or 2.0, enforced only once the matrix exists. The one hard gate that is justified now: refuse a binary that fails the bounded identity/version probe entirely (see below) |
| One capability probe reused for shutdown GC | `SupportsArchiveLevelConfig` tests the YAML config key only; SQL `DOLT_GC` arg, `DOLT_STATS_GC`, and the standalone CLI flag are distinct capabilities that happen to share history (arg exists by 1.52.1, absent in 1.40.0 — coincidence, not contract) | Capability registry with **separate probes** per surface (YAML key, SQL GC arg, stats GC, CLI flag), consistent fallback in every caller (shutdown, `bd gc`, `bd compact` proxied paths) |
| Identity = resolved path + version, cached by path+size+mtime | Conflates the *candidate* for the next launch with the binary *backing the live child*; PATH change/in-place upgrade/symlink retarget makes status describe a file the server isn't running; path+size+mtime is spoofable-by-accident; two workspaces can resolve different candidates for one shared server | Three distinct identities in the contract: (a) candidate (resolved now), (b) launched (recorded at spawn into the **pidfile — natural extension of the psxg.5 pidfile schema v2** from PR 5013: add dolt binary path, OS file identity/digest, parsed version), (c) live (SQL `dolt_version()`). `bd dolt status`/doctor report all three and flag disagreement. Shutdown/adopt decisions key off launched/live identity, never a fresh path lookup |
| Post-ready `dolt_version()` probe; v1 waffled gate-vs-report (Q4) | Complementary to the PR 5013 IDENT handshake (which authenticates the *proxy*, not the backend engine); must run in the child after backend-ready but **before the pidfile is published**, else another client can adopt in the gap | **Gate managed startup** on a bounded (timeout + output-capped) `SELECT dolt_version()` before pidfile publication; external topology: report-only diagnostic (bd doesn't own that lifecycle) |
| `BEADS_DOLT_ALLOW_UNVERIFIED` hatch, loosely specified | Hatch must not bypass floor/trust/arch failures | Env-only, strict-bool parse, loud warning (the `remote_migrate_gate.go:14-33,445-462` pattern); permits only an *unparseable* dev version string, nothing else |
| "every bare exec.Command fixed" in a proxied-scoped PR | Over-promise: bare sites span shared-server, compact, remote-cache, bootstrap, remotes | PR-2 scope = managed proxied lifecycle end-to-end; a follow-up extends resolution+reporting (not floor enforcement) to shared managed mode and the rest |
| winget/scoop for Windows | Not official channels; MSI + Chocolatey are (dolt README) | Document MSI + Chocolatey; enumerate supported OS/arch/libc tuples (amd64/arm64, glibc/musl, Windows PATHEXT, macOS arch/signing) as explicit contract rows with "tested/expected/unsupported" states |
| Hash binary in doctor | Latency for no provenance unless compared to vendor checksum | Default: path, source, parsed version, live version, OS file identity. SHA-256 only verbose/on-request, stated against the official checksum when verifiable |

Probe hardening (new, review finding 6): execution + process-tree timeout,
stdout/stderr caps, regular-file + executable-bit validation, explicit
symlink policy (resolve and report both), TOCTOU note (launch re-validates
file identity captured at probe), normalized prerelease/dev parsing,
arch/loader diagnostics (exec format error → actionable message naming the
architecture mismatch).

## 3. Contract v2 (normative summary)

C1 Discovery: `BEADS_DOLT_BIN` → clone-local sidecar setting → PATH; the
   resolved absolute path threads to every managed-proxied dolt child
   (`--dolt-bin` plumbing already exists, `db_proxy_child.go:98`); the
   `ensureDoltIdentity`/`ensureDoltInit` bare-name leaks in the *shared*
   server path are fixed opportunistically (they already hold a resolved
   path). Committed repo data never selects an executable.
C2 Versioning: bounded probe must succeed (parse or hatch) or startup
   fails with path+output+expectation; sub-recommended version → warning
   naming the docs floor; hard floor deferred to the matrix (own bead).
C3 Identity: candidate/launched/live triple reported by `bd dolt status`,
   proxied startup log, and doctor; pidfile v2 extension carries launched
   identity; disagreement is surfaced, adopt/stop key off launched/live.
C4 Capabilities: per-surface probes, per-caller fallback, cache keyed on
   OS file identity, invalidation re-runs config reconcile
   (`reconcileManagedProxiedServerConfig` already handles both directions).
C5 Startup: child gates pidfile publication on the bounded engine probe;
   failures surface last ~20 lines of server.log + launched identity.
C6 Packaging/docs: per-OS official channels (Linux tarball/install.sh,
   macOS brew + services caveat, Windows MSI/Chocolatey), OS/arch/libc
   support table, provenance = vendor checksum verification at install,
   offline guarantee scoped to discovery/probe/start (not all of bd).
C7 External topology: exempt from spawn/floor rules; live-version probe is
   report-only there; nothing selects external implicitly.

## 4. Upstream shape v2

- PR-1: `internal/doltversion` leaf pkg (stdlib-only; no dolt imports):
  hardened probe, parser (extracted from `gc_config.go:103-138`), resolution
  order, canonical errors; wire into `uow_factory.go:90` + init preflight
  (before `.beads/` writes).
- PR-2: managed-proxied identity threading: sidecar setting, pidfile v2
  dolt-identity fields (stacks on psxg.5's PR 5013 pidfile schema — same
  file, coordinate merge order), pre-publication engine gate, status
  reporting, capability registry + per-caller GC fallbacks.
- PR-3: doctor "Dolt CLI" check — the next single vetted proxied doctor
  subcommand per owner policy (#3794/#3758 pattern); coordinate with
  coffeegoddd first.
- PR-4: docs + CI: prerequisites section, Windows channel, support table,
  `.beads/proxieddb` drift fix, repo-wide `DOLT_VERSION` pin + one
  latest-canary lane so "tested-through" is CI fact.
- Separate bead: **cross-version compatibility matrix** to establish the
  enforceable floor (blocks any hard enforcement, not PRs 1-4).

Tests: unit (resolution order/precedence, hardened probe incl. hung and
garbage-output stub binaries, hatch strictness); integration on the psxg.5
lifecycle lane (missing dolt → preflight refusal pre-`.beads`; stub dolt
with old version string → warning not refusal; unparseable → refusal unless
hatch; binary swap under a live server → status shows candidate≠launched;
engine-probe failure → no pidfile published). Windows/macOS specified,
staged after Linux (psxg.5 lane pattern).

## 5. Review's answers to open questions (adopted)

- Q1 shared-server floor: extend resolution/reporting later; no floor
  extension without the matrix.
- Q2 config home: env → gitignored clone-local → PATH; never committed
  metadata.
- Q3 floor derivation from driver/v2: rejected — unrelated version spaces;
  explicit product constant once the matrix exists.
- Q4 probe gating: gate managed, report external.
- Q5 hashing: verbose/on-request only, against authenticated checksums.

## 6. Follow-ups

- Cross-version matrix bead (floor evidence) — created this session.
- psxg.5 coordination note: pidfile v2 gains dolt-identity fields in PR-2
  here; if #5013 review requests pidfile changes, fold this in then.
