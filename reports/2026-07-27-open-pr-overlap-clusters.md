# Open PR queue overlap report

> Snapshot: 104 open PRs in gastownhall/beads fetched 2026-07-27 via `gh pr list --limit 1000` + per-PR file lists (no default-limit truncation).
> Analysis: Codex reviewer (gpt-5.6-sol, high reasoning, session 019fa70b-ea1a-7683-baca-999137c271e7), orchestrated by Claude Code; spot-checked against raw file-overlap data.

Ages are calendar-day differences from **2026-07-27**. PR #5101 is dated 2026-07-28 in the supplied snapshot, so its computed age is **−1d**.

| Metric | Count |
|---|---:|
| Open PRs | 104 |
| Drafts | 14 |
| Conflicting | 59 |
| Mergeable | 42 |
| Unknown mergeability | 3 |
| Primary clusters | 20 |
| Duplicate/supersession clusters | 5 |
| Overlap clusters | 15 |
| Strict file-isolated singletons | 19 |

Primary assignment is disjoint: **11 duplicate-cluster PRs + 74 overlap-cluster PRs + 19 singletons = 104**. Consolidation opportunities are explicitly secondary review overlays and do not alter that count.

## 1. Duplicates and superseding variants

### D1. Attachments Feature/4051 cumulative snapshots

- #4316 (MovGP0, 50d, CONFLICTING, 44 files): Feature/4051
- #4317 (MovGP0, 50d, CONFLICTING, 53 files): Feature/4051 Jira
- #4318 (MovGP0, 50d, CONFLICTING, 59 files): Feature/4051 linear

Shared files/subsystem: attachment CLI, storage implementations, migration `0050`, tests and generated documentation. All 44 files in #4316 occur in #4317/#4318, and all 53 files in #4317 occur in #4318.

Recommended action: Treat these as cumulative alternatives; prefer **#4318** if both Jira and Linear attachment integration are wanted, otherwise deliberately select the narrower #4316 and close the other snapshots.

### D2. Empty Dolt commit suppression

- #4288 (realies, 56d, CONFLICTING, 7 files): fix(storage): skip empty Dolt commit when working set has no staged changes
- #4348 (realies, 48d, CONFLICTING, 3 files): fix(storage): stop guaranteed-empty DOLT_COMMITs flooding the Dolt log on busy coordination DBs

Shared files/subsystem: `internal/storage/dolt/store.go`; both suppress no-op Dolt commits.

Recommended action: Prefer newer, smaller **#4348**, after confirming it covers the embedded/ephemeral paths tested by #4288.

### D3. Molecule bond operand routing

- #4350 (j-s-au, 47d, CONFLICTING, 6 files): fix(mol bond): route operands to the target's database
- #4720 (R0SEWT, 16d, MERGEABLE, 5 files): fix(mol): route bond operand resolution like show/update/close (closes #4714)

Shared files/subsystem: `CHANGELOG.md`, `cmd/bd/mol_bond.go`, `cmd/bd/mol_bond_routing_test.go`, and `cmd/bd/routed.go`.

Recommended action: Use newer, mergeable, smaller **#4720** as canonical and absorb any still-useful unique test coverage from #4350.

### D4. Skip migration lock when the schema is current

- #4764 (outdoorsea, 14d, CONFLICTING, draft, 3 files): perf(schema): skip migration lock on already-migrated opens
- #4804 (atbrace, 12d, CONFLICTING, 8 files): perf(schema): skip the migration lock and pass when the database is current

Shared files/subsystem: `internal/storage/schema/lock.go`, `lock_test.go`, and `schema.go`.

Recommended action: Prefer **#4804** because it includes broader Dolt, benchmark, sentinel and schema coverage, despite being larger.

### D5. Proxied-server database creation policy

- #5086 (arcaven, 1d, MERGEABLE, 5 files): fix(uow): probe for existing database before CREATE on proxied-server open
- #5087 (arcaven, 1d, MERGEABLE, 9 files): fix(cmd/bd): create the proxied-server database only on bd init

Shared files/subsystem: all five #5086 files occur in #5087, covering DDL and the Dolt SQL/server/external-server UOW providers.

Recommended action: Treat **#5087** as the complete policy implementation and #5086 as its extracted predecessor unless maintainers intentionally want the narrower behavior separately.

## 2. Overlap clusters

