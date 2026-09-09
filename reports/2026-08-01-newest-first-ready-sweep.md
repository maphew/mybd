# Newest-first `bd ready` sweep — 2026-08-01

Session brief: work the ready queue newest-first (a parallel session worked
oldest-first), check each candidate isn't already covered by a branch or PR,
worktree + branch + tests + PR per task. Don't merge, don't decide product
questions, don't touch history.

Four PRs opened, one of them merged by the patrol; one item stopped short with a
sharpened diagnosis instead of a fix. Five beads filed, three corrections made
to existing bead records, one memory.

---

## 1. The red base (P0) — diagnosed and cleared

`mybd-zbsg4` said `gastownhall/beads@main` had been red for five patrol passes
with no lanes parked, and the zero-token bisect lane had already given up with
`bisect_state=unreproducible`.

The bisect was never going to work, for a structural reason worth writing down:
**the failing job is `Test (macos-latest)` and the bisect oracle runs on this
Linux host**, so no bad commit can fail locally. A macOS-only red base burns a
bisect cycle and produces no signal.

Three tests were failing, all macOS-only, all downstream of the same two
properties of macOS `$TMPDIR` — it is `/var/folders/<hash>/T`, which is a
symlink to `/private/var/...` and is already ~48 bytes deep:

| test | cause | disposition |
|---|---|---|
| `TestCheckHooksPath_MissingBeadsManagedPath/absolute_.beads/hooks` | unresolved abs path string-compared against a symlink-resolved repo root | already fixed in #5210 (another session) |
| `TestDispatchDoesNotPolluteViperIssuePrefix` | ignore set keyed on one spelling of a path; `os.Getwd()` keeps the symlink, `BEADS_DIR` arrives resolved | **#5220** |
| `TestResolveServerModeUOWTopology_KeepsALiveSocket` | socket path 120 bytes vs a 104-byte `sun_path`; `bind(2)` returns `EINVAL` | **#5220** |

#5220 merged as `491d8872d`. All three fixes are on main; the bead self-closes
on the next green Main run.

### The part I got wrong, and what it cost

I checked coverage with `gh pr list` and `scripts/pr-preflight.sh` — **both of
which only see open PRs** — found nothing, and implemented the config fix.
An earlier session that same morning had already committed a better version of
it to `fix/config-ignore-set-symlink-resolve` (`738dd56f9`, 01:08): unpushed, no
PR, no worktree, invisible to every check I ran.

Theirs normalizes through a single `ignoredConfigKey` used by both insert and
lookup, and resolves the *directory* rather than the file, so a candidate path
whose leaf does not exist still keys consistently. Mine resolved the full path
and fell back to lexical on a missing leaf. I discarded mine, cherry-picked
theirs, and added the mirror-direction test on top.

Filed as memory `check-local-branches-not-just-prs`. The cheap check that would
have caught it:

```bash
git -C bd-main branch --sort=-committerdate --format='%(committerdate:short) %(refname:short)' | head -20
git -C bd-main log --all --oneline --since=3.days -- <path you are about to edit>
```

This is the same failure AGENTS.md already describes for unlanded coordination
branches, one repo over: there the cost is a lost report, here it is duplicated
implementation.

### Also flagged

`.github/workflows/main.yml` triggers on `push: branches: [main]` only, so the
`macos-latest` Test job **never runs on a PR**. Neither #5220 nor the PRs that
introduced these failures could observe them before merging. macOS-only
breakage is undetectable pre-merge by construction, and it lands as a red base
that then reads as "pre-existing failures" for everything opened behind it.
Filed as `mybd-5eacq` with four options and no recommendation — it is a CI-spend
call.

One recovery blocker found and reported rather than acted on: #5210 was green
and verified but **was never handed to the patrol** — `mybd-sb0sl` carried no
`merge-when-green` label and no patrol metadata, so nothing would have merged
it. It was claimed by another session, and the sweep rule is to stay out of
claimed lanes, so I noted it on `mybd-zbsg4` instead. It merged at 08:35.

---

## 2. `bd admin reset` deleting hooks it never installed — #5221

`mybd-n7j2z`. `isBdHook` decided whether reset may delete a git hook by scanning
the first ten lines for the substring `"beads"` — anywhere, in any context.

