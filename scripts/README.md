# Upstream triage + review scripts

Tooling for managing the firehose of issues + PRs on `gastownhall/beads`. Two
loops: **triage** (decide what to do) and **review** (do the PR work, resumable
across machines).

The workflow is split into three layers by **output audience** (v2 redesign,
2026-07-07, after the v1 experiment drowned readers in agent-written text):

1. **Mechanical sync** (`tri-pull`, `tri-sync`, `tri-daily`, labels) - posts
   no text anywhere; runs freely, cron-safe.
2. **Classification** (`/triage` command in Claude Code) - dispositions and
   one-line reasons into bd labels/notes, plus one short digest per run under
   `reports/triage/`. Never posts text upstream.
3. **Publication** (`tri-submit`) - the only path that posts agent-drafted
   text to upstream GitHub. Word-budgeted, distilled into a separate
   `NNNN.post.md`, and gated behind interactive terminal confirmation so
   unattended agents cannot post.

The old blanket `MYBD_ENABLE_TRIAGE=1` gate is gone; the gate now sits
exactly where the risk is (text publication), not on the whole toolkit.

On Windows, do not invoke extensionless scripts directly from PowerShell. Use
the matching `.ps1` wrapper, for example `scripts/tri-daily.ps1`, or run the
extensionless script through Git Bash.

## Daily workflow

```
1. tri-pull + tri-sync          # or /triage in Claude Code, which wraps both,
     classifies each stub (tri:* label + one-line reason), and writes a short
     digest to reports/triage/YYYY-MM-DD.md
2. review the digest / bd ready # confirm or flip dispositions:
     close / defer / claim / human / needs-info
3. tri-review <id>              # for claimed PRs: worktree + scaffolds + checks
4. edit pr-reviews/NNNN.md      # full analysis, stays local
5. distill pr-reviews/NNNN.post.md   # <=150 words, the only text posted
6. tri-submit <id> --approve    # budget-lint + confirm at terminal + post
                                #   + close bd + label upstream

For non-PR triage stubs: tri-close <id> [--reason=...]
```

Re-running `tri-pull` daily is idempotent. It only mirrors items lacking the
`triaged` label upstream and skips any already in bd (matched by `external_ref`).

Pair with `tri-sync` (below) to also auto-close bd stubs whose upstream item
has since been merged or closed.

## ready-lanes (readable `bd ready`)

```bash
scripts/ready-lanes            # P0 hoist + own-work lane
scripts/ready-lanes --mirror   # P0 hoist + upstream-mirror lane
scripts/ready-lanes --all      # no per-lane display cap
scripts/ready-lanes --json     # the ready set, each item tagged with .lane
```

Step 2 of the daily workflow ("review the digest / `bd ready`") stops working
once the queue is deep enough. On 2026-07-29 `bd ready` returned ~335 items:
~56% were stubs mirrored from `gastownhall/beads`, ~53% carried the default P2,
and five P0 data-loss beads were sitting invisibly inside the pile.

`ready-lanes` is a read-only view over `bd ready --json` that splits it in two
and hoists P0 above both:

| lane | rule | what it holds |
|------|------|---------------|
| own-work | no `external_ref` | our fixes, reviews, campaigns, chores |
| upstream-mirror | `external_ref` set | `gh-iss-*` / `gh-pr-*` stubs from triage |

The rule is derived at read time, so newly mirrored stubs classify themselves
and no bulk relabelling is needed. On the 2026-07-29 set it agreed with a
description-text probe on 331/335 items (3 mirrored stubs had no `external_ref`,
1 own-work bead had one) — good enough to triage by, not a load-bearing
invariant. A bead in a surprising lane is a mislabelled bead, not a script bug.

Only **P0** is hoisted. A P0+P1 hoist was 85 items on the same set, which is
just a second haystack; P1 is not hidden, it sorts to the head of its own lane.
This is a view, not a gate — it exits 0 whenever `bd` answered.

## tri-daily (unattended Layer 2 wrapper)

```bash
scripts/tri-daily                         # run tri-pull + tri-sync + tri-drift once
scripts/tri-daily --pull-only             # only mirror new items in
scripts/tri-daily --sync-only             # only close upstream-terminal stubs
scripts/tri-daily --drift-only            # only flag upstream activity on triaged stubs
scripts/tri-daily --no-drift              # skip the drift pass
scripts/tri-daily --verbose               # print the same summary it logs
scripts/install-tri-daily                 # Linux: systemd user timer (06:47 + 16:47)
scripts/tri-install-cron                  # non-systemd: daily cron entry (06:17 local time)
scripts/tri-install-cron --schedule "45 5 * * *"
```

`tri-daily` is the practical machine-bound unattended path for Layer 2. It is
designed for unattended scheduling:

- silent on success when nothing changed
- appends a one-line summary to `${XDG_STATE_HOME:-~/.local/state}/mybd/tri-daily.log`
  when `tri-pull` creates new stubs, `tri-sync` auto-closes stale ones, or
  `tri-drift` flags upstream movement; the summary line also carries
  `human_pending=N` (open `tri:human` stubs) as a standing nag for owner
  decisions
- appends full diagnostics and exits non-zero on failures (`gh` auth/rate
  limit, network, command errors)

On Linux prefer `scripts/install-tri-daily`, which installs the
`tri-daily.timer`/`.service` systemd user units (same babysitter pattern as
pr-babysit and verify-babysit; fires twice a day, zero model tokens, catches
up after sleep via `Persistent=true`). `tri-install-cron` remains for
non-systemd machines: it installs or replaces a single tagged crontab entry
that `cd`s into this checkout and runs `scripts/tri-daily` once per day. Both
are intentionally local-machine only; if you rotate between machines, install
on the one that has working `gh auth`, and don't install both on one machine.