### O1. DB proxy pooling and listener lifecycle

- #4303 (cstar, 53d, CONFLICTING, draft, 49 files): db-proxy connection pooling (opt-in) + proxied-server external deploy path
- #4313 (bourgois, 51d, CONFLICTING, draft, 23 files): fix(dolt): proxied routed store must not clobber dolt-server.port
- #4473 (rbriski, 35d, CONFLICTING, draft, 24 files): feat(dolt): query-level connection pooler to collapse Dolt connection churn
- #5024 (maphew, 3d, MERGEABLE, 11 files): fix(dbproxy): race-free proxy port allocation and managed loopback listener policy

Shared files/subsystem: db-proxy endpoint, server, pool and MySQL-wire implementation; proxied init/UOW wiring; `internal/storage/dolt/store.go`. All 23 #4313 files occur in #4303.

Recommended action: Decide the pooling architecture first, treat #4313 as corrective work within #4303, and rebase the chosen design around focused, mergeable #5024.

### O2. Remote Dolt server lifecycle and policy

- #3563 (shaunc, 90d, CONFLICTING, 5 files): fix: infer server mode from non-localhost host config (#3545, #3518)
- #3595 (trillium, 89d, MERGEABLE, draft, 18 files): fix: remote dolt server support — backup, push, pull
- #4133 (Zireael, 65d, CONFLICTING, 4 files): fix(dolt): disable background workers and drain MySQL handshake before TCP close
- #4167 (Shockwave2k, 62d, CONFLICTING, 10 files): perf(dolt): reduce remote-Dolt round trips (showcase — do not merge)
- #4383 (aaronlippold, 45d, CONFLICTING, 13 files): fix: commit config-table writes in server mode + truthful explicit commits (GH#4078)
- #4407 (bourgois, 43d, MERGEABLE, 2 files): fix(dolt): retry on transient Dolt merge-conflict (Error 1105)
- #4581 (julianknutsen, 22d, MERGEABLE, 13 files): fix(dolt): borrow ignored-tx from pool + per-dial credential connector (hosted-gateway churn)
- #4742 (medhatgalal, 15d, CONFLICTING, draft, 17 files): fix(proxied): fresh-UOW retry for Dolt serialization conflicts
- #5092 (maphew, 1d, MERGEABLE, 13 files): feat(doltversion): dolt CLI discovery, hardened version probe, and warn-only version policy (contract part 1)
- #5093 (maphew, 1d, MERGEABLE, 13 files): feat(workspacegate): shared physical-root resolver, beads.OpenGated, and CLI gate wiring (part 2)

Shared files/subsystem: `internal/doltserver`, Dolt store opening and transactions, config files, proxied UOW providers, and `cmd/bd/{init,main,uow_factory,proxied_server}.go`.

Recommended action: Exclude showcase-only #4167 from a landing plan, review #5092→#5093 as the current policy baseline, then rebase the focused lifecycle/retry fixes onto it.

### O3. Dolt CLI and version-control operations

- #3837 (ckumar1, 79d, CONFLICTING, 2 files): fix(dolt): classify SSH/auth failures with accurate guidance
- #4831 (vishnujayvel, 12d, CONFLICTING, 2 files): fix(dolt): align show config-source priority with DefaultConfig (#4511)
- #4844 (rjc123, 11d, MERGEABLE, 9 files): feat(dolt): add `bd dolt rebase` to reconcile colliding child IDs (#4796)
- #5085 (arcaven, 1d, MERGEABLE, 3 files): fix(embeddeddolt): use stored peer credentials for federation sync

Shared files/subsystem: #3837/#4831 both replace `cmd/bd/dolt.go` and its tests; #4844/#5085 both change embedded version-control behavior.

Recommended action: Reconcile the two `bd dolt` command fixes first, then land the rebase and federation changes in that order with targeted credential/version-control tests.

### O4. Workspace startup, bootstrap and backend detection

