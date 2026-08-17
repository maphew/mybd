# Overnight maintainer fleet: architecture and failure modes

Date: 2026-08-16. Author: claude-code session for maphew. Status: phase 1
implemented (`scripts/fleet`, `scripts/fleet-lane`, `scripts/fleet-digest`,
`scripts/test-fleet`); phases 2-3 tracked as beads.

## Why, and two corrected premises

The request: a lane supervisor that runs N parallel overnight lanes, each
claiming one bead, running the full implement-to-PR pipeline inside the
existing guardrails (gate labels, worktrees, red-team, cross-vendor review),
with per-lane budgets, CI-outage discrimination, and a single morning digest.

Two premises in the request are stale and the design corrects for them:

1. **`pr-babysit` no longer exists.** It was deleted in the 2026-08-10
   maintainer step-down. The surviving zero-token patrol is
   `scripts/index-babysit`, which already flags fleet regressions as comments
   on `mybd-ykt9f`. The digest *reads* that surface instead of duplicating it.
2. **There are no upstream merge rights.** maphew is a contributor to
   `gastownhall/beads`, not a maintainer. "Merge if policy allows" therefore
   hard-resolves: **upstream PRs are always parked for ratification; the fleet
   never merges, closes, or labels anything upstream.** Local merges to
   `maphew/mybd` main remain routine, but phase 1 scopes lanes to beads-source
   work only, so the fleet merges nothing at all.

Also noted: the wind-down epic (`mybd-ykt9f`) says "land/hand-off/close
everything non-personal". A new overnight fleet is new infrastructure in a
repo being wound down. This build follows the owner's current explicit
request; the tension is flagged here for the owner to reconcile, and the
fleet's own beads sit under a dedicated epic so they are easy to sweep.

## Components

```
scripts/fleet          supervisor: pool -> filter -> claim (serial) -> spawn lanes -> wait -> digest
scripts/fleet-lane     one bead, full pipeline, state machine + budget + clean-exit trap
scripts/fleet-digest   render run dir -> morning digest (md + bead comment)
scripts/test-fleet     seam-driven smoke suite (style of test-red-team-gate)
[phase 2] fleet-ci-classify   change-broken vs infra-outage vs base-red discrimination
[phase 3] systemd fleet.timer + install-fleet (+ drift check)
```

### Run layout

Every run gets `.worktrees/.fleet/runs/<run-id>/`:

```
run.json                     config snapshot (N, budget, pool mode, candidates, claims)
lanes/<bead-id>/state.json   lane state machine record (atomic tmp+mv writes)
lanes/<bead-id>/lane.log     full lane log
digest.md                    morning digest
```

`state.json` is the contract between lane and digest: stage
(`setup|implement|test|review|pr|ci-watch` and terminal
`ratify|parked|handoff|failed`), branch, worktree, base sha, PR url, outcome
reason, budget used. The digest treats a missing or unparseable state file as
an **anomaly**, never as "nothing happened" (fail-closed aggregation).

### Supervisor (`scripts/fleet`)

1. **Preflight**: fleet-wide flock (one fleet at a time); bd reachable; codex
   on PATH (else executor-dependent lanes would burn wall clock failing);
   disk space; `GOTMPDIR`/`GOCACHE` pointed at the home disk (tmpfs trap).
2. **Pool**: `bdj ready -n 0`, then filter (below).
3. **Claim serially, before any lane spawns**: `bd update <id> --claim` one
   at a time through the agentbin flock shim. A failed claim means another
   actor got there first: skip to the next candidate, never retry. Claims
   are the *only* anti-collision primitive; worktree naming is just hygiene.
4. **Spawn** up to N lanes (`FLEET_LANES`, default **2**) as background
   processes in their own process groups, each with `FLEET_LANE_BUDGET_SECS`
   (default **2700s / 45min**) and the agentbin shim on PATH with
   `MYBD_BD_LOCK_WAIT=300`.
5. **Wait** with a supervisor ceiling (budget + 10min grace); on ceiling,
   TERM the lane process group and let the lane's trap do its clean exit.
6. **Digest**: run `fleet-digest`, comment the summary on the fleet epic.

### Queue filter (gate primitive)