**The bead's own headline example is wrong**, and I checked rather than repeated
it: none of this repo's five `.githooks/*` files matches case-sensitively in the
first ten lines. The bead's attribution of the 2026-07-21 incident to this
mechanism is therefore unsupported by the evidence it gives. Corrected on the
bead.

The defect is real anyway, and there is a genuine in-tree case: **beads' own
tracked `.githooks/pre-commit`** says `# the beads section at the bottom must
run for non-Go commits too` on line 9. The old scan matched that comment and
would have deleted the whole hand-composed file — with no restore, because
`performReset` only renames `<hook>.backup` back, and a backup exists only for
hooks bd itself displaced.

**Bigger than the bead described:** the loose match also deletes *user-owned*
hooks that bd only injected a section into, because `generateHookSection`'s
second line reads `# This section is managed by beads.` Any marker-managed hook
whose section sits near the top matches inside the ten-line window and is
removed whole. That is the shape every install since v0.49 produces.

The fix returns three ownership states instead of a boolean, reusing the model
`preservePreexistingHooks` already worked out (#3536): bd-owned (remove),
user-owned-with-bd-section (report, leave), not-ours (neither). The test worth
looking at is `TestClassifyResetHook_AgreesWithHookPreservation`, which pins that
the two functions deciding this independently agree — drift between them is not
untidiness, it is deletion without a restore path.

A doc commit rides along: `docs/recovery/uninstalling.md` claimed reset removes
"beads-managed git hook *sections*" (it works on whole files), and its manual
cleanup section handed out five unconditional `rm -f .git/hooks/<name>` lines
directly below a paragraph explaining why `bd hooks uninstall` is safer.

Left out deliberately and filed as `mybd-6w40a`: `collectResetItems` scans four
hook names, `managedHookNames` has five. Widening it makes reset delete *more*,
which should not ride on a fix that exists to make it delete less.

---

## 3. `bd admin reset` reaching outside its target — #5223 (partial)

`mybd-3bevm`, carrying a 2026-07-21 incident where a reset aimed at a temp repo
removed the global `.beads` plus hooks from an unrelated checkout. A prior
session verified the root cause and stopped, correctly, because the fix shape is
a product choice.

I implemented **only AC3** — refuse to delete `~/.beads` from a repo-scoped
reset — and made two corrections to the standing analysis, both empirical:

- **D3 as stated is wrong for the path that matters.** "The ancestor walk has no
  upper boundary" is true of `FindBeadsDirFrom`, but `FindBeadsDir` — the
  function `runReset` actually calls — bounds its walk at the git root in both
  step 2 and step 4. Verified by building `bd`, constructing a fake `$HOME` with
  a populated global `.beads` and a git repo under it, and running reset: it
  resolves nothing rather than climbing out. The unbounded walker is reached
  specifically through `-C` (`main.go:789`), which then exports the result as
  `BEADS_DIR` — the highest-priority source, consulted with no walk at all.
- **`bd admin reset` is refused outright in embedded mode** by
  `requireServerMode`. The whole blast radius is server-mode installs. That also
  means the documented uninstall path does not work for default installs, since
  `docs/recovery/uninstalling.md` leads with `bd admin reset` — filed as
  `mybd-bomo8` for a maintainer, with two resolutions and no pick.

I did not reproduce end to end and the PR says so: going further meant standing
up a Dolt server to watch a deletion happen, which was the wrong trade.

#5223 is **not** in the patrol lane — it is stacked on #5221 and wants human
sequencing.

---

## 4. Import polarity rework — #5202

`mybd-cebxh` carried an owner decision: #5202 had made *skipping* invalid
records the default for `bd import` with `--strict` to restore the old abort;
the owner wanted the opposite polarity.

Done, with the catch the bead insisted on. Strict-by-default does **not** fix
gh#4492 as the reporter experienced it — their plain `bd import` still imports
nothing. What reaches them is the error, which now names the offending line and
reason, says plainly that nothing was imported, and points at `--skip-invalid`
and `--rejects`. `TestFirstRejectErrorNamesTheEscapeHatch` pins it and explains
in its comment why it is load-bearing rather than cosmetic.

"Nothing was imported" is deliberate too: a user who believes some rows landed
will repair the file and re-import, applying the good rows twice.

`reportRejectedRecords` also lost its `strictHint` parameter — every caller that
reaches it has already decided to skip, so the hint could only advertise a mode
the caller was already in.

**Deviation from the bead, deliberate:** it said "rework on that branch and
force-push". I added a commit instead. The brief said don't touch history, and
the two commits are worth reviewing separately anyway — one is the mechanism,
one is the policy decision about the default. The PR title and body were
rewritten, because the old body argued for the polarity that was just reverted
and would have misled a cold reviewer.

---

## 5. Stopped short: the proxy startup race

`mybd-e1b3f`. The 2026-07-30 diagnosis proposed a pidfile schema change with a
new "starting" state. I think that is not the minimal fix, and the evidence is
specific:

- **The mechanism already exists and is disarmed one line into the function.**
  `endpoint.go` writes a spawn marker before handing off to the child, and
  `shutdown.go:171-187` consults it: a live marker means "a start is in
  progress", and stop waits. The child clears it at `server.go:118` — the first
  thing it does after taking `proxy.lock`, ~115 lines and up to 30s before it
  publishes the pidfile at `:233`. From 118 to 233 there is neither marker nor
  pidfile. That is exactly the interval the CI failure lands in, and why stop
  reported `pid 0`: not a torn read, not merely a missing record, but a record
  withdrawn at the moment the long window opened.
- **The two timeouts disagree by 6×, independently.** `serverReadyTimeout = 30s`
  against `shutdownConfirmDeadline = 5s`, and the 5s bounds both the lock
  acquisition *and* the spawn-marker wait. Fixing the marker alone converts
  "timeout acquiring proxy.lock after inspecting pid 0" into "timeout waiting
  for spawn marker" — a better message for the same failure.

**Why I stopped**, and it is a resource call rather than a difficulty one: the
test is runnable here, but reproducing a race needs many iterations and each
spawns a real `dolt sql-server`. This host already had four orphaned ones from
`beads-bd-tests-*` temp dirs, ~10h old — the exact drain `mybd-yc4vo` tracks, on
a machine that is remote-controlled. Looping a lifecycle test whose failure mode
is "leaves a half-torn-down topology" would add more. Changing a race protocol
without a feedback loop is the one thing not worth doing, so that is where it
stops. Filed the orphan observation as `mybd-avwqg` — different door from
`yc4vo`: those come from inactive projects, these from the test suite, meaning a
green `make test` can leak a long-lived dolt process per shard.

I did not kill them. Four ~10h-old servers rooted in `/tmp` test dirs are almost
certainly dead leftovers, but "almost certainly" is not the standard for
`SIGKILL` on another session's work.

---

## Ledger

| bead | outcome | PR |
|---|---|---|
| `mybd-zbsg4` (P0) | diagnosed; self-closes on green | — |
| `mybd-2sh9j` | **closed** — merged as `491d8872d` | #5220 (merged) |
| `mybd-n7j2z` | fixed, verify queued, patrol lane | #5221 |
| `mybd-3bevm` | AC3 only; corrections recorded | #5223 (not in lane) |
| `mybd-cebxh` | reworked, verify queued | #5202 |
| `mybd-e1b3f` | diagnosis sharpened, not implemented | — |

Filed: `mybd-5eacq` (macOS undetectable pre-merge), `mybd-6w40a` (reset's
four-vs-five hook names), `mybd-bomo8` (documented uninstall path fails on
embedded), `mybd-avwqg` (test-suite dolt orphans).

Memory: `check-local-branches-not-just-prs`.

## What I noticed that isn't on any list

The two PR-coverage tools this repo hands agents — `gh pr list` and
`scripts/pr-preflight.sh` — answer the question "is there an open PR for this?"
and are used as if they answered "is anyone already doing this?". On a machine
running parallel sessions that commit to local branches before pushing, those
are different questions, and the gap between them is measured in whole
reimplementations. `pr-preflight.sh` prints `[pass] No open PRs matched this
search` — accurate, and read as an all-clear. A local-branch scan would fit in
that script's existing output without changing its contract.
