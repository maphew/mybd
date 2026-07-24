# Upstream PR Review Sweep — 2026-07-07

**Bead:** mybd-kjow · **Session:** claude-fable-5-high on behalf of matt wilkie
**Coverage:** 7 of 7 open gastownhall/beads PRs with zero maintainer engagement (100% of the unreviewed set as of this morning).

## Selection

Starting from all ~90 open non-draft PRs, exclusions with reasons:

- **Already reviewed** by the 2026-07-05 sweeps (batches A/B/oldest/oldest-2/old-but-based, 73 signed reviews total) — execution backlog tracked in mybd-j5ed and salvage epic mybd-8chd, not re-reviewed here.
- **Bot PRs** (dependabot ×12, flake-updater ×1) — easy-win class, not review targets.
- **Own PRs** (maphew ×14, #4576–#4600) — routed to a cross-vendor Codex second-opinion follow-up instead (see Follow-ups).
- **Co-maintainer PRs with active maintainer threads** (#4491, #4493 — steveyegge/timsehn already engaged).
- **#4104** — already dispositioned in salvage cluster mybd-8chd.3.

What remained was exactly seven PRs with **zero** reviews and zero comments. Every one was reviewed with a correctness pass plus an explicit charter-fit assessment (PROJECT_CHARTER boundaries + storage-driver roadmap), and every blocker/major claim went through an adversarial verify agent before posting. All seven got signed review comments on 2026-07-07.

## Verdicts

| PR | Author | Title (short) | Triage | Outcome | Fit | Verified findings |
|----|--------|---------------|--------|---------|-----|-------------------|
| [#4611](https://github.com/gastownhall/beads/pull/4611) | csauer02-personal-user | self-heal migrate/bootstrap, atomic per-migration commits (finishes #4566) | fix-merge-candidate | **fix-merge** | in-scope-core | 2 major (1 confirmed, 1 softened), 2 minor, 1 nit |
| [#4610](https://github.com/gastownhall/beads/pull/4610) | coffeegoddd | prune/purge proxied-server support | easy-win | **merge-fix** | in-scope-core | 1 major (confirmed), 1 minor, 1 nit |
| [#4603](https://github.com/gastownhall/beads/pull/4603) | banozz0 | beads-mcp comment/comments/note tools | fix-merge-candidate | **fix-merge** | in-scope-integration | 1 major (softened to minor), 1 minor, 1 nit |
| [#4602](https://github.com/gastownhall/beads/pull/4602) | rjc123 | multi-clone migration docs + gate hints (#4259) | needs-review | **split-merge** | in-scope-core | 1 major (refuted → minor), 1 minor |
| [#4597](https://github.com/gastownhall/beads/pull/4597) | kevglynn | `bd q --parent` hierarchical quick capture | easy-win | **merge** | in-scope-core | none (one help-text nit) |
| [#4581](https://github.com/gastownhall/beads/pull/4581) | julianknutsen | dolt pool ignored-tx borrow + per-dial credential connector | fix-merge-candidate | **fix-merge** | in-scope-core | 2 major (both softened), 1 minor, 1 nit |
| [#4472](https://github.com/gastownhall/beads/pull/4472) | harry-miller-trimble | reject cross-table issue/wisp ID collisions (#4455) | easy-win | **merge** | in-scope-core | 2 minor, 1 nit |

## Per-PR notes

### #4611 — self-heal migrate/bootstrap (fix-merge)
Strong finish to #4566: per-migration atomic commits (DDL + cursor row, selectively staged) end the stranded-batch failure mode; deletes the failed-0053 band-aid; respects the #4516 smart gate structurally. Confirmed major: deleting `failed0053DirtyTablesAreRecoverable` regresses *already-stranded* legacy stores (the #4555 incident class) from automatic to manual recovery — needs a conscious maintainer decision. Softened major: the "plain supervisor retry converges" claim doesn't hold on remote-backed stores (retry parks at the smart gate), but that parking predates the PR. CI hasn't run (first-contribution approval gate). Base 28 behind, touched files undrifted.

### #4610 — prune/purge proxied-server (merge-fix)
Routes delete-closed-beads through UnitOfWork + existing domain use cases; only widens `DeleteIssuesParams` with a Cascade flag — the right side of the storage seam, all CI green. Confirmed major: `buildReferencedSetProxied` copies the slow regexp-alternation scan that open PR **#4599 (maphew)** replaces — whichever lands second must reuse the shared matcher. JSON parity gap: proxied `--json --force` drops `referenced_ids_sample`. Recommendation: fix parity here (~5 lines), land, coordinate the matcher with #4599.

### #4603 — beads-mcp comment/note tools (fix-merge)
Real gap for MCP-only agents; wraps existing `bd comment`/`comments`/`note` CLI correctly (arg construction and Comment model verified against Go source). Verify softened the test claim: no hard one-test-per-tool convention exists, but coverage stops at the bd_client layer while the description claims it "mirrors the add_dependency approach" — which is tested at all three tiers. No PR-triggered CI exists for beads-mcp, so the description's pytest/ruff claims are unverified. Ask: add wrapper-level (and ideally integration) tests, re-run locally, then merge.

### #4602 — multi-clone migration docs + gate hints (split-merge)
Change 1 (ordering hints in the two plain-text gate messages) is clean and ready — land now. Change 2 (manual "adopt without re-clone" recipe) had its major finding **refuted** in verification: the gate re-evaluates in a fresh process, so no un-gated migration path opens; residual issue is minor docs precision (the "gate stays silent" promise only holds single-hop) plus imminent supersession by #4586 adopt-ff. Posted comment offers the author both paths (caveat-and-land vs hold-for-#4586).

### #4597 — `bd q --parent` (merge)
Faithful mirror of `bd create --parent` (validation, label inheritance, child-ID reservation, post-write Dolt commit); solid embedded tests; docs regenerated; CI fully green; no overlap. The main review risk (semantics divergence, resolver fuzziness) checked out clean — parent lookup is exact `GetIssue`, unaffected by the #4376 resolver bug. Merge-ready as-is.

### #4581 — dolt pool ignored-tx borrow (fix-merge)
Kills real per-write fresh-dial churn (TLS+auth+session) on hosted gateways; BeforeConnect is the correct driver extension point; adapter-internal, right side of the storage boundary, composes with the interface split. Both majors softened on verification: the branch-leak on borrowed conns is **latent** (no non-test `Checkout` caller on main) — cheap hardening recommended at normal severity; and the stacked-base blocker stands (no CI ran, base branch has no PR) but retargeting is mechanically clean (3-way merge onto main auto-merges, no #4481 conflict).

### #4472 — cross-table ID collision guard (merge)
The prevention half of release-blocking #4455, still live (main only has the #4163 tolerance+repair half; no competing PR). Create-time rejection is the right layer — Dolt can't express a cross-table unique constraint. Carve-outs (promotion window, ConflictSkip) are deliberate and tested; base 139 behind but merges clean, CI green. Merge-ready as-is; note the import-path behavior change (loud failure on cross-table dup) is an improvement worth accepting consciously.

## Verification quality

Five verify agents ran (two PRs had no blocker/major claims). Of 8 blocker/major claims: 2 confirmed, 5 softened, 1 refuted. Every correction was folded into the posted comment — including one full rewrite (#4602, where the reviewer's hazard mechanism was wrong against current main). The per-stage budget cap (review ≤55% of target) prevented the batch-B failure mode where verification got starved; total workflow spend ~207k tokens against the 200k standing target.

## Follow-ups filed

- **mybd-kjow** (this sweep) — closed with this report.
- **Act-on-verdicts bead** — merge-ready: #4597, #4472 (local stacked-merge validation first per stale-PR gate); merge-fix: #4610; fix-merge: #4611, #4603, #4581; split-merge: #4602.
- **Codex cross-vendor review bead** — own PRs #4576–#4600 (14 PRs) still have zero independent review; route through `scripts/codex-agent reviewer` serially.

## Posted comments

[#4611](https://github.com/gastownhall/beads/pull/4611#issuecomment-4903801919) · [#4610](https://github.com/gastownhall/beads/pull/4610#issuecomment-4903802149) · [#4603](https://github.com/gastownhall/beads/pull/4603#issuecomment-4903802352) · [#4602](https://github.com/gastownhall/beads/pull/4602#issuecomment-4903802513) · [#4597](https://github.com/gastownhall/beads/pull/4597#issuecomment-4903802697) · [#4581](https://github.com/gastownhall/beads/pull/4581#issuecomment-4903802893) · [#4472](https://github.com/gastownhall/beads/pull/4472#issuecomment-4903803124)

All signed `claude-fable-5-high on behalf of matt wilkie`.
