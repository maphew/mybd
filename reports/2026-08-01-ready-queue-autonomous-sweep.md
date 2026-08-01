# Autonomous `bd ready` sweep — 2026-08-01

**Brief:** work the `bd ready` queue autonomously until dry or genuinely blocked;
check coverage before claiming; worktree + branch + tests + PR per task; do not
merge, do not decide product questions, do not touch history.

**Runtime:** claude-opus-5-high, solo (no subagents, no workflows — the session
harness disallowed both for this run, overriding the repo's standing opt-in).

---

## The finding that reframes the rest

**`bd ready` shows 100 of 383 and says nothing about it.**

The default `--limit` is 100 and there is no shown/total footer. Measured this
session:

| command | result |
|---|---|
| `bd ready` | 100 |
| `bd ready --limit 0` | **383** (P1:74, P2:208, P3:98, P4:3) |

The first 100 rows are the entire P1 band. So a session that surveys "the queue"
from a bare `bd ready` sees only P1s — which in this repo are overwhelmingly
owner-decision beads, upstream campaigns, and PR-shepherding tails — and
concludes the queue holds no actionable autonomous work. That conclusion is
wrong, and it is wrong in a specific direction: **the contained, self-contained
code tasks live in the P2 band the cap hides.** Two of the three tasks completed
below came from beyond row 100.

I made exactly that mistake for the first half of this session, and I am at least
the third to make it — `mybd-5vf6r` records two sessions on 07-26/27 reporting
"queue size 100", caught by the owner. It is filed upstream as
gastownhall/beads#5102 (unconditional `shown/total` footer on every listing
command). Prior art #3243 exists but is tty-gated (`IsStderrTerminal`
early-return in `cmd/bd/list_output.go`), so piped and `--json` consumers — that
is, every agent — still get the silent cap.

Stored as memory `bd-ready-default-cap-hides-work`, because a report is not on
the cold-start path and this needs to reach the next agent before it repeats.

---

## Work completed

### 1. Lane unit drift check — `mybd-fbr7z`

Branch `feat/lane-unit-drift` (commit `12e5db19c`, pushed). **Not merged**, per
the brief.

Every lane here (`verify-babysit`, `pr-babysit`, `solo-sweep`, `tri-daily`) is a
tracked template in `scripts/systemd/` that a `scripts/install-*` script renders
into `~/.config/systemd/user/`. Nothing reconciles the two. Editing a template
does not change the machine, and the failure is invisible precisely because git
says the feature exists — that is how the zero-token bisect lane sat unexecuted
for days while AGENTS.md claimed `base-red` beads "often arrive pre-diagnosed".

Added `scripts/check-lane-units` (+ `scripts/test-check-lane-units`, 11 cases),
wired into `session-close-check` as warn-only check 5, documented in
`scripts/README.md` and AGENTS.md.

Three design points worth keeping if this is revised:

- `@ROOT@` is derived from the git common dir **exactly as the installers derive
  it**, so running from a worktree does not invent drift.
- An installed unit that is a *superset* of the template is classified `local`,
  not drift, because `install-solo-sweep` injects `Environment=` lines from its
  arming flags. A permanently-red check gets ignored, which would reproduce the
  original bug at one remove. (This is not hypothetical: the live machine has
  `Environment=SOLO_SWEEP_MAX_RUNS=16` on `solo-sweep.service`.)
- It never reinstalls. A deliberate hand-edit is legitimate; clobbering it
  silently would be the same class of bug pointing the other way.

Verified against the historical failure: seeding a unit dir with the
pre-`bisect-next` `verify-babysit.service` yields
`DRIFT verify-babysit.service / missing: ExecStart=-<root>/scripts/bisect-next /
re-run: scripts/install-verify-babysit`. An in-sync machine prints nothing.

Machine state right now: all 8 units in sync, modulo the legitimate solo-sweep
injection.

### 2. Example modules broken on main — `mybd-jgqy` → gastownhall/beads#5229

Branch `maphew:fix/example-extension-go-tidy`. PR open, **not** handed to the
merge patrol (the brief says do not merge, so no `merge-when-green` bead exists
for it; it needs ordinary review).

The bead understated the scope. **Both** modules under `examples/` fail a plain
`go build` on current `upstream/main` (`b5ba4cd42`), not just the one named:

```
go: updates to go.mod needed; to update it:
	go mod tidy
```

They reach the parent through `replace github.com/steveyegge/beads => ../..`, so
their `go.mod`/`go.sum` record the parent's whole dependency graph and every root
dep change invalidates them — and `grep -rl 'examples/' .github/workflows/`
returns nothing, so no CI job has ever compiled them.

Did both remedies the bead offered as alternatives, because either alone leaves a
hole: tidy without CI just resets the clock; CI without tidy lands red.

1. `go mod tidy` in both. Extension example churn is ~1.6k `go.sum` lines, which
   is inherent to the replace directive and is why #4942 deliberately skipped it.
