# Autonomous ready-queue workdown - 2026-08-10 (evening session)

**Directive:** work `bd ready` until dry or genuinely blocked; newest first, existing PRs first; workflows; worktree + branch + tests + PR per task.

**Headline:** ready queue 151 → 76. 11 upstream PRs opened plus 2 repaired, 3 abandoned contributor PRs/reviews carried with authorship preserved, 5 upstream issues filed, 9 evidence/nudge comments posted, ~25 beads closed, 8 deferred with real checkpoints. Every upstream change passed the cross-vendor codex gate; several needed multiple rounds and the gate caught real bugs each time.

## Why the queue "looked old" (session preamble)

`bd ready` silently truncates at `--limit 100` with no shown/total indicator, hiding everything created after 2026-08-03. Saved as bd memory `bd-ready-default-limit-100`; the upstream fix is already tracked (mybd-5vf6r / gh 5102). Real ready count was 151.

## Existing PRs shepherded (mybd-jcylm, P0)

- **#5202** (import --skip-invalid): red CI root-caused to new gosec G705 taint rule; annotated per main's convention. Now **fully green (100/100 checks)**.
- **#5064** (aux-rekey drift survival, carries marcodelpin's #4380): rebased across main's multi-pass rekey restructure - the delicate part was keeping ONE shared drift record across both passes, sound because every pass runs the identical rewrite over the identical table set. Reviewer pass (opus tier) said SHIP with should-fixes; all applied (drift-name filtering against `auxRekeyTables`, invariant doc + `TestRekeyAuxRowIDsAllPassesSharesDriftRecordAcrossPasses`). Force-pushed with an explanation comment; validator ping posted on #4380 (v1.1.2's release unblocks kikin81's earlier no-build blocker).
- #5229, #5092, #5316, #5243 remain green and mergeable, awaiting review.

## New upstream PRs (all codex-gated before opening)

