# Rebase-debt routing plan — 2026-07-28

> Method: fresh conflicting-PR list (54 of 94 open) fetched 2026-07-28; each PR head merged in-memory against upstream/main (3e6f25960) via `git merge-tree --write-tree` — no worktrees, per-file conflict lists captured. Buckets: noise = CHANGELOG.md/generated docs/go.sum only (found: zero PRs), shallow = ≤2 non-noise conflicted files, semantic = more. Routing synthesized by Codex reviewer (gpt-5.6-sol high, session 019faa52-103c-7eb2-a3a1-72d256b0f31a) against the 2026-07-27 cluster report + owner exclusions.
> Correction: #3876 is listed under "Excluded (O7)" but was already declined 2026-07-26 per gascity#2947 — effectively no-action/decline, not awaiting the design round. Net rebase-debt insight: only 8 of 54 conflicting PRs are worth maintainer rebase now; 22 are gated on 5 design/ordering decisions (O1 pooling, O5 backend seam, O2 5092/5093 baseline, O8 capability model 4753, O4 4907 rules) — settling those gates unblocks far more debt than rebasing does.

## Summary

| Route | PRs |
|---|---:|
| Maintainer-rebase batch | 8 |
| Author nudge | 3 |
| Cluster-gated | 22 |
| Decline candidate | 1 |
| Excluded (author design round) | 12 |
| No action (existing lane/bead) | 8 |
| **Total** | **54** |

## Maintainer-rebase batch

For these, resolve the conflicts for the contributor: push directly where maintainer edits are enabled; otherwise open a superseding PR with attribution.

| PR | Author | Bucket | Behind | Non-noise files | Cluster | Rationale |
|---|---|---:|---:|---|---|---|
| #3837 | ckumar1 | shallow | 1638 | 2 — `cmd/bd/dolt.go`, `cmd/bd/dolt_test.go` | O3 | Focused auth-error classification fix; reconcile behavior with #4831 during the cheap two-file rebase. |
| #4257 | Jacob-qd | shallow | 1072 | 2 — `cmd/bd/auto_import_upgrade.go`, `cmd/bd/auto_import_upgrade_unit_test.go` | Singleton | Isolated, plausibly wanted import-loop fix with only its implementation and test conflicted. |
| #4376 | sarendipitee | shallow | 623 | 1 — `internal/utils/id_parser.go` | Singleton | Focused resolver-correctness fix with a single non-noise conflict. |
| #4409 | bdarlt | clean-merge | 787 | 0 — none | Singleton | No non-noise conflicts; refresh only generated/noise material and preserve draft status. |
| #4804 | atbrace | shallow | 318 | 1 — `internal/storage/schema/lock.go` | D4 | Verified as the safer canonical migration-lock implementation; #4764 is already in its close lane. |
| #4806 | christso | shallow | 318 | 1 — `cmd/bd/setup/plugin_layout_test.go` | Singleton | Pi integration remains plausible and needs only one test conflict resolved. |
| #4808 | marcodelpin | shallow | 318 | 1 — `.github/workflows/pr.yml` | Singleton | Focused Windows liveness correction; the sole conflict is CI wiring. |
| #4959 | srobroek | shallow | 213 | 1 — `cmd/bd/gate.go` | O15 | Repository-metadata correctness is the first item in O15’s recommended order. |

## Author nudge

Ask for a rebase with the concrete conflict notes below. Allow 1–2 weeks, then supersede with attribution if the fix remains wanted and there is no response.

| PR | Author | Bucket | Behind | Non-noise files | Cluster | Rationale |
|---|---|---:|---:|---|---|---|
| #3859 | GraemeF | semantic | 591 | 4 — `cmd/bd/main.go`, `cmd/bd/storage_chain_test.go`, `docs/reference/observability.md`, … | O11 / C2 | Wanted telemetry migration; ask for one consolidated series with #3861 against the current initialization and observability layout. |
| #3861 | GraemeF | semantic | 1241 | 4 — `cmd/bd/main.go`, `cmd/bd/storage_chain_test.go`, `docs/reference/observability.md`, … | O11 / C2 | Wanted companion feature; ask the author to stack or fold it after #3859 rather than independently resolving shared telemetry conflicts. |
| #4175 | fengning-starsend | semantic | 1044 | 3 — `cmd/bd/rename_prefix.go`, `internal/storage/domain/db/config.go`, `internal/storage/domain/db/config_test.go` | O6 | Explicit prefix-mutation semantics look wanted; request a rebase preserving the current domain/config contract. |

