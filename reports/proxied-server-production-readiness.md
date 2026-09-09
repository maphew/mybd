# Proxied Dolt server production-readiness audit

**Campaign:** `mybd-psxg` — Productionize local-first proxied Dolt mode  
**Audit date:** 2026-07-23  
**Authoritative source:** `gastownhall/beads` `upstream/main` at
`2f9367d6a76e8bab2bf056e0a1c545014f5fe18f`  
**Coordination branch:** `campaign/proxied-server-readiness`  
**Scope:** implementation, lifecycle, data movement, platform coverage,
failure paths, documentation, and current upstream ownership

## Executive verdict

Proxied-server mode is **implemented but insufficiently verified overall**. It
is no longer gated, and upstream `main` has broad command-level proxied tests.
However, every one of those CI shards uses an externally managed Dolt
testcontainer. The production path in which `bd` launches a loopback proxy and
that proxy launches a local `dolt sql-server` has no end-to-end CI lane.

The full acceptance journey is not currently possible:

> install → migrate a copy → work offline → concurrent writers →
> crash/restart recovery → push/pull between machines → backup/restore →
> doctor → migrate back

The largest functional breaks are:

1. There is no embedded-to-proxied copy migration or reverse migration.
2. Managed-local proxy/child lifecycle, offline behavior, and recovery are not
   exercised end to end.
3. `bd dolt push/pull`, backup/restore, import/export, memories, doctor, and
   explicit schema migration are unavailable or ineffective in proxied mode.
4. Ninety-nine non-test guard sites reject command paths in proxied mode,
   including core maintenance plus optional integrations and orchestration
   features.
5. PID files and open ports are trusted without a process/protocol identity
   handshake; stale recovery can kill a PID without proving it is the expected
   process.
6. The generated backend config is loopback-only, but custom managed Dolt YAML
   can override its listener host without a policy check.
7. Windows and macOS do not run the proxied lifecycle suite.

No source changes were made. The live `mybd` database remains in embedded mode.

## Repository and control-plane verification

The repository layout matches the requested architecture:

| Role | Path | Remote truth | Verified state |
|---|---|---|---|
| Campaign control plane | `/var/home/matt/dev/mybd` | `origin = maphew/mybd` | Clean `main` at `ce22a0029694`; database `mybd`, issue prefix `mybd-`, `dolt_mode=embedded` |
| Beads source checkout | `/var/home/matt/dev/mybd/bd-main` | `origin = maphew/beads`, `upstream = gastownhall/beads` | Clean `main`, exactly equal to `upstream/main` at `2f9367d6a76e` |
| Coordination report worktree | `.worktrees/mybd/proxied-server-readiness` | local branch only | Dedicated branch `campaign/proxied-server-readiness` |
| Future source worktrees | `.worktrees/beads/*` | topic branches push to fork | Convention confirmed; none created for this audit |

There is **no repository-name or remote mismatch**. The configured `upstream`
remote is `git@github.com:gastownhall/beads.git` and was treated as
authoritative. The source `origin` correctly points to the maintainer fork,
`git@github.com:maphew/beads.git`. The coordination repository has no
`gastownhall` remote.

One local policy drift exists: `scripts/check-beads-config` reports
`core.hooksPath=/var/home/matt/dev/mybd/.git/hooks` rather than the expected
opt-in `.githooks`. It did not affect this read-only source audit and was not
changed.

## Local-first invariants

These are release constraints, not preferences:

1. **Managed-local is the default authority.** A normal install stores data
   locally and never requires a network service to remain available.
2. **Offline work is complete work.** After binaries are installed, create,
   update, query, history, memory, maintenance, and recovery must not require
   internet or hosted infrastructure.
3. **The proxy is local machinery, not centralized authority.** Managed proxied
   mode may use a local loopback proxy and local Dolt child to coordinate
   concurrent clients, but ownership remains on the workstation.
4. **External Dolt is an explicit topology.** Host, port, credentials, and
   operational responsibility must be selected deliberately. External mode
   must never be silently substituted when local launch fails.
5. **Mode changes preserve a recoverable source.** Migration first operates on
   a copy, verifies integrity, and supports rollback. It does not repoint the
   live database in place without a proven recovery path.
6. **`mybd` is a late canary.** Disposable repositories come first, then a
   shadow copy, and only after the entire round trip passes may the live
   coordination database be considered.

## Verified current architecture