| PR | What | Bead |
|---|---|---|
| #5630 | dbproxy `DoltServer.waitReady` drains the MySQL greeting (the site #5277 missed) + mute-listener not-ready + post-drain liveness recheck (gate finding) | mybd-c4x69 (closed) |
| #5632 | pre-commit golangci args mirrored from the ci-pr-lint gate | mybd-jp0l8 (closed) |
| #5633 | init-safety doc: exit 12 vs 11 split per symptom | mybd-nekrd (closed) |
| #5634 | gitignore chmod hoist + check-side loose-perms warning + idempotency tests (post-#5285 regression, verified still live) | mybd-s8wbq (deferred on 4791) |
| #5635 | **carry of #4730** (jakelindsay87, authorship preserved): UTC timestamp preservation re-applied across main's `addDependencyInTx` rewrite; supersedes #5297's literal on that line while keeping its intent | mybd-jw9ch (deferred) |
| #5636 | CHANGELOG entry for #4686's tree-nesting change + deterministic `[]`-marshalling `filterIssueGates` | mybd-uaiv (closed) |
| (see below) | `bd sql` read-only open (#4121) | mybd-9222 |
| (see below) | **carry of #5065** (halaprix) + review-blocker hardening | mybd-fezwm |

The last two went through 4-6 gate rounds each; final PR numbers are in the addendum below.

Notable gate catches worth remembering: the CTE scanner (`withOuterStatementIsRead`, pre-existing, proxied path) ignored MySQL string escapes - a crafted `WITH ... DELETE` classified as a read; fixed in the shared helper AND made irrelevant to the new path by failing closed on comments and backslashes. On the 5065 carry, the gate escalated the embedded-footer design to its logical end: extracted IDs are now consistency hints, never identity sources - a fabricated footer can't mint an ID or adopt an unlinked bead.

## Upstream issues filed

- **#5627** - archive_level yaml failure (#4986) reachable again after 68afa3d51 removed the version gate (mybd-rvyzh, closed).
- **#5628** - reinit preflight: count errors silently skip the destroy confirmation; counted DB can diverge from gated DB (mybd-nekrd).
- **#5629** - pr.yml runs the lint shape three times (mybd-jp0l8).
- **#5631** - doctor test suites leak dolt sql-server processes that outlive their deleted temp dirs (mybd-avwqg, closed; the four fresh orphans were reaped).
- **#5637** - `bd set-state` commits its event and its label patch independently; a failed patch leaves a phantom transition event. Flagged independently by three separate codex sweeps today before being verified and filed.

## Evidence and nudge comments

#3575 (claim race: verified fixed by row_lock CAS, retest evidence), #4887 + #4988 (auto-export: root cause = export.auto default flip / fixed-by-#5141 evidence - published the drafts a prior maintainer-era session had held back), #5058 (docs already fixed by #5394, can close), #3861 (GraemeF: dependency merged, offering credited carry), #4858 (vishnujayvel: conflicting, offering credited carry - this PR supersedes mybd-h9w5's implementation plan), #4730 and #5065 carry notices, #4380 validator ping.

## Local (coordination repo) work landed on main

- **gh-body-lint restored** (mybd-l2la0/5sff9): the 2026-08-10 teardown deleted `_tri-lib.sh` out from under it; helpers inlined, smoke test added (`scripts/test-gh-body-lint`). Used by every GitHub post this session.
- **report-room reader** (mybd-0nzhq.1): `scripts/report-room.ps1 open/check` - deterministic joined view of the reading room + live bead snapshots; 108 fixture tests; adversarial review round fixed a malformed-source crash and five smaller findings pre-landing. Remaining: Windows smoke run (bead stays open for the next Windows session).
- **Navigation decision memo** (mybd-0nzhq → `reports/2026-08-10-reports-navigation-decision.md`): recommends the two-layer model (curated README + deterministic reader); owner sign-off requested, human-decision label applied.
- **fix/agent-migrations landed** (mybd-lk7c6): the stranded mybd-f1fv delivery merged; `bd dolt` sync verified with its `git+https` remote form.

## Disposition sweep (17 tracking beads, parallel workflow)

Closed 9 (zahk, mlik, psis, 45gp, 5buk, noz5j, mlqr, hxa9, 7kcg - tracked work merged/moot, or the remaining action was maintainer-only under the contributor role), deferred 2 to 08-24 (3br1, 21yl), converted 6 to live work of which 4 were executed this session (9222, uaiv, epp3→already-fixed-upstream, xb9h→ping posted) and 2 deferred with carry plans (h9w5 behind #4858, do1mx closed after the #3861 nudge).

## Other queue outcomes

- mybd-guity closed: the 17 lapsed-defer beads all resurfaced - current bd implements snooze-on-lapse; the 08-01 observation was an old-binary artifact.
- mybd-zwurw closed (claim race fixed upstream, evidence posted). mybd-vkc56 closed (both wedge tracks verdicted; evidence published). mybd-02te closed (doc line already gone). mybd-ki3pc annotated: its two failing tests are `//go:build cgo` and this host can't build CGO (missing ICU headers) - unverifiable here.
- mybd-pdvy (overdue owner decision) freshened: upstream engaged on 4249 and #4986 changed the zstd landscape; flagged human-decision with updated inputs.
- mybd-jrbuu deferred: escalated upstream as #5577 in the morning harvest; waiting on maintainer direction.

## Blocked / owner queue (the "genuinely blocked" residue)

- **mybd-pdvy** - escalate-vs-fork-carry call, inputs refreshed (owner).
- **mybd-0nzhq** - approve the navigation model (owner).
- **mybd-0nzhq.1** - Windows smoke run (next Windows session).
- **mybd-vv48x** - Dolt bookkeeping tables commit-vs-ignore (owner, untouched).
- **mybd-jk2kg** - fold-in vs follow-up hinges on maintainer reply on #5202.
- **mybd-psxg / psxg.2 / psxg.4** (P0 campaign) and **mybd-khkc5** (workspace-gate B2), **mybd-zgqpl** (batch-close error taxonomy PR), **mybd-t7mk** - substantive multi-session implementation efforts, deliberately not started at session tail; zgqpl's scope was narrowed (CAS half explicitly rejected upstream, taxonomy half verified still live with file:line).

## Process notes

- Parallel-session stash trap re-confirmed: a bare `git stash` in a worktree popped another session's WIP from the shared stack (AGENTS.md already warns; entry preserved, no loss).
- The codex gate earned its keep: across ~10 runs it caught one real P2 on c4x69 (post-drain liveness), one P1-class scanner bug (CTE escapes), the post-run-gates propagation gap on 9222, and drove the 5065 footer-identity design to fail-safe. Findings against upstream code outside the diff (state.go atomicity, show emoji) were reconciled, not blindly applied - one became #5637; the emoji one was judged upstream's policy/practice tension and skipped.

## Addendum: final PR numbers (session extended past the first close-out)

- **#5641** - `bd sql` read-only open (mybd-9222, closed). Six gate rounds; the final one clean. The classifier fails closed on comments and backslashes, making it safe under any server `sql_mode`.
- **#5642** - carry of #5065 (mybd-fezwm, closed). Three gate rounds converged 1 P1 + 5 P2 → 4 P2 → 3 polish P2s; residuals listed in the PR body, halaprix/jms830 notified.
- **#5645** - `bd gate create --title` regression test (mybd-qjtbb, closed; offered in the 5099 review).
- **#5648** - dependency-type alias family (mybd-i61ti + mybd-2rne5, closed; fixes upstream #5585 + #5560). The gate caught the proxied batch twin AND a direction inversion in the form path that only the Docker-gated CI tests would have exposed.
- **#5651** - batch-close error taxonomy (mybd-zgqpl, closed; the taxonomy half of the 5293 review offers, CAS half deliberately dropped per upstream's documented rejection). Eight gate rounds converged to zero findings, en route adding phase-marked post-write errors, scoped HTTP mapping, and the previously-unreachable mid-batch infrastructure conformance slice.

Second sweep additions beyond PRs: the 29 harvest-filed watch beads deferred as a cohort to 2026-08-25 (memory `harvest-watch-cohort`); `scripts/bdj` + codex-agent size cap landed locally (retro F-004/F-005); PR 4858 nudge (supersedes h9w5's implementation plan); jgqy/y938/6qr7s/62300 dispositioned; 24 stale test temp dirs swept. Final fleet: **17 open PRs** tracked by mybd-koabx.
