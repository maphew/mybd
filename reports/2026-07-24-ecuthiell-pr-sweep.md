# Maintainer sweep: ecuthiell's open PRs — 2026-07-24

Second run of the author-clustered sweep pattern (PR_MAINTAINER_GUIDELINES.md
"Sweep by author, not by age"; owner-endorsed same day). Sweep bead: mybd-tm42
(now the #4979 merge tail). Review fan-out: workflow `wf_95a850b9-d32` — one
reviewer per PR plus one adversarial verifier per verdict (~605k subagent
tokens across both passes).

Context: ecuthiell had 8 open PRs at the 07-23 CHANGES_REQUESTED wave; 3
(#4990, #4981, #4966) merged before this sweep, leaving 5. The unifying fact:
**every one of maphew's 07-23 changes-requested reviews had already been
addressed by the author's 07-24 pushes** — all five blocks were stale reviews,
not open problems. Base health at action time: upstream main green.

## Outcomes

| PR | Verdict | Action taken |
|----|---------|--------------|
| 4979 doc-freshness sans Python | merge | Stale CR superseded with verified approval; handed off (mybd-tm42) |
| 4968 fake-gh preflight tests | merge | Approval (BASH_ENV hermeticity verified closed + falsifier test); handed off (mybd-5alu) |
| 4949 Git Bash Make bootstrap | merge | Approval (MAKE_HOST gating spares msys/cygwin; 3-lane Windows matrix required); handed off (mybd-mivm) |
| 4929 worktree merge containment | merge | Approval; maintainer rerun of flaked proxied-Dolt job (run 30089571462); handed off (mybd-4a7x) |
| 4928 embedded backup size | fix-merge | Maintainer merge commit `47831a41c` pushed to the contributor branch; approval; handed off (mybd-0q4x) |

All merges go through the pr-babysit patrol per the role split — nothing was
merged in-session.

## The 4928 fix-merge

Sole conflict: additive-additive collision in `internal/storage/dolt/store.go`
between main's `buildTestModeProductionPortPanic` (AD-01, #3632) and the PR's
`resolveLocalActiveDatabaseDir` at the same post-`New()` insertion point.
Resolution: both functions kept verbatim. Validated in the worktree
(`.worktrees/beads/pr-4928-fixmerge`, since removed): build, vet, gofmt, and
the focused ActiveDatabaseSize/BackupStatus/MeasureDirectorySize/
sibling-scoping test set across `internal/storage{,/dolt,/embeddeddolt}` and
`cmd/bd`, all green (CGO_ENABLED=1, `-tags gms_pure_go`). The adversarial
verifier had independently test-driven the same resolution before I applied it.

## Follow-ups filed

- **mybd-orcx** (P3 bug): `addToGitignore` in `cmd/bd/worktree_cmd.go` splits
  on LF without stripping CR, so a CRLF .gitignore defeats the duplicate-entry
  check (usually masked by the `isIgnoredByGit` early return). Small
  maintainer commit once #4929 lands; promised in the #4929 approval.
- Non-blocking notes left in approvals, not tracked: paths-filters could trim
  the three new always-on required CI matrices (doc-freshness 3-OS,
  windows-make-shell, worktree-remove-windows) if runner cost ever matters;
  `freshnessDocuments` fixture duplicates the script's DOCS array (fails
  loudly on drift).

## Process notes

- **Author-clustering paid off again**: one context load surfaced the shared
  story (stale reviews across the whole cluster), one review pass unblocked
  five PRs, and the contributor gets five consistent approvals in one sitting
  instead of scattered verdicts.
- **Workflow budget-guard bug worth knowing**: `budget.spent()` is turn-wide,
  not per-workflow. The first run of this sweep silently skipped all five
  adversarial verifiers because an earlier workflow in the same turn had
  already spent past the target. Fix: capture `budget.spent()` at script start
  and guard on the delta. The verify pass was re-run (cached reviews replayed
  free) before any outward action was taken; all five verdicts confirmed.