## Cluster-gated

These should not be rebased until the named architecture, baseline, or ordering gate is settled.

| PR | Author | Bucket | Behind | Non-noise files | Cluster | Rationale / gate |
|---|---|---:|---:|---|---|---|
| #3563 | shaunc | shallow | 1475 | 2 — `internal/configfile/configfile.go`, `internal/configfile/configfile_test.go` | O2 | Gate: land/settle the #5092→#5093 Dolt-version and workspace policy baseline first. |
| #3579 | jozefizso | shallow | 1475 | 2 — `docs/CONFIG.md`, `internal/jira/tracker_test.go` | O12 | Gate: attachment decision mybd-982o must establish the retained Jira/Linear model. |
| #3610 | octo-patch | semantic | 1030 | 7 — `cmd/bd/compact.go`, `cmd/bd/find_duplicates.go`, `docs/CONFIG.md`, … | O11 | Gate: consolidate #3859/#3861 so provider and telemetry environment handling rebase against one contract. |
| #3612 | gt-rm-0306 | shallow | 1448 | 1 — `cmd/bd/dep_test.go` | O8 | Gate: establish #4753’s external-capability model as the dependency baseline. |
| #4133 | Zireael | shallow | 480 | 1 — `internal/doltserver/doltserver.go` | O2 | Gate: rebase focused lifecycle fixes only after the #5092→#5093 baseline settles. |
| #4242 | osamu2001 | shallow | 623 | 2 — `cmd/bd/routing_read.go`, `cmd/bd/routing_read_test.go` | O4 | Gate: settle #4907’s historical-upgrade policy in the excluded author round first. |
| #4289 | outdoorsea | shallow | 892 | 1 — `internal/storage/issueops/filters.go` | O6 | Gate: settle query correctness and #4175’s prefix-mutation contract before adding the index. |
| #4303 | cstar | semantic | 891 | 16 — `cmd/bd/db_proxy_child.go`, `cmd/bd/db_proxy_child_test.go`, `cmd/bd/dolt.go`, … | O1 | Gate: choose the pooling architecture and define how it rebases around focused #5024. |
| #4313 | bourgois | semantic | 785 | 7 — `cmd/bd/db_proxy_child.go`, `cmd/bd/main.go`, `internal/storage/dbproxy/proxy/endpoint.go`, … | O1 | Gate: decide whether this corrective work is folded into the selected #4303 design. |
| #4346 | ksletmoe-aws | shallow | 871 | 2 — `internal/storage/issueops/blocked_state.go`, `internal/storage/issueops/dependencies.go` | O8 | Gate: use #4753’s capability model as the blocked-state baseline. |
| #4383 | aaronlippold | semantic | 791 | 5 — `cmd/bd/config.go`, `cmd/bd/dolt.go`, `cmd/bd/vc.go`, … | O2 | Gate: settle #5092→#5093 before rebasing server-mode commit semantics. |
| #4415 | MarkAtwood | semantic | 316 | 15 — `cmd/bd/init.go`, `cmd/bd/store_factory.go`, `cmd/bd/store_factory_nocgo.go`, … | O5 | Gate: choose the backend-extension architecture and the role of #4859’s registry seam. |
| #4473 | rbriski | semantic | 714 | 7 — `cmd/bd/db_proxy_child.go`, `go.mod`, `internal/storage/dbproxy/pidfile/pidfile.go`, … | O1 | Gate: choose between the competing pooling approaches before paying semantic rebase cost. |
| #4561 | duncan4123 | semantic | 475 | 10 — `beads.go`, `beads_cgo.go`, `beads_nocgo.go`, … | O5 / C3 | Gate: decide whether the configured-backend API survives separately or folds into #4859. |
| #4674 | blairsilverberg | shallow | 519 | 1 — `internal/storage/issueops/dependencies.go` | O8 | Gate: rebase cascade behavior after #4753 fixes the capability/dependency baseline. |
| #4730 | jakelindsay87 | shallow | 472 | 2 — `internal/storage/issueops/create_test.go`, `internal/storage/issueops/dependencies.go` | O8 | Gate: land the capability baseline, then rebase timestamp normalization with conformance coverage. |
| #4736 | duncan4123 | shallow | 475 | 1 — `beads.go` | O5 / C3 | Gate: determine whether this remains an ordered #4561 follow-up or is absorbed into #4859. |
| #4738 | thewoolleyman | semantic | 472 | 4 — `cmd/bd/config.go`, `cmd/bd/create.go`, `cmd/bd/create_proxied_server.go`, … | O9 | Gate: land #4984’s validation baseline, then decide combined create-policy precedence. |
| #4742 | medhatgalal | semantic | 469 | 9 — `cmd/bd/close_proxied_server.go`, `cmd/bd/create_proxied_server.go`, `cmd/bd/delete_proxied_server.go`, … | O2 | Gate: settle #5092→#5093 before rebasing proxied-UOW retry semantics. |
| #4795 | harry-miller-trimble | shallow | 325 | 1 — `cmd/bd/init.go` | O4 | Gate: establish #4907’s historical-upgrade rules before rebasing initialization guards. |
| #4971 | harryhan24 | semantic | 205 | 8 — `docs/community-tools.md`, `docs/core-concepts/index.md`, `docs/getting-started/ide-setup.md`, … | O13 | Gate: stabilize/regenerate command and schema documentation; do not hand-resolve the translation against moving generated docs. |
| #4985 | davevan2 | shallow | 205 | 1 — `cmd/bd/main.go` | O4 | Gate: settle historical-upgrade rules, then rebase preview/open behavior last as recommended. |