- #3812 (seanmartinsmith, 81d, MERGEABLE, 1 file): test(cmd/bd): tolerate timeout-killed processes in TestEmbeddedInitConcurrent
- #4242 (osamu2001, 60d, CONFLICTING, 5 files): Fix role detection for bd -C target repos
- #4284 (krantiutils, 56d, MERGEABLE, 3 files): fix: bound embedded Dolt opens
- #4449 (bourgois, 39d, MERGEABLE, 3 files): bootstrap: guard git code-repo sync.remote + transient-not-found retry
- #4740 (steveyegge, 15d, CONFLICTING, 10 files): fix(config): stale legacy backend:"sqlite" metadata must not shadow a live Dolt workspace (bd-oyvc2.7)
- #4791 (harry-miller-trimble, 13d, MERGEABLE, 3 files): fix(bootstrap): commit .beads workspace files so adopt-from-remote leaves a clean tree (#4644)
- #4792 (harry-miller-trimble, 13d, MERGEABLE, 2 files): fix(context): resolve from .beads when outside a git repository (#4772)
- #4795 (harry-miller-trimble, 13d, CONFLICTING, 2 files): fix(init): refuse to initialize directly in the home directory (#4635)
- #4907 (julianknutsen, 8d, MERGEABLE, 35 files): Guard and qualify historical upgrades to v1.2
- #4985 (davevan2, 4d, CONFLICTING, 7 files): fix: keep preview commands from migrating stores

Shared files/subsystem: `cmd/bd/{bootstrap,context,init,main,store_factory}.go`, backend/config detection and historical migration tooling.

Recommended action: Establish #4907’s historical-upgrade rules first, then review the small bootstrap/context guards together and rebase preview/open behavior last.

### O5. Backend extension architecture

- #4415 (MarkAtwood, 41d, CONFLICTING, 121 files): feat(storage): flat-file storage backend
- #4561 (duncan4123, 24d, CONFLICTING, 37 files): Add configured backend API and external backend plugins
- #4736 (duncan4123, 15d, CONFLICTING, 5 files): Expose configured backend opener
- #4859 (julianknutsen, 10d, MERGEABLE, 11 files): feat(storage): add extension-safe backend registry seam

Shared files/subsystem: public `beads` opening API, backend/configured-backend packages, store factories, and backend classification.

Recommended action: Prefer mergeable #4859 as the architectural seam, treat #4736 as a follow-on to #4561, and require a separate architecture decision before rebasing the 121-file flat-file backend.

### O6. Storage query and configuration metadata

- #3458 (quad341, 94d, MERGEABLE, 12 files): perf(storage): SearchIssueSummaries narrow-projection list (be-nu4.3, stacks on #3453)
- #3777 (iuyua9, 81d, MERGEABLE, 3 files): fix: honor deferred filters for ready list queries
- #4175 (fengning-starsend, 62d, CONFLICTING, 5 files): bd-91bzp: make issue prefix mutations explicit
- #4289 (outdoorsea, 56d, CONFLICTING, draft, 7 files): feat(metadata): index metadata fields for fast equality filtering

Shared files/subsystem: issue scans/search, Dolt/list queries, configuration metadata and shared issue/type representations.

Recommended action: Review the query correctness changes before the projection/index optimizations and keep the issue-prefix mutation contract explicit during rebases.

### O7. Write semantics, ownership, history and journals

- #3548 (kingfly55, 91d, UNKNOWN, 7 files): Add suppress-history update primitive
- #3876 (jjgarzella, 77d, CONFLICTING, 36 files): feat(formula): implement on_complete runtime fanout executor (GH#3782)
- #4461 (sjarmak, 37d, MERGEABLE, 15 files): Add append-only provenance_events log and bd provenance CLI
- #4493 (steveyegge, 32d, MERGEABLE, 21 files): feat(lease): claim-TTL + heartbeat + reclaim for dead-worker recovery
- #4682 (julianknutsen, 18d, CONFLICTING, 59 files): feat(cas): optimistic concurrency for beads — metadata + whole-row compare-and-swap
- #4697 (julianknutsen, 17d, CONFLICTING, 58 files): feat(ownership): claim_fence + guarded verbs + tier-complete requested leases
- #4715 (julianknutsen, 17d, CONFLICTING, 63 files): feat(ownership): holder_token + advisory enforcement mode
- #4756 (steveyegge, 14d, CONFLICTING, 4 files): fix(cli): emit claim failures as structured JSON under --json (wy-kxgf4)
- #4798 (harry-miller-trimble, 13d, CONFLICTING, 5 files): fix(storage): preserve closed_by_session on wisp promotion (#4662)
- #4839 (steveyegge, 11d, CONFLICTING, 10 files): fix(update,close): gate the no-ID last-touched fallback to interactive sessions (bd-m00pb)
- #4916 (julianknutsen, 8d, CONFLICTING, 47 files): bd: transactional events journal + hooks on both write plumbings
- #5101 (idirectships, −1d, MERGEABLE, 5 files): fix: preserve forced delete dry-runs and payload-blind previews

