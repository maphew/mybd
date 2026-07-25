# Design v2: safe embedded ↔ proxied copy migration with rollback (mybd-psxg.2)

Status: v2 after adversarial review. v1 drafted in-session from codex scout
recon; reviewed by codex gpt-5.6-sol (xhigh), which found 5 FATAL + 8 MAJOR
flaws, all evidence-verified against the pinned dolt module and beads source.
v2 adopts every finding. Review transcript: session scratchpad
`psxg2-design-review.txt` (key points reproduced inline). Base:
gastownhall/beads main, 2026-07-25.

## 1. Problem (unchanged from v1)

`bd migrate from-server-to-proxied-server`/reverse (#4691) are metadata flips
between modes sharing `.beads/dolt`. There is no supported path between
**embedded** (`.beads/embeddeddolt/<db>/`) and **managed proxied**
(`.beads/dolt`) modes — different roots, drivers, lifecycles. Current
guidance is "copy `.beads` by hand while nothing runs"
(`docs/getting-started/upgrading.md:187`).

## 2. What the review killed in v1, and the v2 posture

| v1 assumption | Reality (review evidence) | v2 posture |
|---|---|---|
| migrate.lock + proxy locks + "embedded holds no lock" ≈ quiescence | Embedded is *designed* for concurrent multi-process writers (`embeddeddolt/store.go:34-41,97-103`; `concurrency_test.go:22-122`); nothing fences a concurrent bd process committing after staging or even after activation | **New prerequisite: a workspace operation gate** (see §3). Migration is blocked until it exists. Older binaries can't be fenced → documented compatibility limitation + activation-epoch check |
| Activation = flip committed `dolt_mode` | `dolt_mode` in metadata.json is git-committed and propagates (`migrate_dolt_mode.go:69-77`); other clones would enter proxied mode with no data, and the proxied UOW provider **auto-creates + migrates an empty database** (`uow/dolt_sql_provider.go:64-95,122-150`) | Cross-root mode selection gets **clone-local activation state**; committed metadata alone never selects a cross-root mode. Auto-create on the proxied path must be fenced by an explicit bootstrap marker (upstream change) |
| Rollback = flip metadata back + head-hash divergence warning | Wisps/leases/memories live in `dolt_ignored` working-set tables; writes can leave `HEAD` unchanged (`schema/schema.go:250-265`, `update_proxied_server.go:185-200`, `delete_proxied_integration_test.go:610-632`) — a "no new commits" check proves nothing | Metadata-only rollback allowed **only** if full state hashes (WORKING/STAGED/HEAD + all refs) equal the activation manifest; otherwise rollback = **reverse copy** (new generation), never a flip. Destructive discard is a separately named explicit operation |
| CP4 rename is atomic; stamp after activation | `Config.Save` doesn't fsync file or dir (`configfile.go:136-169`); `os.Rename` not atomic on Windows (Go contract); sidecar is torn-write `os.WriteFile` (`proxied_server_client_info.go:42-54`); metadata-then-sidecar ordering has a crash window (`migrate_dolt_mode.go:245-259`) | Durable ordering: manifest+sidecar written+synced *first*, metadata *last* via Windows-safe replace; recovery protocol on open models every old/temp/new combination; attempt journal precedes activation |
| `DOLT_BACKUP('restore')` restores "into `.beads/dolt/<db>`" | Restore goes through the *session provider's* root (`dolt_backup.go:235-277` pinned module); opening a normal proxied provider first would create+migrate the target and break restore | Restore runs in a **dedicated raw admin session rooted at the destination** with no create/migrate/auto-start side effects; cleanup drops only the attempt's exact database |
| Source opened read-only for backup | `DOLT_BACKUP` needs superuser + write; `syncRemote` commits the calling session's working set (`dolt_backup.go:55-79,280-313`); beads rejects backup on read-only stores (`embeddeddolt/version_control.go:80-89`); `sync-url` isn't even exposed (`versioncontrolops/backup.go:10-47`) | New `BackupSyncURL` capability on a writable no-create/no-migrate source session; G2 restated as **"no logical source changes"**, proven by comparing source root hashes before/after |
| Verify = counts + head + schema | Counts are filtered app queries (`embeddeddolt/counts.go:25-39`); corruption can pass all of them | Acceptance gate = **exact `DOLT_HASHOF_DB`** over WORKING/STAGED/HEAD **per branch/tag/remote-ref** (`dfunctions/hashof_database.go:51-120`; ref enumeration via `versioncontrolops/branches.go`, `remoterefs.go`) + full config-table row compare + repo-local state compare. Counts demoted to diagnostics |
| "non-empty destination → refuse" | A sql-server root legitimately hosts sibling databases (the documented `beads`+`mybd` layout); blanket refusal makes real migration impossible; known bootstrap-drift hazard (`doctor/fix/metadata.go:189-193,334-470`) | Preflight enumerates `SHOW DATABASES`, selects exact source/target by name + `project_id` identity; non-empty root fine if the exact target database is absent; ambiguity requires `--db`; sibling databases and root config files are never touched |
| Quiesce proxy via `proxy.Shutdown` | That's a SIGKILL test helper (`shutdown.go:20-35`) | Graceful SIGTERM drain path (`proxy/server.go:117-133,169-194`) then lock acquisition; force-kill only as explicit recovery |

## 3. New prerequisite: workspace operation gate (own work item)

The single hardest gap: nothing can stop a concurrent bd process (same or
older binary) from writing the embedded database mid-migration. v2 requires
an upstream **workspace operation gate**: every command acquires a shared
lock before metadata/mode selection and holds it until its store closes;
migration (and future maintenance ops) take it exclusively. Older binaries
that predate the gate cannot be fenced — the contract documents this as a
compatibility limitation ("all bd processes touching this workspace must be
≥ the gate version") and the activation manifest records a workspace
**activation epoch** that gate-aware binaries check after open, so a stale
write at least fails fast post-migration instead of silently forking.
Coordinate with upstream #4513 (birth coherence) — same family of
process-coordination primitives; and with the psxg.5 identity work which
already owns proxy-side process identity.

## 4. Clone-local activation semantics

- Committed `dolt_mode` remains what it is today for same-root modes.
- Cross-root modes activate via a **clone-local, gitignored activation
  record** (`.beads/local/activation.json`, fsynced, schema-versioned):
  `{mode, root, database, generation, epoch, manifest_ref}`.
- Precedence: local activation record > committed metadata. A clone that
  pulls a committed mode change without a local activation record for a
  cross-root mode **refuses to auto-create** and prints the bootstrap
  command (`bd migrate adopt` — runs the same copy pipeline locally from its
  own embedded root, or bootstraps from the Dolt remote).
- Upstream change required: the proxied UOW provider's silent
  create+migrate (`dolt_sql_provider.go:64-95`) must be gated behind an
  explicit bootstrap intent marker. **Review also flagged that this path
  runs `MigrateUpWithLock` without the remote-migrate gate, unlike the
  guarded server path (`dolt/store.go:1871-1923`) — filed as its own
  upstream-facing bead (mybd-wshx, see §9), it is a live policy bypass
  independent of migration.**

## 5. Procedure v2 (forward; reverse is symmetric)

Phases with durable attempt journal `.beads/migrations/<uuid>/` (created
first, fsynced; every phase writes a completion marker; recovery reads the
journal, never guesses):

0. **Preflight** (all read-only, raw no-create/no-migrate connections):
   workspace gate exclusive; graceful proxy stop + locks; enumerate
   databases, resolve exact source/target (+`project_id`); schema check via
   `CheckForwardDrift`/`PendingVersions`/content hashes
   (`schema.go:311-338,1038-1062`) — pending schema → refusal directing the
   designated migrator to the existing migrate workflow (never combine
   schema migration with mode migration, never set `BD_ALLOW_REMOTE_MIGRATE`);
   reverse direction additionally rejects external-proxy topology (sidecar
   `External: true`, `uow_factory.go:28-39`); record source state manifest:
   `DOLT_HASHOF_DB` all refs + config rows + repo-local state inventory
   (remotes, backup remotes, branch tracking from `.dolt/config` — restore
   does not carry these, cf. `dolt/store.go:1889-1892`).
1. **Stage**: `BackupSyncURL` from a writable no-create source session to
   `file://<attempt-dir>/staging`; re-hash source after; any drift → abort
   (concurrent writer got through → gate bug, fail loudly). Journal-heavy
   sources are converted by `SyncRoots` itself (`remotes.go:747-761`) —
   acceptable *only because* the gate guarantees no concurrent GC (upstream
   TODO acknowledges backup/GC races, `remotes.go:799-804`).
2. **Materialize**: raw admin session rooted at destination; restore staging
   as the target database name; recreate repo-local state from the
   inventory; crash here → journal marks attempt incomplete, recovery drops
   exactly that database and retries.
3. **Verify** (acceptance gate): destination hashes equal source manifest
   for every ref + WORKING/STAGED; config-table row equality; repo-local
   state equality. Counts/doctor checks run as diagnostics only.
4. **Activate** (durable ordering): write+fsync activation record and
   sidecar first; committed metadata updated last via temp+fsync+
   Windows-safe replace (`ReplaceFile`/rename-with-retry semantics behind a
   platform shim); journal completion marker; post-activation open runs an
   epoch check.
5. **Preserve**: source root untouched forever by this command; journal
   holds the relationship; doctor coherence check (conventions-tier only,
   per the owner's one-subcommand-at-a-time doctor policy, #3794) flags
   mode/root/activation drift and stale attempt dirs.

Rollback: `bd migrate rollback` compares *current* destination full state
hashes to the activation manifest; equal → deactivate (reverse the durable
ordering); unequal → refuses metadata-only path and offers the reverse copy
pipeline (new generation into a fresh directory, same 0-5 phases). No
destructive option under this name.

## 6. Test matrix v2 (delta over v1)

Everything in v1 §6 plus, per review: kill *during* backup and *during*
restore (not only between phases); concurrent embedded writer immediately
before/during/after activation (must be excluded by the gate, and the epoch
check must catch a stale gate-unaware binary); GC during backup; multi-db
roots incl. empty `beads` bootstrap + populated named db; non-main branches,
tags, remote refs, dirty working/staged state, ignored wisps/leases,
uncommitted memories; remotes/backup-remotes restoration; crash windows
around each durable write incl. every Windows old/temp/new metadata state;
Windows path/URL forms (drive letters, UNC, spaces, non-ASCII —
`DirToFileURL` is naive concatenation, `backup.go:50-56`); rollback after a
wisp-only write (HEAD unchanged). Existing backup/clone unit tests are
string-parsing mocks (`backup_test.go:8-47`) — the integration lane is the
real coverage, structured like the psxg.5 lifecycle lane (Linux first,
Windows/macOS specified then staged).

## 7. Upstream shape v2

Ordered, each independently landable:
- PR-0a: workspace operation gate (prerequisite; own design conversation —
  overlaps #4513 family).
- PR-0b: fence proxied UOW auto-create + route it through the
  remote-migrate gate (bug-fix framing; independent value).
- PR-1: `BackupSyncURL` + raw admin destination session + attempt journal
  (plumbing, no user command yet).
- PR-2: `bd migrate from-embedded-to-proxied-server` / reverse +
  clone-local activation + durable activation protocol + verification gate;
  Linux lane.
- PR-3: doctor coherence check (owner-gated, #3758 pattern).
- PR-4: docs replacing the hand-copy guidance; Windows/macOS lanes.

Charter fit: lifecycle primitives in beads core; activation state is
metadata-not-schema; no orchestration policy. Coordinate #4547 (the
migration command should sit behind its capability seam when that lands)
and #2764 (cross-mode test infra).

## 8. Review's answers to v1 open questions (adopted)

- Q1: `sync-url` + restore; **clone fallback rejected** (clone does not
  preserve local changes — the pinned restore uses `SyncRoots` for exactly
  that reason, `dolt_backup.go:269-272`).
- Q2: journal conversion is handled by the engine; the risk is concurrent
  GC — solved only by the gate, tested explicitly.
- Q3: `--db` required on ambiguity; exact-database targeting; siblings
  preserved.
- Q4: attempt journal in `.beads/migrations/<uuid>/`, written before
  activation, outside both engine roots.
- Q5: exact hash verification always; deep semantic checks are optional
  diagnostics.

## 9. Follow-ups filed

- Upstream-facing: proxied UOW provider bypasses the remote-migrate gate —
  **mybd-wshx** (verify on latest main, then raise upstream).
- Workspace operation gate design (PR-0a) — **mybd-xznw**; blocks
  implementation of this design (dep edge: mybd-psxg.2 → mybd-xznw).
