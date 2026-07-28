# v1.1.2 verification batch — upstream close-comment drafts

Session 2026-07-28 (bead mybd-xvw9d). A throwaway rig built bd from tag
`v1.1.2` (`CGO_ENABLED=1 -tags gms_pure_go`, isolated `HOME`), plus external
`dolt 2.2.2` sql-server hosting three bd databases simultaneously. All five
"probably fixed since v1.0.4" lanes verified **FIXED**. Full command logs:
session scratchpad `v112-rig/` (ephemeral); evidence summaries below are
self-contained.

**These are drafts. Posting text upstream is human-gated — maphew reviews,
posts, then runs `scripts/tri-close <bd-id>` per item (local lane beads are
already closed with the same evidence).**

Issue → local bead map: 4239+4128 → mybd-zlqec; 4135 → mybd-5vvos;
4468 → mybd-j881; 4137 → mybd-veofl; 4297 → mybd-3aev4. Family members
4245/3948/3880 are covered by the 4239/4128 mechanism and were closed earlier
as stubs.

---

## gastownhall/beads#4239 and #4128 (auto-import overwrite / OOM, server mode)

We re-tested this on v1.1.2 against an external `dolt sql-server` (2.2.2) and
believe it is fixed by the v1.1.x rework. Setup: server-mode project, two
issues exported to `.beads/issues.jsonl`, then the DB rows were edited (title
change + a close) so the jsonl was stale, and the jsonl mtime was touched to
tempt any mtime-based import. `bd list`, `bd ready`, `bd stats`, and a write
command were then run.

Result: the stale jsonl was never imported — the newer DB rows survived
untouched (`bd show` returned the post-edit title and the closed status), no
duplication, no lock contention, instant returns. In server mode auto-import
does not fire at all (the #4170 gate), and `.beads/issues.jsonl` is now a
passive export rather than a sync input. Closing as fixed in v1.1.2 — please
reopen with a repro on 1.1.2+ if you still see it.

## gastownhall/beads#4135 (six embedded-mode failure modes)

Re-tested the practical shapes on v1.1.2, embedded mode. The stale-jsonl
clobber and two-clone split-brain shapes no longer reproduce: reads never
import; explicit `bd import` of an older export reports
`Imported 0 issues (1 stale skipped; use --allow-stale to restore older rows)`
and the newer local edit survives.

Architecturally, the trigger mechanism behind all six 1.0.4 modes is gone:
`export.auto` defaults to false (no issues.jsonl is even created at init),
import is explicit with a stale-row guard, IDs are hash-suffixed rather than
sequential (removing the ID-collision mode), and sync is Dolt-remote based
(`refs/dolt/data`) so jsonl is off the data path entirely. Closing as fixed
in v1.1.2.

## gastownhall/beads#4468 (bd close fails / bd create hangs on shared sql-server; is_blocked recompute)

Re-tested on v1.1.2 against a genuinely shared external dolt sql-server
(three bd databases on one server). Dep chain A←B←C, then `bd close` on the
root (which triggers the is_blocked recompute over both issue and wisp ID
sets) and an immediate `bd create`.

Result: close returned `✓ Closed` instantly, create returned a new ID with no
hang, and the recompute was correct (`bd ready`/`bd blocked` reflected the
new state). Schema on the live server DB has the typed columns the recompute
queries (`wisp_dependencies.depends_on_issue_id`/`depends_on_wisp_id`,
`wisps.is_blocked`) — the missing-column failure cannot occur on this schema
regardless of row counts. Closing as fixed in v1.1.2 (post-#4878).

## gastownhall/beads#4137 (migration 0028 "nothing to commit" on fresh server-mode DB)

Re-tested on v1.1.2: fresh `bd init --server --external` against an external
dolt sql-server (2.2.2). Init completed cleanly
(`✓ bd initialized successfully! Mode: server`), all 53 schema migrations
applied (`schema_migrations` count/max = 53/53), zero "nothing to commit"
strings in the server log, and create/list work. Closing as fixed in v1.1.2
(post-#4531).

## gastownhall/beads#4297 (bd list blocker-count references removed depends_on_id)

Re-tested on v1.1.2, embedded mode: two issues, a blocking dep, then
`bd list --json`, `bd list`, `bd blocked`, `bd ready`. No SQL errors on any
surface; `dependency_count`/`dependent_count` and the dependency objects are
correct, and `bd blocked` prints the right blocker set. Note: in v1.1.2 the
issues-side `dependencies` table legitimately retains `depends_on_id` — it is
the wisps tables that use typed columns — and every blocker-count surface
queries it without error. Closing as fixed in v1.1.2.

---

_Each draft to be signed per convention when posted._