The existing gate primitive is a label (live use: `human`; `bd human` is a
stale command). Filtering is fail-closed and layered:

- **Exclude** any bead carrying a label in `FLEET_GATE_LABELS`
  (default: `human human-decision gate needs-owner product-decision`).
- **Exclude** epics (not implementable units) and priorities outside
  `FLEET_PRIORITIES` (default `1 2 3`; P0 criticals are deliberately left
  for humans, P4 backlog is not worth overnight tokens).
- **Exclude** beads already assigned to anyone.
- **Pool mode** (`FLEET_POOL`):
  - `optin` (**default for validation nights**): additionally require the
    `fleet-ok` label. The owner explicitly marks beads safe for autonomy.
  - `optout`: the full ready queue minus exclusions - the target steady
    state once the fleet has earned trust.
- A bead whose labels cannot be parsed is excluded (fail-closed).

### Lane pipeline (`scripts/fleet-lane <bead-id>`)

1. **setup**: source worktree
   `git -C bd-main worktree add <abs>/.worktrees/beads/fleet-<bead> -b fleet/<bead> main`
   (absolute path, per convention). Record base sha.
2. **implement**: build a spec from `bd show <id> --json` (title,
   description, design, acceptance) and hand it to the executor:
   `scripts/codex-agent builder -C <wt> -o <log> "<spec>"` by default.
   The executor must commit its work; a lane verifies commits exist past the
   base sha, else outcome is `parked: no-change`.
3. **test**: `FLEET_TEST_CMD` (default `go build ./...`) under the remaining
   budget. Deeper testing is the red-team stage's job.
4. **review**: `scripts/pr-open -C <wt> --base main --search "<title>"` -
   the existing preflight + red-team (with its own fix rounds) + cross-vendor
   review, unchanged. Exit 3 (preflight objection) or 4 (red-team exhausted;
   red-team files its own bead) park the lane.
