# Design v2: workspace operation gate (mybd-xznw)

Status: v2 after adversarial review; design COMPLETE, implementation is
upstream work consumed by mybd-psxg.2 (PR-0a there). v1 drafted from codex
scout recon; reviewed by codex gpt-5.6-sol (xhigh): 4 FATAL + 4 MAJOR +
1 MINOR, all adopted. Review transcript: session scratchpad
`xznw-design-review.txt`. Base: gastownhall/beads upstream/main 5a88c2b48.

## 1. Purpose

Give maintenance operations (embedded↔proxied migration, restore,
destructive repair) a way to exclude other bd activity on a workspace,
with near-zero cost for normal commands. Motivated by the psxg.2 FATAL:
embedded mode is designed for concurrent multi-process writers and nothing
can quiesce it.

## 2. What the review killed in v1 → v2 posture

| v1 | Review evidence | v2 |
|---|---|---|
| Activation epoch in metadata.json as the old-binary safety net | An SH-holding store can't see a bump (EX waits for it); gate-unaware binaries neither record nor validate it; `configfile` round-trip in an *old* binary silently drops the unknown field; git resets tracked metadata.json; save isn't fsynced (`configfile.go:80-169`, `version_tracking.go:18-21`) | Epoch demoted to **cooperating-client staleness detection only**, moved **into the database** (config-table row, validated transactionally at commit points) so old binaries can't structurally erase it; never claimed as a fence. The honest contract: gate-unaware writers are excluded by *policy + refusal*, not mechanism |
| `beads.Open` documented as outside the gate; `BEADS_WORKSPACE_GATE=0` hatch | Both public entry points bypass entirely (`beads.go:251-264`); the hatch is the same undetectable hole — the guarantee dies for exactly the Gas City case psxg.2 needs | Library gets `beads.OpenGated` in PR-A and **migration refuses by default** unless it can hold the gate uncontested; the only override is a migration-scoped `--unsafe-no-fence` that prints, truthfully, that the quiescence guarantee is waived. **No general env hatch** |
| One gate per workspace (`.beads/workspace.lock`) | Projects share physical backends: `~/.beads/shared-server/dolt`, arbitrary proxied roots (`doltserver.go:237-287`, `proxied_server.go:200-211`, `migrate_dolt_mode.go:82-95`) — workspace B can restart the server workspace A is draining | **Two-level gate**: workspace gate + **physical-root gate** on the canonical (realpath) backend root; maintenance takes both (sorted, see lock order). Normal commands take SH on both |
| Lock file inside `.beads` | Unix flock follows the inode; replacing/renaming the guarded tree splits lock identity (prior art warning `linear/synclock.go:74-79`; existing migration purges lock paths it holds, `migrate_dolt_mode.go:353-390`) | Gate files live in a **stable parent outside every mutated root**: `<workspace>/.beads-gate.lock` (sibling of `.beads`, gitignored) and `<server-root-parent>/<name>.gate.lock`. Invariant: no gated operation may replace the gate's parent directory. Lock files are never deleted |
| SH at root pre-run; upgrade to EX when needed | Same-process SH→EX self-blocks; not a portable atomic upgrade | **Mode preselected by command classification** before any acquisition (the existing skip-classification dispatch point, `main.go:896-910`); acquire final mode once |
| `bootstrap`, `backup restore` as normal SH commands | Both replace database state (`bootstrap.go:531-679`, `backup_restore.go:81-114`) | Classified EX. Full EX set: init, mode migration, restore, bootstrap-clone/adopt, destructive repair |
| Drain = existing SIGTERM path | SIGTERM cancels context and **force-closes active sockets** (`proxy/server.go:117-133,291-299`); Windows has no graceful control channel at all (`endpoint_windows.go:11-14`) | New proxy control verb **DRAIN** (stop accepting; wait for active conns; then stop backend) riding the psxg.5 control channel (PR 5013's authenticated IDENT conduit is the natural carrier — coordinate there); Windows gets it via the same channel, closing its gap. Until DRAIN exists, migration's stop step is honest: "waits for idle or forces after timeout" |
| Bounded blocking waits | `lockfile` blocking calls have no deadline (`lock_unix.go:29-33`) | Timed polling of the nonblocking primitives; normalize `ErrLocked`/`ErrLockBusy` (`lock.go:7-17`) |

Confirmed non-issues: spawned children don't inherit the flock handle
(spawn passes only stdio, no `ExtraFiles` — `endpoint.go:268-285`,
`flock.go:42-56`); keep the gate handle non-inheritable + Windows
regression test. MCP shells out to bd → inherits gating. Post-run
auto-export runs before store close → covered by store-lifetime scope.

## 3. Acquisition points (v2, complete set from review finding 5)

- Root chokepoint after workspace resolution, mode preselected
  (`main.go:984-1287`), released after store/provider close
  (`main.go:1388-1455`).
- **`configfile.Load` legacy-migration write during discovery**
  (`configfile.go:80-107`) — runs before any gate today; that write moves
  under the gate (or becomes read-only during discovery, write deferred).
- `noDbCommands` that mutate: `bd dolt set` rewrites metadata
  (`dolt.go:1561-1685`) → SH (EX not needed; it doesn't touch data roots,
  but it must not race an EX holder's activation — SH suffices to exclude).
- Doctor: SharedStore plus its fallback constructors
  (`doctor/database.go:77-85,183-191,245-253`) and auto-migrate
  (`doctor.go:497-527`) → SH; doctor never takes EX.
- Secondary-target opens gate **their target's** workspace/physical roots:
  `create --repo` (`create.go:371-415`), routed (`routed.go:202-240`),
  direct recovery (`direct_mode.go:33-57`), version_tracking pre-store open.
- `bd init` → EX on the workspace it creates.
- Library: `OpenGated` (participates); bare `Open` remains but migration
  refuses while it cannot prove sole ownership (it can't detect bare
  opens — hence refusal is the default posture and the override is loud).

## 4. Lock ordering (total order, release in reverse)

`workspace gate(s) sorted → physical-root gate(s) sorted → migrate.lock →
init embeddeddolt/.lock → proxy.lock → proxy-child.lock →
dolt-server.lock → schema GET_LOCK → transaction/Dolt locks`

Matches existing migration ordering (`migrate_dolt_mode.go:280,353-369`)
with the two gates prepended; the factory-internal acquisition v1 implied
would have inverted init-lock/workspace order and is dropped.

## 5. Review answers to open questions (adopted)

- Q1 hold SH for full store lifetime (chunked release would let one
  operation span two workspace identities).
- Q2 no daemon-held SH — "take EX then stop proxy" would deadlock against
  it; daemon participation would need a two-phase quiesce protocol, not v1.
- Q3 no freshness sentinel; if starvation materializes, a proper turnstile
  (readers touch turnstile-SH first, writers hold turnstile-EX while
  waiting).
- Q4 epoch bumps only on successful identity-invalidating operations,
  coupled durably with activation — not on every EX session.
- Q5 no general escape hatch; ungated deployments get refusal + explicit
  coordinated-downtime override at the migration command only.

## 6. Upstream shape v2

- PR-A `internal/workspacegate`: two-level gate on `internal/lockfile`
  (promoting the unused shared-lock API to production), timed-poll waits,
  non-inheritable handles, info sidecars (advisory), `beads.OpenGated`;
  cross-process + Windows tests.
- PR-B classification-driven acquisition at all §3 points; doctor
  lock-visibility check; gitignore entry for the gate files.
- PR-C DRAIN control verb on the psxg.5 channel (coordinate with
  coffeegoddd + our PR 5013 stack); migration's stop step upgrades from
  idle-wait to true drain when it lands.
- PR-D (with psxg.2's PR-0b) database-side epoch row + commit-point
  validation for cooperating clients.

Charter: process-coordination under existing storage surfaces; epoch row
is data not schema (config table). Coordinate #4513, psxg.5, #4547.

## 7. Status

Design complete; bead mybd-xznw closes with this report. Implementation
tracked through mybd-psxg.2's PR sequence (PR-0a = PR-A/B here).
