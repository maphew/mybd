# Maintainer sweep: athosmartins (5) + mohamedramadan14 (3) — 2026-07-24

Third and fourth runs of the author-clustered sweep pattern
(PR_MAINTAINER_GUIDELINES.md "Sweep by author, not by age"). Sweep beads:
mybd-pkq7 (athosmartins), mybd-0k71 (mohamedramadan14). Review fan-out:
workflow `wf_ca5ff59c-9a8` — one reviewer + one adversarial verifier per PR
(16 agents, ~928k subagent tokens). Execution: 7 Claude sonnet builders in
parallel source worktrees, then — per the owner's mid-session quota directive —
**all verification and the fix round moved to Codex** (gpt-5.6-sol reviews,
gpt-5.6-terra builders, billed to the ChatGPT pool).

Unlike the ecuthiell cluster (authors had already fixed everything), **none of
these authors returned after the 07-23 reviews** — every PR needed maintainer
absorption. All eight came out as fix-merge or retire; zero request-changes.

## Outcomes

| PR | Author | Verdict | Action |
|----|--------|---------|--------|
| 4885 history long-timeout conn | athosmartins | fix-merge | Branch-selection blocker fixed (SELECT active_branch() + DOLT_CHECKOUT on the fresh conn); guard-proven test; approved; tail mybd-dz33 |
| 4884 label-regex pipeline | athosmartins | retire | Closed with credit: list-half superseded by #3971, ready-half ships via 4882 fix-merge under author's name |
| 4882 label-pattern WHERE | athosmartins | fix-merge | Ready-path rebuilt to main's LIKE-ESCAPE/REGEXP idiom; bd ready flags registered (absorbs 4884); proxied wiring gap fixed; approved; tail mybd-1kie |
| 4865 comments_omitted | athosmartins | fix-merge | Proxied else-branch added + 3 proxied subtests + schema doc; approved; tail mybd-85c0 |
| 4393 socket→TCP fallback | athosmartins | fix-merge (re-cut) | Cherry-picked fallback commit only (authorship kept), auto-convoy dropped per charter; wiring-guard tests added; force-pushed with explanation; approved; tail mybd-ewp9 |
| 4912 history NULL coalesce | mohamedramadan14 | fix-merge | COALESCE kept; tests reshaped to real TEXT→LONGTEXT 0049 migration with revert-proof; approved; tail mybd-k3d5 |
| 4910 history partial IDs | mohamedramadan14 | fix-merge | Rebuilt on main's runHistory seam; ErrAmbiguousID surfaces candidates (plain+JSON); proxied skip explicit; approved; tail mybd-ovpm |
| 4909 import dry-run counts | mohamedramadan14 | fix-merge | Both blockers + cleanups; all-title-only short-circuit bug also fixed; approved; tail mybd-yi2m |

All merges via pr-babysit patrol; nothing merged in-session.

## The cross-vendor gate earned its keep

The serial Codex reviewer pass (gpt-5.6-sol, high) over the sonnet builders'
commits returned 3 SHIP / 4 FIX, and every FIX was real:

- **4882**: the new flags were dead under `--proxied-server` (reads after the
  early return; `gatherReadyInput` didn't copy them) — a functional bug the
  builder's SQL-level tests couldn't see.
- **4909**: an all-title-only batch short-circuited before classification —
  residual instance of the exact bug being fixed.
- **4393 / 4910**: test-honesty gaps (wiring unguarded; candidate list
  unasserted).

The re-review round then caught a **second-order miss**: the 4910 fix-round
builder's "tests pass" claim was vacuous (its focused `-run` matched nothing);
the JSON assertion read stderr while `HandleErrorRespectJSON` writes to stdout.
Fixed in-session, adjudicated by actually running the test. Lesson: treat a
builder's "focused test passed with empty output" as unverified until the test
name is seen in `-v` output.

## Follow-ups filed

- **mybd-6g66** (P3): bd show comment counts read only the permanent comments
  table — commented wisps report 0 (pre-existing, orthogonal to 4865).
- 4884's close comment routes the auto-convoy idea toward gastown/plugin
  discussion if the author wants it.

## Process notes

- **Infra incident**: running 4 Codex builders in parallel (plus test suites)
  transiently exhausted the tool harness — the orchestrator's shell could not
  spawn processes for several minutes (even `echo` failed). AGENTS.md already
  says to keep Codex runs serial in this repo; this extends the rationale
  beyond bd/dolt locks to harness resource pressure. Codex sandboxes also
  cannot write the shared `.bare` worktree index — Codex builders report
  "commit blocked, read-only file system" and the orchestrator commits on
  their behalf (verify the diff first).
- Three stale `dolt sql-server` processes (port 3306) observed on the host
  during diagnosis — mybd-q6cz territory, not urgent, not cleaned this session.