## Decline candidate

| PR | Author | Bucket | Behind | Non-noise files | Cluster | Rationale |
|---|---|---:|---:|---|---|---|
| #3572 | jozefizso | semantic | 1475 | 3 — `.github/workflows/release.yml`, `.goreleaser.yml`, `docs/getting-started/installation.md` | Singleton | Ninety-day-old draft touching release machinery; seek a current-value disposition and use close-when-quiet instead of funding a semantic rebase. |

## Excluded (author design round)

| PR | Author | Bucket | Behind | Non-noise files | Cluster | Rationale |
|---|---|---:|---:|---|---|---|
| #3548 | kingfly55 | semantic | 1482 | 3 — `internal/storage/dolt/issues.go`, `internal/storage/issueops/update.go`, `internal/storage/storage.go` | O7 | Entire write-semantics/ownership cluster is reserved for the author design round. |
| #3876 | jjgarzella | semantic | 1215 | 15 — `cmd/bd/close.go`, `cmd/bd/cook.go`, `cmd/bd/cook_qnt_test.go`, … | O7 | Entire write-semantics/ownership cluster is reserved for the author design round. |
| #4682 | julianknutsen | semantic | 336 | 23 — `cmd/bd/close.go`, `cmd/bd/update.go`, `docs/cli-reference/index.md`, … | O7 / C4 | Excluded by author and by the ownership/concurrency design round. |
| #4697 | julianknutsen | semantic | 227 | 16 — `cmd/bd/close.go`, `cmd/bd/ready.go`, `cmd/bd/reclaim.go`, … | O7 / C4 | Excluded by author and by the ownership/concurrency design round. |
| #4715 | julianknutsen | semantic | 336 | 28 — `cmd/bd/close.go`, `cmd/bd/main.go`, `cmd/bd/ready.go`, … | O7 / C4 | Excluded by author and by the ownership/concurrency design round. |
| #4740 | steveyegge | semantic | 469 | 6 — `cmd/bd/init_test.go`, `cmd/bd/store_factory.go`, `cmd/bd/store_factory_nocgo.go`, … | O4 | All steveyegge PRs are excluded from maintainer rebase action. |
| #4756 | steveyegge | shallow | 421 | 2 — `cmd/bd/update.go`, `cmd/bd/update_proxied_server.go` | O7 | Excluded by author and by the write-semantics/ownership design round. |
| #4757 | steveyegge | shallow | 423 | 2 — `cmd/bd/config.go`, `cmd/bd/import_shared.go` | O9 | All steveyegge PRs are excluded from maintainer rebase action. |
| #4762 | steveyegge | shallow | 411 | 1 — `go.mod` | O14 | All steveyegge PRs are excluded from maintainer rebase action. |
| #4798 | harry-miller-trimble | semantic | 322 | 4 — `internal/storage/domain/db/issue_scan_parity_test.go`, `internal/storage/issueops/helpers.go`, `internal/storage/issueops/scan.go`, … | O7 | Entire write-semantics/ownership cluster is reserved for the author design round. |
| #4839 | steveyegge | shallow | 318 | 1 — `cmd/bd/update.go` | O7 | Excluded by author and by the write-semantics/ownership design round. |
| #4916 | julianknutsen | shallow | 227 | 2 — `internal/storage/domain/db/dependency.go`, `internal/storage/issueops/lease.go` | O7 | Excluded by author and by the ownership/journal design round. |

