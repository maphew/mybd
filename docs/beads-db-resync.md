# Resyncing a beads database from its remote

The recipe for "my local beads DB is stale, schema-skewed, or wedged, and the
remote is the authority". It replaces the local database wholesale instead of
merging, then **proves** nothing was lost before you walk away.

It is deliberately generic: nothing below is mybd-specific, so the same script
works in any project with a `.beads/` directory and a reachable Dolt remote.

## TL;DR

```bash
beads-db-resync --audit-only          # what would I lose? (touches nothing)
beads-db-resync                       # back up, replace, audit, report
beads-db-resync --restore             # ...and put local-only rows back
beads-db-resync --rollback <backup>   # undo
```

`--audit-only` is the safe first move and is worth running on its own as a
"am I ahead of the remote?" check.

## Install

```bash
ln -sf "$(git -C <mybd-root> rev-parse --show-toplevel)/scripts/beads-db-resync" ~/.local/bin/beads-db-resync
```

Needs `bd`, `python3`, and `git`. `dolt` is optional: without it the audit still
covers issues and memories, but skips the table-level checks (events, comments,
labels, dependency edges).

## When to reach for it

- `bd` refuses commands with *"database is at vNN, binary knows up to vNN-1"*.
- The local DB is far behind and `bd dolt pull` will not converge — most often a
  merge conflict in a table you do not actually care about merging, such as the
  audit `events` table.
- A machine has been offline long enough that you would rather take the remote
  and re-apply your handful of local beads than reconcile histories.

Do **not** reach for it when the local database is the one holding the good
data. This tool treats the remote as the authority; the backup is your only
protection, which is why it is taken before anything is touched and verified
before anything is deleted.

## What it does

1. **Export** the current DB to `local-all.jsonl` (`bd export --all`, retried
   with `BD_IGNORE_SCHEMA_SKEW=1` so a skewed DB can still be read). Aborts
   without touching anything if the export fails or comes back empty.
2. **Move** the live Dolt directory into the backup — a rename when possible, a
   verified `cp -a` when the backup lands on another filesystem.
3. **Clone** the remote with `bd bootstrap --yes`.
4. **Verify** the result opens, and that it accepts a *write* (see below).
5. **Audit** the backup against the fresh clone and write `audit.json`,
   `restore.jsonl`, and per-table `only-old.*.txt`.
6. **Restore** local-only rows with `bd import` when you pass `--restore`.

Exit codes: `0` clean · `1` error · `2` bad usage · `3` local-only data found
and not restored. That makes it safe to script: `beads-db-resync --restore ||
handle-conflicts`.

## Four traps this encodes

Each of these produced a wrong answer before the script accounted for it.

**Compare comments by content, never by id.** A beads recovery that replays the
`events` table regenerates comment UUIDs. An id-based comparison reported 220 of
256 comments as "lost" when every one was present. The key is
`issue_id|author|created_at|md5(text)`.

**A table missing from the clone is not automatically data loss.** beads keeps
`events` (and friends) in `dolt_ignore` so per-machine audit history never has
to merge. A fresh clone legitimately has no such table. Check `dolt_ignore`
before crying loss — otherwise you get 8,000 phantom findings.

**A read-only smoke test is not enough.** On a repo that ignores `events`, a
fresh clone has no events table and `bd create` / `bd import` fail with
`record event in events: Error 1146: table not found: events` — while
`bd status`, `bd ready`, `bd show` and even `bd kv set` all succeed, because the
kv path records no audit event. The write probe therefore creates and deletes a
real bead. If it fails, recreate the table from the backup (it stays
machine-local, `dolt_ignore` still covers the name):

```bash
cd <backup>/dolt-db.original && dolt sql -q "show create table events"
cd <live-db>                 && dolt sql -q "<that CREATE TABLE>"
# optional, to keep this machine's audit history:
cd <backup>/dolt-db.original && dolt sql -q "select * from events" -r csv > /tmp/events.csv
cd <live-db>                 && dolt table import -u events /tmp/events.csv
```

**Never use `bd -C <dir>` for this.** bd resolves `.beads/config.yaml` — and so
`sync.remote` — from the **process cwd**, not from the `-C` target. Run
`bd -C /other/project bootstrap` from inside a beads repo and it plans a clone
of *this* repo's remote into `/other/project`. Verified on bd 1.2.2. The script
always `cd`s into the target, and refuses to run when the project's declared
remote disagrees with the one bd plans to clone.

## Doing it by hand

If you would rather not run the script, this is the whole of it:

```bash
cd <project>                                   # cd, do not use bd -C
bd export --all -o /tmp/local-all.jsonl        # BD_IGNORE_SCHEMA_SKEW=1 if skewed
mv .beads/embeddeddolt/<db> ~/backups/db.original
bd bootstrap --yes
bd status                                      # reads
bd create "probe" -t chore && bd delete <id> --force   # writes - do not skip
bd export --all -o /tmp/remote-all.jsonl
# diff the two JSONL files by issue id and memory key; compare comments by
# content; ignore tables listed in dolt_ignore
bd import /tmp/restore.jsonl                   # whatever was local-only
bd dolt push
```

The script exists because step "diff the two JSONL files" is where the traps
above live.

## Output

```
<project>-backups/pre-resync-<ts>/
├── dolt-db.original/       the whole pre-swap database
├── local-all.jsonl         everything the old DB held
├── remote-all.jsonl        everything the new DB holds
├── audit.json              counts, only-local ids, unexplained content drift
├── restore.jsonl           bd import this to put local-only rows back
├── tables.json             per-table row counts and status
├── only-old.<table>.txt    keys present only in the backup
└── memory-conflicts/       <key>.local.txt / <key>.remote.txt to merge by hand
```

Memories that differ on both sides are never auto-resolved: they carry no
timestamp to arbitrate with, so both versions are written out and the run exits
`3` until a human merges them.

Keep the backup until the next successful `bd dolt push`. `--keep-jsonl-only`
drops the Dolt directory once the audit comes back clean, if the space matters.

## Tests

```bash
scripts/test-beads-db-resync
```

No network, no real database. Every test fails if its guardrail is removed,
including regressions on the four traps above.
