# Issue sweep — theme:doctor (solo-sweep run 6)

2026-07-30, unattended lane. Theme `doctor`: 7 open `tri:claim` stubs, all 7
examined (theme is smaller than the 12-stub cap; nothing left unreached).
Cluster parent: mybd-xmx7.10.

**Nothing was executed.** All dispositions below are proposals; each stub
carries a `solo-sweep:proposed` note with the full evidence.

## Dispositions

| stub | gh | pri | proposal | evidence |
|---|---|---|---|---|
| mybd-yc8c | 4475 | p1 | **close** | PR #4933 **merged** 2026-07-28T04:29:02Z, merge commit `88454d54a` (verified via API `merged:true`). On `upstream/main`, `cmd/bd/doctor/integrity.go` has no `WITH RECURSIVE`: keyset-paged edge loads (`dependencyCyclePageSize=1000`, `dependencyCycleMaxEdges=1_000_000`) over `{dependencies, wisp_dependencies}` + iterative Tarjan SCC. Issue timeline has **no** link to 4933 — unlinked fix. |
| mybd-uh8q | 4993 | p1 | keep-open (gate) | No schema-version guard anywhere on `--fix` at `upstream/main`. Commit `90c6f46f5` (#5142, merged) added only `verifyFixTargetIdentity` — a **project-identity** check (`_project_id` vs metadata.json), not schema skew. Fix PR #5145 is **open, unmerged**; owned by mybd-dcdfw + mybd-bwx67. |
| mybd-kr0i | 5025 | p1 | keep-open (gate) | All three report claims verified on main: `testPrefixPattern` +0.7 on lowercased title, same-minute-≥10 +0.3 → 1.00 reachable by a real epic; no status/type filter (`SearchIssues` with empty filter); `doctor/validation.go:220-223` SQL predicate genuinely differs from the scorer regex. Fix PR #5137 ("Closes #5025") **open, unmerged**; review bead mybd-54zj9. |
| mybd-rnjr | 5026 | p2 | keep-open (gate) | `epic_closure.go` on main still counts children by `status == closed` only; `close_reason` never consulted. Fix PR #5138 (head `18b79ec7a`) **open, unmerged** — and `18b79ec7a` is **not** an ancestor of main, despite appearing as a `referenced` event on issue 5026. Review bead mybd-kj8rp. |
| mybd-8bse | 4814 | p2 | **flesh-out** | Predicate on main is one-directional prefix only: `WHERE d.issue_id LIKE CONCAT(d.depends_on_id,'.%')`. New upstream comment 2026-07-28 (jacobhausler) adds a verified 3-node cycle no prefix test can catch, and a better fix. Resolves the `tri:stale` flag. Scope expanded; spun out mybd-p2wyk. |
| mybd-7vyw | 4539 | p2 | keep-open (gate) | No `child_counters` orphan detection on main. PR #4858 **open, unmerged**; its branch commits (`6a65d999a`, `cb2cfc7db`) appear as `referenced` events on the issue but are not on main. Already owned by mybd-dodi9 (owner decision) + mybd-fyno. |
| mybd-1yi6x | 3705 | p3 | **flesh-out** | `doctor/git.go CheckGitWorkingTree` runs `git status --porcelain` with `cmd.Dir` = the beads repo root; no bare-repo / linked-worktree handling → exit 128 in the reported layout. No fix in flight, no upstream comments since 2026-05-04. |

Counts: 1 close · 4 keep-open · 2 flesh-out · 1 new engineering bead.

## Root-cause map

**A. Fix already in flight upstream — 3 stubs (4993, 5025, 5026), all p1/p2.**
The dominant finding. Every one has an open vishnujayvel PR (#5145, #5137,
#5138) and a `review-needed` bead already queued (mybd-dcdfw/mybd-bwx67,
mybd-54zj9, mybd-kj8rp). The sweep's value here is **linking, not deciding**:
these stubs are duplicating review work that another lane already owns, and
each should get a dep edge so `bd ready` stops surfacing it independently.

**B. Detector predicate too narrow — 2 stubs (4814, 4539).**
Both are "doctor cannot see a class of drift that actually bricks work."
4814 additionally turned out to be under-specified *as filed* — see below.
4539's real blocker is an owner call on PR #4858 (mybd-dodi9), not engineering.

**C. Path resolution not worktree-aware — 1 stub (3705).**
Only stub with no fix in flight and no upstream engagement in ~3 months.
Umbrella #3601; #3120 migrated some checks and missed these two.

**D. Fixed and verified — 1 stub (4475).**

Cross-cutting: `mybd-v479b` (CGO gate darkens 13 doctor checks) and
`mybd-qx3f` (doctor Dolt tests have no PR-CI path) sit under all of these —
several of these bugs shipped because the check that would catch them does not
run in CI or does not run in the default build.

## New / housekeeping

- **mybd-p2wyk (new, p2)** — `DetectCycles`' edge set disagrees with
  `AffectsReadyWork()`: `AffectsReadyWork` includes `DepParentChild`, the cycle
  detector does not, so parent-child deadlocks are invisible to `bd dep cycles`
  at any path length. Filed separately from mybd-8bse because widening a
  read-only *detector* carries none of the over-rejection risk that made the
  write-time guard contentious — it can land independently of the destructive
  `--fix-child-parent` question.
- **mybd-h9w5** (p3, deferred, "Track upstream #4539") is a duplicate tracker of
  mybd-7vyw. Suggest closing it as a dupe.

## Confidence and caveats

- **The one close is the strongest claim here.** #4933's merge was verified via
  the GitHub API (`merged: true` + merge commit), and the merged behaviour was
  then re-verified in the source at `upstream/main` — not inferred from the PR
  title. Two independent confirmations.
- **Three "referenced" commits in this theme were not merges** (5026's
  `18b79ec7a`, 4539's `6a65d999a`/`cb2cfc7db`). Read naively, each would have
  produced a wrong close on a live bug. Conversely #4933 *was* a real fix with
  **no** timeline link at all. Timeline cross-references were, in this theme,
  anti-correlated with truth in both directions.
- **Do not read #5142 as fixing 4993.** Both are "guard before destructive
  doctor `--fix`"; one checks project identity, the other schema version. They
  are different guards and only the identity one has merged.
- **I did not read the diffs of PRs #5137, #5138, #5145** — only their
  descriptions and head SHAs. My "fix in flight" claims mean *a PR exists that
  targets this defect*, not *that PR is correct or sufficient*. That judgement
  belongs to the review beads.
- **Unverified sub-claim (3705):** I confirmed the Git Working Tree half in
  code but did **not** read `agentDocFiles()`' path resolution, so the Agent
  Documentation half rests on the reporter's shared-root-cause argument.
- **Unverified sub-claim (4814):** the two live deadlock instances are the
  commenter's `bd dep list --json` output, not reproduced by this lane. The
  *code* asymmetry they rest on (`AffectsReadyWork` vs the detector's filter) I
  did verify directly.
- **Not re-audited (4475):** the 2026-07-21 reconcile note flagged a possible
  `rows.Scan` error path that repeats a page without advancing the cursor. Wisp
  parity is now confirmed; the cursor concern is not, and it is now a question
  about *merged* code. If it matters, it needs its own bead.
- All beads source read at `upstream/main` (HEAD `84431ee5c`). No working-tree
  reads. No blocked or denied commands; bd and the GitHub API were available
  throughout.

_solo-sweep lane (claude-opus-5) on behalf of maphew_