## tri-pull

```bash
scripts/tri-pull              # full pass: issues + PRs, limit 100 each
scripts/tri-pull --limit 30   # smaller batch
scripts/tri-pull --prs-only
scripts/tri-pull --issues-only
scripts/tri-pull --dry-run    # preview
```

Each created bd issue:
- `external_ref`: `gh-pr-NNNN` / `gh-iss-NNNN` — the structured upstream link
- `title`: the upstream title verbatim
- `description`: URL, author, created date, labels, draft flag, decision options
- `priority`: heuristic from title/body/size/age/review state
- `type`: `bug` if title starts `fix(`/`fix:`, `feature` if `feat(`/`feat:`, else `task`

Additional Layer 2 behavior now shipped in `tri-pull`:
- smarter default priority (`P0`..`P4`) for fresh bugs/perf work vs drafts, stale conflicts, and very large changes
- dependency linking for stacked PRs (`stacks on #NNNN`, `depends on #NNNN`) and PRs that close issues
- warning pass for recently closed stubs whose upstream item still lacks the `triaged` label

The classifier is still heuristic. It should get `bd ready` closer to manual
triage order, not replace human judgment.

## tri-sync

```bash
scripts/tri-sync                # close bd stubs whose upstream PR/issue is merged/closed
scripts/tri-sync --dry-run      # preview
scripts/tri-sync --prs-only
scripts/tri-sync --issues-only
scripts/tri-sync --limit 20
```

Walks open bd issues with `gh-(pr|iss)-NNNN` refs, queries `gh` for upstream
state, and closes bd stubs that are terminal upstream:

- PR `MERGED` → `bd close --reason="upstream merged: <sha7>"`
- PR `CLOSED` (not merged) → `bd close --reason="upstream closed (not merged)"`
- issue `CLOSED` → `bd close --reason="upstream closed: <stateReason>"`

Does NOT apply the `triaged` label upstream — the upstream item is already
terminal, so labeling adds noise. Each closure also gets a `tri-sync: closed
(...)` audit note on the bd issue. Idempotent; safe to run from cron alongside
`tri-pull`.

## tri-drift

```bash
scripts/tri-drift                # flag triaged stubs whose upstream item moved
scripts/tri-drift --dry-run      # preview, no bd writes, no baseline updates
scripts/tri-drift --prs-only
scripts/tri-drift --issues-only
scripts/tri-drift --limit 20
```

The activity complement to `tri-sync` (which only sees *terminal* upstream
states). Walks open bd stubs that already carry a `tri:*` label, compares
upstream `updatedAt` against a machine-local baseline in
`${XDG_STATE_HOME:-~/.local/state}/mybd/tri-drift.state`, and on movement:

- adds the `tri:stale` label (the "re-triage me" flag)
- appends a `tri-drift: upstream activity after triage (...)` audit note
- advances the baseline, so one upstream event produces one flag

First sighting of a ref seeds the baseline silently. Claimed (`in_progress`)
stubs are excluded — activity on work in flight is expected. Stubs already
labeled `tri:stale` get baseline refreshes but no duplicate notes; re-triage
clears the label (`bd update <id> --remove-label tri:stale` after flipping the
`tri:*` disposition if needed). The `/triage` worklist treats `tri:stale`
items as needing reclassification.

## tri-close

```bash
scripts/tri-close mybd-XXX                      # close + label upstream
scripts/tri-close mybd-XXX --reason="dupe of #1234"
scripts/tri-close mybd-XXX --skip-label         # close bd only (rare)
scripts/tri-close mybd-XXX --dry-run            # preview
```

Reads `external_ref` to know which upstream PR/issue to label. Refuses to act
on bd issues without a `gh-(pr|iss)-NNNN` ref — use `bd close` directly for
non-triage stubs.

Plain `bd close <id>` is also covered in this repo via `.beads/hooks/on_close`,
which calls `scripts/tri-label-upstream` as a best-effort async hook.

## Triage decision tree (per item in `bd ready`)

| Decision  | What to run                                              | When                                        |
|-----------|----------------------------------------------------------|---------------------------------------------|
| **close** | `tri-close <id> --reason="..."`                          | Won't engage; dupe; out of scope; rejected  |
| **defer** | `bd defer <id> --until="next monday"`                    | Re-look later; not actionable now           |
| **claim** | `bd update <id> --claim` + flesh out desc, set real priority | You'll actually do the work                 |
| **human** | `bd human <id>` (or add `--notes="human: <Q>"`)          | Need a maintainer call before deciding      |

For `claim`: the stub becomes the real working bead. Add proper description,
acceptance criteria, dependencies, etc. The `external_ref` stays so the link
to upstream survives.

## Configuration

Override the upstream repo with `TRI_UPSTREAM` env var (default
`gastownhall/beads`):

```bash
TRI_UPSTREAM=other/repo scripts/tri-pull
```

## Beads Database Drift Guard

The canonical issue database for this coordination repo is
`.beads/embeddeddolt/mybd`, with issue prefix `mybd-` and Dolt remote
`maphew/mybd` (either `git+ssh://git@github.com/maphew/mybd.git` or
`git+https://github.com/maphew/mybd.git` is accepted; the live DB uses SSH). A
sibling database named `beads` may exist as a populated legacy/bootstrap
artifact; do not point `.beads/metadata.json` at it. If `mybd` is empty but
`beads` holds the issues, migrate the populated folder into `mybd` rather than
re-pointing metadata (see thread history) so the guard and data agree.

```bash
scripts/check-beads-config          # fail if metadata points at the wrong DB
scripts/check-beads-config --fix    # repair only the known safe mybd/beads drift
scripts/pre-commit-beads-config     # block staged metadata drift from commits
```

