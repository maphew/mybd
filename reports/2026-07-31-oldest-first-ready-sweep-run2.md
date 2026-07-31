# Oldest-first sweep of `bd ready`, run 2 — 2026-07-31

**Session:** Claude Code, opus-5, high reasoning, on behalf of maphew.
**Brief:** work `bd ready` autonomously from the oldest end until dry or genuinely
blocked; a parallel agent worked the newest end. Check nothing is already covered
by a branch or PR before claiming. Worktree + branch + tests + PR per task. No
merging, no product decisions, no history rewriting.

Three other sessions were live: one on the red-`main` P0, one draining `bd ready`
newest-first, one adjudicating the solo-sweep proposals *outside* `bd ready`.

## Outcome

| PR | Bead | What |
|----|------|------|
| [#5202](https://github.com/gastownhall/beads/pull/5202) | mybd-itgj | JSONL import skips invalid records instead of discarding the whole file |
| [#5203](https://github.com/gastownhall/beads/pull/5203) | mybd-b8ht | `bd doctor` diagnoses a dangling `core.hooksPath`; uninstall clears `beads.role` |
| [#5205](https://github.com/gastownhall/beads/pull/5205) | mybd-cjcpt | `TestEmbeddedInitConcurrent` no longer requires that a racer lost the race |

All three were reproduced on `main` first — each has a recorded fail-on-`main`
observation, not an argument that it would fail. **None was armed for merge** —
the brief said don't merge, so `pr-handoff` was deliberately not run. They need a
human or a later session to arm or merge them.

`make test` has **passed** for #5203 (`b079684b0`, exit 0). #5202 and #5205 are
queued in the local verifier.

One bead closed by evidence (mybd-yc8c), one follow-up filed (mybd-v789f), two
beads corrected where the queue was actively misleading (mybd-tgdx, mybd-isc6).

## The oldest band is still triage residue — and that is now a two-run finding

Yesterday's run of this same brief
(`reports/2026-07-30-oldest-first-ready-queue-sweep.md`) concluded that the oldest
band of `bd ready` is triage residue rather than backlog. Working it again a day
later reproduced that result exactly: of the ~15 stubs older than 2026-07-17 that
are not `human`-labelled, **two** were actionable, and both are in the table
above. The rest re-confirmed as blocked on a competing PR, an unavailable reproduction,
or an owner contract decision — and in most cases their own notes already said so.

Worth stating plainly because age ordering keeps implying the opposite: **the
oldest items look like the most neglected work when they are in fact the most
deliberately deferred.** A third run of this brief against the same band should
expect roughly the same yield, which is an argument for the queue carrying a
"deferred, do not re-derive" marker rather than for running the sweep again.

## What made the two live ones different

Both had a solo-sweep flesh-out note from the last few days that had already done
the code archaeology and written acceptance criteria. That is the tell: **a stub
whose most recent note names specific functions and specific unfixed behaviour is
work; a stub whose most recent note names a decision is not.** Neither of the two
needed re-triage, only implementation.

## mybd-itgj — the failure mode the fix could have introduced

The reported bug: one record with `"status":"verify"` aborted an entire JSONL
import. Reproduced on `main` before touching anything — three records, one bad,
**zero** imported, including the two good ones.

The fix pre-validates per record before the batch reaches storage, using
`issueops.PrepareIssueForInsert` — the same function the create path calls first,
before it issues any SQL for that row.

The interesting part is not the fix, it is what pre-validation risks. Validating
twice means that if the two validations ever disagree, the pre-filter **silently
drops records the writer would have accepted** — strictly worse than the bug being
fixed. The obvious way to get that wrong is custom statuses and types, which live
in the database, and which the reporter's `verify` value is an instance of.

So the pre-filter reads the configured vocabulary first and declines to run at all
if that read fails. Checked empirically rather than by reading:

```
$ bd config set status.custom verify
$ bd import in.jsonl
Imported 3 issues from in.jsonl        # all three, including "status":"verify"
```

Same file, same binary, opposite outcome from the repro. Had I trusted the code
reading, the natural implementation — validate against built-ins — would have
passed review and quietly eaten every custom-status record in every import.

**A pre-existing test also caught a scope error I was about to make.**
`TestImportFromLocalJSONL/invalid_JSON_returns_error` pins that the *restore*
paths hard-fail on unparseable JSON. My first pass made everything skip, which
would have let `bd bootstrap` restore a truncated export minus its damaged part
and report success. The fix now distinguishes the two kinds explicitly
(`rejectKind`): a record the writer refuses is one bad row; a line that is not
JSON at all means the file is corrupt. That distinction is the one design decision
in the PR worth arguing with, so it is named in the code rather than implied.

## mybd-b8ht — the fix does not reach the people who reported it

Three suggested fixes in the upstream issue. One was already implemented and does
not help, because it only runs when you use the command the reporter did not use
(they did `rm -rf .beads/`, not `bd hooks uninstall`). The other two are in the PR:
a doctor check for a `core.hooksPath` that resolves to a missing directory, and
uninstall also clearing `beads.role` and failing loudly instead of warning.

Then, verifying end to end, `bd doctor` printed:

```
Note: 'bd doctor' is not yet supported in embedded mode.
```

Bare `bd doctor` is gated off in embedded mode by deliberate policy (#3794:
*"embedded support is enabled one subcommand at a time, each human-vetted — do not
lift this gate wholesale"*). **Embedded is the default, and it is the reporter's
mode.** The check written to diagnose their problem cannot reach them.

The gate's stated reason is that checks reach into the database layer. This one
does not — it shells out to `git` and stats a directory, like the whole git/hooks
family beside it. That makes it a candidate for the same per-subcommand vetting
that already admitted `--check=artifacts`, `--check=conventions` and
`--check=pollution`. But that is exactly the human-vetted call the policy comment
reserves, so it is filed (mybd-v789f) and stated prominently in the PR rather than
decided here. The uninstall and documentation halves are mode-independent and do
help embedded users today.

Two corrections to the builder output before commit, both from its own flagged
concerns and one of mine:

- **git's exit code 5 is not a reliable "key not set" signal.** It also means
  "refusing an ambiguous unset" on a multi-valued key. Treating them alike would
  report a clean uninstall with `beads.role` still set — the precise failure the
  change exists to prevent. Now the key is read before it is unset, with a test
  that sets it twice and asserts both the error and the surviving values.
- **The docs change told users to unset `core.hooksPath` unconditionally**, which
  contradicted the conservatism of the code in the same commit. `core.hooksPath`
  is not beads-only; husky uses it too. The doc now says to check the value first.

## mybd-cjcpt — the assertion was testing the machine, not the lock

Yesterday's sweep declined this one because our own unmerged #5093 touched the
same file. #5093 merged at 08:41 this morning, so it became pickable — and its
merge commit `6d81e1c73` is, separately, the prime suspect named on the red-`main`
P0 (mybd-5p561). Worth knowing for whoever is on that.

The test required that at least one of ten concurrent `bd init` processes came
back reporting contention. That asserts timing, not locking. If the winner
releases the gate inside the waiters' wait budget, the waiters block and then
**succeed** — zero lock errors, which is the *correct* outcome, because it means
serialization worked and nobody had to give up. The test therefore fails on
exactly the hardware where the gate is working best. #5093's EXCLUSIVE gate,
acquired before the embedded flock is ever attempted, makes that outcome more
likely, so the flake got worse this morning rather than better.

This host reproduces it directly. On `main` @ `9973e9628`, unmodified:

```
init_embedded_test.go:1984: expected at least 1 lock error, got 0
init_embedded_test.go:1994: 10/10 succeeded, 0/10 got lock error, 0/10 timed out
--- FAIL: TestEmbeddedInitConcurrent (11.10s)
```

**I wrote a deterministic replacement test and then deleted it.** Before
committing I went looking for where the contention path *should* be covered, and
found that #5093 had already added `TestInitGateBusyClassifiedAsLockContention`,
which holds the gate in-process and asserts the loser's output is classified as
contention — precisely what the racy assertion was approximating. So the change
is a deletion with no coverage gap, and it is really the other half of #5093
rather than a new idea. Had I not checked, this PR would have shipped a second
test doing the same job slightly worse.

## The rest of the queue: three parallel scouts, one useful lead

With the oldest band exhausted I had 56 stubs from the 2026-07-26 tranche left
and no cheap way to tell work from residue. I dumped their notes to a file once
(bd stays serial in this repo) and ran three read-only scouts over disjoint
slices, asking each to verify the *deciding* claim rather than repeat the note.

That produced exactly one lead I could act on, and it is worth recording that the
scouts were wrong in both directions on others:

- **mybd-ho2z** was returned ACTIONABLE with a precise `file:line`. The line was
  right, but `maybeAutoCommit` carries an explicit `"Skips SQL server modes; the
  server owns transaction commit lifecycle there"` — so "server mode ignores
  `dolt.auto-commit`" is at least partly deliberate, and deciding what `off`
  should even mean when the server owns the transaction is a semantics call.
  BLOCKED-DECISION, not actionable.
- **mybd-yc4vo** was returned ACTIONABLE with "fix test cleanup". The bead is
  about *production* daemons on inactive projects; the scout had latched onto
  yesterday's incidental observation of test leftovers. Fixing it needs a reaping
  policy — how long is "inactive" — which is an owner call.
- **mybd-cjcpt** was returned ACTIONABLE and was correct.

The lesson is the same one the delegation policy already states and this run
re-earned: a scout's verdict is a lead, not a finding. All three of the above
took under ten minutes each to confirm or overturn against the actual code, and
two of three would have been wasted work.

Two beads in the results — **mybd-sopqb** and **mybd-s9fcm** — are near-duplicates
of each other ("pr-babysit base-red lane is blind when no merge lanes are armed"
/ "...when the merge queue is empty"), filed 89 seconds apart at 21:58 and 22:00
tonight. They are the P0 session's spinoff from the same 13-hour-red-main
incident, so I left them alone rather than reach into a live lane, but they
should be collapsed into one.

## Queue-state corrections

- **mybd-yc8c — closed.** #4933 merged 2026-07-28 and the recursive-CTE cycle
  check is gone from `integrity.go`. I also closed out the one review gap the last
  sweep left un-audited: the `rows.Scan` cursor-advance concern does not survive
  contact with the merged code — `loadDependencyEdgePage` advances `*lastID` per
  row and returns a hard warning on a scan error, with a comment naming that exact
  failure mode. Left for the owner: upstream issue #4475 is still open with no
  cross-reference to #4933, an unlinked fix. Posting that is publication.
- **mybd-tgdx and mybd-isc6 — annotated, not claimed.** mybd-tgdx has sat as
  "needs a repro we don't have" since 2026-07-22. There is an open PR that fixes
  it: #4449, with a 288-line test file, untouched since 2026-07-05. The repro was
  never the blocker; the disposition is. mybd-j5ed already records the verdict
  (SPLIT-MERGE: land the Layer 1 URL guard, route the Layer 2 retry elsewhere —
  and Layer 2 is a real concern, it sleeps 70 seconds of wall clock inside
  `bd bootstrap`). Executing that means editing a contributor's branch or opening
  a superseding PR against their month-old untouched work. That is an
  outward-facing maintainer disposition, not an autonomous fix, so both beads now
  say so instead of repeating "needs repro". mybd-isc6 is the same PR under a
  different label; the two should be collapsed onto one lane.

## Not claimed, and why

- **mybd-alm2, mybd-s4h6, mybd-ad63** — all three need a contract decision
  (hierarchy output semantics; `--set-labels` vs add/remove precedence). Out of
  scope per the brief. mybd-ad63 additionally has a proposed consolidation into
  mybd-agf58 that is contingent on the owner accepting agf58 first, so the
  dependency edge the last sweep recommended was deliberately not added — adding a
  blocking edge would remove it from `bd ready` on the strength of an unaccepted
  proposal.
- **mybd-lvss** — blocked on destructive cross-clone untracking semantics plus a
  Docker-backed historical-Dolt fixture, and mybd-n0147 is the live engineering
  lane for the same root cause.
- **mybd-7cpd** — the surviving leaves are a Windows NTFS exec-bit problem
  (unverifiable on this host) and a `Signal(0)` fix that already has an open PR.
- **mybd-3wkx, mybd-m6q8, mybd-47ly** — need HQ-scale data, a customer
  environment, or a staged design and benchmark respectively.
- Everything labelled `human`, `tri:human`, `human-decision`, `tri:needs-info` —
  out of scope per the brief.

## What I noticed that isn't on any list

**`bd doctor`'s git/hooks checks are dead code for most users.** This is filed as
mybd-v789f, but it deserves saying beyond that bead: it is not one check that is
unreachable, it is the entire `CategoryGit` family — `Git Hooks`,
`Stale Legacy Hooks`, `Git Hooks Dolt Compatibility`, and now `Hooks Path` — none
of which touch the database, all of which are registered in `runDiagnostics()`,
which embedded-mode users never reach. Anyone writing a new doctor check today
will register it in the same place and it will have the same fate. That is a
structural fact about where checks live, not a property of any one check, and I
did not find it written down anywhere.

**`bd status add` silently does nothing.** While setting up the custom-status
verification I ran `bd status add verify`; it printed a `bd list` hint and exited
0 without adding anything. `bd status` is the database-overview command and takes
no such subcommand. The working form is `bd config set status.custom verify`. A
plausible-looking invocation exiting 0 while doing nothing is a small trap; I did
not file it, because I did not go back to confirm whether cobra is absorbing the
argument or whether something else is happening, and a bead asserting the wrong
mechanism is worse than none.

**`bd dolt push` rewrote a tracked config file, and my local `bd` is two weeks
old.** Closing the session, `git status` showed `.beads/config.yaml` modified:
`bd dolt push` had silently changed `sync.remote` from
`https://github.com/maphew/mybd.git` to `git@github.com:maphew/mybd.git`, in a
file that is tracked in git. I reverted rather than committed — this repo is
worked from Linux and Windows, and flipping the checked-in remote to SSH is a
cross-machine decision, not something a push should do on its own. Recorded on
mybd-uhpr, which covers the adjacent "adopts a remote without consent" symptom.

I then had to correct that note. I had written that this happened "with a bd
binary current as of this session"; it did not. The `bd` on `PATH` here has
mtime **2026-07-15**, and the PR that added the consent gate (#5188) merged
today at 16:41 — two weeks later. So the observation is evidence about a
pre-#5188 binary and says nothing about whether the fix works. The
`bd-binary-provenance` memory is what flagged this: `bd version` reports the
*workspace* HEAD, not the build commit, so it would have confirmed the wrong
thing. The binary mtime is the usable signal. Anyone re-testing that path must
upgrade `bd` first — and on this host, `bd --version` will lie to them about
whether they did.

## Handoff

- **#5202 and #5203 are open and unarmed.** Neither has a `merge-when-green` bead.
  Arming them is `scripts/pr-handoff <n> --bead <id>`.
- **`make test` is queued for both** (`mybd-itgj`, `mybd-b8ht`) in the local
  verifier; the `verify-babysit` timer drains one job per 15-minute fire, so
  results land after this session ends. `scripts/verify-status` is the check.
  Neither bead should be considered complete until its `verify_state` is `passed`.
- **`main` was red for the whole session** (11 migrate-mode tests, `workspacegate:
  acquiring .beads.gate.lock: context canceled`, since `d223edcb6`). Expect it on
  both PRs' CI; it is not from these changes. mybd-5p561 is the P0 and was claimed
  by the parallel session at 21:37Z.
- **mybd-itgj, mybd-b8ht and mybd-cjcpt are still `in_progress` and claimed**,
  deliberately — the work is not done until verification passes and the PRs
  land. `session-close-check` warns about this; the warning is correct and the
  state is intentional.
- **The local `bd` binary is from 2026-07-15** and predates several fixes that
  landed today, including #5188 and #5093. Worth upgrading before any session
  that tests remote-adoption or workspace-gate behaviour.