2. `scripts/build-examples.sh` + a `build-examples` job in `pr.yml`. Discovers
   modules via `git ls-files` (no hardcoded list), sources `.buildflags` so
   `check-build-tags.sh` stays green, builds into a scratch dir so it leaves no
   untracked binaries, reports every failing module with its exact `go mod tidy`
   command.

**One thing deliberately left to the maintainers, and said so in the PR body:**
`build-examples` is *not* in `ci-gate`'s `CI_GATE_REQUIRED`. The replace directive
means any root `go.mod` change not mirrored into examples fails the job, so making
it blocking adds a "tidy the examples too" step to every dependency bump. That is
contributor-friction policy, not the adding PR's call. `pr.yml` carries a comment
with the exact promotion steps.

Negative test performed: reverting `library-usage/go.mod` to pre-tidy makes the
script exit 1 and name that module while the other still reports `ok`.

### 3. Queue hygiene — five stubs dep-gated

Five ready stubs recorded their blocker **in prose only**, so they kept surfacing
as independently actionable while the fix was mid-flight. Prose is invisible to
`bd ready`; AGENTS.md's own cold-start prompt 3 asks sessions to encode it as an
edge. PR state was verified live via `gh` at edge-creation time (all OPEN,
non-draft, unmerged):

| stub | now depends on | upstream PR |
|---|---|---|
| `mybd-uh8q` | `mybd-dcdfw` | #5145 doctor `--fix` schema-skew gate |
| `mybd-kr0i` | `mybd-54zj9` | #5137 pollution-scorer corroboration |
| `mybd-guvk` | `mybd-n5dul` | #5136 `refs/dolt/data` verification |
| `mybd-7vyw` | `mybd-dodi9` | #4858 orphaned `child_counters` |
| `mybd-j9v5` | `mybd-6y9i0` | #4804 migration-lock fast path |

Each carries a note recording the verification and the reversal condition: **if
the PR closes without landing, remove the edge** — a closed-unmerged PR returns
the work to us. All five left `bd ready` and nothing was closed.

---

## Examined and genuinely blocked

Recording these so the next session does not re-derive them.

