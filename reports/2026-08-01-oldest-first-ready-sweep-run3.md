# Oldest-first sweep of `bd ready`, run 3 — 2026-08-01

**Session:** Claude Code, opus-5, high reasoning, on behalf of maphew.
**Brief:** work `bd ready` autonomously from the oldest end until dry or genuinely
blocked; a parallel agent worked the newest end. Check nothing is already covered
by a branch or PR before claiming. Worktree + branch + tests + PR per task. No
merging, no product decisions, no history rewriting.

## Outcome

| PR | Bead | What |
|----|------|------|
| [#5222](https://github.com/gastownhall/beads/pull/5222) | mybd-89mod | `bd setup claude` no longer reads a *fenced* `@AGENTS.md` example as a redirect stub |

One PR, not three, and the reason is the main finding below. Alongside it:

- **Two red-`main` failures diagnosed, fixed and then abandoned as duplicates** —
  see "The collision".
- **Independent verification and review of [#5220](https://github.com/gastownhall/beads/pull/5220)**,
  including one defect: its body describes functions the diff does not contain.
- **Six beads filed**, all verified against `upstream/main` @ `ed8526721` rather
  than restated from existing notes: mybd-a3905, mybd-5r1s2, mybd-ypdz4 (plus
  mybd-89mod, and mybd-s2y0s / mybd-slyfe which were closed as duplicates).
- **Two beads closed on evidence** (mybd-xq68, and the duplicate pair), **four
  corrected** (mybd-zbsg4, mybd-2sh9j, mybd-j9v5, mybd-aokv, mybd-m4obg).
- `make test` queued in the local verifier for mybd-89mod (`d629ab235`).

#5222 was **not** armed for the patrol — the brief said don't merge.

## The oldest band is now a three-run finding, and the sweep should stop

Runs on [2026-07-30](2026-07-30-oldest-first-ready-queue-sweep.md) and
[2026-07-31](2026-07-31-oldest-first-ready-sweep-run2.md) both concluded the
oldest band of `bd ready` is triage residue rather than backlog, and run 2
predicted a third run would yield roughly the same. It did — but the prediction
undersold how *structural* it is. Of the pre-2026-07-17 band, everything that is
not `human`-labelled is blocked on one of exactly three things:

- **an open contributor PR we must not compete with** (mybd-tgdx, mybd-isc6 →
  #4449; mybd-j9v5 → #4804; mybd-7cpd → the `Signal(0)` PR),
- **a contract or product decision** (mybd-alm2, mybd-s4h6, mybd-ad63,
  mybd-r5u2, mybd-1hao),
- **an environment this host is not** (mybd-3wkx needs HQ-scale data, mybd-m6q8 a
  customer environment, mybd-gwxj a Windows box, mybd-lvss a Docker-backed
  historical-Dolt fixture).

The single item that moved did so because *its blocker resolved elsewhere*, not
because anyone worked it: mybd-xq68's PR #4838 merged on 2026-07-26 and nobody
had closed the bead.

That is the shape of the whole band. **Age ordering is not surfacing neglected
work; it is re-surfacing decisions and other people's PRs, once per sweep.** A
fourth run of this brief against the same band is not worth a session. What the
band needs is a marker — a `deferred-until` or a dependency edge onto the thing
each item actually waits for — so `bd ready` stops offering them. Three sessions
have now paid to re-derive the same list.

**The corollary is the useful part:** this run's entire value came from the
*newest* end and from things not in the queue at all — a red base, a merged PR
nobody closed the bead for, and three product warts recorded in a PR body a
fortnight ago and never filed anywhere.

## `main` was red, and the P0 was wrong about how red

`mybd-zbsg4` (P0, `base-red`) and `mybd-sb0sl` both described **one** failing test
on `Test (macos-latest)`. At `upstream/main` `ed8526721` there were **three**,
landed by three different commits within four hours of each other:

| Test | From | Covered by |
|---|---|---|
| `cmd/bd/doctor TestCheckHooksPath_MissingBeadsManagedPath/absolute_.beads/hooks` | `868dd077a` (#5203) | mybd-sb0sl, PR #5210 |
| `cmd/bd TestResolveServerModeUOWTopology_KeepsALiveSocket` | `6510641c3` (#5208) | nothing, at the time |
| `cmd/bd TestDispatchDoesNotPolluteViperIssuePrefix` | `ed8526721` (#5218) | nothing, at the time |

Merging #5210 alone would not have turned `main` green, and its bead said it was
the sole failure. Both beads now say otherwise.

### Why the bisect lane said "unreproducible", and why that was misleading

`mybd-zbsg4` carried `bisect_state=unreproducible`: *"bad commit did not cleanly
fail locally (exit 0/good); a timeout/unrunnable/flake, not a reproduction of the
CI failure."*

That verdict was correct and uninformative. `scripts/bisect-next` runs `make test`
as its oracle **on this Linux host**, and all three failures are macOS-only in
effect. A Linux oracle can never reproduce them, so it will always report
`unreproducible` — which reads as *flake*, and here meant *wrong platform*.

**All three are reproducible on Linux once you simulate the macOS property
instead of re-running the commit.** Both techniques are one environment variable:

```bash
# symlink-resolution failures: macOS $TMPDIR is /var/folders/... under /var -> /private/var,
# so every t.TempDir() has two names and code that string-compares them breaks.
ln -s /tmp/real /tmp/link
TMPDIR=/tmp/link go test -run TestDispatchDoesNotPolluteViperIssuePrefix ./cmd/bd/

# path-length failures: macOS $TMPDIR is ~50 bytes before the test name is spent,
# against a 104-byte sun_path.
TMPDIR=/tmp/aaaaaaaaaa-bbbbbbbbbb-cccccccccc-dddddddddd/ee \
  go test -run TestResolveServerModeUOWTopology_KeepsALiveSocket ./cmd/bd/
```

Both produced the **byte-identical** error strings the macOS runner printed. This
is now `bd remember`'d, because a base-red bead that says "unreproducible" will
otherwise keep being read as a flake.

The structural gap — `.github/workflows/main.yml` triggers on `push: branches:
[main]` with no `pull_request`, so the macOS job **cannot** run pre-merge — was
already filed by the parallel session as **mybd-5eacq**. Confirmed against the
workflow file. It is the reason all three landed unseen, and it is the most
important open item to come out of today.

## The collision

I diagnosed both uncovered failures from scratch, reproduced each on Linux, wrote
the fixes, wrote regression tests, verified the tests fail against the parent
commit, and committed. **Then** I ran `pr-preflight.sh --search` before pushing —
and found [#5220](https://github.com/gastownhall/beads/pull/5220), opened by the
parallel session at 08:06Z, covering both.

`bd search` had found nothing when I started, correctly: the duplicate did not
exist yet. It appeared while I was working. But preflight would have caught it
before I wrote a line of the second fix, and the brief already told me to check
for a covering PR — I ran that check at the wrong end of the task.

What made it worse than a normal race is that **#5220 contains my commits.** All
worktrees here share one object store, so my `738dd56f9` was visible to every
other session the moment I made it; the parallel session picked it up and pushed
it as `f7f5fdf0a` (same author timestamp to the second, byte-identical content),
along with the socket change, and added a third commit of its own. So the work
was not wasted — but it was also not *mine to open a PR for* by the time I looked.

**The salvage, which is the reusable part:** don't open the competing PR. Review
the incumbent instead, and use the work you already did as the review instrument.
Running my own regression tests against their head is a much stronger review than
reading their diff, and it is nearly free once the tests exist:

- Their fix passes both of my repros, under a symlinked and an over-long `$TMPDIR`.
- I probed for the failure mode the change *could* have introduced — over-ignoring,
  where the normalization collapses two genuinely distinct workspaces into one
  ignore-set key. It does not; the guard test was already there.
- **One real defect: the PR body does not describe the diff it ships.** It names
  `repoConfigPathKeys`, `shortTempDir` and `TestShortTempDirOmitsTheTestName`;
  none of the three exist in the change. The shipped `bindableSocketPath` in fact
  argues the *opposite* of what the body says about the `internal/storage/dbproxy/server`
  convention. The body reads as written against an earlier draft, and a reviewer
  following it would go looking for functions that are not there.

That finding is on mybd-2sh9j. My branches were deleted; mybd-s2y0s and mybd-slyfe
were closed as duplicates of mybd-2sh9j.

**Carried out of that work rather than folded into a red-main fix:** mybd-a3905.
The two pre-existing socket sites in `internal/storage/dbproxy/server` guard the
same limit with `if len(sock) >= 104 { t.Skipf(...) }`. On macOS that is not a
guard — `$TMPDIR` alone makes the condition always true, so **those two socket
assertions have never run on a macOS runner.** Switching them over would newly
execute two assertions that have never executed there, which is not something to
do inside the commit that is supposed to restore green. It is filed with a
`blocked-by` edge onto mybd-zbsg4 so it cannot be picked up against a red base.

## The one live item: #5222

`mybd-xq68`'s PR #4838 merged on 2026-07-26 and the bead was still open. Verified
on `upstream/main` rather than from the PR state — `isAgentsImportStub`,
`claudeAgentsEnvRedirect` and `stripStaleClaudeBlock` are all present, and one of
the two nits the review left open (path-qualified `@./AGENTS.md`) was handled
before merge. So the bead closed on evidence.

The other nit was still live, and it is not cosmetic. `isAgentsImportStub` scans
for `@AGENTS.md` on its own line with no notion of code blocks, so a CLAUDE.md
that **documents** the redirect pattern in a fenced example is classified as a
stub. The consequence is not a misrouted write:

> once the redirect activates, `stripStaleClaudeBlock` **removes** the managed
> block from CLAUDE.md, on the reasoning that AGENTS.md now owns it.

A documentation example silently moves managed content out of the file that was
actually authoritative. The end-to-end test is the one that carries the argument —
against `main` it fails with *"CLAUDE.md is authoritative and must carry the beads
block; a fenced example redirected it away."*

Skipping fences also matches the semantics being detected in the first place:
Claude Code does not expand an `@`-import shown as code, so a fenced directive was
never going to make the file a stub.

**Two places the fix is deliberately narrow, both pinned by tests**, because both
are where a more thorough version would be wrong:

- **Four-space-indented lines are still scanned.** Indentation is ambiguous in a
  way a fence is not — it is equally a list continuation, a plausible home for a
  real directive. Treating it as code would trade this false positive for a false
  negative.
- **A closing fence must match the character that opened the block**, so ` ``` `
  inside a `~~~` block does not terminate it and let a following directive leak
  through. An unterminated fence swallows the rest of the file, which is what a
  Markdown renderer does too — so the conservative answer there is correct rather
  than accidental.

Five of the seven new unit cases fail against `main`. The two that pass in both
directions are the over-correction guards, and exist so a future change cannot go
too far the other way.

## Three product warts that had been sitting unfiled for a fortnight

`mybd-aokv` recorded three warts in the body of PR #4722 on 2026-07-13 and
"offered to file upstream". They were never filed — not upstream, not in bd. All
three verified against `ed8526721` before filing, not restated from the note:

- **mybd-5r1s2 (P2):** `bd setup junie` writes `.junie/mcp/mcp.json` invoking
  `bd mcp`. **There is no `bd mcp` command** — no cobra command declares it
  anywhere under `cmd/` or `internal/`; the only `mcp` surfaces are `bd prime`'s
  `--mcp` *flag* and its detection of someone else's `mcpServers` block.
  `schema.go:18` refers to `beads-mcp` as a separate project, which is the hint
  about what the config should point at. Every Junie user gets a server entry that
  cannot start, and it fails at the IDE, away from the command that wrote it.
  Filed rather than fixed: choosing between "point at external `beads-mcp`",
  "stop writing MCP config" and "add a real `bd mcp`" is a product call.
- **mybd-ypdz4 (P3):** two config keys that are validated, defaulted and
  documented but have no consumer. `routing.mode` advertises
  `auto, maintainer, contributor, explicit`, but `internal/routing/routing.go:215`
  holds the only comparison against the value in the package — `== "auto"` — so
  the other three are behaviourally identical to each other and to a rejected
  value. And `sync.require_confirmation_on_mass_delete` has **no reader at all**
  while being documented as *"Prompt before pushing when a merge deletes most
  issues"*. A user who sets it believes they have a guard in front of a mass
  delete and does not. That one is the reason this is filed at all rather than
  shrugged at.

Filing these **upstream** is publication and stays the owner's call; the beads are
the internal record so they stop being invisible.

## What I noticed that isn't on any list

**`bd` went completely blind for about ninety seconds, and reported it as an empty
queue rather than an error.** Mid-session, with ~4 concurrent bd-using sessions on
this host:

```
08:14:30Z  bd show mybd-sk7e   -> full issue
08:15:20Z  bd show mybd-sk7e   -> "no issue found matching \"mybd-sk7e\""
           bd list --id ...    -> "No issues found."
           bd ready --json     -> []        # it had returned 100 rows minutes earlier
08:15:40Z  scripts/check-beads-config -> "active database mybd (1743 issues)"
08:16:10Z  bd ready --json     -> 100 rows again
```

No writes to those rows in between, and `check-beads-config` is read-only, so
nothing repaired it. It is **not** the `metadata.json`-points-at-the-empty-`beads`-
database drift `AGENTS.md` warns about — the correct database with all 1743 issues
was reported while the window was still open.

The dangerous part is the shape, not the duration: **every command exited 0 and
said "no issues found."** An agent that hit this inside a decision path would
conclude the queue was drained and end its session, not that the tracker was
unreadable. `bd ready` returning `[]` is indistinguishable from success. This is
recorded on mybd-m4obg, which is the existing bead for the read path serving stale
data across concurrent sessions, and which until now had no first-party
timestamped observation on it.

Two smaller things, neither filed because I did not confirm the mechanism:

- **`TestConfigValidateReadOnlyIsHermetic` fails on this host at `ed8526721`
  unmodified**, with both a default and a symlinked `$TMPDIR` — a `dolt.gate.lock`
  appears in the target `.beads` during a `--readonly` validate. CI's ubuntu job
  passes it, so it is host-specific and I did not chase it. Worth knowing before
  anyone reads a local `cmd/bd` run as clean or dirty.
- **An untracked `.beads.gate.lock` was in the working tree at session start** and
  still is. Possibly related to the item above; possibly another session's live
  state, which is why I left it alone.

## Handoff

- **`main` is still red.** It needs **two** merges, not one: #5210 (mybd-sb0sl,
  `MERGEABLE`, local verify passed, and its bead's lease is **expired** so nobody
  is holding it) and #5220 (mybd-2sh9j, verification was running locally at
  session end). Neither is armed, correctly — `PR_PREFLIGHT_BLOCK_RED_BASE=1`
  parks armed lanes behind a red base *including the lanes carrying its fix*, so
  merging these is a session or human action. The brief said don't merge.
- **#5220's body should be corrected before it merges.** Details on mybd-2sh9j.
- **#5222 is open, unarmed, CI in flight.** Arming is
  `scripts/pr-handoff 5222 --bead mybd-89mod`. Its `make test` is queued in the
  local verifier; the bead is not complete until `verify_state=passed`.
- **mybd-89mod is `in_progress` and claimed deliberately** — the work is not done
  until verification passes and the PR lands. `session-close-check` will warn
  about it; the warning is correct and the state is intentional.
- **mybd-a3905 is blocked-by mybd-zbsg4** on purpose. Do not pick it up until
  `main` is green — it newly enables assertions that have never run on macOS.
- **Stop running this brief against the oldest band.** See the section above. If
  the band is to shrink, it needs `deferred-until` markers or dependency edges
  onto the PRs and decisions each item is actually waiting for — not another
  sweep.

---

_claude-opus-5-high on behalf of maphew_
