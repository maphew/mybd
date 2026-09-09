# Red-base prevention lanes: detect it, act on it, and stop lying about it

**Session:** 2026-07-31 (Claude Opus 5, high reasoning, on behalf of maphew)
**Branch:** `feat/ci-lane-gaps`
**Beads:** mybd-sopqb, mybd-01yzj, mybd-eotx (worked) · mybd-msll (specced) ·
mybd-ks4vq, mybd-fbr7z (discovered)

A parallel session was fixing the CI that was red *right now*. This session was
asked for the other half: tooling so it stops recurring. The starting question
was "what ready work is about CI" — 16 of 375 ready beads are, and four of them
are the same story told from four angles.

## The story the four beads tell

Upstream main went red at 08:52Z on 2026-07-31 and stayed red ~13h. The owner
noticed by eye. The morning outage the same day *was* caught automatically
(mybd-xm6rc, raised 06:05Z, auto-closed 08:45Z on recovery), which is what makes
the miss sharp: the detector worked while lanes were parked and went silent the
moment they drained.

That is not a coincidence, it is the mechanism. Red-base sightings came only
from merge lanes running `pr-preflight`, so a base was watched only while
something was already queued to merge onto it. The ordering that breaks it is
the *normal* one:

1. base goes red → lanes park behind it
2. base recovers → all 14 parked lanes merge → queue empties
3. base breaks again 34 minutes later → **nobody is looking**

