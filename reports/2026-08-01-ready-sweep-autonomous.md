# Ready-queue autonomous sweep — 2026-08-01 (afternoon)

Session brief: work `bd ready` until dry or genuinely blocked; workflows; check for
prior coverage before claiming; worktree + branch + tests + PR per task; patrol owns
merges; no product decisions; no history rewrites. Model: claude-opus-5-high.

## Headline

Five upstream PRs opened, six merge lanes armed on existing green PRs, five upstream
reviews posted (one PR merged by its author minutes later), two empirical bug verdicts
recorded, one contributor PR re-ported with attribution, and a main-red investigated
and dispositioned as a connection flake. The ready queue is **not dry** — see "What
remains" for the honest classification of the ~90 survivors.

## PRs opened (all cross-vendor reviewed at their final heads, all in patrol merge lanes)

| PR | Bead | What | Provenance chain |
|----|------|------|------------------|
| gastownhall/beads#5240 | mybd-5eacq | ci(pr): run the macOS test leg on PRs — macOS regressions were landing on main undetected (3 in one day) | builder → codex clean |
| gastownhall/beads#5241 | mybd-e1b3f | fix(dbproxy): abort readiness wait when a concurrent stop advances the epoch; negative-verified (29.5s → 0.06s without/with) | opus impl → opus adversarial review (5 findings applied) → codex clean |
| gastownhall/beads#5242 | mybd-p9a1o | fix(embeddeddolt): nothing-to-commit tolerance — bd bootstrap dies on pristine store (#3886); + honest no-op reporting for both backends | builder → opus review caught a MAJOR (Sync's merge-conclude would have been swallowed) → 2 codex rounds (shutdown-budget fix via CommitPending) |
| gastownhall/beads#5243 | mybd-w7yc / mybd-5g9n5 | fix(routing): bind role detection to the bd -C target — maintainer re-port of #4242, Co-authored-by Osamu Okano; + test repair + redirect guard | reviewer (disposition) → builder port → codex caught a P1 (redirect users would regress) → guard mutation-tested |
| gastownhall/beads#5245 | mybd-n8an7 | fix(automerge): settled merges mint row_lock distinct from both parents — absorbed from #4682, all commits Co-authored-by Julian Knutsen; + AST completeness guard (15 verified writes) | opus impl → opus review (7 findings) → codex (2 P2s: guard missed its own resolver + backtick quoting) → all fixed, mutation-verified |

Every head has `make test` in the local verify queue; 5202/5241/5242/5245-parent heads
already **passed** before session end.

## Merge lanes armed on pre-existing green PRs

5222 (mybd-89mod), 5232 (mybd-wfxwe), 5223 (mybd-s2j21 — its 5221 sequencing condition
was met this morning), 5229 (mybd-pp5hv — after fixing codex's P2, GNU-only `sort -z`
in the macOS path, pushed as edf05f5a1), 5202 (mybd-cebxh — after fixing both codex P1s:
reject-path/source collision guard, stale reject artifacts; pushed as c6c39295d).

## Reviews posted upstream (review-needed lane batch)

- #5239 openapi Profiles relation — approve; merged by julianknutsen at 17:23Z (bead closed).
- #5244 removed-backend test-matrix collapse — approve; lane armed (mybd-ifzlp).
- #5219 wisp gc --age cascade — approve-with-followups; the real gap (proxied-server
  path re-expands cascade at delete time, bypassing the filter, dry-run divergence) is
  bd **mybd-1o2sm**; lane armed (mybd-ciuod).
- #5197 goldmark bump — approve; its 7 withheld workflow runs approved via API; lane armed (mybd-0fnrw).
- #5198 fastmcp bump — approve; lane armed (mybd-1mfmf).

## Investigations with verdicts (bead mybd-vkc56, now open + human-decision)

- **gh 4887** (auto-export stops after v53 migration): symptom REPRODUCED end-to-end via
  a real v1.0.4→main upgrade — root cause is the `export.auto` default flip in #4063,
  not a state latch (latch REFUTED: state detection self-heals). Fix options (a) one-time
  upgrade notice vs (b) grandfather existing exporters are an owner call; draft upstream
  comments on the bead.
