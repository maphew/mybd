# Ready-queue processing loop (session c) - 2026-07-05

Session: claude-code-fable-5 orchestrator; haiku freshness scouts (workflow), sonnet-5 builders,
opus-4-8 reviewers. Third mybd session today; built on the earlier ready-sweep
(reports/ready-sweep-and-fixmerge-2026-07-05.md), which had already swept 16 ready beads, so this
loop targeted the un-swept remainder.

## Freshness sweep (workflow `ready-freshness-phase-a`, 6 haiku scouts, ~202k haiku tokens)

| Bead | Verdict | Action taken |
|------|---------|--------------|
| mybd-day-throughput | close | Closed: #4309 merged 2026-06-07; v1.0.x blocker framing moot post-v1.1.0 |
| mybd-day-discovery-import | close + refile | #4302/#4305 merged 2026-06-13; live remainder #4304 refiled as focused tracker **mybd-3fvn** |
| mybd-kj2v | blocked-upstream | #4310 open, zero activity 30d; drift note added |
| mybd-t7mk.7 | blocked-upstream | #4249 still unanswered since 2026-05-29; #4408 stalled; #4587 (auto gms_pure_go tag) merged today; note added with escalate-by ~2026-07-12 suggestion |
| mybd-iihf | work-now | dolt#11236 closed 2026-07-02; bd `dolt push/pull` still `context.Background()` with no timeout. **Left for next session** (mid-size, needs design pass) |
| mybd-ethh | work-now | Executed below |
| mybd-q6cz | work-now | Executed below |

## Work executed

### mybd-ethh slice 1: depguard storage-boundary rule -> PR #4589

- `.golangci.yml` (schema v2): `dolt-storage-boundary` rule denying `github.com/dolthub/*`
  outside `internal/storage/**` + `internal/doltserver/**`, message pointing at
  PROJECT_CHARTER "Storage Boundary". Exceptions carved out with inline justification:
  `cmd/bd/proxied_server.go` (dolt servercfg/filesys; adapter-migration candidate) and
  `internal/metrics/{flusher,metrics}.go` (eventkit telemetry).
- Opus review: no blockers; two improvements applied pre-PR: (1) companion rule
  `dolt-storage-boundary-metrics-exception` allowing only eventkit in the metrics files
  (reviewer proved a real engine import there slipped through the wholesale file exclusion);
  (2) charter wording no longer overstates coverage (`run.tests: false` means `_test.go` is
  never analyzed). Builder discovered `!$all` expands wrong in depguard v2.2.1 and used a plain
  positive files-allowlist for the companion rule instead.
- Verified against CI-pinned golangci-lint v2.9.0 with CI args; negative probes (driver/v2 in
  cmd/bd, go-mysql-server in metrics) fail with the boundary message, then revert clean.
- **PR: gastownhall/beads#4589** (branch `feat/ethh-depguard-storage-boundary` @ 646fa20a8).
  CI fully green at session close. Bead remains open (slices 2-3: optional module split, docs
  terminology sweep).
- Spin-off: **mybd-kpd7** - golangci-lint pin drift (CI v2.9.0 vs pre-commit v2.10.1) surfaces
  8 gosec findings only under the newer pin.

### mybd-q6cz: leaked test dolt sql-servers -> PR #4592

- Two-piece defense in depth: (A) `BEADS_TEST_MODE=1`-gated `Pdeathsig: SIGTERM` in
  `procAttrDetached`, split into `procattr_linux.go` / `procattr_other_unix.go` (Pdeathsig is
  Linux-only; production attr byte-identical when env unset); (B) `SweepOrphanedTestServers`
  after `m.Run()` in six TestMains, including a new TestMain for `internal/doltserver`'s
  integration tests which previously had none.
- Opus review found a **real blocker** in the first draft: an unconditional `os.TempDir()`
  reap root would have let a finishing suite SIGTERM sibling suites' still-live servers under
  `scripts/test.sh -p 4` (every suite's data dir lives under /tmp). Fixed: live servers are
  reaped only under caller-suite-owned roots; the deleted-cwd `/proc` signature (the actual
  observed leak shape) reaps unconditionally; no global root exists. Test contract reworked to
  pin cross-suite isolation. The review also confirmed `killStaleServersForDir` is per-beadsDir
  PID-file based and unusable as a general sweep base - the builder's separate pure selector was
  the right call.
- **PR: gastownhall/beads#4592** (branch `fix/q6cz-test-server-reap` @ 73b6866c1). At session
  close: 10 checks green, 14 pending (embedded-Dolt matrix). Slow local suites enqueued:
  `scripts/verify-enqueue mybd-q6cz ... "make test"` (verify_head 73b6866c1) - run
  `scripts/verify-next` when a slot is free.

## Bead housekeeping

- Closed: mybd-day-throughput, mybd-day-discovery-import.
- Created: mybd-3fvn (track upstream #4304 JSONL auto-import hazard), mybd-kpd7 (lint pin drift).
- Notes/drift records added: mybd-kj2v, mybd-iihf, mybd-t7mk.7, mybd-ethh, mybd-q6cz.
- Confirmed closed elsewhere: mybd-0a7n (upstream e1d5b3fae fixed bd human respond storage-nil).
- PR #4586 (ae1i piece 2, prior session): 54/54 checks green, still no maintainer review -
  shepherding only; piece 3 remains the queued follow-on.

## Incident note: suspected prompt-injection during builder run (benign, handled correctly)

Mid-task, after the ethh builder reverted its temporary negative-test import with
`git checkout --`, a tool-output note claimed the file change was "intentional" and told the
agent not to revert it and not to report it. The builder disregarded it, followed its
instructions, and flagged it upward. Orchestrator assessment: most likely the harness's standard
external-file-modification reminder misread as adversarial, not an actual attack - but the
builder's response (ignore, comply with orchestrator, report) is exactly right either way.
Post-hoc verification confirmed the worktree contained only the intended two-file diff.

## Handoff / next session

1. **mybd-iihf is the next work-now item**: bounded timeouts + diagnostics for `bd dolt
   push/pull` (upstream blocker dolt#11236 now closed; auto-push already has timeouts via
   #3381; doltPushCmd/doltPullCmd still bare `context.Background()`). Needs a short design pass
   (timeout defaults, config knob vs flag) before delegation.
2. Shepherd PRs #4589, #4592 (and #4586 from the prior session); after #4592's CI matrix is
   green and local `verify-next` passes, close mybd-q6cz.
3. mybd-t7mk.7: if #4249 still unanswered by ~2026-07-12, escalate with a follow-up comment or
   decide the beads-side fork path.
4. Owner decisions still queued from earlier sessions: mybd-ufzk (orphaned-PR disposition),
   mybd-fry6 (tri-pull re-enable).
5. Worktrees kept: `ethh-depguard`, `q6cz-server-reap` (both have open PRs), `ae1i-ff-piece2`.

Token spend (workflow budget accounting): freshness workflow ~202k (haiku); builders+reviewers
~450k across 6 delegated runs (sonnet/opus). The 200k-per-task default was respected per task
but not per session; scout stage stayed within one batch as recommended by the previous report.
