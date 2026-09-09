# Issue sweep — theme:data-integrity (solo-sweep run 1)

2026-07-29, unattended solo-sweep lane. One theme sweep per
`reports/2026-07-26-triclaim-drain-strategy.md` ("Sweep unit"). All
dispositions below are **proposals** carried on the stubs as
`solo-sweep:proposed` notes; nothing was closed, labeled upstream, merged, or
posted. Owner executes or rejects on return.

## Scope

The theme held **10 open stubs** at sweep time — the strategy report's count
of 11 no longer matches; no closed or relabeled 11th bead carries
`theme:data-integrity`, so one stub evidently left the pool between 07-26 and
now. All 10 fit under the 12-stub cap; **nothing was left unreached.**

Freshness recon was delegated to three parallel read-only subagents (gh
reads + local source greps in `bd-main/`); disposition judgment stayed with
the orchestrator. All 10 upstream issues are still **OPEN** on
gastownhall/beads.

## Disposition table

| Stub | Upstream | P | Proposed | Evidence core |
|------|----------|---|----------|---------------|
| mybd-o4wzj | gh 3926 (silent dolt-server.port rewrite, split-brain) | 1 | **close** | PR **4217 VERIFIED MERGED** (mergeCommit `32586cbf6`, 2026-05-28): stops persisting env-supplied managed ports into the repo-local port file, adds doctor detection, docs recovery. Caveat: PR says "Refs" not "Fixes"; issue still open upstream; reporter's exact repro not re-run. |
| mybd-tgqsj | gh 3905 (bd close no-ops status UPDATE, prints success) | 0 | **consolidate → mybd-agf58** | Open, 0 comments, no fix PR found. Same silent lost-write signature as the gh 4135 embedded-mode family. |
| mybd-j6mrb | gh 3964 (append-notes drops rapid writes) | 1 | **consolidate → mybd-agf58** | Open, 4th independent repro (deterministic harness, 2026-05-28); commenter explicitly links consolidated report gh 4135 (open, active 2026-07-28, no fix PR). |
| mybd-xwgrd | gh 4093 (events.old_value ~64K TEXT overflow) | 1 | **flesh-out** | Open, no fix PR, and a **fresh second repro 2026-07-16** (39k-char notes field, Error 1105). Distinct root cause; acceptance criteria proposed in note. |
| mybd-f0wgx | gh 3807 (DeleteIssue cascade parity gap) | 1 | **flesh-out** | Fix PR 3808 **CLOSED-UNMERGED** — yet the raw-SQL shape the issue quotes is gone from main (now shared `issueops.DeleteIssueInTx`). Survives: dolt tx marks 1 table dirty vs embedded's 5 (`dolt/transaction.go:681` vs `embeddeddolt/transaction.go:86`), and `DeleteIssueInTx` has no explicit deletes for labels/comments/deps/events (cascade behavior unverified). Stub should be rewritten around the surviving gap. |
| mybd-3rhd1 | gh 3360 (ghost wisps: log before commit) | 1 | **keep-open** | v1.0.0-era, ~100 days silent, no fix PR found, and recon could not establish whether the ordering exists in the current rewritten wisp path. Unverifiable either way → no close. |
| mybd-inbv | gh 5005 (--deps verbatim ids, wrong edge deleted) | 1 | **keep-open** | Fix PR 5127 **OPEN-unmerged**, self-declares a proxied-path gap. Lane collision: 5127 is in the mybd-php3l maintainer-push batch (5120–5134); adjacent to in-progress mybd-i9x0. |
| mybd-37wi | gh 4662 (promotion drops closed_by_session) | 1 | **keep-open** | Fix PR 4798 **OPEN-unmerged**. Bug **confirmed live on main**: `closed_by_session` absent from `sqlbuild.IssueBaseColumns` (sqlbuild.go:38); promotion uses the generic column path. |
| mybd-kl59 | gh 4673 (wisp deletion never cascades wisp_dependencies) | 1 | **keep-open** | Fix PR 4674 **OPEN-unmerged**. Bug **confirmed live on main**: delete helpers (`issueops/dependencies.go:555–575`) touch only `dependencies`; no wisp_dependencies cascade on any delete path. |
| mybd-0proh | gh 4750 (child_counters recycles archived suffixes) | 2 | **keep-open** | PR 5122 **OPEN-unmerged and explicitly partial** ("#4750 stays open"); allocator confirmed blind to archived/deleted children. Lane collision: 5122 carries maintainer commit 31388add6 from the mybd-php3l lane. |