**`mybd-hyhd0`** (pr-babysit polls blocked absent-check lanes forever) — **the
primary symptom is already fixed.** All three cited beads merged and closed hours
after the bead was filed (`mybd-o21it` → #4535 at 07-28T05:28Z, `mybd-06h1a` →
#4751, `mybd-i6oj` → #4933), and the log spam was fixed by `126851c05`
(`explain_no_checks` + per-head `pr_babysit_nochecks` marker). The bead's
diagnosis also mis-models the design: `rearm_sweep()` is *supposed* to probe
`merge-blocked` beads — that probe is the only route back into automation — and
`checks-unavailable-persistent` shares the `*)` branch with `checks-persistent`,
so the claim that failed-checks blocks "stop polling correctly" does not hold in
current source. Residual: `REARM_LIMIT` budgets re-arms, not probes, so a
permanently blocked PR is probed forever; current cost is zero (one
`merge-blocked` bead, `deferred`, which the sweep skips). Recommended
rewrite-or-close; did not close it myself. The one live item riding along under
that title — the review-needed self-filter matching the GH actor but not commit
identity, which queued a bead for our own push to #5093 — is split out as new
bead **`mybd-xqpl4`**.

**`mybd-cof8`** (widen `update-vendor-hash` beyond dependabot) — blocked, and the
two options are not equally available. Option (a) collides head-on with the
safety analysis in the workflow's own header: it uses `pull_request_target`, and
its stated trust boundary is *"dependabot is the only allowed actor and never
modifies `scripts/`"*. Widening the actor set means a same-repo PR could edit
`scripts/update-nix-vendorhash.sh` and have it execute in the trusted base context
with a write token. That is a security-boundary change needing an owner ruling,
not an autonomous PR. Option (b) (read-only recompute-and-compare check) is the
safe half and the one I would recommend — but it is **unverifiable on this host**:
`nix` and `nix-build` are both absent, so I could not run the script once before
shipping a nix CI job to a repo whose nix gate has already been red once.

**`mybd-e1b3f`** (proxied lifecycle race) — covered by unmerged work. The fix
direction (publish an identifying record before the long startup steps) is
already the subject of `feat/psxg5-listener-policy` ("epoch-fenced startup",
`d83434010`, pushed to origin, not on `upstream/main`). Left alone.

**`mybd-msll`** (pr-preflight blind to pr.yml-only jobs) — has a concrete design
proposed, but the bead itself parks it on an unsettled question: whether "the PR
gate is broken" should reuse `base-red`'s counter and one-bead-per-base escalation
or get its own `gate-red` label. Different remedies, different text. Not mine.

**`mybd-5eacq`**, **`mybd-ad63`**, **`mybd-s4h6`**, **`mybd-alm2`**,
**`mybd-y06g`** — each explicitly needs a maintainer call on CI spend or on a
semantics/precedence contract before implementation.

**`mybd-gwxj`**, **`mybd-sk7e`** (items 2–3) — need the Windows host.

---

## What I noticed that isn't on any list

**The `bd ready` cap is not just an ergonomics wart; it has been shaping triage
verdicts.** Two memories in this repo —
`oldest-band-is-triage-residue` and `oldest-band-of-bd-ready-is-triage-residue` —
record independent sessions concluding that the ready queue is triage residue
rather than startable work. Both were written by sessions working from `bd ready`.
If those sweeps also saw only the P1 band, their conclusion was drawn from 26% of
the queue, selected for being the part most likely to be owner-gated. I am not
asserting they are wrong; I am flagging that the sampling frame was never stated,
and that this session found startable work at rows 100+ after reaching the same
"it's all blocked" conclusion from rows 0–99. Worth a re-check of those verdicts
with `--limit 0` before they harden into policy.

Second: those two memories appear to be near-duplicates of each other. Worth a
merge pass.

---

## Dual-vendor review — and what it caught in my own work

Owner ruling mid-session: **mybd merges to `main` once dual-vendor review has
happened, and that is the default course; `gastownhall/beads` is PR-only and
also requires local dual-vendor review.** Both code branches were then reviewed
by a Claude reviewer and `scripts/codex-agent reviewer` (GPT-5.6-sol) on the
same diff.

It was not ceremony. **Six of the findings were false greens in code I had
already declared verified** — the single failure direction neither of these
tools may have.

**Lane-unit check (`feat/lane-unit-drift`).** Both vendors independently hit the
same first defect:

1. Each unit was packed into one `|`-delimited record and unpacked with `read`,
   which stops at the first newline. A unit with two missing directives reported
   one, and the extras list was emitted as `[]` while an extra existed. My test
   suite passed on this because every fixture had exactly one missing line.
2. Any superset counted as `local`, exit 0 — but a directive *deleted* from the
   template still runs on the machine, and an added `ExecStart=` in a
   `Type=oneshot` runs in addition. A hand-edit adding `ExecStart=/bin/false`
   reported clean.
3. A half-installed lane reported clean: a service whose timer is missing never
   fires, yet the timer was `absent` and the service `ok`.
4. No `errexit` and an unguarded `mktemp -d`: on failure every `diff` compared
   two nonexistent files and the tool printed *"installed units match their
   templates"* against a genuinely drifted machine.
5. Hand-rolled JSON escaping handled only `\` and `"`; a tab — legal leading
   whitespace, legal inside `Environment=` — produced output `jq` refused to
   parse.
6. A `|` inside a directive (`ExecStart=/bin/sh -c 'journalctl | grep foo'`,
   stock systemd) split across missing/extra, inventing a hand-edit that never
   happened.

The deeper problem was the test suite: **it passed on broken code twice.** The
Claude reviewer demonstrated it by mutation — deleting the `@ROOT@`
stable-checkout derivation outright, and replacing `json_escape` with the
identity function, both left the suite green. Rewritten to 20 cases; the fixture
now carries a quote, a backslash, a literal tab and a piped `ExecStart`, and the
`@ROOT@` derivation is exercised from a real linked worktree. I re-ran the
reviewers' mutations plus one of my own against the new suite; each now fails.

**Examples PR (#5229).** Two correctness bugs, one of which contradicted my own
PR description:

1. `go build -o <dir>/ ./...` compiles only the *main* packages and silently
   skips libraries. Verified in an isolated module: `go build -o dir/ ./...`
   exits 0 where `go build ./...` and `go vet ./...` both exit 1. Switched to
   `go vet ./...`, which also type-checks test files — and
   `examples/library-usage/main_test.go` exercises a lot of live API whose
   imports `go mod tidy` counts, so the committed go.mod had a portion the
   check never touched.
2. **"Not in `ci-gate`" is not "non-blocking".** My PR body claimed leaving the
   job out of the required list kept it friction-free. False for our own
   automation: `pr-preflight.sh` blocks on any FAILURE in the raw
   `statusCheckRollup`, and the `pr-babysit` patrol requires every rollup entry
   SUCCESS/NEUTRAL/SKIPPED — neither consults `ci-gate`. The state I proposed
   was the one posture that stalls the merge lane repo-wide while advertising
   itself as optional. Now `continue-on-error: true`; promotion to a real gate
   is documented and left to the maintainers. PR description corrected and the
   correction posted as a comment rather than made silently.
3. Codex alone caught that `mapfile` (bash 4) and `xargs -r` (GNU) meant the
   script could not run on stock macOS at all — pointed, given `mybd-5eacq` in
   this same sweep is about macOS-only breakage being undetectable.

The vendors overlapped on exactly one finding and were disjoint on the rest,
which is the pattern the `cross-vendor-review-pairing` memory already records.

Two follow-up beads came out of the review: `mybd-hb6pk` (the extension example
is runtime-broken — `sql.Open("sqlite3")` with no driver registered anywhere in
beads; the new CI job will certify it "buildable" forever, so green ≠ working)
and `mybd-xqpl4` (the review-needed self-filter).

## Landing

Both mybd branches merged to `main` after the review above, per the owner
ruling. `maphew:fix/example-extension-go-tidy` remains open as
gastownhall/beads#5229 — PR-only repo, ordinary review, deliberately not handed
to the `pr-babysit` merge lane and carrying no `merge-when-green` bead.
