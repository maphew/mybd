Tree: `bd-main/` / upstream `gastownhall/beads`; no coordination-repo files were queried or modified. All heads are unchanged after the cited maintainer review. GitHub GraphQL reported `mergeStateStatus: "UNKNOWN"` for every PR; REST `mergeable` lookup failed with the exact output `error connecting to api.github.com`.

`gh pr view` CI filter output was `"[PR,[]]"` for every row marked green: no non-success or pending checks. #4828 is red: `PR Core (wrapper timing)` and `CI Gate / Required`.

### harry-miller-trimble

| PR | Head / last commit | Latest maintainer review | After review / author reply | CI / merge | Small maintainer push? |
|---|---|---|---|---|---|
| #4798 `fix(storage): preserve closed_by_session…` | `1025634`, 2026-07-14 21:42Z | CHANGES_REQUESTED, 2026-07-24 01:49Z — “one more writer needs it, and the rebase is semantically loaded.” | Unchanged; no post-review author comment (`"comments":[]`). | Green; UNKNOWN | No — reconcile multiple writers and semantic rebase. |
| #4795 `fix(init): refuse to initialize…` | `b735819`, 2026-07-14 22:12Z | CHANGES_REQUESTED, 01:48Z — “guard must run ahead of every store-opening path.” | Unchanged; none. | Green; UNKNOWN | No — shared direct/proxied ordering and command tests. |
| #4793 `fix(dolt): derive circuit-breaker temp dir…` | `76c325c`, 20:20Z | CHANGES_REQUESTED, 00:55Z — “legacy sweep … should remove closed files too.” | Unchanged; none. | Green; UNKNOWN | Yes — localized legacy-cleanup condition plus test. |
| #4792 `fix(context): resolve from .beads…` | `2e7bba5`, 20:06Z | CHANGES_REQUESTED, 00:55Z — “introduce a typed/sentinel error…”. | Unchanged; none. | Green; UNKNOWN | No — error-contract/proxied-path change. |
| #4791 `fix(bootstrap): commit .beads workspace files…` | `cbc5d08`, 20:36Z | CHANGES_REQUESTED, 01:48Z — “commits unrelated `.beads` content” and linked-worktree risk. | Unchanged; none. | Green; UNKNOWN | No — commit blast-radius and worktree safety. |
| #4790 `fix(actor): let BEADS_ACTOR outrank…` | `88f941c`, 19:55Z | CHANGES_REQUESTED, 00:55Z — “`bd config show` now contradicts the actor actually used.” | Unchanged; none. | Green; UNKNOWN | Yes — reuse precedence helper in show path and add wiring tests. |
| #4789 `docs(create): document … blocks:id…` | `613a8eb`, 19:44Z | CHANGES_REQUESTED, 00:55Z — “drop the two generated-file edits.” | Unchanged; none. | Green; UNKNOWN | Yes — remove two generated docs; source help change is sound. |
| #4788 `fix(create): reject whitespace-only titles…` | `e4e4ccb`, 19:42Z | CHANGES_REQUESTED, 00:54Z — “proxied-server creation bypasses the new validation.” | Unchanged; none. | Green; UNKNOWN | Yes — shared/pre-open validation plus proxied regression. |
| #4787 `fix(comments): reject swapped-order…` | `729716e`, 19:39Z | CHANGES_REQUESTED, 00:54Z — “move the tailored rejection into a custom `Args` validator.” | Unchanged; none. | Green; UNKNOWN | Yes — localized validator and proxied test. |
| #4430 `fix(wisp): never age-GC active…` | `1e3c579`, 2026-07-14 19:33Z | COMMENTED, 2026-07-05 07:08Z — “I’ll … rebase onto current main, and push the fix-up”. | Unchanged; no author reply after review. | Green; UNKNOWN | Yes — maintainer already volunteered a mechanical rebase/fix-up. |

Summary — harry-miller-trimble: **0 changed since review; 9 unchanged CHANGES_REQUESTED** (plus #4430 unchanged COMMENTED). This cluster is worth a full sweep now: several are small maintainer-push candidates, but the storage/init/bootstrap items should stay author-owned.

### vishnujayvel

| PR | Head / last commit | Latest maintainer review | After review / author reply | CI / merge | Small maintainer push? |
|---|---|---|---|---|---|
| #4913 `docs(async-gates): fix nonexistent…` | `308867f`, 2026-07-24 23:29Z | APPROVED, 23:30Z — “Merge tail goes to the pr-babysit patrol.” | Unchanged. Author’s pre-approval reply: “addressed the three should-fixes … in the latest commit.” | Green; UNKNOWN | Yes — no code work; patrol merge tail only. |
| #4858 `fix(doctor): detect orphaned child_counters…` | `5c7b191`, 2026-07-17 01:53Z | CHANGES_REQUESTED, 2026-07-24 02:41Z — “destructive repair path needs hardening”. | Unchanged; no post-review author reply. | Green; UNKNOWN | No — concurrency-safe delete and pinned Dolt transaction work. |
| #4833 `fix(create): hard-fail multi-type…` | `b956262`, 2026-07-20 03:52Z | CHANGES_REQUESTED, 02:40Z — “guard is both too strict and porous”. | Unchanged; none after review. | Green; UNKNOWN | No — semantic redesign around normalized specs and atomic create. |
| #4832 `fix(swarm): exclude closed issues…` | `6c29e64`, 2026-07-17 00:43Z | CHANGES_REQUESTED, 02:40Z — “closed-node cycles still suppress all ready fronts.” | Unchanged; none. | Green; UNKNOWN | Yes — align cycle graph predicate and add full-path test. |
| #4831 `fix(dolt): align show config-source priority…` | `046cdaf`, 2026-07-15 22:46Z | CHANGES_REQUESTED, 01:49Z — “Kill the copy and the bug class dies with it.” | Unchanged; none. | Green; UNKNOWN | No — source-of-truth/refactor decision. |
| #4830 `fix(dolt): show remotes from persisted repo_state…` | `84237aa`, 2026-07-15 22:46Z | CHANGES_REQUESTED, 01:49Z — “Pick the one mode-appropriate path and honor an authoritative empty result.” | Unchanged; none. | Green; UNKNOWN | Yes — focused selection/error-surfacing and test cleanup. |
| #4829 `fix(storage): total ORDER BY…` | `03cc09f`, 2026-07-15 22:46Z | CHANGES_REQUESTED, 01:49Z — “add the primary key as final tie-breaker.” | Unchanged; none. | Green; UNKNOWN | Yes — append `id` to both order clauses and adjust tests. |
| #4828 `fix(metrics): honor BEADS_DIR…` | `3991752`, 2026-07-21 03:29Z | CHANGES_REQUESTED, 02:40Z — “telemetry binds its queue before workspace selection.” | Unchanged; no author reply after review. | **Red:** `PR Core (wrapper timing)`, `CI Gate / Required`; UNKNOWN | No — lifecycle ordering and flusher configuration need redesign. |

Summary — vishnujayvel: **0 changed since review; 7 unchanged CHANGES_REQUESTED** (plus #4913 unchanged APPROVED). This cluster is worth a full sweep now: #4913 is merge-tail only, and #4832/#4830/#4829 are plausible small maintainer pushes; #4858/#4833/#4831/#4828 require author-level work.

The queried rollups did not currently show a failed `Contract corpus (golden + determinism + conformance)` job. If it appears on a fresh rerun, classify it as **base-inherited**, per the task instruction—not PR fault.