`--fix` is deliberately conservative. It rewrites `.beads/metadata.json` only
when the configured database is empty or missing, `mybd` has issues, and `mybd`
has the expected `origin` remote. It additionally repairs one other known
drift: `core.hooksPath` not pointing at the composed `.githooks` set (e.g.
after `bd hooks install --beads` flips it to `.beads/hooks`); this git-config
write activates the composed hook set and is announced on stderr even under
`--quiet`. If both databases contain issues, export both
and reconcile manually before changing metadata. Intentional database renames
must set `MYBD_ALLOW_DB_RENAME=1`.

## GitHub body lint

Before posting PR, issue, comment, or review Markdown through `gh`, write the
body to a file and lint it:

```bash
scripts/gh-body-lint body.md
scripts/gh-body-lint --fix body.md          # rewrites GH#1234 to #1234
scripts/gh-body-lint --max-words 150 body.md   # also enforce a word budget
gh pr edit 1234 --repo gastownhall/beads --body-file body.md
```

The lint guard rejects literal `\n` sequences and `GH#1234` refs, both of
which render badly or fail to autolink in GitHub posts. With `--max-words N`
it also fails bodies over the budget (fenced code blocks excluded from the
count) - use it on anything public-facing; long analysis belongs in a local
report, not the post. `tri-submit` runs both checks automatically.

## tri-review (PR work loop)

```bash
scripts/tri-review mybd-XXX                  # claim, worktree, build+lint, scaffold note
scripts/tri-review #3482                     # accepts PR# directly (resolves via external_ref)
scripts/tri-review mybd-XXX --tests          # also run go test ./... (slow)
scripts/tri-review mybd-XXX --no-checks      # skip build/lint, just scaffold
scripts/tri-review mybd-XXX --reuse-worktree # don't fetch/recreate (resuming)
```

Effects:
- Fetches PR branch into `bd-main/` (origin/pull/NNNN/head:pr-NNNN-review)
- Creates worktree at `~/dev/mybd-tri/<NNNN>/`
- Runs `go build ./...` + `golangci-lint --fast` (or `go test ./...` with `--tests`)
- Scaffolds `_working_on/pr-reviews/<NNNN>.md` with auto-computed signals (size, age,
  type, mergeable, CI checks, closes-issues, build/lint/test status)
- Logs `review-started: worktree=... note=...` to bd notes (timestamped + hostname)
- Sets bd status to `in_progress`

If the review note already exists, it is left untouched — you keep your work.

## verify-* (local asynchronous validation)

The `verify-*` scripts move slow beads source validation out of implementation
agent sessions while preserving a full local quality gate.

```bash
scripts/verify-enqueue <bd-id> <worktree> "make test"
scripts/verify-status
scripts/verify-next
```

Workflow:

1. The implementation agent runs fast preflight in its source worktree.
2. The agent commits or otherwise freezes the candidate; the worktree must be
   clean.
3. `verify-enqueue` records the candidate in bd metadata:
   `verify_state=queued`, `verify_head`, `verify_branch`, `verify_cmd`, and
   `verify_worktree`.
4. A verifier shell runs `verify-next`, which creates a clean detached worktree
   under `.worktrees/beads/verify-*`, runs the recorded command, logs under
   `.worktrees/beads/.verify-logs/`, and writes `verify_state=passed|failed`.

Defaults:

- `verify_cmd`: `make test`
- `VERIFY_TIMEOUT`: `45m`
- `VERIFY_KEEP_WORKTREE`: `failed` (`always`, `failed`, or `never`)
- `VERIFY_WORKTREE_BASE`: `<project>/.worktrees/beads`
- `VERIFY_LOG_DIR`: `<project>/.worktrees/beads/.verify-logs`

Run a simple local queue loop from this repo when several agents have queued
work:

```bash
while :; do
  scripts/verify-next || true
  sleep 30
done
```

The verifier intentionally uses local git, local bd metadata, and local logs
only. It does not call GitHub Actions or poll GitHub status.

## bisect-next (red-base bisect lane)

```bash
scripts/bisect-next [bd-id]          # run one queued base-red bisect job (FIFO if no id)
scripts/bisect-enqueue <bd-id> [cmd] # manually (re)queue a base-red bead
```

Zero-token companion to the pr-babysit **base-red** lane. When pr-babysit
raises a `base-red` P0 bead it also marks it `bisect_state=queued` (one extra
metadata key at creation; disable with `PR_BABYSIT_BISECT=0`). `bisect-next`
picks up one such job and files the culprit commit back onto the same bead, so
the stop-the-line signal arrives pre-diagnosed.

What one run does, keyed off the bead's `pr_babysit_red_base` (`repo@branch`):

1. Confirm `repo` is the local upstream (`TRI_UPSTREAM`); anything else is
   `skipped` — we can only bisect a branch we clone.
2. `git fetch upstream <branch>`; **bad** = the current `upstream/<branch>` tip.
3. **good** = the most recent successful CI run (`gh run list --status success`)
   whose head is an ancestor of bad. None found ⇒ `no-good-sha`.
4. **Oracle guards (the correctness rail):** in a detached worktree under
   `.worktrees/beads/bisect-*`, run the command at good (must PASS) and at bad
   (must FAIL). Either disagreeing ⇒ `unreproducible` — CI-red is not proof the
   failure reproduces locally (different suite, flake, CI-only), and we never
   bisect an unconfirmed range.
5. `git bisect start bad good` + `git bisect run`; parse the first bad commit.
6. Write `bisect_culprit`/`bisect_culprit_subject`/`bisect_log` + one note.

It **only ever** writes `bisect_*` metadata and one note. It never touches the
bead's status, labels, claim, or assignee — the base-red lane owns that bead's
lifecycle (including closing it on recovery); this lane only annotates.

