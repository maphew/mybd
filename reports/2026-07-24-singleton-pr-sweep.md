# Maintainer sweep: singleton cluster — 14 PRs, 11 authors — 2026-07-24

Fifth run of the author-clustered pattern, singletons edition. Sweep bead:
mybd-7p4j. Review: workflow `wf_f133986b-4c4` (14 sonnet reviewers, ~984k
subagent tokens). Per the quota directive, ALL verification ran on Codex
(gpt-5.6-sol serial gates) and the four small fix-rounds were done by the
orchestrator inline; the seven larger fix-merges used sonnet builders in
parallel worktrees.

## Outcomes

| PR | Author | Outcome | Tail bead |
|----|--------|---------|-----------|
| 4984 create input-discard | davevan2 | fix-merge (direct-mode guards + tests) | mybd-xpk1 |
| 4985 preview store-migration | davevan2 | needs-author (review <24h old) | mybd-vy09 deadline 07-31 |
| 4897 ready pagination meta | jacobhausler | fix-merge (proxied route + omitempty Total) | mybd-v07m |
| 4918 waits-for-gate validation | jacobhausler | fix-merge (batch-route rejects; ID after validation) | mybd-hwc6 |
| 4858 doctor child_counters | vishnujayvel | needs-author | mybd-fyno deadline 07-31 |
| 4913 async-gates docs | vishnujayvel | merge + maintainer doc fix (cross-rig await-id unevaluable) | mybd-9u0z |
| 4896 metadata key queryability | anisoptera | fix-merge (dual-preserve merge over #4732 + query-path proofs) | mybd-3ofo |
| 4930 readonly purity | idirectships | fix-merge (DisableAutoStart gating; OpenReadOnly wiring; Close() purity; canary fixture) | mybd-rdks |
| 4940 backup test path | imkp1 | easy-win (CI approved for first-timer; approved) | mybd-7rn3 |
| 4862 claim advisory lock | itsandyking | **retire with credit** (superseded by row_lock CAS fence + #5006/#5008); re-test ask posted | — |
| 4939 exact-hash ID matching | joshuaguyervs | fix-merge (HasPrefix restore; wisp infix handling) | mybd-5u3f |
| 4866 routing-swap notice | RaviTharuma | fix-merge (RoutingRule enum; per-rule text; --quiet) | mybd-gxil |
| 4959 gate repo metadata | srobroek | needs-author | mybd-dtdm deadline 07-31 |
| 4933 doctor dep-cycle bounds | swedeinasia-flow | merge (author addressed all 4 items; CI approved) | mybd-i6oj |

All merges via pr-babysit patrol; nothing merged in-session. The three
needs-author PRs have substantive same-day CHANGES_REQUESTED reviews at their
exact heads — nudging <24h later would be noise, so each has a deadline bead:
fix-merge around 2026-07-31 if the author hasn't pushed.

## Cross-vendor gate results (Codex, serial)

Verdict verification: 4862 retire CONFIRMED, 4933 merge CONFIRMED, **4913
merge REFUTED** — the doc's cross-rig `--await-id` example describes an ID
form `bd gate` accepts but never evaluates (pends forever); converted to a
one-commit maintainer doc fix.

Builder-output gate: 2 SHIP, 4 FIX first round — all four real:
- 4897: `Total int` without omitempty → proxied emits false `"total": 0`.
- 4930: `OpenReadOnly.Close()` could delete `tmp_pack_*` files (strict-readonly
  violation); plus the "unrelated drift" hermeticity failure was actually the
  PR's own fixture missing the now-required `federation.remote` — the gate
  correctly refused the unrelatedness claim.
- 4984: the round-trip test was silently SKIPPING (needs `-tags cgo` for the
  container test server) and leaked three globals not covered by
  `saveAndRestoreGlobals`.
- 4866: contributor notice could claim `beads.role=contributor` when the rule
  fired via URL inference with the key unset.
4896 (gated separately): dual-preserve merge verified function-complete; two
doc-accuracy fixes (caller list, "embedded" overstatement).
All re-checks SHIP after fixes.

## Also this session

- First-time-contributor CI runs approved for 4933 and 4940 (they'd been
  sitting with zero checks since 07-20/07-21 — worth watching for as a queue
  smell: `action_required` runs are invisible in the PR list).
- Flake reruns: 4897's PR Risk (proxied cmd timeout), earlier 4929.
- New dependabot wave (5015-5023, 9 PRs) arrived 07-24; left for a batch
  session / patrol. gh#4702's replacement appears in it (#5017).
- AGENTS.md: added the shared-stash warning (see below) to the worktree
  section.

## Process notes

- **git stash is repo-wide across worktrees**: two parallel sonnet builders
  each ran bare `git stash`/`pop` and popped each other's entries,
  cross-contaminating worktrees (both recovered, nothing lost; one stale
  entry dropped after verifying its content was committed). bd memory
  `git-stash-shared-across-worktrees` + AGENTS.md note added.
- The "would the test fail if the fix were reverted" and "did the test
  demonstrably run by name" questions caught something in a majority of
  gate rounds today. Cheap sonnet builders + serial Codex gates is a good
  quota-constrained division of labor.