### Default embedded managed-local mode

The default remains embedded Dolt under `.beads/embeddeddolt/<database>`.
`cmd/bd/store_factory.go` selects embedded mode unless configuration explicitly
requests another topology. The embedded store uses a repository lock and does
not require a server, so it remains the only currently complete offline-first
path.

This is the correct product default. Proxied production work must not replace
it with a hosted service or make the external topology implicit.

### Managed-local proxied mode

With `dolt_mode=proxied-server`, command dispatch bypasses the legacy global
store and creates a unit-of-work provider. The managed path:

1. resolves a per-workspace root, normally `.beads/dolt`;
2. finds a separate `dolt` executable with `exec.LookPath("dolt")`
   (`cmd/bd/uow_factory.go:89`);
3. starts the current `bd` executable as the hidden `db-proxy-child`;
4. binds the proxy to `127.0.0.1`
   (`internal/storage/dbproxy/proxy/server.go:136`);
5. has the proxy start `dolt sql-server` with a generated loopback-only
   configuration (`cmd/bd/proxied_server.go:213`);
6. opens a short unit of work for each command and shuts the proxy/backend down
   after the idle period.

The local process tree is therefore:

```text
bd command
  └─ detached bd db-proxy-child (per workspace)
       └─ dolt sql-server (per workspace)
```

The implementation uses `proxy.lock`, `proxy.pid`, `proxy-child.lock`, and
`proxy-child.pid`. On Unix the proxy is detached with a new session; Windows
uses `DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP`. Default provider idle
timeout is 30 seconds, with proxy connection draining before backend shutdown.

Loopback-only intent is clearly implemented for the proxy and the default
backend. The proxy listener binds only `127.0.0.1`, the generated backend
configuration uses `127.0.0.1`, and free port selection also probes loopback.
However, `--proxied-server-config-path`, `BEADS_PROXIED_SERVER_CONFIG`, and the
sidecar `ConfigPath` can select caller-supplied Dolt YAML. Current validation
parses that file but does not enforce its listener host
(`cmd/bd/proxied_server.go:62-77`, `:154-165`). Therefore the full managed
topology does not yet enforce the loopback-only invariant.

### External proxied mode

External mode uses the same local proxy but fronts a caller-specified,
externally managed Dolt host and port. This is a centralized topology. It is
useful, but it does not demonstrate the local-first invariant and must retain
explicit configuration.

### Store and capability seam

The proxied command path deliberately does not populate the legacy global
`store`. `newDoltStore` rejects proxied mode, while command implementations are
being moved to short-lived units of work. Commands still calling `getStore()`
can therefore return `no store available`; examples occur in
`cmd/bd/dolt.go:379`, `:465`, and `:524`.

