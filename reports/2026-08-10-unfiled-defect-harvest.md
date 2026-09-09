# 2026-08-10 Unfiled-defect harvest: 31 upstream issues from three months of review findings

## Why

Owner /goal directive (2026-08-10): the maintainer-era review work left roughly 30
specific, file-and-line-level Beads defects recorded only in local beads, none
reported upstream. With the role change to contributor (2026-08-10), those findings
were the main unconverted asset of the maintainer period. This session harvested
them: verify each against current upstream/main, dedupe against existing issues,
file the survivors as upstream issues with provenance, and record the issue numbers
back on the beads.

## Method

- Candidate selection: all 153 open beads reviewed by hand; 38 selected as
  concrete upstream-code defects with no known upstream issue. Excluded: tracking
  beads of already-filed issues, local coordination-repo problems, and findings
  already recorded on live upstream PR threads.
- Verification: one read-only sonnet/medium agent per candidate (workflow
  wf_297679f1-46f, 38 agents, ~1.7M subagent tokens), each pinned to
  upstream/main 7e825441b, restricted to `git grep`/`git show` on that ref plus
  at most 3 gh dedupe searches. Every claim re-located to current line numbers.
- Two agents failed structured output (mybd-5r1s2, mybd-5ct1m) and two returned
  junk drafts (mybd-guity, mybd-ypdz4); all four re-verified by hand in-session.
- mybd-zg2dj and mybd-i61ti drafts converged on the same bd link gap and were
  merged into one issue.
- All bodies linted (em dashes, GH# refs, literal \n, internal bead IDs stripped;
  scripts/gh-body-lint itself is broken since the teardown deleted _tri-lib.sh -
  checks replicated by hand, see follow-up below), signed, and filed serially.

## Filed: 31 issues (#5555-#5585)