- **gh 4988** (wisp-compaction orphans wedge): NOT reproducible on main; fixed by #5141 +
  follow-ups — verified with a pre-fix control run that wedges on the exact recipe.

## Other dispositions

- P0 stub mybd-az4uo closed (dup of mybd-89mod, our own PR 5222).
- mybd-w1o2f closed — all three sweep-tail PRs dispositioned (5221 merged upstream;
  5223 lane armed; 5202 reviewed/fixed/armed).
- PR 4461 (provenance log): patrol's red check was expired build artifacts (unmergeable
  rerun of a 3-week-old run), but the real state is approved + conflicting + migration
  0060 collision (main is at v62) — a focused-session semantic re-port, recorded on
  **mybd-pu6w**; duplicate lane mybd-qui9t closed.
- Deadline beads mybd-h8bb (08-02), mybd-nathu (08-03), mybd-ncx38 (08-03): authors
  still silent, freshness noted; actionable tomorrow/Sunday.
- Main went red 16:52Z: single failure in 12,884 tests (`TestIssueOperationsTypedIssueType
  UsesConfiguredTypes`, "uow: ping db: invalid connection" + mysql unexpected EOF) — a
  dolt-server connection flake, not a regression from #5237. Failed job rerun; concurrency
  then routed green-determination to the queued run on the newest merge. Patrol watches.
- Comment posted on #4242 crediting osamu2001 and offering first right over the re-port.

## New beads filed

mybd-ylnpl (P2 vocab cache fails open — pre-existing, verified), mybd-d0u3f (P3
issueops diagnostics-suppression seam), mybd-z9h7j (P2, reopened: atomic committed-bool
through VersionControl), mybd-o4u1w (P3 residual -C non-git leak), mybd-tmheo (close
4242 after 5243 lands), mybd-5g9n5 (5243 merge tail), mybd-1o2sm (P2 wisp-gc proxied
cascade).

## What remains in `bd ready` (~90 non-human beads) — why this isn't "dry"

1. **tri:human / human-decision / solo-sweep:proposed** — owner judgment by design
   (mybd-lvzry is the review bead for the proposed batch).
2. **Theme-cluster campaign stubs** (xmx7.4/.5/.6 and their ~50 tri:claim members) —
   session-scale sweep campaigns, not single tasks.
3. **Review-needed backlog** (~25 more) — includes the arcaven trio already claimed by
   another session's lane (mybd-94l2i) and heavier stacks (federation 5207/5214/5215/5216,
   4844 rebase, 4415 flat-file) that each want a focused review session.
4. **Deadline-gated** (h8bb/nathu/ncx38) and **design/contract-gated** (alm2/s4h6 need a
   dependents-semantics decision; 47ly needs a benchmark design; lq8i.3 Amp hardening;
   hs98a unattended-lane design).
5. **Epics** (t7mk, t8l8, 9i93, jcx5…) with no ready children — umbrella records.

## Process notes worth keeping

- `bd` run from inside a bd-main worktree silently binds to the beads repo's own tracker
  context — `bd ready` returns `[]` and creates fail. Run bd from the coordination-repo
  root, always.
- `scripts/pr-review-gate` resolves HEAD from a **leading** `cd X &&` or the session cwd;
  a compound command with `cd` mid-pipeline gets the wrong checkout blocked. Lead with `cd`.
- A per-job rerun of a >1-day-old run can never pass in this repo (build artifacts have
  1-day retention) — "checks still fail after rerun budget" on an old head means *stale
  run*, not necessarily *real failure*.
- The adversarial verify stage kept earning its cost: the p9a1o review caught a
  merge-conclude swallow that would have shipped a re-wedge bug; codex caught the n8an7
  guard missing its own resolver, the 5243 redirect regression, and the 5229 macOS-path
  breakage. Zero of the five PRs shipped at their first-committed head.

_claude-opus-5-high on behalf of maphew_
