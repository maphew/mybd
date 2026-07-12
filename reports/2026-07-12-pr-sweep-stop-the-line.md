# 2026-07-12 PR sweep: 7 merges, 1 self-inflicted red main, fixed forward

Session: claude-code-fable-5, processing `bd ready` triage-mirror beads via
delegation (workflow review fan-out, builder/reviewer agents, codex
cross-vendor) per the standing orchestration opt-in.

## Merged upstream (gastownhall/beads)

| PR | What | Path |
|----|------|------|
| #4686 | `bd list --tree` nests by parent-child edges only | merge (approved+validated locally) |
| #4518 | seed dolt_ignore idempotently at MigrateUp | merge — **broke main**, see below |
| #4744 | fix: commit the seed before the migration pass | stop-the-line fix (ours) |
| #4500 | scope `bd gate list <id>` to that issue | fix-merge (docs regen pushed to branch) |
| #4675 | unclaim ownership + lease on proxied claim + batch exit | fix-merge (conflict resolution vs #4718, sqlkit adaptation) |
| #4712 | redact all DSN password forms in telemetry | fix-merge (5 bypass fixes pushed, see below) |
| #4733/#4734 | ExternalRefHistoryQuerier capability + tracker gate (issue 4549) | reviewed, approved, merged in order |

Also: PR #4743 opened (ours): stderr warning when `--notes` overwrites
(issue 4541). Green, awaiting independent review — tracked in `mybd-8qyu`.
Closed `mybd-wpxs` as already-landed (#4713).

## The incident: #4518 turned main red

`#4518`'s own checks were green — but they predated the #4566 per-step-commit
convergence test landing on main (#4611). The seed dirtied `dolt_ignore` at the
top of `MigrateUp` and deferred its commit to the end of the pass, so a pass
killed between steps left a dirty working set:
`TestEmbeddedMigrateConvergesUnderConcurrentInterruptedRetries_4566` failed
deterministically on main and every PR merge-ref (first seen as identical
failures on three unrelated PRs — the tell that it was the base, not the PRs).

Fix (#4744): commit the seed in its own scoped, labeled commit on the needed
path too, after `unstagePreExistingTables` and before the first step. Local
pre-merge validation had run the schema suite but not the embedded-dolt
convergence suite — the gap is now a `bd remember`
(`stale-green-checks-merge-hazard-learned-2026-07`): refresh any PR whose green
checks predate recent main commits before merging; base-green preflight does
not test the PR+base composition.

## Cross-vendor review earned its keep again

On #4712, the Claude reviewer confirmed one known blocker (percent-encoded
query keys); `codex-agent reviewer` (gpt-5.6-sol) found four more real
bypasses: `-qpSECRET` pflag shorthand clusters, backslash-escaped whitespace in
libpq values, `\v` as pgx whitespace (Go `\s` excludes it), and
overlapping-secret replacement ordering. All five reproduced test-first before
fixing (maintainer push `4b56677e8`).

## Open follow-ups (in tracker)

- `mybd-uaiv` — batched: CHANGELOG entries (#4686 tree behavior, #4675
  `--force`/exit codes), #4500 gate-list nits, #4675 nits.
- `mybd-8qyu` — PR #4743 needs an independent reviewer.
