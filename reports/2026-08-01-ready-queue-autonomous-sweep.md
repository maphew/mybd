# Autonomous `bd ready` sweep — 2026-08-01

**Brief:** work the `bd ready` queue autonomously until dry or genuinely blocked;
check coverage before claiming; worktree + branch + tests + PR per task; do not
merge, do not decide product questions, do not touch history.

**Runtime:** claude-opus-5-high. The implementation phase ran solo — the session
harness disallowed subagents and workflows, overriding the repo's standing
opt-in. That changed mid-session when the owner made dual-vendor review a
precondition for merging, which is a direct request for review agents; the
review phase therefore used a Claude `reviewer` subagent and
`scripts/codex-agent reviewer`. No workflows were used at any point.

---

## The finding that reframes the rest

**`bd ready` shows 100 of 383 and says nothing about it.**

The default `--limit` is 100 and there is no shown/total footer. Measured this
session:

| command | result |
|---|---|
| `bd ready` | 100 |
| `bd ready --limit 0` | **383** (P1:74, P2:208, P3:98, P4:3) |

`bd ready` sorts by priority ascending, then `created_at` ascending. With P1 at
74, the whole P1 band fits inside the cap and the cut lands 26 rows into P2: the
bare listing showed 74 P1s and the 26 oldest P2s, hiding **182 of 208 P2s and
every P3 and P4 row.** So a session that surveys "the queue" from a bare
`bd ready` sees a listing dominated by the P1 band — which in this repo is
overwhelmingly owner-decision beads, upstream campaigns, and PR-shepherding
tails — plus a thin, oldest-only slice of P2, and concludes the queue holds no
actionable autonomous work. That conclusion is wrong in a specific direction:
**the contained, self-contained code tasks are disproportionately in the part of
P2 the cap hides.**

Concretely, at the moment of the survey the bare listing ended at `mybd-guvk`,
and neither `mybd-jgqy` nor `mybd-cof8` appeared in it — both were past the cut.
`mybd-fbr7z` sat far deeper. Of the three tasks completed below, one came from
well beyond the cap and two from just past it; the five dependency edges this
session added later pulled `jgqy` and `cof8` up into the visible window, which is
why re-running the numbers now shows them at rows 83–84. Marginal exclusion is
still exclusion when there is no footer telling you a cut happened.

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

Branch `feat/lane-unit-drift`, merged to `main` as `9f5dbf8a4`. Two commits:
`12e5db19c` (the original) and `1f3636ad8` (the review fixes). Read the second —
`12e5db19c` alone is the version with the false greens catalogued below.

Every lane here (`verify-babysit`, `pr-babysit`, `solo-sweep`, `tri-daily`) is a
tracked template in `scripts/systemd/` that a `scripts/install-*` script renders
into `~/.config/systemd/user/`. Nothing reconciles the two. Editing a template
does not change the machine, and the failure is invisible precisely because git
says the feature exists — that is how the zero-token bisect lane sat unexecuted
for days while AGENTS.md claimed `base-red` beads "often arrive pre-diagnosed".