Terminal `bisect_state`: `done` | `unreproducible` | `no-good-sha` | `skipped`
| `failed`. Defaults: `bisect_cmd`=`make test` (override via `BISECT_CMD` or a
`bisect_cmd` key), `BISECT_TIMEOUT`=90m (whole bisect), `BISECT_STEP_TIMEOUT`=45m
(per suite run), `BISECT_KEEP_WORKTREE`=`failed`, `BISECT_MAX_GOOD_SCAN`=50.

**Serialization.** `bisect-next` runs as a second sequential `ExecStart` in the
existing `verify-babysit` oneshot (after `verify-next`, each prefixed `-` so a
routine verification failure does not skip it). Because systemd never overlaps
activations of a oneshot, the two heavy git-worktree consumers never run
concurrently — no shared lock needed. `bisect-next` additionally `flock`s
against a second `bisect-next`. The one uncovered race is a **manually** run
`verify-next`/`bisect-next` firing during a timer activation; as with
`verify-next`, don't run them by hand while the timer is installed unless
debugging.

`test-bisect-lane` is the regression test: it drives `bisect-next` through its
hermetic job-file mode (`BISECT_JOB_FILE`, which bypasses bd, gh, and the
network) against a throwaway repo with a known culprit, and asserts the real
`.beads` DB and `bd-main` clone are never touched. Re-run it after any change
to the lane.

## pr-babysit / pr-handoff (merge-tail patrol)

```bash
scripts/pr-handoff <pr-number> [--repo owner/repo] [--method squash|merge|rebase] [--no-flake-rerun] [--bead <id>] [--base-fix]
scripts/pr-close-handoff <pr-number> [--repo owner/repo] --bead <id> --reason <text> [--after <hours, default 72>]
scripts/pr-babysit
scripts/install-pr-babysit
```

Three zero-token lanes, one patrol. `pr-babysit` is the only actor that
mutates a merge or close tail; both handoff scripts hand a decision to it and
end the session — see AGENTS.md "PR Merge Tails (babysitter pattern)" for the
fuller narrative (transient-block budgets, re-arm sweep, base-health gating).
The third lane (review-needed, below) has no handoff script: it watches
upstream directly.

**merge-when-green** — `pr-handoff` labels a bd bead `merge-when-green` and
records `pr_babysit_repo`/`pr_babysit_pr`/`pr_babysit_method`/
`pr_babysit_flake_rerun` metadata. The patrol reruns flaky checks once,
retries transient merge states for a bounded number of passes, and merges
only against a freshly re-read, matching head SHA. Anything it can't trust
(unreadable checks, a genuine policy block, an authorization mismatch) parks
the bead `merge-blocked` and unclaims it for `bd ready`.

