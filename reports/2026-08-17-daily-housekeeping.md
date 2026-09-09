# Daily report and housekeeping — 2026-08-17

Session: Claude Code (fable-5, high), Fedora box.

## Headline: recovered from the accidental v1.2.1 schema migration

`bd dolt pull` refused with "database is at v65, binary knows up to v53".
Cause: the untested v1.2.0/v1.2.1 release ran on this box at some point
(`.beads/.local_version` still said `1.2.1`) and silently migrated the DB
from schema v53 to v65. The supported v1.2.2 (tested 1.1-line code) speaks
v53 only.

Applied the official recovery (docs/RECOVERY-1.2.1.md @ tag v1.2.2), which is
a replay-safe metadata fix, not a data migration:

1. `bd dolt pull` under `BD_IGNORE_SCHEMA_SKEW=1` to get latest first.
2. Backup: `~/dev/mybd/.beads.backup-pre-recovery` (1.8G; now gitignored).
3. Cursor rollback to v53 via `dolt sql` in `.beads/embeddeddolt/mybd`
   (Dolt commit `uvf8emjt`).
4. Verified `bd list` / `bd ready` run clean with no skew warning.
5. `bd dolt push` so other machines receive the recovered cursor.

**Follow-up filed: `mybd-obnzd` (P1)** — the Windows box must be on bd
v1.2.2 *before* its next bd command (a leftover v1.2.1 binary re-migrates
silently on any command, even `bd list`), then `bd dolt pull`. Delete the
backup and close the bead once Windows is confirmed healthy. Knowledge
saved as bd memory `beads-v121-schema-recovery`.

## Routine checks

- git pull / push: coordination repo clean and current.
- `scripts/check-beads-config`: ok (hooksPath `.githooks`, db `mybd`, 2253 issues).
- bd 1.2.2 at `~/.local/bin/bd`; `.local_version` bumped 1.2.1 → 1.2.2 (committed).
- `bd ready`: 17 unblocked. Top of queue: `mybd-koabx` (P0, shepherd the 15
  open upstream PRs), `mybd-ykt9f` (wind-down epic), `mybd-hli9` (zstd seam).
- In progress (5): cebxh (PR 5202 strict import), itgj, lq8i.3 (other
  session's claim — untouched), 0nzhq.1, pp5hv.
- index-babysit timer: active, firing every 30 min, runs healthy. No new
  flag comments on `mybd-ykt9f` since the 08-14 reading-room synthesis.
- Upstream PR fleet: 15 open PRs, **all mergeable, zero failing checks**.
  Only 5202 carries CHANGES_REQUESTED (already tracked in `mybd-cebxh`).
- No leaked `dolt sql-server` processes; no `beads-bd-tests-*` debris.

## Hygiene pass

- Removed dead beads worktrees for merged PRs: `pr5092-rebase`
  (feat/doltversion-contract) and `pr5229-rebase`
  (fix/example-extension-go-tidy) — both clean, both PRs on upstream/main
  since 08-13. Local branches deleted. Kept `pr5202-rebase` and
  `pr5243-fix` (live PRs).
- Fast-forwarded `bd-main` to upstream/main (picked up the v1.2.2
  forward-port, reclaim doc fixes, federation quickstart).
- No stray stashes, no merged/orphaned branches, no untracked cruft beyond
  the recovery backup (now ignored).
- Closed `mybd-hf5ph` as a duplicate of `mybd-obnzd` (double-submit while
  filing the Windows follow-up).

## What did I notice that isn't on any list?

- Origin (fork) deleted branch `fix/hookspath-symlink-resolve` upstream of
  this session — presumably a merged/closed PR's branch auto-cleanup; no
  local counterpart existed. Nothing to do.
- The v1.2.1 exposure window is unknowable from here: any bd writes made
  while on v1.2.1 used the v65 code paths (leases, events journal). The
  recovery doc says that data stays inert and harmless; noted only so a
  future oddity has a candidate explanation.
- `bd close --json` emits an output shape that `jq -r .status` can't read
  directly (array vs object); `scripts/bdj` remains the right wrapper but
  it wraps `bd list` flags, not a `--search` passthrough — use `bdj search`.