Shared files/subsystem: claim/update/close/delete commands, issueops write implementations, storage interfaces, lease migrations and CLI documentation. #4697/#4715 share 44 files; #4461/#4916 overlap conceptually as competing or layered event logs.

Recommended action: Make one ownership/concurrency design decision before landing write-path fixes, explicitly decide whether provenance is separate from the transactional journal, then rebase the smaller CLI behavior fixes.

### O8. Dependencies, capabilities and blocked-state semantics

- #3612 (gt-rm-0306, 88d, CONFLICTING, 4 files): fix(storage): emit placeholders for cross-rig dependency targets
- #4346 (ksletmoe-aws, 48d, CONFLICTING, 5 files): fix(storage): set updated_at to UTC in all blocked-state recompute paths
- #4674 (blairsilverberg, 19d, CONFLICTING, draft, 2 files): fix(storage): cascade wisp_dependencies when deleting wisps (mol burn / wisp GC orphan leak)
- #4730 (jakelindsay87, 16d, CONFLICTING, 3 files): fix(storage): normalize persisted audit timestamps to UTC
- #4753 (dredozubov, 14d, MERGEABLE, 28 files): fix: enforce external capability blockers (#4769)
- #4833 (vishnujayvel, 12d, CONFLICTING, 3 files): fix(create): hard-fail multi-type same-target --deps (#4626)

Shared files/subsystem: `cmd/bd/dep.go`, Dolt/issueops dependency storage, blocked-state recomputation and create-time dependency validation.

Recommended action: Use #4753’s capability model as the baseline, then rebase the smaller placeholder, cascade, timestamp and input-validation fixes with dependency conformance tests.

### O9. Create configuration and labels policy

- #4738 (thewoolleyman, 15d, CONFLICTING, 9 files): feat(create): add status.default config for default initial status
- #4757 (steveyegge, 14d, CONFLICTING, 20 files): feat(labels): exclusive label namespaces, flag-gated (bd-7u5ki)
- #4984 (davevan2, 4d, MERGEABLE, 4 files): fix(create): reject caller input that would be discarded

Shared files/subsystem: `cmd/bd/create.go`, create input/config processing and CLI reference documentation.

Recommended action: Land targeted validation fix #4984 first, then rebase the two policy features and review their combined precedence and error behavior.

### O10. Schema migration and integrity repair

- #4504 (Rome-1, 29d, MERGEABLE, 7 files): fix(schema): make CALL-bearing migrations idempotent and drain all proc result sets
- #4858 (vishnujayvel, 10d, CONFLICTING, 10 files): fix(doctor): detect orphaned child_counters rows (#4539)
- #5064 (maphew, 1d, MERGEABLE, 5 files): fix(schema): survive dolt#11131 encoding drift in the aux row re-key (#4380)

Shared files/subsystem: schema migration execution, aux-row backfill and doctor validation of schema-derived state.

Recommended action: Review #4504 and #5064 as schema-runtime prerequisites, then rebase #4858’s diagnostic/fix behavior against the resulting invariants.

### O11. Compact provider, telemetry and metrics wiring

- #3610 (octo-patch, 88d, CONFLICTING, 18 files): feat: add MiniMax provider support via Anthropic-compatible API
- #3859 (GraemeF, 78d, CONFLICTING, 8 files): refactor(telemetry): adopt standard OTel SDK env vars with BD_OTEL_* back-compat
- #3861 (GraemeF, 78d, CONFLICTING, draft, 15 files): feat(telemetry): stamp bd.prefix on resource and every metric measurement

Shared files/subsystem: compact-provider configuration, `cmd/bd/main.go`, storage-chain tests and telemetry initialization; #3859/#3861 share four central telemetry files.

Recommended action: Consolidate #3859/#3861 first, then rebase MiniMax configuration so provider and telemetry environment handling remain coherent.

### O12. External tracker synchronization

