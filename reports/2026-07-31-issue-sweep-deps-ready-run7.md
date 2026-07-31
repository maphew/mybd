# Issue sweep — theme:deps-ready (solo-sweep run 7)

Unattended lane, 2026-07-31. Theme population is small: 4 stubs carry
`theme:deps-ready`, of which **mybd-i9x0 is `in_progress`** in another session's
lane (gh 5069, fix PR gh 5116 already open) — left untouched per the collision
guard. The remaining **3 open stubs were all dispositioned**; nothing was
skipped for budget or scope.

All code claims below were read at `upstream/main` (tip `84431ee5c`), not the
`bd-main` working tree.

## Dispositions

| bd | gh | p | proposed | evidence |
|---|---|---|---|---|
| mybd-a7wxv | 3982 | 3 | **close** | Commit `e1c8b8b97` (dependabot PR #3957, authored 2026-05-27) is the exact 3.2.4 → 3.3.1 pin bump asked for, and is reachable from `upstream/main`; I read the diff hunk. main has since moved to `fastmcp==3.4.4` via `936aa33fa` (#4999). Issue was never closed. |
| mybd-y06g | 5036 | 1 | **flesh-out** | Live and unfixed. gh 5036 timeline is **empty** — no PR, no commit ref, nothing since filing 2026-07-25. Both halves of the reporter's contradiction reproduce from code (see Group A). |
| mybd-i7de | 4769 | 2 | **keep-open** | Fix PR gh 4753 is `merged=false, merged_at=null`, still open. Both reported symptoms reproduce at `upstream/main`. See "First thing to look at". |

New engineering bead filed: **mybd-zelnn** (p1) — the Group A root cause.

## Root-cause map

**Group A — `bd ready` is one denormalized bit, so every relationship class the
recompute can't express becomes its own bug report.**
`sqlbuild/ready.go` `BuildReadyWorkWhere` is the entire readiness test: `status`,
`(pinned = 0 OR pinned IS NULL)`, `is_blocked = 0`. No dependency join, no
`parent_id`, no `depends_on_external`. Everything readiness knows was
precomputed into `is_blocked` by `issueops/blocked_state.go`
`markBlockedTemplateForIssues`, whose EXISTS arms all join
`depends_on_issue_id` / `depends_on_wisp_id` to a local row.

Both sweep stubs reduce to that:

- **gh 5036** — the parent-child arm keys on `p.is_blocked = 1`, so hierarchy
  propagates the parent's *blocked flag*, never "parent not yet complete". The
  reporter's parent is `in_progress` → `is_blocked = 0` → child is ready.
  Meanwhile `cmd/bd/dep.go` `isDisallowedHierarchicalDependency` (pure dotted-ID
  string parsing, no DB lookup) refuses the explicit edge with *"Children
  inherit dependency on parent completion via hierarchy"*. The two views assert
  genuinely different semantics; the reporter is right that both cannot hold.
- **gh 4769** — `depends_on_external` is joined by no arm (there is no local row
  to join to), so an `external:proj:cap` blocker cannot set `is_blocked` and
  cannot gate ready, by construction.

Same family, currently open upstream, and the reason this deserved a bead rather
than two stub edits: **gh 3887** (grandchildren of a blocked parent are ready —
propagation is one level, not transitive), **gh 4138** / mybd-ltbf2 (migration
leaves blocked rows at `is_blocked = 0`, i.e. the derived bit can simply be
*wrong*), **gh 3877** / mybd-lhwnf (deferred: "re-evaluate using the
`ready_issues` view in `GetReadyWork`" — the same question from the perf side).

**Group B — external refs are second-class on read paths, inconsistently.**
`GetDependenciesWithMetadataInTx` selects the `COALESCE(...)` target — so the
external string *is* read — then resolves every target through
`GetIssuesByIDsInTx` and drops misses (`if !ok { continue }`). `bd dep list <a>`
and `bd show <a>` both go through it, so external edges vanish. But
`bd dep list <a> <b>` (batch form) uses `GetDependencyRecordsForIssues`, a raw
select with no issues join, where external edges **do** appear. `bd graph` and
`bd swarm` also show them. This asymmetry is not in gh 4769 and is recorded on
mybd-i7de for whoever re-reviews gh 4753.

## First thing to look at

**mybd-i7de is a live p1-adjacent bug gated behind a deferred bead.** It is
`blocked-by` mybd-hb3lo (the gh 4753 mirror), which is `DEFERRED` with the note
*"under active review, not yet ready to land"*. That note is stale: maphew left
CHANGES_REQUESTED on 2026-07-24 and **dredozubov has pushed twice since** —
`b38a4b98c` (2026-07-25) and `ecd1146cd` (2026-07-26). The PR is waiting on
*us*, not the author, and the bead structure hides that from `bd ready`.
Suggest un-deferring mybd-hb3lo.

Two smaller items: gh 4769 is a **re-report**, not a new gap — gh 2025
("DECISION: external blockers silently ignored by bd ready", 2026-02-23) posed
the same gate-vs-advisory question with a failing regression test and was closed
unmerged two days later with no decision I could find. gh 4769 supplies the
tiebreaker gh 2025 lacked: `bd dep add --help` already documents *"They block
the issue until the capability is shipped"*, so the documented contract picks
"gate". And **gh 3887 has no bd stub** — the closest sibling to gh 5036 is not
mirrored into the tracker at all.

## Confidence and caveats

- **The one `close` is well-evidenced but has an unverified tail.** gh 3982 asked
  for two things; I verified the pin bump merged (`e1c8b8b97`, diff read) but the
  second ask, "release a new version of `beads-mcp` to PyPI", is **not
  verifiable from this lane** — no PyPI access. `pyproject.toml` says
  `version = "1.1.0"`. Confirm the release, or close for the pin ask and split
  the release ask out.
- **Two near-miss "fixed upstream" traps, both rejected.** gh 5131
  ("fix(doctor): detect parent→child hierarchy-blocking deps", opened 2026-07-29)
  is open, **unmerged**, diagnostics-only, and covers the *opposite* edge
  direction — it fixes gh 4814, not gh 5036. gh 4753 is referenced by the author
  as "the implementation for" gh 4769 but is unmerged. Either would have closed a
  live issue on a referenced-not-merged reading; both are exactly the
  false-positive shape the strategy report warns about.
- **Code claims are high confidence**: I re-read `ready.go`, `blocked_state.go`,
  `dependencies.go` and `dep.go` at `upstream/main` myself after a subagent
  located them in the working tree. The subagent's line numbers are working-tree
  numbers; the *content* is confirmed at `upstream/main`. Nothing here rests on
  the working tree.
- **Not verified**: I did not run any of the repros (no build/test in this
  lane), so "reproduces from the code" is a reading, not an execution. The gh
  3887 corroboration is that issue's own prose, not my test.
- **Search coverage is partial.** Timeline enumeration ran clean on all three
  issues. PR discovery used `search/issues` keyword queries; `solo-recon`'s
  endpoint regex rejects `+` in query strings, so I used `%20` — results looked
  sane, but an unlinked fix PR with unrelated wording could still be missed. The
  gh 5036 empty timeline is the strongest single signal that nothing touched it.
- **Not examined**: mybd-i9x0 (in another lane). Its gh 5116 fix is *not* part of
  Group A — an alias-normalization bug writes an inert edge that never reaches
  the recompute. Do not fold the two together.