| mybd-075zn | [#5555](https://github.com/gastownhall/beads/issues/5555) | Add a golden-list test pinning migration version to filename (guards CLI dispatch and content-hash skew detection) |
| mybd-179w8 | [#5556](https://github.com/gastownhall/beads/issues/5556) | mergesettle.go's 11 CALL DOLT_* sites on a transaction-pinned connection are not drained, unlike the rest of the package (follow-up from #5146) |
| mybd-1o2sm | [#5557](https://github.com/gastownhall/beads/issues/5557) | wisp gc --closed purge path can delete open children of a closed parent (cascade re-expands past the selection) |
| mybd-1s7pl | [#5558](https://github.com/gastownhall/beads/issues/5558) | PROJECT IDENTITY MISMATCH error tells the user "Do NOT run 'bd init'" while running inside bd init |
| mybd-2cxve | [#5559](https://github.com/gastownhall/beads/issues/5559) | Dolt server-mode identity check silently skips for Path-only configs (e.g. beads.Open) because it's passed cfg.BeadsDir instead of the already-resolved beadsDir |
| mybd-2rne5 | [#5560](https://github.com/gastownhall/beads/issues/5560) | bd create-form silently drops one dependency edge when two entries target the same issue with different types |
| mybd-4rgyc | [#5561](https://github.com/gastownhall/beads/issues/5561) | Strict `bd --readonly` writes a dolt.gate.lock file into .beads, and the test that catches it never runs under CGO_ENABLED=0 CI |
| mybd-5ct1m | [#5562](https://github.com/gastownhall/beads/issues/5562) | bd delete --dry-run --json emits different JSON shapes on embedded vs proxied-server backends |
| mybd-5r1s2 | [#5563](https://github.com/gastownhall/beads/issues/5563) | bd setup junie writes an MCP config invoking 'bd mcp', which does not exist |
| mybd-668of | [#5564](https://github.com/gastownhall/beads/issues/5564) | federation sync uses the bare CALL DOLT_MERGE path fixed elsewhere by MergeWithStrategy, so conflict-strategy resolution can still 1105-fail |
| mybd-6g66 | [#5565](https://github.com/gastownhall/beads/issues/5565) | bd show undercounts comments on a wisp: CountIssueComments never queries wisp_comments |
| mybd-6w40a | [#5566](https://github.com/gastownhall/beads/issues/5566) | bd admin reset only scans 4 of the 5 managed git hooks, leaving prepare-commit-msg behind |
| mybd-a3905 | [#5567](https://github.com/gastownhall/beads/issues/5567) | Two unix-socket tests in internal/storage/dbproxy/server are unconditionally skipped on macOS, not conditionally |
| mybd-bomo8 | [#5568](https://github.com/gastownhall/beads/issues/5568) | Uninstall docs lead with `bd admin reset`, which refuses to run in embedded mode (the default) |
| mybd-exkxx | [#5569](https://github.com/gastownhall/beads/issues/5569) | DepDelegatedFrom comment claims completion cascades up, but no code implements it |
| mybd-flw3u | [#5570](https://github.com/gastownhall/beads/issues/5570) | Auto-export always runs storeKnownIssueIDs's full table scan even when the shrink guard never uses it |
| mybd-gc9i5 | [#5571](https://github.com/gastownhall/beads/issues/5571) | doctor tests: TestCheckHooksPath_SetToExistingDir assumes `git init` always creates .git/hooks (fails under custom init.templateDir) |
| mybd-gzvw1 | [#5572](https://github.com/gastownhall/beads/issues/5572) | Plain proxied-server mode has no project-identity check: --database can open any database with no assertion |
| mybd-h1vz1 | [#5573](https://github.com/gastownhall/beads/issues/5573) | doctor --fix dials its own DB connection with a different port than doctor's read-only checks used |
| mybd-hb6pk | [#5574](https://github.com/gastownhall/beads/issues/5574) | examples/bd-example-extension-go panics/errors at runtime: sql.Open("sqlite3", ...) has no driver registered, and the path it's given is a Dolt directory, not a SQLite file |
| mybd-hk7hm | [#5575](https://github.com/gastownhall/beads/issues/5575) | ADO: legacy "parent"-typed dependency rows need a migration to retype and reverse them |
| mybd-jlgdx | [#5576](https://github.com/gastownhall/beads/issues/5576) | doctor --fix: FixMissingDoltDatabase's fallback probe has no project-identity check, unlike the authoritative-metadata path it falls back from |
| mybd-jrbuu | [#5577](https://github.com/gastownhall/beads/issues/5577) | conditional-blocks unblocks on any close of the precondition, not only on failure, defeating its documented semantics |
| mybd-ktgpw | [#5578](https://github.com/gastownhall/beads/issues/5578) | pr-risk CI compiles internal/storage/dolt tests but only ever executes ^TestConformance$ |
| mybd-orcx | [#5579](https://github.com/gastownhall/beads/issues/5579) | bd worktree create appends duplicate .gitignore entries on CRLF-terminated .gitignore files |
| mybd-v789f | [#5580](https://github.com/gastownhall/beads/issues/5580) | bd doctor's git/hooks checks (Git Hooks, Stale Legacy Hooks, Hooks Path, Git Hooks Dolt Compatibility) are unreachable in embedded mode, the default backend |
| mybd-ylnpl | [#5581](https://github.com/gastownhall/beads/issues/5581) | Custom status/type config cache fails open on transient read error, silently caching an empty/degraded result |
| mybd-ypdz4 | [#5582](https://github.com/gastownhall/beads/issues/5582) | Two validated, documented config keys have no consumer: routing.mode's non-auto values and sync.require_confirmation_on_mass_delete |
| mybd-yw7pm | [#5583](https://github.com/gastownhall/beads/issues/5583) | bd ready lists an open epic alongside its own open children, offering the container as claimable work |
| mybd-z9h7j | [#5584](https://github.com/gastownhall/beads/issues/5584) | bd vc commit / bd dolt commit use a racy HEAD-before/after compare instead of an atomic committed-bool |
| mybd-zg2dj + mybd-i61ti | [#5585](https://github.com/gastownhall/beads/issues/5585) | bd link and bd batch dep.add store dependency-type aliases and unknown types verbatim, creating edges that never gate bd ready |

## Not filed, with verdicts

- **mybd-o1i9c** (goal-named): CLOSED as refuted. The ignored-plane migration
  `migrations/ignored/0004_add_wisp_aux_fks.up.sql` gives all four wisp aux
  tables FK ON DELETE/UPDATE CASCADE to wisps(id); the bead read only the main
  migration series. DB-level cascade covers rename; no orphan-repair migration
  exists for these tables, consistent with no field breakage.
- **mybd-guity** (goal-named): upstream half resolved as already-filed -
  gastownhall/beads#5289 (open, another reporter, bd 1.1.2 repro) covers the
  defer-lapse bug exactly. Local sweep of the 17 lapsed deferred beads remains.
- **mybd-e1b3f**: CLOSED as fixed upstream - #5354 (merged 2026-08-05) implements
  the stop-epoch fast-abort for the exact stop/start interleave race. Our
  overlapping open PR #5241 was closed as superseded with a signed comment.
- **mybd-r5u2**: policy already decided upstream ('RULING R1': bd create refuses
  occupied --id; raw CreateIssue upsert deliberate + scoped to import/reconcile,
  both conformance-pinned). Left open only for the human gate mybd-pt1vk;
  recommend close.
- **mybd-6qr7s**: claimed mechanism refuted (no-workspace errors hard at current
  main; the empty-list repro is bd resolving a different valid workspace
  boundary). Re-scoped in notes to a UX ask before any filing.
- **mybd-rgs2i**: unverifiable statically; needs a live repro under the current
  .bare/bd-main layout before filing. Noted on the bead.

## Side effects and follow-ups

- PR gastownhall/beads#5241 closed as superseded by #5354.
- scripts/gh-body-lint is broken: it sources scripts/_tri-lib.sh, deleted in the
  2026-08-10 teardown. Needs either the lib restored, checks inlined, or the
  script retired (bead filed: see mybd-xcocv close notes).
- All 28 filed beads now carry external_ref gh-iss-NNNN and a dated note, so
  future sessions see the upstream linkage from bd show.

## Session bead

mybd-xcocv (this harvest). Verification workflow run id wf_297679f1-46f;
issue bodies and verdicts archived in the session scratchpad.
