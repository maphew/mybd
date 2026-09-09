# tri:claim backlog drain strategy — theme-clustered sweeps (mybd-xmx7)

2026-07-26. Owner asked for a drain pattern for the tri:claim issue-stub backlog,
analogous to the author-clustered PR sweeps (`author-clustered-pr-sweeps` memory)
but clustered by subsystem/theme instead of author.

## Population

223 open `tri:claim` stubs at design time (pool grew from 52 to 223 with the
2026-07-26 full-pool triage run, `reports/triage/2026-07-26.md`). Every stub now
carries exactly one `theme:<slug>` label (classification pass this session,
haiku-tier, ~57k tokens):

| theme | count | notes |
|-------|------:|-------|
| pr-mirror | 43 | stubs whose upstream ref is a PR — belong to the PR-sweep lane, NOT issue sweeps |
| cli-ux | 36 | flag handling, output/json shape, error messages |
| server-mode | 34 | shared/proxied sql-server lifecycle, unreachable-server write loss |
| misc | 22 | needs a reclassify pass; likely splits into existing themes |
| sync-remote | 17 | bd dolt push/pull, remotes, bootstrap, backup remotes |
| import-export | 13 | JSONL auto-import/export, fidelity, round-trip |
| test-ci | 12 | flakes, CI-only failures |
| migration-schema | 12 | migrations, gates, dolt version compat |
| data-integrity | 11 | silent no-ops, lost updates, ghost records |
| doctor | 7 | bd doctor checks/--fix |
| concurrency | 7 | races, locks, simultaneous claims, stale reads |
| deps-ready | 6 | bd ready semantics, dependency edges |
| hooks-install | 3 | git hooks, core.hooksPath artifacts |

## Sweep unit

One theme, all its stubs, one session, one consolidated report + follow-up
bead. Steps per sweep:

1. **Freshness (delegated, cheap tier):** for every stub, check upstream —
   issue still open? merged PR references it? last comments indicate
   resolution? version-pinned to behavior since rewritten (many stubs are
   v1.0.4-era; current is v1.1.2)? Scout/haiku gathers facts verbatim;
   orchestrator synthesizes.
2. **Dedupe within theme:** stubs frequently share one root cause (e.g. the
   auto-import-on-every-command family). Identify root-cause groups.
3. **Disposition per stub (orchestrator judgment):**
   - `tri-close` — fixed upstream since filing, stale, or dupe (reason names
     the fixing PR / surviving stub). Uses `scripts/tri-close` so the
     `triaged` label lands upstream; text publication stays human-gated via
     `scripts/tri-submit`.
   - **consolidate** — N same-root-cause stubs → ONE actionable engineering
     bead with repro + design; stubs closed as dupes pointing at it.
   - **flesh out** — stub survives alone: add acceptance criteria, repro,
     affected code paths so it stops being a stub.
4. **Report:** `reports/<date>-issue-sweep-<theme>.md` — disposition table +
   root-cause map. One follow-up bead for engineering work that emerged.

## Ordering (proposed)

1. **import-export (13)** — first sweep, this session (proof of pattern).
2. **data-integrity (11) + concurrency (7)** — highest severity density,
   freshness likely kills several (many predate the v1.1.x write-path work).
3. **migration-schema (12)** — warm context from #4504/#5042/mybd-efzs work.
4. **sync-remote (17), doctor (7), deps-ready (6), hooks-install (3)**.
5. **cli-ux (36)** — bulk lane, low risk; batch freshness via one delegated
   pass, dispositions mostly mechanical.
6. **misc (22)** — reclassify first, then fold into the above.
7. **server-mode (34)** — LAST or coordinated: overlaps the active
   local-first/proxied campaign (epic mybd-psxg, in-progress lanes). Sweep
   only dispositions/consolidates; engineering routes into the campaign.
   Check with campaign lane owners before closing anything they may be using
   as evidence.
8. **pr-mirror (43)** — not an issue sweep at all: route to the
   author-clustered PR sweep lane (mybd-8nq5s pattern). The theme label makes
   them separable (`bd list -l theme:pr-mirror`).

## Rules learned in execution (sweeps 1–7, same day)

- **Verify every recon "fix merged" claim in-session before closing.**
  Session scoreboard: 10 claims, 7 confirmed, 3 rejected (~30% false-positive
  — a closed-unmerged PR, a diagnostics-only PR, and a cross-ref for a
  different issue). One rejected claim would have closed a live p1 gap.
- **Check `bd dep list` before consolidating** — the triage layer often
  already dep-gated stubs on fix-PR mirror beads (the Windows test cluster
  was fully structured; a redundant consolidation bead had to be reverted).
- **Timeline cross-refs miss unlinked fix PRs**; join through the
  theme:pr-mirror stub inventory as well.
- Post-sweep, `misc` reclassified to near-zero (22 → 1: 18 cli-ux,
  1 deps-ready, 1 migration-schema, 1 repaired mistitled stub → test-ci).

## Rules

- Theme labels are durable: future triage runs should theme-label new
  tri:claim stubs at creation (add to `/triage` procedure — follow-up bead).
- A sweep never posts prose upstream except through the human-gated
  `tri-submit`; `tri-close` label-only closes are allowed (existing policy).
- bd writes stay serial; freshness recon parallelizes freely (gh reads).
- Collision guard: before dispositioning a stub, check it isn't referenced by
  an in-progress bead in another session's lane (`bd list --status=in_progress`).