- #3579 (jozefizso, 90d, CONFLICTING, draft, 5 files): Import Jira ticket relationships
- #3717 (kevglynn, 84d, MERGEABLE, 10 files): feat(linear): persistent sync audit log with history CLI and rollback
- #4329 (kevglynn, 49d, MERGEABLE, 9 files): fix(github): content-based dedup on push to stop re-PATCHing every issue (#4214)
- #5065 (halaprix, 1d, MERGEABLE, 4 files): fix(github): include bead metadata in synced issue bodies

Shared files/subsystem: Jira, Linear and GitHub tracker adapters plus shared tracker engine/types. #4329/#5065 share `cmd/bd/github.go`, `internal/github/mapping.go`, and `internal/github/tracker.go`.

Recommended action: Review #4329/#5065 as one GitHub-sync batch and coordinate Jira/Linear model changes with whichever attachment snapshot is retained.

### O13. CLI schema and documentation mega-change

- #4413 (griels, 42d, CONFLICTING, 10 files): Add `bd schema` command to emit a JSON Schema for --json/export output
- #4971 (harryhan24, 4d, CONFLICTING, draft, 180 files): docs: translate documentation into Korean

Shared files/subsystem: `docs/CLI_REFERENCE.md` and generated/versioned CLI documentation; #4971 also collides with many command-specific PRs across its 180 files.

Recommended action: Land or regenerate command documentation before rebasing the translation, and do not hand-resolve generated-doc conflicts across dozens of feature branches.

### O14. Conformance, protocol and CI validation

- #4739 (steveyegge, 15d, MERGEABLE, 1 file): ci(conformance): run on push to main (bd-oyvc2.8)
- #4762 (steveyegge, 14d, CONFLICTING, 2 files): test(protocol): pin §E3 exit 11 with a PTY harness (wy-vh5y8)
- #5073 (ecuthiell, 1d, MERGEABLE, 3 files): ci: give conformance explicit timeout budgets

Shared files/subsystem: conformance workflow/scripting and protocol test infrastructure; #4739/#5073 directly overlap `.github/workflows/conformance.yml`.

Recommended action: Merge the conformance scheduling and timeout changes as one small CI batch, with the PTY protocol test rebased independently if its module change conflicts.

### O15. Gate command behavior

- #4959 (srobroek, 5d, CONFLICTING, 3 files): fix(gate): honor repository metadata for GitHub checks
- #5099 (jacobhausler, 0d, MERGEABLE, 1 file): feat(gate): add --title flag to bd gate create

Shared files/subsystem: `cmd/bd/gate.go`.

Recommended action: Land the repository-metadata correctness fix first, then rebase the one-file `--title` feature.

## 3. Consolidation opportunities

These are secondary review batches; their PRs retain the primary memberships above.

### C1. Windows and process-portability micro-fixes

- #3797 (seanmartinsmith, 81d, CONFLICTING, 1 file): test: let bash canonicalize formula path in release script tests
- #3801 (seanmartinsmith, 81d, CONFLICTING, 1 file): test(doltserver): release log handle in newDoltServer cleanup on Windows
- #3802 (seanmartinsmith, 81d, MERGEABLE, 1 file): test: skip TestUpdateCloseHookFiring on Windows (GH#3800)
- #3806 (seanmartinsmith, 81d, MERGEABLE, 1 file): test(hooks): skip 5 POSIX-shebang tests on Windows (GH#3800)
- #3812 (seanmartinsmith, 81d, MERGEABLE, 1 file): test(cmd/bd): tolerate timeout-killed processes in TestEmbeddedInitConcurrent

Shared shape: same author, same day, one-file portability/test corrections.

Recommended action: Review together, land the three mergeable test-only fixes immediately if still applicable, and rebase the two conflicting ones only if their failures remain reproducible.

### C2. Telemetry pair

- #3859 (GraemeF, 78d, CONFLICTING, 8 files): refactor(telemetry): adopt standard OTel SDK env vars with BD_OTEL_* back-compat
- #3861 (GraemeF, 78d, CONFLICTING, draft, 15 files): feat(telemetry): stamp bd.prefix on resource and every metric measurement

Shared shape: same author and four central telemetry/configuration files.

Recommended action: Consolidate into one rebased telemetry series so environment migration and resource attributes are reviewed together.

### C3. Configured-backend API sequence

- #4561 (duncan4123, 24d, CONFLICTING, 37 files): Add configured backend API and external backend plugins
- #4736 (duncan4123, 15d, CONFLICTING, 5 files): Expose configured backend opener