5. **pr**: **off by default** (`FLEET_OPEN_PR=0`). pr-open's philosophy is
   that reconciling review findings is judgment; on validation nights the
   lane stops after a green review and parks the branch as
   `ratify: review clean, PR not opened (policy)`. With `FLEET_OPEN_PR=1`
   the lane opens the PR (`gh pr create` from the worktree; the review-gate
   hook's evidence files already exist for the exact sha) and proceeds.
6. **ci-watch** (phase 2): poll checks with backoff via `fleet-ci-classify`;
   phase 1 records `pr-opened, ci-unwatched` and leaves CI red-flagging to
   index-babysit.
7. **finish**: park for ratification. Comment on the bead (branch, PR,
   review log path, one-line summary); the bead stays `in_progress` so it is
   visible in `bd list --status=in_progress` and cannot be re-claimed by the
   next fleet run.

### Budget and the clean-exit guarantee

Wall clock is the enforced primitive (`FLEET_LANE_BUDGET_SECS`); every stage
runs under `timeout` for the remaining budget, and a TERM/EXIT trap owns the
invariant **no lane ever leaves a dirty worktree**:

- dirty tree -> `git add -A && git commit -m "WIP(fleet): <bead> budget
  exhausted at <stage>"` on the lane branch;
- push the branch to `origin` (the fork) so it survives the machine;
- file a handoff bead (`discovered-from:<bead>`) whose description is a
  cold-start summary: branch, base sha, stage reached, log tail, suggested
  next action;
- `git worktree remove` the (now clean) worktree; the branch is the
  deliverable, the handoff bead is the pointer to it (a branch nothing
  points at is invisible).

Tool-call ceilings are executor-specific (codex has none exposed;
`claude -p --max-turns` exists) and are deferred to phase 2; wall clock
subsumes them for safety, if not for cost.

## Failure modes guarded against

| # | Failure mode | Guard |
|---|---|---|
| 1 | Two lanes claim one bead | Atomic `bd --claim`, performed serially by the supervisor before any lane spawns; claim failure = skip, never retry. |
| 2 | Parallel bd racing embedded Dolt | All bd calls via the agentbin flock shim; `MYBD_BD_LOCK_WAIT=300`; claims centralized; lanes make few, staggered bd writes. |
| 3 | Human-gated bead enters the pool | Fail-closed label filter + epic/priority/assignee excludes + opt-in pool mode for validation nights. |
| 4 | Dirty worktree left behind | TERM/EXIT trap: WIP commit, push, handoff bead, `git worktree remove`. `rm -rf` on worktree paths is never used. |
| 5 | Runaway agent burns the night | Per-stage `timeout` off one lane deadline; supervisor ceiling TERMs the lane's process group (kills the executor too, not just the wrapper). |
| 6 | CI infra outage read as "my change is broken" | Phase 2 classifier: ignore CANCELLED (known stale-wave artifact), compare failing jobs against the same jobs on base `main`, detect setup-phase deaths; verdicts `change-broken / infra-outage / base-red / flaky-suspect / unknown`, with backoff on non-change verdicts. Phase 1 avoids the problem by not watching CI (index-babysit flags regressions). |
| 7 | Merge-base churn thrash | Base sha recorded at setup; at most one rebase per run, immediately before PR; base moving after PR is a morning item, not a 3am loop. |
| 8 | Review gate bypassed | Lanes reach `gh pr create` only after `pr-open` has written both evidence files for the exact head sha; the PreToolUse hook is a Claude-session guard, so the lane re-checks evidence itself before creating a PR (the hook cannot see a bash lane). |
| 9 | Fleet vs interactive-session collision | Fleet-wide flock (one run at a time); claims exclude beads assigned to anyone; `fleet-` worktree/branch namespace; lanes never touch `in_progress` work of other actors. |
| 10 | Accidental upstream write | Lanes push only to `origin` (the fork); no `merge/close/label` verbs exist anywhere in the scripts; upstream PR creation is off by default. |
| 11 | Digest lies by omission | Digest is fail-closed: every claimed bead must have a terminal state file, anything else is listed under Anomalies; lane exit codes cross-checked against states. |
| 12 | Executor unavailable at 2am (codex missing, quota out) | Supervisor preflight fails fast before claiming anything; a mid-run executor failure parks the lane with the error, it does not retry all night. |
| 13 | Host exhaustion (tmpfs /tmp, leaked dolt servers) | `GOTMPDIR/GOCACHE` exported; disk preflight; lanes reap their own process groups; digest lists surviving `dolt sql-server` processes as an anomaly. |
| 14 | Deployed systemd unit drifts from template | Phase 3 installer re-run required after template change + drift check, per the existing `install-index-babysit` lesson. |
| 15 | Same-actor cross-machine claim trap | Known: claims are idempotent only for the same actor string (`bd-claim-actor-string-mismatch`). The digest surfaces claim failures with the holder's actor string so the morning session recognizes its own other-machine self. |

## Morning digest

One markdown file per run plus a phone-sized summary commented on the fleet
epic bead:

1. **Merged** (always empty upstream by policy; present so its emptiness is
   an explicit statement, not a blind spot).
2. **Awaiting ratification** - branches/PRs with a green review, ranked by
   risk score: open P2/P3 red-team findings, diff size, files touched.
3. **Parked** - bead, stage reached, reason (preflight objection, red-team
   FAIL, no-change, executor error).
4. **Handoffs** - budget-exhausted lanes: branch + handoff bead id.
5. **Budget** - per lane: wall clock used / ceiling, stages reached.
6. **Anomalies** - missing or non-terminal states, claim skips, leaked
   dolt processes, plus a standing pointer to index-babysit's flag comments
   on `mybd-ykt9f` (auto-folded into the digest in phase 2).

## Incremental rollout

- **Phase 1 (this session)**: supervisor + lane + digest + tests. N=2,
  45min/lane, `FLEET_POOL=optin`, `FLEET_OPEN_PR=0`. Validate by labeling
  one or two boring beads `fleet-ok` and running `scripts/fleet` manually in
  the evening; read the digest in the morning.
- **Phase 2**: `fleet-ci-classify` + CI watch + `FLEET_OPEN_PR=1`;
  executor tool-call ceilings; reconcile-findings agent stage.
- **Phase 3**: systemd `fleet.timer` (nightly), `install-fleet`, unit drift
  check; scale to N=4 after two clean supervised nights.

Each phase is a bead under the fleet epic; nothing advances a phase
implicitly.