Added `scripts/check-lane-units` (+ `scripts/test-check-lane-units`, 20 cases
after review; the first version's 11 were weaker than they looked),
wired into `session-close-check` as warn-only check 5, documented in
`scripts/README.md` and AGENTS.md.

Three design points worth keeping if this is revised:

- `@ROOT@` is derived from the git common dir **exactly as the installers derive
  it**, so running from a worktree does not invent drift.
- Installer-injected additions must not count as drift, or the check goes
  permanently red and gets ignored — which would reproduce the original bug at
  one remove. This is not hypothetical: the live machine carries
  `Environment=SOLO_SWEEP_MAX_RUNS=16` and two siblings on `solo-sweep.service`.
  **The exemption must stay narrow.** My first version exempted *any* superset,
  which the review showed was a false green (see below); only
  `Environment=SOLO_SWEEP_*`, the set `install-solo-sweep` actually writes, is
  benign now. Do not widen it back to "extras are fine".
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
   `check-build-tags.sh` stays green, and reports every failing module with its
   exact `go mod tidy` command. It runs **`go vet ./...`**, not `go build` —
   that changed during review, for the reason in the review section below.

**One thing deliberately left to the maintainers, and said so in the PR body:**
`build-examples` is `continue-on-error: true` and *not* in `ci-gate`'s
`CI_GATE_REQUIRED`. The replace directive means any root `go.mod` change not
mirrored into examples fails the job, so making it blocking adds a "tidy the
examples too" step to every dependency bump. That is contributor-friction
policy, not the adding PR's call. `pr.yml` carries a comment with the exact
promotion steps. (The `continue-on-error` half also changed during review:
omitting a job from `ci-gate` is *not* by itself enough to make it non-blocking
in this repo — see below.)

Negative test performed: reverting `library-usage/go.mod` to pre-tidy makes the
script exit 1 and name that module while the other still reports `ok`.

### 3. Queue hygiene — five stubs dep-gated

Five ready stubs recorded their blocker **in prose only**, so they kept surfacing
as independently actionable while the fix was mid-flight. Credit where due: four
of the five already carried a `[solo-sweep 2026-07-30]` note proposing this exact
edge — `mybd-uh8q`'s says *"Suggested owner action: add a dep edge from this stub
to mybd-dcdfw so bd ready stops surfacing it independently."* This session
verified each PR's live state and executed the proposals; it did not originate
them. That lane is doing its job, and consuming its output is the point of it. Prose is invisible to
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
primary symptom is already fixed.** All three cited beads merged and closed within
two hours of the bead being filed (`mybd-o21it` → #4535 at 07-28T05:28Z, `mybd-06h1a` →
#4751, `mybd-i6oj` → #4933), and the log spam was fixed by `126851c05`
(`explain_no_checks` + per-head `pr_babysit_nochecks` marker). The bead's
diagnosis also mis-models the design: `rearm_sweep()` is *supposed* to probe
`merge-blocked` beads — that probe is the only route back into automation — and
`checks-unavailable-persistent` shares an explicit alternation label with
`checks-persistent` at `scripts/pr-babysit:141` (the bare `*)` next to it is the
skip branch), so the claim that failed-checks blocks "stop polling correctly"
does not hold in current source. Residual: `REARM_LIMIT` budgets re-arms, not probes, so a
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

**`mybd-e1b3f`** (proxied lifecycle race) — left alone: adjacent unmerged work
is already in this area, though whether it fully covers the bead is a judgment
call I did not make. The fix
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

**The cap has a blind spot that oldest-first sweeps cannot see past, and it is
not the one I first wrote down.**

My first draft of this section claimed the memories `oldest-band-is-triage-residue`
and `oldest-band-of-bd-ready-is-triage-residue` concluded "the ready queue is
triage residue", drawn from a sampling frame that "was never stated". A
fact-check pass killed both halves, and they deserve to be recorded as killed
rather than quietly dropped, because the shape of the error is the interesting
part. Both memories are explicitly scoped to the **oldest band**, not the queue;
one says verbatim *"Do not read that as 'the queue is dry'"* and then names three
merged-quality PRs produced from that band. And both **do** state their frame —
*"Of ~15 non-human-labelled stubs older than 2026-07-17"* and *"Of ~20 stubs from
2026-05/06/07-11 examined in age order"*. I had paired "I am not asserting they
are wrong" with a factual assertion about them that was wrong, which is a hedge
functioning as a shield. Worth naming so the next reader distrusts that move.

The real version of the worry is better, and it survives:

Within each priority band `bd ready` sorts oldest-first, so the cap hides the
*newest* rows of each band — the last thing an age-ordered sweep would want. But
it also truncates **whole bands**. The first P3 row sits at position 264 of 383,
so the entire P3 band is invisible to a bare `bd ready` — and P3 contains
`mybd-d8q0` (2026-07-05), `mybd-8chd.8` and `mybd-63ns` (07-06), and four more
from 07-11. Every one of those is **older** than the 2026-07-17 cutoff one of
those memories used to define "the oldest band". An oldest-first sweep run off an
unfootered `bd ready` could not have seen them, and would have had no way to know
they existed. That is a concrete, checkable gap in those sweeps' coverage, and it
does not require the memories to be wrong about what they *did* look at.

Those two memories overlap heavily in headline and taxonomy, but they are not
near-duplicates: the second carries specific tells for finding real work in that
band, plus bead and PR evidence, and its posture partly conflicts with the
first's "expect near-zero yield". Consolidate carefully or not at all — a naive
merge would lose the tells.

---

## Dual-vendor review — and what it caught in my own work

Owner ruling mid-session: **mybd merges to `main` once dual-vendor review has
happened, and that is the default course; `gastownhall/beads` is PR-only and
also requires local dual-vendor review.** Both code branches were then reviewed
by a Claude reviewer and `scripts/codex-agent reviewer` (GPT-5.6-sol) on the
same diff.

It was not ceremony. **Six of the findings were false greens in code I had
already declared verified** (the fix commit folds two of them into one item, so
it reads as five there) — the single failure direction neither of these
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
   this same sweep is about macOS-only breakage being undetectable. The same
   pass also guarded an unchecked `source ./.buildflags` (under `set -uo
   pipefail` a failure continued with `GOFLAGS` unset, type-checking the ICU
   path while `check-build-tags.sh` still passed, since it only greps for the
   literal string) and made "found zero modules" an error rather than a green.

The vendors overlapped on exactly one finding and were disjoint on the rest,
which is the pattern the `cross-vendor-review-pairing` memory already records.

Two follow-up beads came out of the review: `mybd-hb6pk` (the extension example
is runtime-broken — `sql.Open("sqlite3")` with no driver registered anywhere in
beads; the new CI job will certify it "buildable" forever, so green ≠ working)
and `mybd-xqpl4` (the review-needed self-filter).

## Landing

`feat/lane-unit-drift` merged to `main` as `9f5dbf8a4` after the review above,
per the owner ruling, and `maphew/mybd#26` auto-closed as merged. This report's
own branch merges immediately after it — that ordering is why the sentence you
are reading names one merge commit and not two.

`maphew:fix/example-extension-go-tidy` remains open as gastownhall/beads#5229 —
PR-only repo, ordinary review, deliberately not handed to the `pr-babysit` merge
lane and carrying no `merge-when-green` bead.

One process note worth keeping, because it nearly went wrong here: the first
draft of this section said "both mybd branches merged to `main`" while neither
was merged and the *reviewed* head of the lane branch was not even pushed. A
reviewer caught it. A report that states a landing prospectively is worse than
one that omits it, because the next session's first move is to trust it —
`scripts/session-close-check` and `bd ready` both key off what is actually
reachable, and neither would have contradicted the sentence.