Shared shape: same author; #4736 exposes API introduced by #4561 and shares `beads.go`, `internal/backend/configured.go`, and opener tests.

Recommended action: Treat #4736 as an ordered follow-up to #4561, or fold both into the smaller registry seam in #4859.

### C4. Ownership and concurrency sequence

- #4493 (steveyegge, 32d, MERGEABLE, 21 files): feat(lease): claim-TTL + heartbeat + reclaim for dead-worker recovery
- #4682 (julianknutsen, 18d, CONFLICTING, 59 files): feat(cas): optimistic concurrency for beads — metadata + whole-row compare-and-swap
- #4697 (julianknutsen, 17d, CONFLICTING, 58 files): feat(ownership): claim_fence + guarded verbs + tier-complete requested leases
- #4715 (julianknutsen, 17d, CONFLICTING, 63 files): feat(ownership): holder_token + advisory enforcement mode

Shared shape: successive lease, CAS, fence and holder-token models over the same write paths.

Recommended action: Review as one design series ordered lease → CAS → claim fence → holder token; do not independently merge overlapping migrations and guards.

### C5. Historical migration harness and catalog

- #4907 (julianknutsen, 8d, MERGEABLE, 35 files): Guard and qualify historical upgrades to v1.2
- #5100 (julianknutsen, 0d, MERGEABLE, 3 files): Pin authenticated historical release catalog

Shared shape: same author and migration-test subsystem; #5100 supplies a catalog for the larger historical-upgrade harness.

Recommended action: Review together and land #4907 before or with #5100.

### C6. Explicit two-part policy series

- #5092 (maphew, 1d, MERGEABLE, 13 files): feat(doltversion): dolt CLI discovery, hardened version probe, and warn-only version policy (contract part 1)
- #5093 (maphew, 1d, MERGEABLE, 13 files): feat(workspacegate): shared physical-root resolver, beads.OpenGated, and CLI gate wiring (part 2)

Shared shape: explicitly titled part 1/part 2 contract sequence.

Recommended action: Review and merge strictly in #5092→#5093 order.

### C7. Ecuthiell mechanical CI/test batch

- #5076 (ecuthiell, 1d, MERGEABLE, 1 file): test(docsmint): make missing staging path portable
- #5074 (ecuthiell, 1d, MERGEABLE, 1 file): test: use native repro timeout fixtures
- #5073 (ecuthiell, 1d, MERGEABLE, 3 files): ci: give conformance explicit timeout budgets

Shared shape: same-day, same-author, test-only portability and timeout corrections.

Recommended action: Review as one low-risk mechanical batch, while rebasing #5073 with #4739’s workflow edit.

### C8. GitHub sync batch

- #4329 (kevglynn, 49d, MERGEABLE, 9 files): fix(github): content-based dedup on push to stop re-PATCHing every issue (#4214)
- #5065 (halaprix, 1d, MERGEABLE, 4 files): fix(github): include bead metadata in synced issue bodies

Shared shape: three central GitHub mapping/tracker files and complementary push-body behavior.

Recommended action: Review together and ensure metadata rendering participates in #4329’s content-based dedup comparison.

## 4. Strict singletons

These PRs have **zero exact changed-file intersection** with every other PR in the snapshot. They are file-conflict-safe to review independently, though large or policy-sensitive changes can still require deeper review.