Upstream issue
[#4547](https://github.com/gastownhall/beads/issues/4547) owns this capability
seam. It should be the coordination point for parity work instead of creating
parallel implementations.

## Classification legend

- **Production-ready:** implementation and realistic cross-platform/failure
  evidence cover the required topology.
- **Implemented but insufficiently verified:** the path exists, but evidence
  does not cover realistic topology, platforms, or failures.
- **Known incomplete:** the command/path is missing, rejected, or unsafe for
  the journey.
- **Blocked by existing upstream work:** the gap overlaps active public
  ownership and should not be duplicated.
- **Apparently unowned:** no direct issue or pull request was found in current
  upstream searches; a local campaign child is appropriate.

No row in the complete proxied acceptance journey qualifies as
production-ready today.

## Acceptance journey

| Stage | Classification | Evidence on current `main` | Ownership / disposition |
|---|---|---|---|
| Install | **Known incomplete; apparently unowned** | Managed proxied mode requires `dolt` separately on `PATH`; no bundled binary, supported-version range, checksum/provenance rule, upgrade, or per-platform packaging contract exists. Audit host had Dolt 2.2.0 while 2.2.2 was current. | Release blocker `mybd-psxg.4`. Upstream #4512 concerns the embedded Go module pseudo-version and is not ownership for the CLI executable. Do not make hosted Dolt the fallback. |
| Migrate a copy | **Known incomplete; apparently unowned** | Merged [#4691](https://github.com/gastownhall/beads/pull/4691) flips server/shared-server metadata to proxied mode when both use `.beads/dolt`. Embedded data resides under `.beads/embeddeddolt`; no copy, integrity proof, activation, or rollback path exists. | Release blocker `mybd-psxg.2`; related to [#2764](https://github.com/gastownhall/beads/issues/2764) and #4547, but not owned by either in this concrete form. |
| Work offline | **Known incomplete** under the full invariant; core CRUD is **implemented but insufficiently verified** | The managed core data path needs no network after installation, but no integration lane proves it. Memory, doctor, explicit migration, backup, and other maintenance commands reject proxied mode, so “offline complete work” does not pass even if core CRUD does. External server outages are a different topology. | Release blockers `mybd-psxg.1` and `.4`; parity architecture is blocked by #4547. External outage/spool work is owned by [#4379](https://github.com/gastownhall/beads/issues/4379) and [#4520](https://github.com/gastownhall/beads/pull/4520). |
| Concurrent writers | **Implemented but insufficiently verified; blocked by existing upstream work** | Broad concurrent command tests pass against one external testcontainer. Locks and transaction retries exist, but fresh-unit serialization work remains draft and pooling branches are unresolved. | [#4742](https://github.com/gastownhall/beads/pull/4742), [#4303](https://github.com/gastownhall/beads/pull/4303), [#4473](https://github.com/gastownhall/beads/pull/4473), and [#3760](https://github.com/gastownhall/beads/issues/3760). |
| Crash/restart recovery | **Known incomplete; apparently unowned in the managed dbproxy path** | Unit tests cover parts of shutdown and stale artifacts, but no real managed proxy/child failure lane exists. Endpoint reuse and PID killing lack process identity proof. | Test coverage in `mybd-psxg.1`; hardening in release blocker `.5`. Coordinate design with related [#4513](https://github.com/gastownhall/beads/issues/4513), [#4637](https://github.com/gastownhall/beads/issues/4637), and local records `mybd-rr4x`, `mybd-qrm9`; they are not direct ownership of this path. |
| Push/pull between machines | **Known incomplete; blocked by existing upstream work** | `bd dolt push` and `pull` still require the legacy store and return `no store available` in proxied mode. Embedded mode has real remotes, but CI lacks a two-workspace end-to-end `bd` sync journey. Child-ID collisions are a demonstrated two-machine failure. | Capability route: #4547. Cross-machine conflict: [#4796](https://github.com/gastownhall/beads/issues/4796) / [#4844](https://github.com/gastownhall/beads/pull/4844), tracked locally by `mybd-cazb`. |
| Backup/restore | **Known incomplete; blocked by existing upstream work** | `backup status/init/sync/remove/restore` and `restore` explicitly reject proxied mode. Embedded native Dolt backup exists. | #4547 capability seam; do not create a duplicate implementation task yet. |
| Doctor | **Known incomplete; architecturally blocked by existing upstream work** | `bd doctor` exits successfully after printing that proxied mode is not yet supported, so it cannot diagnose proxy, child, lock, port, schema, or identity state. | #4547 D6 is the capability route. [#3794](https://github.com/gastownhall/beads/issues/3794), [#4860](https://github.com/gastownhall/beads/issues/4860), and [#4977](https://github.com/gastownhall/beads/issues/4977) are related doctor policy/coverage constraints, not direct proxied-doctor owners. |
| Migrate back | **Known incomplete; apparently unowned** for embedded; **implemented but insufficiently verified** for server/shared-server | Proxied-to-server and proxied-to-shared-server metadata flips have unit tests. There is no proxied-to-embedded copy-back. | Release blocker `mybd-psxg.2`. |

## Capability and risk matrix

| Capability | Classification | Evidence and risk | Release status |
|---|---|---|---|
| Default embedded managed-local/offline | **Implemented but insufficiently verified** | Correct default and no server dependency. Existing sync/schema incidents prevent calling the entire operational journey production-ready from this audit alone. | Non-negotiable baseline; must remain default. |
| Loopback-only managed proxy/backend | **Known incomplete** | Proxy and generated backend config hard-code `127.0.0.1`, but custom managed Dolt YAML is accepted without enforcing the backend listener host. No integration assertion enumerates listeners or tests rejection. | Default-topology evidence in `mybd-psxg.1`; custom-policy test and implementation in release blocker `.5`. |
| Proxy idle shutdown | **Implemented but insufficiently verified** | Active-connection tracking, drain, keepalive, and idle watcher exist; unit packages pass. No launched-process end-to-end proof. | Release blocker evidence in `mybd-psxg.1`. |
| Stale process/port/lock recovery | **Known incomplete; apparently unowned in managed dbproxy** | `PickFreePort` releases the socket before launch, leaving a TOCTOU race. A listener on the PID-file port can be accepted without protocol identity. Stale recovery can kill a PID without birth/identity verification. | Release blocker `.5`; coordinate primitives with related #4513/#4637. Test harness is `.1`. |
| Multiple commands/agents | **Implemented but insufficiently verified** | Proxy and child locks plus UOW retries exist. External-topology concurrent tests are broad; managed-local process contention is absent. | #4742/#4303/#4473; do not displace contributors. |
| Dolt executable availability | **Known incomplete; apparently unowned** | `exec.LookPath("dolt")` is the contract. There is no supported-version negotiation or packaged-binary behavior. | Release blocker `mybd-psxg.4`; #4512 is a distinct embedded-module policy issue. |
| Server/shared-server ↔ proxied mode | **Implemented but insufficiently verified** | #4691 merged with dry-run, lock, mode-flip, and reverse unit tests. It changes metadata around the same `.beads/dolt` database rather than migrating data. | Useful but not sufficient for this campaign. |
| Embedded ↔ proxied mode | **Known incomplete; apparently unowned** | Storage roots differ and no copy/activation/rollback command exists. | Release blocker `mybd-psxg.2`. |
| Proxied `bd dolt push/pull` | **Known incomplete; blocked by existing upstream work** | Store-based commands fail before reaching remote operations. | #4547. |
| Genuine local-first two-machine sync | **Implemented but insufficiently verified** in embedded; **known incomplete** in proxied | Raw Dolt script coverage is not a two-workspace `bd` journey. #4796 demonstrates real collision risk. | Release blocker after capability seam; #4796/#4844 already owned. |
| Backup/restore | **Known incomplete; blocked by existing upstream work** in proxied | Explicit command guards; no proxied round-trip evidence. Direct-mode native backup exists, but restore treats backup-remote re-registration/config persistence failures as warnings, so restored data can be healthy while immediate follow-on backup sync is not configured. | #4547 for proxied parity; retain the direct-mode recovery warning as acceptance evidence. |
| Export/import | **Known incomplete; blocked by existing upstream work** in proxied | Both commands explicitly reject proxied mode. | #4547. |
| Remember/recall/forget | **Known incomplete; blocked by existing upstream work** in proxied | All memory commands explicitly reject proxied mode. | #4547. |
| History | **Implemented but insufficiently verified** | A proxied implementation and external-harness integration test exist. Managed-local and mode-round-trip history equivalence are untested. | Include in migration integrity evidence. |
| Schema migration/reconciliation | **Known incomplete** | Startup has proxied reconciliation, but explicit `migrate`, `migrate sync`, and `migrate schema` reject proxied mode. Recent `main` also contains schema-repair work, raising data-risk stakes. | Coordinate through #4547 and schema owners before implementation. |
| Linux lifecycle | **Implemented but insufficiently verified** | Proxy unit tests and external proxied CI run on Ubuntu. Actual managed-local lifecycle is absent. | First platform for `mybd-psxg.1`. |
| Windows lifecycle | **Known incomplete; blocked by existing upstream work** | Detach flags exist but no proxied integration lane. Broader Windows work [#4132](https://github.com/gastownhall/beads/issues/4132) / [#4133](https://github.com/gastownhall/beads/pull/4133) is open and currently red. | Parity after Linux harness; coordinate. |
| macOS lifecycle | **Known incomplete** | General macOS CI exists, but no proxied lifecycle lane or process/FD recovery evidence. | Platform parity, after Linux harness. |
| Failure-path CI | **Known incomplete; apparently unowned for managed local** | No managed child kill, proxy kill, port steal, stale PID, lock wedge, or offline lane. | Baseline harness in release blocker `mybd-psxg.1`; adversarial lifecycle and correctness in `.5`. |
| Documentation/configuration consistency | **Known incomplete; apparently unowned** | Runtime says `.beads/dolt`; generated init docs and doctor gitignore still say `.beads/proxieddb`. | Desirable parity `mybd-psxg.3`, not a release blocker. |

### Unsupported command surface

The matrix emphasizes the acceptance journey, not every CLI command. A
mechanical search on the pinned commit found **99 non-test guard sites** that
report a path as unsupported in proxied mode across 57 source files. The
surface includes:

- core recovery and maintenance: backup, restore, import/export, memory,
  cleanup, compact, GC, reset, recompute-blocked, rename, branch/diff/version
  control, and explicit migration;
- issue/workflow behavior: batch, duplicate/supersede, delete variants, gates,
  merge slots, molecules, swarm, promote, ship, KV, and repository/federation
  operations;
- optional integrations: Azure DevOps, GitHub, GitLab, Jira, Linear, and
  Notion.

Not all 99 guards are release blockers for a local-first core. They must be
inventory-classified as core acceptance, desirable parity, or explicit
unsupported addon before proxied mode can be called production-quality.
Architectural command routing should remain coordinated through #4547 rather
than spawning one local task per guard.

## CI evidence

Merged [#4765](https://github.com/gastownhall/beads/pull/4765) ungated proxied
mode and activated 15 proxied command shards on `main` and the full PR-risk
tier. For the audited commit, upstream Actions run
[29990202001](https://github.com/gastownhall/beads/actions/runs/29990202001)
was green, including all proxied shards.

That signal is valuable but narrower than its name suggests:

- `.github/workflows/main.yml:714-775` describes the 15 Ubuntu shards.
- `.github/workflows/pr-risk.yml:35-90` runs the same tier for risky PRs.
- `cmd/bd/proxied_shared_harness_test.go:55-64` always initializes test
  projects with `--proxied-server-external-host 127.0.0.1` and the shared
  testcontainer port.
- The suite therefore tests command/UOW behavior against external Dolt, not
  `bd` launching and supervising a local Dolt child.
- The ordinary Linux integration shards set `BEADS_TEST_SKIP=dolt`; they do not
  provide a second end-to-end check of Dolt-backed command paths.

Local targeted verification on the same source commit passed:

```text
ok github.com/steveyegge/beads/internal/storage/dbproxy/pidfile
ok github.com/steveyegge/beads/internal/storage/dbproxy/proxy
ok github.com/steveyegge/beads/internal/storage/dbproxy/server
ok github.com/steveyegge/beads/internal/storage/dbproxy/util
ok github.com/steveyegge/beads/internal/storage/uow
ok github.com/steveyegge/beads/cmd/bd
```

Those tests validate units and mode helpers; they do not close the managed-local
acceptance gap.

## Existing upstream ownership

| Upstream work | Current state on 2026-07-23 | Campaign interpretation |
|---|---|---|
| [#4303](https://github.com/gastownhall/beads/pull/4303) | Open draft, dirty, about 4.8k additions; db-proxy pooling and external deployment path | Historical pooling branch; do not compete. Re-evaluate design against current ungated proxied architecture. Local mirror `mybd-p62i`. |
| [#4473](https://github.com/gastownhall/beads/pull/4473) | Open draft, dirty, about 2.3k additions; author describes it as reference material to consolidate into #4303 | Same pooling problem; local mirror `mybd-6k80`. |
| [#3760](https://github.com/gastownhall/beads/issues/3760) | Open | Connection amortization/product direction. |
| [#4379](https://github.com/gastownhall/beads/issues/4379) / [#4520](https://github.com/gastownhall/beads/pull/4520) | Open issue; non-draft PR with green sampled checks | Own external-server outage/offline spool. This must not be confused with managed-local offline operation. |
| [#4547](https://github.com/gastownhall/beads/issues/4547) | Open, assigned | Owns the global-store/UOW capability seam and proxied capability routing. Central blocker for sync, backup, doctor, memory, and parity. |
| [#2764](https://github.com/gastownhall/beads/issues/2764) | Open, unassigned | Broad cross-mode portability and CI gaps. Coordinate the narrower managed-local lane and copy migration here rather than silently overlapping. |
| [#4513](https://github.com/gastownhall/beads/issues/4513) | Open | Stable PID/birth-coherence API for external lifecycle managers; related design primitive, not direct ownership of managed dbproxy stale recovery. |
| [#4637](https://github.com/gastownhall/beads/issues/4637) | Open | Shared-server direct-connect identity verification; related risk, not direct ownership of managed dbproxy. Local mirror `mybd-rr4x`. |
| [#4742](https://github.com/gastownhall/beads/pull/4742) | Open draft; latest sampled run failed Embedded Dolt Storage | Fresh-UOW serialization-conflict retries. |
| [#4796](https://github.com/gastownhall/beads/issues/4796) / [#4844](https://github.com/gastownhall/beads/pull/4844) | Open issue and PR | Own machine-to-machine child-ID collision/rebase behavior; local mirror `mybd-cazb`. |
| [#4132](https://github.com/gastownhall/beads/issues/4132) / [#4133](https://github.com/gastownhall/beads/pull/4133) | Open; PR has failing required checks | Broader Windows lifecycle/packaging work. |
| [#3794](https://github.com/gastownhall/beads/issues/3794), [#4860](https://github.com/gastownhall/beads/issues/4860), [#4977](https://github.com/gastownhall/beads/issues/4977) | Open | Related embedded/server doctor policy and coverage constraints, not direct proxied-doctor ownership. |
| [#4691](https://github.com/gastownhall/beads/pull/4691) | Merged 2026-07-13 | Implements same-root server/shared-server ↔ proxied mode switching, not embedded copy migration. |
| [#4765](https://github.com/gastownhall/beads/pull/4765) | Merged 2026-07-16 | Ungates proxied mode and activates external-topology CI. |

Exact searches for managed-local proxied lifecycle, embedded/proxied copy
migration, proxied backup/restore, proxied export/import, proxied doctor/memory,
proxied machine sync, local Dolt executable packaging, and managed dbproxy
identity/listener safety found no direct additional owner. Local children were
created only for the concrete unowned portions; broad capability implementation
stays with #4547 and named contributors.

## Campaign graph created in `mybd`

| Bead | Kind | Priority | Role |
|---|---|---:|---|
| `mybd-psxg` | Epic | P0 | Full production-readiness acceptance journey and upstream coordination |
| `mybd-psxg.1` | Task | P0 | **Release blocker:** managed-local offline/lifecycle/failure acceptance lane |
| `mybd-psxg.2` | Feature | P0 | **Release blocker:** safe embedded ↔ proxied copy migration and rollback |
| `mybd-psxg.3` | Task | P3 | **Desirable parity:** reconcile runtime path docs and doctor configuration |
| `mybd-psxg.4` | Task | P0 | **Release blocker:** supported local Dolt CLI install/version contract |
| `mybd-psxg.5` | Bug | P0 | **Release blocker:** managed proxy identity, port, and listener safety |

`mybd-psxg.2` is blocked by `mybd-psxg.1`, because migration cannot be accepted
until the target managed-local topology has a realistic harness. The epic has
`related` edges to the locally mirrored upstream ownership for #4303, #4473,
#4379, #4468, #4483, #4634, #4637, and #4844. Parent/child status cascading
prevents using child-to-epic blocking edges, so release blockers are explicit
P0 labels rather than an invalid cyclic dependency.

`mybd-psxg.5` is also blocked by `.1`: the managed-local harness supplies the
safe place to reproduce and prove identity/listener fixes. `.4` is independent
because the initial test job can install a pinned Dolt directly while the
product-level installation contract is designed.

Execution metadata is recorded on every new bead. Ambiguous lifecycle and
migration work are staged for a high-reasoning mixed agent; the narrow docs
cleanup is delegated to a lower-cost worker.

The previously stale memory `proxied-server-suite-dormant` was corrected:
proxied CI is active, but it covers only external topology. A new
`proxied-server-production-campaign` memory points cold-start agents to this
epic and report.

## Phased implementation and verification sequence

### Phase 0 — Freeze truth and protect the canary

- Keep live `mybd` in embedded mode.
- Pin each audit/reproduction to an upstream commit and Dolt version.
- Treat `.beads/embeddeddolt` as the protected source in all migration work.
- Keep source implementation branches under `.worktrees/beads/*`.

### Phase 1 — Add the managed-local smoke lane

Implement the smallest realistic test-only slice described below. Run it on
Linux first with a disposable repository and separately installed Dolt. This
establishes whether the core local topology actually launches and persists
before modifying production behavior.

### Phase 2 — Expand lifecycle and failure injection

Add concurrent commands, idle shutdown, transparent restart, proxy termination,
backend termination, stolen ports, stale PID files, held locks, custom backend
listener policy, and interrupted startup/shutdown. Implement managed dbproxy
identity/listener correctness through `mybd-psxg.5`; coordinate reusable
primitives with #4513/#4637 and pooling owners.

### Phase 3 — Design and prove copy migration

Build an embedded-to-proxied copy with preflight, dry-run, staging, integrity
checks, atomic activation, preserved source, and rollback. Verify issues,
relationships, labels, events, memories, history, schema, and remote
configuration. Then prove the reverse copy.

### Phase 4 — Finish the capability seam with upstream owners

Work through #4547 instead of adding ad hoc store exceptions. Enable and test
proxied remote operations, backup/restore, export/import, memory, doctor, and
schema maintenance through a coherent capability interface.

### Phase 5 — Prove genuine multi-machine local-first synchronization

Use two clean workspaces/machines, each authoritative and usable offline.
Create divergent work, push/pull through the configured Dolt remote, resolve
collisions via the #4796/#4844 outcome, and verify complete data/history on
both sides. Do not count a raw `dolt` script as a `bd` acceptance test.

### Phase 6 — Cross-platform lifecycle

Run the managed-local lane on Windows and macOS. Validate detach semantics,
signals/process groups, file-descriptor/handle inheritance, path and executable
discovery, lock behavior, idle cleanup, crash recovery, and package availability.

### Phase 7 — Shadow-copy canary

Copy, never move, the live `mybd` database into an isolated disposable root.
Execute the full journey and compare integrity evidence with the embedded
source. Preserve both logs and immutable pre-migration identifiers.

### Phase 8 — Live canary decision

Only after all release blockers pass should maintainers decide whether to
migrate live `mybd`. That decision is outside this audit and requires an
explicit rollback window and designated operator.

## Smallest safe first upstream contribution

The recommended first contribution is a **test-only Linux managed-local smoke
test**, not a lifecycle refactor:

1. install/pin Dolt in the job;
2. create a disposable repository with `bd init --proxied-server`, with no
   external host/port flags and no testcontainer;
3. prevent outbound network access after installation;
4. create and read one issue;
5. assert the proxy and default generated backend listeners are loopback-only;
6. wait for idle shutdown;
7. run another command and prove transparent restart and persistence;
8. fail rather than skip when the local child cannot start.

This is the smallest slice that validates the campaign’s defining invariant
without changing storage or process behavior. It will expose whether subsequent
work belongs in packaging, launch, recovery, or CI. Documentation drift
(`mybd-psxg.3`) is smaller mechanically, but it does not reduce production
uncertainty and should not displace this test.

## Reproduction commands

Run from `/var/home/matt/dev/mybd` unless a command changes directory.
Commands that inspect Beads/Dolt state were run serially.

### Repository and tracker state

```bash
git status --short --branch
git remote -v
git worktree list --porcelain
git fetch origin --prune

git -C bd-main status --short --branch
git -C bd-main remote -v
git -C bd-main worktree list --porcelain
git -C bd-main fetch --all --prune
git -C bd-main rev-parse HEAD
git -C bd-main rev-parse upstream/main
git -C bd-main show -s --format='%H%n%cI%n%s' upstream/main

bd prime
scripts/check-beads-config
bd context --json
bd ready
bd list --status=in_progress
bd show mybd-psxg --json
bd show mybd-psxg.1 --json
bd show mybd-psxg.2 --json
bd show mybd-psxg.3 --json
bd recall proxied-server-suite-dormant
bd recall proxied-server-production-campaign
```

### Installed toolchain

```bash
command -v bd
bd --version
command -v dolt
dolt version
go version
```

Observed:

```text
bd version 1.1.0 (dev)
dolt version 2.2.0
go version go1.26.5 linux/amd64
```

### Implementation and test inventory

```bash
cd /var/home/matt/dev/mybd/bd-main

AUDIT_SHA=2f9367d6a76e8bab2bf056e0a1c545014f5fe18f
test "$(git rev-parse HEAD)" = "$AUDIT_SHA"
test "$(git rev-parse upstream/main)" = "$AUDIT_SHA"

rg -n 'proxied-server|BackendProxiedServer|uowProvider' cmd/bd internal/storage
rg -n '127\.0\.0\.1|PickFreePort|proxy-child|LookPath\(\"dolt\"\)' \
  cmd/bd internal/storage/dbproxy
rg -n 'not supported in proxied-server mode|not yet supported in proxied-server mode' \
  cmd/bd
rg -n 'proxieddb|\.beads/dolt' \
  cmd/bd/init.go cmd/bd/doctor/gitignore.go \
  docs/CLI_REFERENCE.md docs/cli-reference/init.md
rg -n 'proxied|testcontainer|BEADS_TEST_PROXIED_SERVER' \
  cmd/bd/proxied_shared_harness_test.go \
  .github/workflows/main.yml .github/workflows/pr-risk.yml
rg -n 'not (yet )?supported in proxied-server mode|is not supported in proxied-server mode' \
  cmd/bd --glob '*.go' --glob '!**/*_test.go'

go test -tags gms_pure_go \
  ./internal/storage/dbproxy/... ./internal/storage/uow/...

go test -tags gms_pure_go ./cmd/bd \
  -run '^(TestMigrate(To|From|Mode|Shared|Proxied)|TestBuildProxiedServerClientInfo|TestRenderProxiedServerConfig_RoundTrips|TestEnsureProxiedServerConfig_|TestProxiedServerPathHelpers|TestResolveProxiedServer|TestValidateProxiedServer|TestNewDatabaseServer_BackendLocalSharedServerStillStubbed|TestNewProxiedServerUOWProvider_|TestNewExternalProxiedServerUOWProvider_)'
```

### Upstream ownership and CI

The audit used `gh` against the configured authoritative repository:

```bash
gh repo view gastownhall/beads
gh pr view 4303 --repo gastownhall/beads --json number,title,state,isDraft,mergeStateStatus,additions,deletions,changedFiles,updatedAt,statusCheckRollup,url
gh pr view 4473 --repo gastownhall/beads --json number,title,state,isDraft,mergeStateStatus,additions,deletions,changedFiles,updatedAt,statusCheckRollup,url
gh pr view 4520 --repo gastownhall/beads --json number,title,state,isDraft,mergeStateStatus,statusCheckRollup,url
gh pr view 4691 --repo gastownhall/beads --json number,title,state,mergedAt,url
gh pr view 4742 --repo gastownhall/beads --json number,title,state,isDraft,statusCheckRollup,url
gh pr view 4765 --repo gastownhall/beads --json number,title,state,mergedAt,url
gh pr view 4844 --repo gastownhall/beads --json number,title,state,isDraft,mergeStateStatus,statusCheckRollup,url

gh issue view 2764 --repo gastownhall/beads
gh issue view 3760 --repo gastownhall/beads
gh issue view 3794 --repo gastownhall/beads
gh issue view 4132 --repo gastownhall/beads
gh issue view 4379 --repo gastownhall/beads
gh issue view 4513 --repo gastownhall/beads
gh issue view 4512 --repo gastownhall/beads
gh issue view 4547 --repo gastownhall/beads
gh issue view 4637 --repo gastownhall/beads
gh issue view 4796 --repo gastownhall/beads
gh issue view 4860 --repo gastownhall/beads
gh issue view 4977 --repo gastownhall/beads

gh search issues --repo gastownhall/beads --state open \
  '"managed local" proxied'
gh search issues --repo gastownhall/beads --state open \
  '"embedded" "proxied" migration'
gh search issues --repo gastownhall/beads --state open \
  'proxied backup restore'
gh search issues --repo gastownhall/beads --state open \
  'proxied doctor remember'
gh search issues --repo gastownhall/beads --state open \
  '"dolt executable" install version proxied'
gh search issues --repo gastownhall/beads --state open \
  'dbproxy proxy identity pid listener proxied'
gh search prs --repo gastownhall/beads --state open \
  'proxied backup restore'

gh run list --repo gastownhall/beads --branch main --limit 10
gh run view 29990202001 --repo gastownhall/beads
```

## Audit limitations

- This first pass intentionally did not switch any live or copied `mybd`
  database into proxied mode.
- It did not create a disposable managed-local proxied repository because the
  absence of an existing CI-grade harness is itself the first implementation
  slice; ad hoc success on one Linux host would not establish lifecycle
  readiness.
- It did not run a two-machine sync, destructive crash injection, backup
  restore, or schema migration.
- GitHub state is a 2026-07-23 snapshot and should be refreshed before starting
  implementation.
- Documentation was treated as aspirational where it disagreed with runtime
  code; `.beads/dolt` is the verified current managed-proxied root.

## Decision

Use `mybd` as the campaign control plane and keep the source tree in `bd-main`
with future source branches under `.worktrees/beads`. Begin with
`mybd-psxg.1`, the managed-local test-only smoke lane. Do not migrate live
`mybd`, and do not start capability implementations that overlap #4547,
#4303, #4473, #4520, #4742, or #4844 without first coordinating with their
owners.
