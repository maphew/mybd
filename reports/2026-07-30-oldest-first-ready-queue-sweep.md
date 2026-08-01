# Oldest-first sweep of `bd ready` — 2026-07-30

Session: claude-opus-5-medium on behalf of maphew.
Brief: work `bd ready` oldest-first, autonomously, until dry or genuinely
blocked. Check nothing is already covered by a branch/PR before claiming.
Worktree + branch + tests + PR per task. No merging, no product decisions, no
history rewriting. A parallel agent was working the top of the queue.

## Outcome

Three upstream PRs, each with an end-to-end repro proving fail-on-`main` /
pass-on-branch, plus two beads resolved by evidence rather than code.

| PR | Bead | What |
|----|------|------|
| [#5184](https://github.com/gastownhall/beads/pull/5184) | mybd-qrm9 | Detached children no longer inherit the caller's fds |
| [#5186](https://github.com/gastownhall/beads/pull/5186) | mybd-v42x4 | Git hooks disabled on the in-process push path (absorbs #4281) |
| [#5187](https://github.com/gastownhall/beads/pull/5187) | mybd-f0wgx | Every table a delete cascades into is staged |

`make test` has **passed** for #5184 (`be394ce4f`, exit 0). #5186 and #5187 are
queued in the local verifier.

No merge lane was armed on any of them — the brief said don't merge, so
`pr-handoff` was deliberately not run. **These three PRs need a human or a
later session to arm or merge them.**

## The main finding: the oldest band is triage residue, not backlog

Worked strictly in `created_at` order. Of roughly twenty stubs from
2026-05/06/07-11, nearly all were parked, and their own notes said why:

- **Active competing PR** — mybd-7vyw (#4858), mybd-j9v5 (#4764/#4804),
  mybd-kr0i (#5137), mybd-uh8q (#5145), mybd-inbv (#5127).
- **Needs a repro we don't have** — mybd-3wkx (HQ-scale dataset), mybd-m6q8,
  mybd-tgdx.
- **Owner design/contract decision** — mybd-alm2 and mybd-s4h6 (hierarchy
  output contract), mybd-ad63, mybd-y06g, mybd-1hao.

That is not the same as the queue being dry, and it is worth saying plainly
because the age ordering actively misleads: the oldest items look like the most
neglected work when they are in fact the most *deliberately* deferred.

Three tells reliably separated real work from residue. All three produced PRs.

**1. A block that names the environment, not the problem.** mybd-qrm9 was
parked 2026-07-21 as "not a safe autonomous leaf" because conclusive tests
needed real Dolt lifecycle integration on Linux/Darwin, "unavailable in this
Windows session." On a Linux host with dolt installed it was a clean fix.
Environment-scoped blocks should be re-read against the current host before
being believed.

**2. A closed-but-unmerged contributor PR.** mybd-v42x4's upstream #4272 had
PR #4281 attached — closed, but *by its author*: "been ready to merge and
passing checks for a month without movement." Not rejected on merit. Per
PR_MAINTAINER_GUIDELINES that is an absorb-with-attribution case, and the bug
was still live on `main` a year after the original fix. "Closed" in a recon
note is not "resolved" — check why.

**3. "Still-valid" and "keep-open" claims that were never actually run.**
Both directions turned up:

- mybd-xwgrd was proposed *flesh-out* on 2026-07-29 with acceptance criteria to
  widen a column. Three minutes of empirical testing showed it already **fixed**:
  a 70,193-byte `old_value` and 140,014-byte `new_value` persisted fine;
  the columns are `longtext` via migrations 0048 + 0057 + `ignored/0019`. The
  sweeps missed it because they searched for a PR naming gh 4093 and the fixes
  never named it.
- mybd-efzs's mechanism **does not reproduce** on dolt 2.2.2 — probed in both
  embedded and server mode, the write stages and the frozen `DOLT_COMMIT('-Am')`
  returns a hash. Deliberately *not* proposed for close: I showed the bug is
  absent on current, not that it was present on 2.1.10 and got fixed, and that
  distinction is exactly the 30% false-positive trap the drain strategy warns
  about.

## Two of the three fixes were initially aimed at the wrong code

Worth recording, because in both cases reading the code supported the wrong
answer and only running it caught the error.

For **#5186** I first patched `withRemoteOperationEnv` in
`internal/storage/dolt` — which had a short-circuit that skipped
credential-free remotes, a plausible-looking culprit. The repro still failed.
Instrumenting the hostile hook to print its own environment showed it received
`GIT_CONFIG_PARAMETERS=[]`, while exporting that variable by hand made the push
succeed — proving the mechanism was right and my code simply wasn't on the
path. Embedded mode goes through `versioncontrolops`, not the
server-mode store. The reverted patch would have shipped as a no-op that
looked correct in review.

That investigation also produced the shape that matters for reviewing #5186:
the two uncovered paths need *different* fixes because the git child is spawned
from a different process in each — embedded runs the CALL in bd's own process,
server mode runs it inside the spawned `sql-server`, where bd's environment is
invisible. #4281 fixed only the server arm, which is not the mode the issue was
reported against.

For **#5187**, the schema-derived test caught a cascade target I had missed
while writing the fix: `wisp_dependencies.depends_on_issue_id` references
`issues(id)`, so deleting an *ordinary* issue also drops wisp edges. Neither
backend's hand-maintained list had it, and I would have shipped without it.
That is the argument for deriving the list from the migrations rather than
restating it — which is what the test now does.

## Not claimed, and why

- **mybd-cjcpt** — the flaky `TestEmbeddedInitConcurrent` lives in
  `cmd/bd/init_embedded_test.go`, which our own open PR #5093 already modifies.
  Editing it now would conflict with our unmerged work.
- **mybd-efzs, mybd-xwgrd** — evidence recorded, disposition left to the owner.
  Closing upstream is a publication decision.
- Everything labelled `human`, `tri:human`, or `human-decision` — out of scope
  per the brief.

## What isn't on any list

Reproducing #5184 surfaced **five orphaned `dolt sql-server` processes** on this
host, cwds under `/tmp/beads-bd-tests-*`, left by earlier test runs. That is
independent live confirmation of mybd-yc4vo ("embedded dolt sql-server daemons
are never reaped on inactive projects"), which until now rested on a report. It
also has a practical cost: they compete for resources with the heavy Dolt
suites, and the `internal/storage/dolt` package blew its default 10-minute
`go test` budget while they were running — `-run TestCrossProject` alone passes
in 46s. If the verify queue reports a dolt-package timeout on #5186, that is the
likely cause rather than a regression.

Two smaller notes for whoever is next:

- Linting any `embeddeddolt`-adjacent package **requires**
  `--build-tags gms_pure_go`; without it `golangci-lint` dies on a missing ICU
  header rather than reporting lint results. This is easy to misread as a
  broken checkout.
- `bd` resolves issue IDs relative to the working directory. Running
  `bd update mybd-...` from inside `bd-main/` fails with "no issue found",
  silently, and looks like a missing bead. Run bead commands from the
  coordination-repo root.

## Cold-start handoff

1. **Learned, and stored where a cold agent will see it**: `bd remember` key
   `oldest-band-of-bd-ready-is-triage-residue` carries the three tells above.
   It is on the `bd prime` path; this report is not.
2. **Deliverables reachable from open beads**: all three PRs are recorded in
   the notes of mybd-qrm9, mybd-v42x4 and mybd-f0wgx, all of which stay
   **open** (PRs unmerged). This report is linked from them by date.
3. **Ordering that needs a dependency edge, not prose**: mybd-cjcpt is blocked
   on PR #5093 landing. That is currently prose in two notes, so `bd ready` will
   keep offering it. Someone should add the edge to whichever bead owns #5093.
   Same for the sweep suggestions I did not act on: dep-gate mybd-7vyw on
   mybd-dodi9, mybd-uh8q on mybd-dcdfw, mybd-kr0i on mybd-54zj9.