- #3395 (kevglynn, 97d, UNKNOWN, 9 files): Add The Agentic Covenant — agentic-forward Code of Conduct and community standards
- #3549 (shaunc, 91d, UNKNOWN, draft, 2 files): fix: resolve symlinks in DirToFileURL for cross-filesystem-view backup remotes
- #3572 (jozefizso, 90d, CONFLICTING, draft, 4 files): Install shell completions for fish users
- #3797 (seanmartinsmith, 81d, CONFLICTING, 1 file): test: let bash canonicalize formula path in release script tests
- #3801 (seanmartinsmith, 81d, CONFLICTING, 1 file): test(doltserver): release log handle in newDoltServer cleanup on Windows
- #3802 (seanmartinsmith, 81d, MERGEABLE, 1 file): test: skip TestUpdateCloseHookFiring on Windows (GH#3800)
- #3806 (seanmartinsmith, 81d, MERGEABLE, 1 file): test(hooks): skip 5 POSIX-shebang tests on Windows (GH#3800)
- #4206 (maphew, 61d, MERGEABLE, 2 files): test: use production schema init in routing e2e
- #4257 (Jacob-qd, 59d, CONFLICTING, 2 files): Stamp auto-import attempts for unchanged JSONL
- #4376 (sarendipitee, 45d, CONFLICTING, 3 files): fix(resolver): use last-segment prefix match to prevent wisp substring collision
- #4409 (bdarlt, 43d, CONFLICTING, draft, 7 files): Custom severity
- #4535 (Kevinwochan, 26d, MERGEABLE, 7 files): [codex] Add Kiro setup recipe
- #4768 (medhatgalal, 13d, MERGEABLE, 32 files): experimental near-data remote-cell operator package (no default bd change)
- #4806 (christso, 12d, CONFLICTING, 12 files): feat(plugin): add Pi coding-agent support
- #4808 (marcodelpin, 12d, CONFLICTING, 5 files): fix(windows): report Dolt run-state correctly in bd config drift
- #4828 (vishnujayvel, 12d, MERGEABLE, 4 files): fix(metrics): honor BEADS_DIR for telemetry DataDir (#4807)
- #5076 (ecuthiell, 1d, MERGEABLE, 1 file): test(docsmint): make missing staging path portable
- #5074 (ecuthiell, 1d, MERGEABLE, 1 file): test: use native repro timeout fixtures
- #5100 (julianknutsen, 0d, MERGEABLE, 3 files): Pin authenticated historical release catalog

Recommended action: Start independent review with the small mergeable test/config fixes; keep separate policy scrutiny for #3395 and architecture/operations scrutiny for #4768 and #4806.

## Coverage check

- Duplicate clusters: **5 clusters / 11 PRs**
- Overlap clusters: **15 clusters / 74 PRs**
- Strict singleton list: **19 PRs**
- Primary total: **11 + 74 + 19 = 104**
- Missing primary assignments: **0**
- Duplicate primary assignments: **0**

The supplied snapshot was read successfully, but durable Beads tracking could not be updated because the environment exposed the embedded Dolt database read-only.
---

## 2026-07-28 verification addendum (execution pass)

A Codex diff-level verification pass (gpt-5.6-sol high, session 019fa975-32fd-7d93-880f-19d0dd0cbe6e) was run before acting on the duplicate recommendations. Corrections to the snapshot analysis above:

- **D2 is wrong**: 4288 and 4348 are **complementary, not duplicates**. 4288 guards selective `-m` commit paths (staged-set checks incl. the embedded/ephemeral `doltAddAndCommitInTx` path); 4348 guards the whole-working-set UOW path plus `dolt_ignore` filtering. 4348's global pending check cannot protect a selective commit with an unrelated dirty table. Neither was closed; re-port tracked in mybd-nathu.
- **D3 confirmed**: 4720 covers all of 4350's production behavior (and improves it). Two unique 4350 tests queued for port with attribution (mybd-bc9cc); 4350 in close-when-quiet lane (mybd-37b0x, disposition posted 07-26).
- **D4 confirmed**: 4804 strictly safer (pass-completion sentinel closes the mid-pass fast-path window 4764 leaves open). Disposition posted, close lane mybd-iy34u.
- **D5 softened**: 5087 contains 5086 line-for-line but intentionally narrows behavior (ordinary commands lose implicit DB creation). Stack-intent question posted on 5086; no close lane pending author answer (mybd-457m0).
- **D1 deferred**: attachments trio remains under open owner decision mybd-982o; no closes before the bytes-survive-push call.
- **C1 outcome reversed**: all five seanmartinsmith PRs (3797/3801/3802/3806/3812) were already absorbed into main via #4600 (commit 7865493f7) — closed as retired 07-28 per pre-authorized grace (mybd-qy7m), not merged.
- Singleton quick-wins re-checked: 4828 has an unresolved CHANGES_REQUESTED (metrics init-order not fixed by the diff) — stays open, not merge-ready; 4206 gated on storage-maintainer approval.
- O7 write-semantics/ownership cluster and C4/C5 (steveyegge + julianknutsen) deliberately untouched per owner direction 2026-07-28: give the authors time to sort out the design overlap themselves.

Open-PR count after this pass: 104 → 99 (five retired), with two more in patrol close lanes.
