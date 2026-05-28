# Release Gate 1.0.5 — dependencies-split migration replay from 1.0.4

**Bead:** mybd-kdxj · **Date:** 2026-05-28 · **Verdict:** ✅ PASS — not release-blocking

## Question

Migrations `0041–0047` split `dependencies.depends_on_id` into
`depends_on_issue_id / depends_on_wisp_id / depends_on_external`, drop the old
generated column, rebuild the blocked view, and add `issues.is_blocked`. These
are new in the 1.0.5 line. The gate: does a real **v1.0.4** database with
**populated dependency rows** replay these migrations on first open by 1.0.5,
and do the blocker-check paths (`bd close` / `bd ready` / `bd blocked`) succeed
afterward — i.e. no recurrence of the `Error 1105: column depends_on_id could
not be found` failure?

## Method — empirical, real binaries

The toolchain on this machine made a gold-standard test possible:

- **Baseline:** Homebrew `bd` on PATH is exactly `bd version 1.0.4 (Homebrew)` —
  the real released binary, not a simulation.
- **Candidate:** built from `bd-main` `main@5af86ffc6` (`go build -tags
  gms_pure_go`), which carries migrations `0041–0049`. (`version.go` still reads
  1.0.4; the bump happens at tag time, so this is the 1.0.5 candidate.)
- **dolt 2.0.7** for direct schema inspection.

Scenario (`/tmp/gate-1.0.5-verify.sh`): init an embedded-Dolt workspace with
released v1.0.4, create issues plus a populated `blocks` dependency (BUG→TASK)
and a `parent-child` dependency (EPIC→TASK), then first-open with the candidate
to trigger in-place migration, then run the blocker-check commands.

## Findings

### 1. Bead premise confirmed — 0041+ are genuinely new in 1.0.5

A v1.0.4-only database (never touched by the candidate) has the **old**
`dependencies` table: a single real `depends_on_id` column as part of the
`(issue_id, depends_on_id)` PRIMARY KEY, **no** split columns, and `issues` has
**no `is_blocked`** column. So the migration gap the bead describes is real.

### 2. ✅ 0041 data-copy runs on populated rows; data preserved

After first-open by the candidate, the in-place migration chain replayed and
**both** dependency rows survived with the target correctly copied into the new
column:

| issue_id | depends_on_issue_id | depends_on_wisp_id | depends_on_external | type |
|----------|---------------------|--------------------|--------------------|------|
| gate-c6d (BUG) | gate-27h (TASK) | NULL | NULL | blocks |
| gate-f3t (EPIC) | gate-27h (TASK) | NULL | NULL | parent-child |

Final schema after migration: split columns present (0041); the generated
`depends_on_id` column and composite PK were dropped and replaced by a surrogate
`id CHAR(36)` PK (0043); `issues.is_blocked TINYINT(1)` added (0046). Queries
recompute `depends_on_id` via `COALESCE(...)` at SELECT time, exactly as the
bead anticipated.

> Note: only the **issue-target** branch of 0041's data-copy was exercised with
> real data (the dataset has no wisp-target or `external:` dependencies). Those
> branches were DDL-exercised only.

### 3. ✅ Blocker-check paths succeed on the migrated DB

These are the exact commands the bead worried about, run against the migrated DB:

- `bd blocked` → correctly reports BUG blocked by 1 open dependency [TASK] (exit 0)
- `bd ready` → correct ready set (exit 0)
- `bd show BUG` → "DEPENDS ON → TASK" rendered correctly
- **`bd close TASK` → PASS, no Error 1105** (the precise failure mode in the bead)
- `bd ready` / `bd blocked` after closing the blocker → BUG correctly unblocked

### 4. ✅ Bonus: candidate operates correctly on the real already-migrated mybd DB

While closing this bead, the Homebrew `bd` 1.0.4 on PATH threw the exact
`Error 1105: column depends_on_id could not be found` on `bd dep add` / `bd close`
against maphew's live mybd DB (already at schema 0045+ from a dev build). The
1.0.5 candidate ran the same `dep add` and `close` against that same DB with no
error — independently reproducing both the bug and its fix described in the bead.

## CI coverage gaps (static analysis — why this still warranted explicit verification)

The gate said "verify explicitly rather than assume." The assumption did **not**
hold in CI:

- **`cross-version-smoke.yml`** (the "Upgrade smoke (vX → candidate)" job named in
  the bead): tests 1.0.4→candidate on tag push (last-30 releases), but its
  dataset has **no dependencies** and it runs **no blocker queries** — only
  `list` / `doctor quick` / `update` / `show`. It would not catch a
  dependency-migration or blocker-query regression.
- **`migration-test.yml`**: *does* create a populated issue→issue dependency and
  checks field-by-field fidelity through an in-place upgrade — but only from
  baselines **≤ v0.63.3** (`DIRECT_PATHS` tops out there; no 1.0.x baseline), and
  it verifies via `bd list` / `bd show` only. It never runs `bd ready` /
  `bd blocked` / `bd close` post-migration.
- The `is_blocked` / ready / blocked logic is unit-tested only on **fresh-schema**
  DBs (`is_blocked_test.go`, `ready_work_test.go`), not on in-place-migrated DBs.
- Rollback (`.down.sql` for 0041–0045) exists but is not exercised by any CI job.

## Verdict & recommendation

**Not release-blocking.** The failure mode the gate guards against does not occur:
a real released-v1.0.4 DB with populated dependencies migrates cleanly under the
1.0.5 candidate, and `bd close` / `bd ready` / `bd blocked` all work with data
preserved. Confirmed by hand, which is stronger than the (absent) CI coverage.

**Non-blocking hardening (follow-up):** add a post-upgrade blocker-query
assertion (`bd ready` / `bd blocked` / `bd close`) to the `migration-test`
harness, which already builds the BUG→TASK dependency. That would lock in
regression coverage for the exact path verified here. Upstream beads change →
route through PR preflight + worktree.

---
_claude-opus-4-8-high on behalf of maphew_
