# julianknutsen upgrade-chain disposition — 2026-07-24

**Scope:** gastownhall/beads#4905 (plan) + #4907 (integration), the open head of
julianknutsen's deterministic-upgrade program. Queued as the next author cluster
in `reports/2026-07-24-mybd-beads-state-sweep.md`.

**Follow-up bead:** `mybd-5buk` (path decision, respond-by 2026-07-31).

## Chain structure

julianknutsen (admin, runs his own Gas City agent program with its own bead
namespace `bd-ldt0f`) built the program as stacked branches pushed directly to
gastownhall/beads (~19 `upgrade/*` + `feature/v12-*` branches):

- **Merged sub-chain** (into feature branches, *not* main):
  - #4801 — real v0.49.6 SQLite upgrade gate → `feature/backend-provider-change-20260713`
  - #4810 — legacy-Dolt pre-store refusal → `upgrade/q1-e1-legacy-dolt-ci-gate`
  - #4845 — verified public v0.62 apply → `upgrade/q1-e5-public-v062-bridge`
- **Open head**, both based on `feature/backend-provider-change-20260713`
  (29 ahead / **308 behind** main):
  - #4905 — plan docs only, +4659 (requirements, architecture, bead DAG,
    qualification contract). Mergeable vs base.
  - #4907 — two-parent provenance-preserving merge of the accepted chain,
    +17,926/−279 across 31 files. **Conflicting even against its own base.**
    Its 8 qualification CI lanes (v0.49.6/v0.55.4/v0.57.0/v0.62.0/v0.63.3) are
    green against that base.

## Reviews (posted 2026-07-24 06:16, both CHANGES_REQUESTED)

Cross-vendor (Codex gpt-5.6-sol primary trace, Claude adjudication re-verified
at PR head). Shared root cause: **the entire chain encodes the
PostgreSQL/MySQL/SQLite storage world that main deleted and now rejects
fail-closed (#4857, #4881)**. This is product-direction conflict, not a rebase
chore — plan artifacts, migration selector, and topology witness all assume
multi-backend.

Per-PR blockers on the threads:

- **#4905**: restores removed backends; fresh `bd init` breaks on FreeBSD
  before RunE (`safefile.ObserveMetadataNoFollow` stub, goreleaser still ships
  freebsd-amd64); redirect rewrite drops #4875's `hasBeadsProjectFiles` guard;
  topology witness ignores `dolt.shared-server` config so it can misclassify
  shared-server as embedded; new
  `InspectSourceShape`/`BindProviderConfiguration` lifecycle has zero
  production callers.
- **#4907**: removed-backend conflict (8 hunks in `init.go`/`main.go`/
  `beads.go`, hard-coded PostgreSQL migration target); linux inspector opens
  and hashes private Dolt paths (`.dolt/config.json`, `.dolt/repo_state.json`)
  — direct engine introspection the storage charter reserves to the driver.
  Should-fix: 22k test lines vs 9k production, pinning source commits and call
  sites past the repo's testing-philosophy limits.

## Disposition (this session)

The program itself is **wanted** — deterministic upgrades from old public
releases is recurring P0/P1 pain in our queue (mybd-p9f0, mybd-kuqk, the
upgrade-failure cluster), and the steveyegge audit's migration-architecture
direction explicitly carved out the upgrade program (see coffeegoddd sweep,
#4286 close). The per-PR reviews alone risked reading as rejection, so a
consolidated chain-level comment went on #4905 (pointer on #4907) offering two
paths with same-week maintainer support:

1. **Contributor re-cut (preferred):** extract harness + v0.62 bridge onto
   Dolt-only main, requalify lanes against main's driver/Dolt pins, re-scope
   the plan docs. Keeps his program and authorship fully intact.
2. **Maintainer-side extraction** with commits preserved as literal ancestry /
   Co-authored-by, blockers fixed in passing.

Path decision requested by **2026-07-31**; silent → one ping, then owner
decides. **No unilateral extraction before the window closes** — he has admin,
the reviews landed only this morning, and the mybd-mlqr precedent (offer paths,
wait, ping, escalate) applies.

Comments: [4905](https://github.com/gastownhall/beads/pull/4905#issuecomment-5075379161),
[4907](https://github.com/gastownhall/beads/pull/4907#issuecomment-5075379311).

## Loose ends

- **mybd-mlqr** (#4581, same author, hosted-gateway churn stack path): defer
  lapsed 2026-07-14, the "ping once" is 10 days overdue; PR still open and
  mergeable. Not part of the upgrade chain — left on its own bead, noted in
  mybd-5buk.
- Julian's other open PRs (4916 mutations journal, 4859 backend registry,
  4715 holder_token, 4697 claim_fence, 4682 CAS) are a separate future
  author-sweep; several likely interact with whichever extraction path wins.
- His PR bodies are signed `on behalf of CI Bot` / `on behalf of Test User` —
  signing-convention drift worth a gentle note whenever the path conversation
  happens.
