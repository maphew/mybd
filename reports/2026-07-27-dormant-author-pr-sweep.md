# Dormant single-PR-author review sweep — 2026-07-27

**Bead:** mybd-75vui (from pr-mirror routing mybd-49q9c) · **Workflow:** wf_f1b90bc8-a36 (5 reviewer agents, ~298k tokens) · **Baseline:** upstream/main c989b6b87

Six PRs from five one-PR authors, each answered at most once (mid-June or
2026-07-05) and silent since — the "dormant sweep residue" band from
mybd-aayb. All six re-reviewed against current main; all six received a
substantive disposition comment today (signed, linted, posted).

## Outcomes

| PR | Author | Verdict | Next | Lane |
|---|---|---|---|---|
| [#4413](https://github.com/gastownhall/beads/pull/4413) | griels | approve-with-nits | maintainer rebase → merge (docs surface moved under it; core verified current) | mybd-1kfm7 |
| [#4383](https://github.com/gastownhall/beads/pull/4383) | aaronlippold | needs-changes | still fix-of-record for GH#4078; author gets first pick, maintainer branch if silent by 08-03 | mybd-ncx38 |
| [#4288](https://github.com/gastownhall/beads/pull/4288) | realies | approve-with-nits | issues.go consolidation must be re-done by hand over withRetryTx refactor | mybd-nathu |
| [#4348](https://github.com/gastownhall/beads/pull/4348) | realies | approve-with-nits | store.go filter re-targets cleanly; uow skip needs tx-close-before-release rework | mybd-nathu |
| [#4175](https://github.com/gastownhall/beads/pull/4175) | fengning-starsend | needs-changes | break-glass must cover all sanctioned writers (import sync would be silently blocked); sequence with GH#4827 | mybd-qwffl |
| [#4346](https://github.com/gastownhall/beads/pull/4346) | ksletmoe-aws | already-absorbed | 03cdc6c86 fixed it with the opposite, divergence-safe design; close-when-quiet handed to patrol (opens 07-30) | mybd-64umj |

Upstream issue [#4298](https://github.com/gastownhall/beads/issues/4298) closed
with credit to ksletmoe-aws, whose diagnosis predated the fix by two days.

## Notable findings

- **Both realies PRs verified still-needed:** the unfiltered dolt_status scan
  (store.go:2385) and unconditional `doltServerTx` commit persist at main; the
  guarded-commit predicate the PRs need already exists at `CommitPending`
  (store.go:2582), making the port precedented.
- **A recurring apology theme:** three of the five authors' only prior contact
  was a mis-aimed triage template (repro request on a feature PR). Each posted
  comment owns that explicitly — it's the mybd-aayb rhythm problem in
  miniature.
- **4383's review cites merged policy PR gastownhall/beads#5094** (rebases are
  maintainer work), verified real before posting.

_claude-code-fable-5-medium on behalf of maphew_