Counts: **1 close, 2 consolidate, 2 flesh-out, 5 keep-open.** New engineering
bead: **mybd-agf58** (embedded-mode silent lost-write family, p1).

## Root-cause map

1. **Embedded-mode silent lost writes / false success** — gh 3905, 3964 (+
   gh 4371, found in comments; upstream umbrella gh 4135, 6 failure modes,
   still open and active as of 2026-07-28). One engineering bead created:
   **mybd-agf58**. All evidence is v1.0.3/1.0.4-era; the bead's first task is
   a repro against current v1.1.x before any upstream engagement.
2. **Wisp lifecycle integrity** — gh 4662 (field dropped on promotion),
   gh 4673 (dep-row orphans on deletion), gh 3360 (pre-commit interaction
   logging). Three distinct code paths in one subsystem; 4662/4673 each have
   their own open fix PR, so no consolidation bead — but a session picking up
   one should take all three.
3. **Fix-PR-pending cluster** — gh 5005, 4662, 4673, 4750: each gated on one
   open unmerged PR (5127, 4798, 4674, 5122). The gating lives in prose only;
   per the cold-start rule the owner should add dep edges (this lane cannot
   create deps). Two of those PRs (5122, 5127) sit inside the active
   mybd-php3l maintainer-push batch.
4. **Singletons** — gh 4093 (64K TEXT overflow, freshly re-reproduced,
   flesh-out), gh 3926 (likely resolved by merged PR 4217, close proposed),
   gh 3807 (issue half-rewritten-away, narrowed residual gap, flesh-out).

## Confidence and caveats

- **`gh api` is denied by the lane allowlist**, so the strategy report's
  step-1 timeline enumeration could not run. All three recon agents fell back
  to `gh search prs/issues` full-text search plus
  `closedByPullRequestsReferences`, with each candidate PR's body read to
  verify the reference. This finds text-linked PRs but can miss
  commit-message-only or unlinked fixes. Statements of the form "no fix PR
  found" carry that weaker meaning throughout. A session with `gh api` (or
  the triage lane) should spot-check the two consolidate proposals and gh
  3360 before executing closes. The pr-mirror stub join the strategy suggests
  was also attempted but the `theme:pr-mirror` inventory is now empty (0
  beads), so it contributed nothing.
- **The one close proposal (mybd-o4wzj / gh 3926) is the highest-risk call.**
  PR 4217's merge is verified by merge commit, and its body targets exactly
  the reported mechanism, but it says "Refs" not "Fixes" and no one has re-run
  the reporter's standalone→managed-city repro. If the owner is spending one
  minute on this sweep, spend it there.
- 4662 and 4673 dispositions are high-confidence: the bugs were confirmed
  live by reading current main, with file:line quotes in the stub notes.
- 3360 is genuinely unknown — the keep-open is an honest "could not verify",
  not evidence of liveness.
- `git log`/`git blame` are also denied in-lane, so no commit-history dating
  of the 3807 partial rewrite was possible.
- Recon subagent cost stayed modest (3 sonnet agents); no budget-driven
  coverage cuts — all 10 stubs got full treatment.
- Theme count drift (11 → 10) noted above; not investigated further (would
  need closed-bead history).
- `scripts/agent-sig.sh` is denied in-lane, so the signature below keeps the
  `unknown-reasoning` placeholder per signing policy rather than a guess.

_claude-code-fable-5-unknown-reasoning on behalf of maphew (unattended solo-sweep lane)_