`--base-fix` is the one exception to base-health gating, and it exists because
the rule deadlocks on exactly one PR: the fix for a red base cannot merge until
the base is green, and the base cannot go green until it merges (bead
mybd-01yzj — found while landing gastownhall/beads#5204 after a 13h red main).
The flag records `pr_babysit_base_fix=<repo>@<branch>`, naming the base this PR
remedies, and the patrol then merges on the PR's **own** green checks while
that base is red. The exception is narrow by construction: the recorded key
must match the base preflight reports red, that red base must be preflight's
*sole* objection (a conflict, draft state, changes-requested, or even a
transient merge state alongside it still holds the lane), and the PR's own
checks were already required green to reach preflight at all. On a green base
the flag does nothing, so it cannot decay into a standing merge licence, and
the patrol never sets the key itself — writing it is a reviewed act at handoff.

Three further guards came out of cross-vendor review, each closing a way the
exception could have merged something it should not:

- **The preflight verdict must be complete.** Preflight prints base health early
  and keeps working (status rollup, closing-issue GraphQL). A run that died
  after printing the red-base block would present a *partial* block list, making
  "the red base is the only objection" unproven. The exception requires exit 1
  plus preflight's terminal `Result: BLOCKED` line.
- **The base is pinned across the merge.** `gh pr merge --match-head-commit`
  pins the head but not the target, so a PR retargeted between authorization and
  merge keeps its head SHA. The final re-read compares `baseRefName` against the
  authorized key and withdraws the exception if it moved.
- **The audit note is written after the merge, never before.** The pre-merge
  authorization check compares the bead against the queue snapshot, notes
  included — appending first would revoke this pass's own authorization and the
  exception could never fire at all. The test harness's fake `bd` really appends
  notes now, so that failure mode cannot hide again.

Provenance is procedural, not enforced: the patrol trusts a matching metadata
key without proving `pr-handoff` wrote it. No other automation in this repo
writes that key and upstream PR content cannot inject it, but anyone with raw
`bd update` or import access could pre-seed one.
A base-fix merge does not record a green sighting: the base is still red, and
claiming otherwise would withdraw the very `base-red` escalation the PR is
trying to resolve.

### Stale-green guard (mybd-uncb7)

The last check before a merge asks whether the green being merged on was
earned against a base that still exists. GitHub runs `pull_request` checks
against a merge ref built when the run is **created**, so "the branch is behind"
is *not* by itself a stale verdict — a run created after the base moved tested
today's base, `behind_by` or not. Stale means a contributing check *started*
before the base last moved. When the branch is behind *and* its oldest check
started before the last base update, the patrol runs `gh pr update-branch` and
declines to merge on that pass; the new head's checks decide on a later one.

Three signal choices, the last two from cross-vendor review of the first cut:

- **`startedAt`, not `completedAt`.** A run that began before the base moved and
  finished after it still tested the old merge ref; completion time would wave
  exactly that case through.
- **The oldest start across the rollup, not the newest.** One late entry — a
  single rerun job, a check added afterwards — must not certify the whole
  verdict, because the jobs that did not rerun still hold the old result.
- **The base ref's activity, not the tip commit's date.** A pre-existing commit
  fast-forwarded or pushed directly onto the base carries its original committer
  date, so a check that ran between that date and the push would read as fresh
  against a base it never saw. `GET /repos/{o}/{r}/activity?ref=…` records the
  ref update itself. If that endpoint is unavailable the guard falls back to the
  committer date and logs it — a narrow hole beats losing the guard entirely.

Accepted residual (**mybd-oa40o**): `startedAt` is *job* start and the merge ref
is built at *run creation*, so a long queue delay still reads slightly
optimistic. Seconds normally; hours for a fork run parked in `action_required`.

Nothing else catches this. Upstream branch protection does not require
up-to-date branches — `mergeStateStatus` never reports `BEHIND` (measured
2026-08-01: absent across all 100 open PRs), so `pr-preflight`'s `BEHIND` arm
can never fire and GitHub merges the stale green without complaint.

Bounds, because this lane pushes a merge commit into a PR branch:

- **Merge-lane only.** `pr-handoff` is per-PR human opt-in, so the lane already
  holds authority over exactly this PR — strictly less than the merge it is
  declining to perform. There is no recovery-triggered fan-out over open PRs;
  see mybd-uncb7 for why that was rejected.
- **Skipped under `--base-fix`.** Being behind a red base is expected of the PR
  that fixes it, and a full CI cycle of delay is what stop-the-line cannot pay.
- **Budgeted per lane, not per head** (`pr_babysit_freshen`, default 3) —
  update-branch moves the head itself, so a head-scoped counter would never
  bind. Exhausting it parks the bead `merge-blocked`, as does a refusal from
  GitHub (conflict, or no write access to a fork branch). The attempt is
  reserved *before* the call, so a crash spends it rather than risking a push
  every pass.
- **Fails closed, but not forever.** An unreadable comparison, base activity, or
  check timestamp retains the bead under patrol rather than merging —
  could-not-ask is not permission. After 10 consecutive unreadable passes it
  escalates to `merge-blocked` (`freshness-unavailable-persistent`), matching
  the unreadable-checks budget: a rollup that carries no timestamps at all never
  recovers on its own, and a retained-forever lane is claimed and therefore
  invisible to `bd ready`. A readable pass clears the counter.

All three stale-green blocks are **durable**: `stale-green-persistent`,
`stale-green-update-failed` and `freshness-unavailable-persistent` are
deliberately absent from the re-arm sweep's class whitelist, because each means
a human has to choose (rebase by hand, resolve the conflict, ask the
contributor, fix whatever makes the freshness unreadable, or merge anyway). The
re-arm sweep does clear `pr_babysit_freshen` and `pr_babysit_freshun` alongside
the other retry counters when it restores a lane blocked for some *other*
reason; an agent re-arming a stale-green block by hand should clear them too, or
the lane re-blocks on its first pass.

Knobs: `PR_BABYSIT_FRESHEN=0` disables the guard entirely (restoring the
pre-2026-08-01 behaviour); `PR_BABYSIT_FRESHEN_LIMIT` changes the budget.

Sanity-checked against the live queue at implementation time: the one armed
lane (gastownhall/beads#5227) was 5 commits behind `main` with its newest check
started 3 minutes *after* the base tip — behind, freshly tested, merged
normally. The guard is meant to be quiet.

**close-when-quiet** — for a decline disposition an agent wants to offer
rather than execute immediately. The agent posts the disposition comment
itself; `pr-close-handoff` does not post anything upstream. It only labels
the bead `close-when-quiet` and records `pr_close_after` (RFC3339, now +
`--after` hours, default 72), `pr_close_head`, `pr_close_reason`, and
`pr_close_since` (the clock start, used for the engagement check). The patrol:

- fails closed on unreadable/malformed GitHub or bd data — never closes on
  data it can't trust; a shared retry counter caps this at 10 consecutive
  passes before escalating to `close-blocked` (label + unclaim)
- closes the bd bead without touching the PR if it's already MERGED/CLOSED
  upstream
- treats any post-disposition comment/review, or a head SHA that no longer
  matches `pr_close_head`, as contributor engagement: removes
  `close-when-quiet`, reopens the bead, and unclaims it so `bd ready`
  surfaces it back to a human — no per-author attribution is attempted, so
  any activity after `pr_close_since` counts as engagement
- once the window elapses with no engagement, runs
  `gh pr close <n> --comment <pr_close_reason>` and closes the bd bead

A PR can only be in one lane at a time: `pr-close-handoff` refuses to hand
off a bead that already carries `merge-when-green`, and the patrol leaves a
bead alone (logged, untouched) if it somehow carries both labels.

**base-red** — not a lane you hand off to; a hand the patrol raises for
itself. Agents run `PR_PREFLIGHT_BLOCK_RED_BASE=1`, so a red base branch
blocks every `merge-when-green` lane behind it. That block is correct and the
lanes are deliberately left armed — no lane caused it, and blocking them would
burn N re-arms on one condition. But a red base was also the only persistent
condition with no counter and no escalation, so it could stall the whole queue
indefinitely in silence (2026-07-28: upstream main red ~8h, seven lanes
parked, 39 patrol passes to the log alone).

The patrol now tracks each red base in
`${XDG_STATE_HOME:-~/.local/state}/pr-babysit/red-base` (one TAB-separated
`key<TAB>passes<TAB>first_seen<TAB>bead` record per `repo@branch`; unparseable
records are dropped and logged rather than trusted) and after
`PR_BABYSIT_RED_BASE_LIMIT` consecutive passes (default 5, ~1h) creates one
P0 bead labelled `base-red` naming the base, the failing run, and how many
lanes are parked. Follow-up notes are rate-limited to one per 10 passes; the
per-pass record lives in the patrol log.

Everything here is keyed per base: a green sighting of `main` never withdraws
an escalation for `release-1.2`, and only a *positively observed* green base
of the same identity closes the bead. An empty queue is absence of evidence,
not recovery.

**Standing base watch.** Sightings originally came only from lanes running
`pr-preflight`, which meant the detector watched a base only while something
was already waiting to merge onto it — and went silent the moment the queue
drained. That is the worst-case ordering, not a rare one: a red base parks
lanes, they all merge when it recovers, and the next breakage lands into an
empty queue unobserved. It happened on 2026-07-31 — main recovered at 08:18Z,
14 parked lanes merged, main broke again 34 minutes later and stayed red ~13h
with no bead (bead mybd-sopqb).

So each pass the patrol also probes every base in `PR_BABYSIT_WATCH_BASES`
(space-separated `owner/repo@branch`, default `gastownhall/beads@main`;
set it empty to disable) with one `gh run list` per base — still zero model
tokens. The verdict deliberately mirrors pr-preflight's: newest *decisive*
completed run per workflow, so cancelled/superseded runs carry no signal and
one green workflow finishing last cannot mask a red one. Three outcomes, and
the third is not the second — red raises a sighting, green is recovery
evidence, and **unreadable or undecidable produces no sighting at all**;
silence is never recorded as green.

A cross-vendor review argued the green verdict should be tied to the branch's
current head SHA rather than to the newest decisive run per workflow. It is not,
deliberately: workflows run on different commits (a docs-only commit may run one
workflow and nothing else), so a per-head verdict would let a green run at a
newer commit hide a red test workflow at an older one — the exact masking
upstream's per-workflow rule was written to prevent (gastownhall/beads#4630).
The residual risk it correctly identifies is window truncation: the run list is
shared across all workflows on the branch, so a chatty bot workflow could push
the one decisive red run out of view and leave an apparent green. The watch
reads 60 runs rather than preflight's 30 for that reason, and counts
`startup_failure` as red alongside `failure`/`timed_out`/`action_required`.

**Known blind spot (bead mybd-msll).** Both the watch and pr-preflight judge a
base by *the base's own* workflow runs. A job that exists only in the PR
workflow never runs on `main`, so a gate that is broken for every PR can sit
behind a "base is green" verdict — five PRs were reported green-based in the
Contract corpus job that only exists in `pr.yml`. The watch inherits this by
construction, deliberately: it mirrors preflight so the two cannot disagree.
Catching that class needs a different signal ("the last K completed PR-workflow
runs, across distinct heads, all failed") and arguably a different bead than
`base-red`, since "the PR gate is broken" is not "main is broken".

The watch feeds the same counter and the same one-bead-per-base escalation, so
a red base escalates after the same wait with zero lanes behind it, and the
bead says `no merge lanes parked` instead of claiming lanes it does not have.
It also closes the old hole in the other direction: recovery no longer needs a
surviving lane to observe it. If a lane and the watch disagree within one pass,
red wins and the disagreement is logged — a spurious extra pass costs nothing,
a spurious close reopens the blind spot.

Nothing about this lane can block, unclaim, or otherwise mutate a merge tail —
it only ever creates, notes, or closes its own `base-red` bead.

**review-needed** — a detector, not an executor: it makes sure PR reviews
*get queued*, on first open and on follow-up activity; agent sessions consume
the queue via `bd ready`. The patrol sweeps open PRs in
`PR_BABYSIT_REVIEW_REPO` (default `gastownhall/beads`) each pass against
per-PR baselines in `${XDG_STATE_HOME:-~/.local/state}/pr-babysit/review-sweep.state`
(tri-drift pattern; the first pass seeds silently, so activation never floods
`bd ready` with the pre-existing backlog — that is a one-time manual sweep,
bead mybd-88rdq). Queue-worthy events:

- a PR opened since the last pass (unless authored by a self login)
- a draft flipped to ready for review (drafts are otherwise ignored, with
  their baseline kept current so the flip itself is the event)
- a moved head, unless every attributable new commit is authored solely by
  self logins (`PR_BABYSIT_SELF_LOGINS`, comma-separated, default `maphew`)
- new comments/reviews, unless all post-baseline activity is by self logins —
  without this filter the lane would re-queue every PR we just reviewed

On an event the lane adds `review-needed` to an existing open unclaimed bead
for that PR (either ref form, `gh:owner/repo#N` or `gh-pr-N`), or creates one
(ref `gh-pr-N` for the default repo so tri-pull's dedup sees it; capped at
`PR_BABYSIT_REVIEW_CREATE_LIMIT`/pass, default 10, deferrals logged). It
never touches claimed beads or beads in the other two lanes, never posts
upstream, and closes unclaimed queue entries whose PR merged/closed upstream.
A baseline only advances after its event is durably represented in bd, so
unreadable gh/bd data means retry next pass, and attribution failures err
toward queueing a review rather than staying silent. Reviewers just close the
bead when done — later activity re-queues automatically. Disable with
`PR_BABYSIT_REVIEW=0`.

Install the timer once with `scripts/install-pr-babysit` (systemd user unit,
fires every 12 minutes); patrol log at
`${XDG_STATE_HOME:-~/.local/state}/pr-babysit/patrol.log`.

## solo-sweep (unattended model lane)

```bash
scripts/solo-sweep --dry-run              # show the theme it would sweep, and the prompt
scripts/install-solo-sweep --days 2       # arm for a 2-day trial window
scripts/install-solo-sweep --days 9 --reset-runs --max-runs 36
scripts/install-solo-sweep --disarm       # stop now
scripts/test-solo-sweep [--live]          # rail tests; --live also probes the deny rules
```

The other three lanes (`pr-babysit`, `verify-babysit`, `tri-daily`) are
deliberately **zero-token** — they only act on facts GitHub or the test suite
already decided. `solo-sweep` is the exception: it spends model tokens on
judgment work while the owner is away. Every rail below exists because nobody
is watching a run of it.

**What it does.** One fire = one theme sweep over the `tri:claim` issue-stub
backlog, following the procedure in
`reports/2026-07-26-triclaim-drain-strategy.md`. Output is a report under
`reports/`, plus per-stub bead notes carrying a **proposed** disposition and
the label `solo-sweep:proposed`. Review the batch on return with
`bd list -l solo-sweep:proposed`.

### Why it is an allowlist

The first draft used a permission **denylist**. Two independent reviewers (a
Claude reviewer and `codex-agent reviewer`) broke it within minutes, and the
bypasses were verified live, not theorised:

| Bypass | Why the denylist missed it |
|--------|---------------------------|
| `/usr/bin/git …` | `argv[0]` is not canonicalised, so every deny entry was one path prefix from inert |
| `python3 -c "open(p,'w').write(…)"` | interpreters are not `Edit`, so `Edit()` denies never saw the write |
| `scripts/pr-babysit` | one allowed command that merges **and** closes PRs internally |
| `bd update <id> --status closed` | closes an issue without the word `close` |
| `bd update <id> --add-label merge-when-green` | does not act — it makes the *patrol* merge on the lane's behalf |
| `codex exec -s workspace-write` | a second runtime with no profile at all |

The lesson generalises: a denylist enumerates what you thought of, and this
lane runs for a week unsupervised. So the profile now **allowlists** a small
read-only vocabulary under `--permission-mode default`, where anything
unmatched needs approval and headless has nobody to give it.

That last row is the subtle one and it shaped the design: the lane cannot be
contained by denying *verbs*, because other automation reads bd state as
instructions. Hence `scripts/solo-bd`.

### Rails

| Rail | Mechanism |
|------|-----------|
| publishes nothing | nothing that writes to GitHub is on the allowlist; `TRI_ALLOW_UNATTENDED_POST` unset; read-only `GH_TOKEN` |
| closes nothing | raw `bd` writes are denied; the only write verb is `scripts/solo-bd`, which is append-only |
| cannot delegate an action | `solo-bd` rejects `merge-when-green`, `close-when-quiet`, `triaged`, `review-needed` and friends, so it cannot ask another lane to act for it |
| merges nothing | no merge path exists in the allowlist, and the token cannot merge |
| never commits | no git write verb is allowed; the **wrapper** commits exactly one file, through a scratch index, via `commit-tree` + `update-ref` with the expected old SHA |
| cannot rewrite its own rails | `Edit` is allowed only under `reports/`, and interpreters are denied |
| expires | refuses to start without `$STATE/until`, past it, or when less than an hour of window remains |
| bounded | run cap, per-run stub cap, `timeout 45m --kill-after 2m`, `--max-budget-usd`, `flock` |
| fails closed | dirty tree, wrong branch, moved HEAD, missing report, or zero progress all **park** the lane rather than commit |

`scripts/test-solo-sweep --live` re-runs every bypass in the table above as a
regression test, reading the harness's own tool-result verdicts rather than the
model's prose. **Re-run it after any Claude Code upgrade** — the boundary is a
property of the harness, not of this repo.

The permission profile is still not the last word. The rail that holds even if
a future release changes permission semantics is credential scope: a
**read-only** fine-grained PAT at
`${XDG_STATE_HOME:-~/.local/state}/mybd/solo-sweep/gh-token-readonly` (mode
0600), exported as `GH_TOKEN`. It is **mandatory**: the runner refuses to start
without it, and the installer refuses to arm a window longer than 3 days
without it. `SOLO_SWEEP_ALLOW_WRITE_TOKEN=1` overrides the runner check for a
short supervised trial only.

The timer is `Persistent=false` on purpose — unlike the zero-token lanes, we
do not want a queue of catch-up **model** runs firing after a suspend.

Kill switch: `touch ${XDG_STATE_HOME:-~/.local/state}/mybd/solo-sweep/disabled`
(or `--disarm`). Log: `…/mybd/solo-sweep/sweep.log`, which carries each run's
theme, credential mode, and the model's closing summary. Full transcripts land
in `…/solo-sweep/transcripts/`.

A run that times out, exits non-zero, writes outside its one report path, or
proposes nothing **parks the lane**: it commits nothing and writes the reason
into the kill-switch file, so the failure stops the week rather than repeating
28 times. Re-arm with `install-solo-sweep --days N` after reading the
transcript.

Not addressed, and worth knowing: the model still runs in the main checkout
with the owner's filesystem visible, so the boundary is Claude Code's
permission layer rather than an OS sandbox. Both reviewers recommended a
disposable restricted checkout as the real fix; that is
[mybd-hs98a](../reports/) follow-up work, not shipped here.

## tri-resume (cross-machine)

```bash
scripts/tri-resume          # show all in-flight PR reviews
scripts/tri-resume --json   # machine-readable
```

Lists every bd issue with `status=in_progress` and a `gh-pr-*` external_ref:
bd-id, PR#, whether worktree exists on *this* machine, age of the review note,
last checkpoint or title. Use it when you sit down at any machine to pick up
where you (or another machine of yours) left off.

## tri-checkpoint (graceful machine switch)

```bash
scripts/tri-checkpoint <id> "stopped at concerns section, need to verify test coverage"
scripts/tri-checkpoint #3482
```

Appends a checkpoint note to bd, pushes bead state with `bd dolt push`, commits
review-note changes (if any), `git pull --rebase`, `git push`. Worktree
branches are local-only by design; if you've made commits in the worktree you
want to keep, push them manually first (e.g., to a `wip/` branch on your fork).

## tri-submit (finalize)

```bash
scripts/tri-submit <id> --approve
scripts/tri-submit <id> --request-changes      # last resort, warns
scripts/tri-submit <id> --comment
scripts/tri-submit <id> --approve --dry-run    # preview the exact body
scripts/tri-submit <id> --comment --max-words 250   # deliberate budget raise
```

Posts `pr-reviews/<NNNN>.post.md` (NOT the full analysis note) as a
`gh pr review --<verdict>`, then calls `tri-close` to close bd + apply
upstream `triaged`. Guards, in order:

- refuses if `<NNNN>.md`'s `Verdict:` line is still `TBD`
- refuses if `<NNNN>.post.md` is missing, empty, or only comments
- fails the body over the word budget (default 150; `TRI_POST_MAX_WORDS`
  or `--max-words` to override deliberately)
- runs the GitHub body lint
- shows the exact body and requires typing `post` at the terminal
  (`/dev/tty`), so unattended agents cannot post text upstream;
  `TRI_ALLOW_UNATTENDED_POST=1` is the owner-only escape hatch

## tri-report (observability digest)

```bash
scripts/tri-report                    # last 7 days, opens in browser
scripts/tri-report --today            # last 24h
scripts/tri-report --days 14          # custom window
scripts/tri-report --since 2026-04-01 # explicit start date
scripts/tri-report --weekly-metrics   # markdown weekly metrics report
scripts/tri-report --no-open          # write file, don't launch browser
scripts/tri-report --out report.html  # custom output path
```

Generates a self-contained HTML digest (no JS, plain CSS) of triage workflow
activity over a period. Sections:

- **What landed** — closed issues with their *why* (description excerpt),
  the *delivered* (close reason), and any linked commits matched by id mention
- **In flight** — `status=in_progress` items with description + latest checkpoint note
- **Came in** — newly created stubs in the window
- **Backlog snapshot** — open issues by priority
- **Activity timeline** — collapsible chronological event log from
  `.beads/interactions.jsonl`

Sources: `bd list`, `bd show --json` (description + notes + external_ref),
`.beads/interactions.jsonl` (timestamped reasons), `git log` (commit subjects).

Browser launch chain: `xdg-open` → `wslview` → `open` (macOS) → on WSL,
`cmd.exe /c start` → `msedge.exe` direct → Python `webbrowser` module.
Falls back to printing the `file://` URI if all fail.

Why Python (vs the bash tri-* scripts): this one templates rather than
orchestrates — date math, HTML escaping, multi-source synthesis. Stdlib only.

`--weekly-metrics` switches from HTML digest to a Markdown report focused on:

- new triage stubs created in the window
- triage stubs closed in the window (excluding `tri-sync` auto-closures whose
  close reason starts with `upstream `)
- median age of remaining open stubs
- P0/P1 leakage: open high-priority stubs older than 48 hours

The default window is still 7 days, so a plain weekly run is:

```bash
scripts/tri-report --weekly-metrics --out /tmp/tri-weekly.md
```

## Existing artifacts

- `_working_on/upstream_pr_triage.md` — manual T1–T5 ranking with scoring rubric
- `_working_on/pr-reviews/NNNN.md` — per-PR detailed review notes (now scaffolded by tri-review)

## bd-version (pinned-release runner)

```bash
scripts/bd-version 1.0.4 version   # downloads + caches bd v1.0.4, then runs it
scripts/bd-version v1.0.4 show mybd-123
```

Fetches a specific released `bd` binary from `gastownhall/beads` GitHub
releases (via `gh`), caches it under `${BD_VERSION_CACHE:-~/.local/share/beads/bin}/<version>/`
(outside any repo, shared across worktrees), and `exec`s it. Use this to open
a beads DB with the exact version that wrote it, so a newer `bd` on PATH
doesn't trigger an unwanted schema migration. Repeat runs for a version
already cached skip the download.

## Generic beads stealth setup

`bd-stealth-init` initializes beads for any project without putting `.beads`,
hooks, or beads commits in that target project. It stores issue data in a
dedicated external git repository and can sync through that repo's remote.

```bash
cd ~/src/some-project
/var/home/matt/dev/mybd/scripts/bd-stealth-init --remote git@github.com:me/some-project-beads.git
```

Use `--set-envrc` only when the target project should persist the `BEADS_DIR`
export in `.envrc`.

## Configuration (env vars)

- `TRI_UPSTREAM` — upstream repo (default `gastownhall/beads`)
- `TRI_WORKTREE_BASE` — worktree parent dir (default `~/dev/mybd-tri`)
- `TRI_BD_MAIN` — canonical upstream checkout (default `<project>/bd-main`)
- `TRI_REVIEWS_DIR` — review notes dir (default `<project>/_working_on/pr-reviews`)
- `TRI_POST_MAX_WORDS` — word budget for upstream post bodies (default `150`)
- `TRI_ALLOW_UNATTENDED_POST` — set to `1` to skip tri-submit's interactive
  confirmation; owner-only, for deliberate automation

## Layer 2

Shipped:
- daily unattended wrapper + cron installer (`tri-daily`, `tri-install-cron`)
- weekly triage metrics (`tri-report --weekly-metrics`)
- smart classifier (auto-priority from rubric)
- `bd close` hook → upstream label
- epic/batch grouping for stacked PRs

Still open:
- JSONL normalization churn follow-up (likely upstream exporter work, not local workflow)

See `bd ready`.

(close-on-merge sync shipped as `tri-sync`.)