## No action (existing lane/bead)

| PR | Author | Bucket | Behind | Non-noise files | Cluster | Rationale |
|---|---|---:|---:|---|---|---|
| #4167 | Shockwave2k | semantic | 1043 | 6 — `cmd/bd/list.go`, `cmd/bd/main.go`, `internal/storage/dolt/queries.go`, … | O2 | Explicitly titled “showcase — do not merge”; no rebase work. |
| #4288 | realies | shallow | 892 | 2 — `internal/storage/dolt/issues.go`, `internal/storage/dolt/store.go` | D2 | Complementary with #4348; re-port is already tracked in mybd-nathu. |
| #4316 | MovGP0 | semantic | 876 | 13 — `README.md`, `docs/ARCHITECTURE.md`, `engdocs/DOC_INVENTORY.md`, … | D1 | Attachment-snapshot selection remains under owner decision mybd-982o. |
| #4317 | MovGP0 | semantic | 876 | 15 — `README.md`, `docs/ARCHITECTURE.md`, `engdocs/DOC_INVENTORY.md`, … | D1 | Attachment-snapshot selection remains under owner decision mybd-982o. |
| #4318 | MovGP0 | semantic | 876 | 16 — `README.md`, `docs/ARCHITECTURE.md`, `engdocs/DOC_INVENTORY.md`, … | D1 | Attachment-snapshot selection remains under owner decision mybd-982o. |
| #4348 | realies | semantic | 871 | 3 — `internal/storage/dolt/store.go`, `internal/storage/uow/doltserver_tx.go`, `internal/storage/uow/doltserver_tx_test.go` | D2 | Complementary with #4288; re-port is already tracked in mybd-nathu. |
| #4350 | j-s-au | shallow | 469 | 2 — `cmd/bd/mol_bond.go`, `cmd/bd/routed.go` | D3 | Superseded by #4720; close-when-quiet lane mybd-37b0x is armed. |
| #4764 | outdoorsea | shallow | 393 | 1 — `internal/storage/schema/lock.go` | D4 | Superseded by safer #4804; close-when-quiet lane mybd-iy34u is armed. |

## Suggested maintainer-rebase order

There is no exact non-noise file overlap among the eight candidates, so the grouping optimizes subsystem context and test setup rather than establishing a stack:

1. **Dolt and schema behavior:** #4804, then #3837.
   Resolve the canonical migration-lock fix first, then stay in Dolt/version-control context for auth-error classification.

2. **CLI state and correctness:** #4257, #4376, then #4959.
   Reuse command-level regression-test context across import stamping, ID resolution, and gate metadata behavior.

3. **Setup and platform integration:** #4806, then #4808.
   Keep plugin-layout and CI/platform validation together.

4. **Policy feature cleanup:** #4409 last.
   It has no non-noise conflict, but remains a draft policy feature; refresh noise/generated artifacts without converting it to ready-for-review.

## Coverage check

Machine-checked against `conflict-classes.jsonl`:

- Input PRs: **54**
- Assigned rows: **54**
- Unique assigned PRs: **54**
- Missing PRs: **0**
- Duplicate assignments: **0**
- Extra PRs: **0**

Durable Beads tracking could not be updated because the embedded Dolt database failed to open on the read-only filesystem.