And when someone finally did look and produced the fix (gastownhall/beads#5204),
the automation could not land it: `pr-handoff` hands the PR to a patrol that
refuses to merge onto a red base, and the base cannot go green until that PR
merges. The one PR the project most wanted landed was the one PR the automation
categorically could not land.

So: **it cannot see the problem, and if it could, it cannot act on it.** Those
are mybd-sopqb and mybd-01yzj.

## What landed

### 1. A standing base watch (mybd-sopqb)

Each pass the patrol now probes every base in `PR_BABYSIT_WATCH_BASES` (default
`gastownhall/beads@main`) with one `gh run list` — still zero model tokens,
independent of whether any lane is armed. It feeds the existing counter and the
existing one-bead-per-base escalation, so a red base with zero lanes behind it
escalates after the same ~1h wait, and the bead says `no merge lanes parked`
rather than claiming lanes it does not have.

It also closes the hole in the *other* direction. The old bead text contained an
admission:

> if every parked lane is merged, blocked or closed while the base is still red,
> no lane remains to make that observation and this bead will stay open until a
> human closes it.

With a standing watch, recovery no longer needs a surviving lane to observe it.

Three outcomes, and the third is deliberately not the second: red raises a
sighting, green is recovery evidence, and **unreadable or undecidable produces
no sighting at all**. Silence is never recorded as green — that is the exact
failure this lane exists to prevent.

### 2. `pr-handoff --base-fix` (mybd-01yzj)

The flag records `pr_babysit_base_fix=<repo>@<branch>`, naming the base this PR
remedies. The patrol then merges on the PR's **own** green checks while that
base is red.

Narrow by construction, and the narrowness is the design:

- the recorded key must match the base preflight actually reports red
- that red base must be preflight's **sole** objection — a conflict, draft
  state, changes-requested, or even a transient merge state alongside it still
  holds the lane
- the PR's own checks were already required green to reach preflight at all
- on a green base the flag does nothing, so it cannot decay into a standing
  merge licence
- the patrol never writes the key itself; setting it is a reviewed act

The rule is also now written down in PR_MAINTAINER_GUIDELINES "Base-Branch
Health", which was the bead's alternative acceptance criterion. Both were cheap,
and the written rule is what stops the next agent rediscovering the deadlock.

### 3. Say "awaiting workflow approval" once (mybd-eotx)

GitHub's first-time-contributor gate parks fork workflow runs in
`action_required`, so no checks exist at all and `gh pr checks` fails exactly
like a transient API error. Ten blocked lanes logged the same unreadable line
every 12 minutes for days while 16 fork PRs (90 runs) waited on an approval
nobody knew was owed. The sweep now distinguishes the standing condition from a
real API error and says so once per head — on the bead, where `bd` surfaces it,
not only in a log nobody reads. Approving is deliberately still manual: running
fork code in CI needs someone to diff the workflow files first.

## What the cross-vendor review changed

A `codex-agent reviewer` pass (gpt-5.6-sol, high) on the base watch found six
things worth fixing, and one worth arguing about.

Applied: `startup_failure` counts as red (a newest `startup_failure` was
discarded, letting an older success read as green); unnamed runs get their own
group instead of collapsing into one bucket where a single green hides a red;
`WATCH_BASES` is read into an array rather than glob-expanded against the
checkout before validation; both directions of a lane-vs-watch disagreement are
logged.

The most valuable finding was about dedup. The code's comments already claimed
"the bead — not the state file — is the record of truth after state loss", but
the metadata lookup only ran during a *red* sighting. Two silent failures lived
there: a stale bead id left in state after someone closed the bead suppressed
re-escalation forever, and a bead created just before a state write failed
became unreachable and would have outlived the outage. The remembered id is now
reconciled against `bd` every pass — with a guard the review did not ask for:
when the metadata lookup misses but `bd show` says the bead is open, the id is
**kept**. Forgetting it there would mint a new P0 every escalation window, which
is a worse failure than the one being fixed.

**Not applied:** tying the green verdict to the branch's current head SHA.
Workflows run on different commits — a docs-only commit may run one workflow and
nothing else — so a per-head verdict lets a green run at a newer commit hide a
red test workflow at an older one, which is precisely the masking upstream's
per-workflow rule was written to prevent (gastownhall/beads#4630). The real
residual the review identified is window truncation: the run list is shared
across all workflows on the branch, so a chatty bot workflow can push the one
decisive red run out of view. The watch reads 60 runs rather than preflight's
30 for that reason. The reasoning is recorded in `scripts/README.md` so it is
not relitigated.

The test harness's fake `bd` now persists created beads and marks closed ones
closed, so the patrol's own dedup path is what the tests exercise rather than a
stub that could never return a duplicate. The pre-existing "red base raised a
duplicate bead" assertion only became meaningful at that point.

A second review pass on `--base-fix` (the first covered only the watch) found
four real defects, one of which would have made the flag useless and three of
which would have let it merge something it should not:

- **It could never have merged at all.** The audit note was appended *before*
  the pre-merge authorization check, which compares the bead against the queue
  snapshot — notes included. Every base-fix pass would have revoked its own
  authorization and logged `authorization-mismatch`. The note is now written
  after the merge. This one was caught in parallel by reading the code, and it
  was invisible to the tests because the fake `bd` ignored `--append-notes`.
- **An incomplete preflight could authorize the exception.** Preflight prints
  base health early and keeps working; a run that died afterwards presents a
  partial block list, and "the red base is the only objection" becomes unproven.
  The exception now requires exit 1 *and* preflight's terminal `Result: BLOCKED`
  line.
- **A PR could be retargeted after authorization.** `--match-head-commit` pins
  the head, not the target, so a same-head retarget could land the PR on a base
  the flag never named. The final re-read now pins `baseRefName` too.
- **A claimed base-red bead read as absent.** `bd update --claim` moves a bead
  to `in_progress`, and the dedup lookup filtered on `status == "open"` — so the
  moment an agent picked up an outage, the patrol would mint a duplicate P0 next
  window, or drop the state record on recovery and orphan the claimed bead. This
  one predates today's work but the new reconciliation made it sharper.

Accepted, not fixed: base-fix provenance is procedural. The patrol trusts a
matching metadata key without proving `pr-handoff` wrote it. No other automation
here writes that key and upstream PR content cannot inject it, but raw `bd
update` or import access could pre-seed one. Recorded in `scripts/README.md`.

The pattern worth naming: **three of these five defects were hidden by unfaithful
test doubles.** The fake `bd` ignored note appends, did not persist created
beads, and did not mark closed ones closed; the fake preflight omitted the
terminal line the real one always prints. Each stub was "good enough" until a
guard depended on exactly the behaviour it elided. The doubles are faithful now,
and each fix was confirmed by injecting the bug back and watching the suite go
red.

## What was found on the way, and matters more than it looks

**The bisect lane has never run.** `scripts/systemd/verify-babysit.service` in
git carries two `ExecStart` lines — `verify-next`, then `bisect-next`. The unit
actually installed on this machine carried only the first. Corroborating
evidence: mybd-xm6rc still carries `bisect_state=queued` with no culprit note,
and no bisect state directory exists at all.

So AGENTS.md's claim that a base-red bead "often arrives pre-diagnosed" has been
false in production for a deployment reason, independent of whether
`scripts/bisect-next` works. Fixed this session by re-running
`scripts/install-verify-babysit`; the unit now carries both lines.

`pr-babysit.service` had drifted too (Description only — `ExecStart` matched, so
harmless, but the same silent mechanism). Two of two units checked had drifted.
Nothing here is self-correcting, which is bead **mybd-fbr7z**: a tracked
template edit looks landed in git while the machine keeps running the old
behaviour, and the failure is invisible *precisely because git says the feature
exists*.

**`scripts/test-bisect-lane` fails on main** (`state=failed`, no culprit),
verified in a clean detached worktree so it is not contamination — bead
**mybd-ks4vq**. With the unit now wired, this is the only thing left between a
raised base-red bead and a pre-diagnosed one.

## What was specced but not built

**mybd-msll** — base health is judged from the base's *own* workflow runs, so a
job that exists only in the PR workflow can be broken for every PR behind a
"base is green" verdict. The new watch inherits this by construction, and that
is documented rather than hidden. The proposed detector ("the last K completed
PR-workflow runs, across distinct heads, all failed") is recorded on the bead,
along with the design question that should be settled first: this is arguably
not a `base-red` bead at all, since "the PR gate is broken" and "main is broken"
want different remedies and different text.

## Honest assessment

The two fixes that landed close a loop that was genuinely open: the patrol can
now see a red base with nothing queued, and can land the fix for it without a
human noticing the deadlock. Both were verified against the live failure — main
was red for ~1.5h during this session with zero detection, exactly reproducing
mybd-sopqb, and the probe's jq run against real data correctly reported it red.

What is *not* verified is an end-to-end escalation in production; that happens
on its own within an hour of this landing, and the bead it raises will be the
proof. The `--base-fix` path has never been exercised against a real PR — its
guards are covered by eight hermetic cases, but the first real use deserves a
human watching it, not least because one review found it would not have worked
at all.

The unglamorous finding is probably the most valuable one: a lane can be
correct, tested, documented, merged — and simply not installed.
