# The "late-May-2026 re-root" of beads main never happened - 2026-07-05

**Verdict: false alarm.** There was no history rewrite, no force-push, no severed ancestry on
`gastownhall/beads` `main`. The "re-root" was an artifact of running forensics inside a **shallow
clone**: the local `bd-main` checkout on this machine was cloned around 2026-05-28 with limited
depth, and its shallow boundary - commits that git deliberately records as parentless in
`.git/shallow` - was misread as three parentless "root" commits proving a server-side rewrite.

Bead: mybd-q1c9. Supersedes the "re-root" framing in mybd-bys5 (orphan inventory) and the
premise of mybd-ufzk (orphan disposition).

## What the earlier forensics claimed vs what is actually true

| Claim (mybd-q1c9 comment, 2026-07-05) | Server-side reality (GitHub API, 2026-07-05) |
|---|---|
| `main` has THREE parentless root commits (e49bc9185, d7469d5ab, 0a61a566b) | All three have parents on GitHub: `e49bc9185` → `f8b9400165`; `d7469d5ab` → `f8b9400165` + `e898babbe6`; `0a61a566b` → `fc0679b8cc` + `3068bc4280` |
| Oldest reachable commit is 2026-05-25; ~7 months of history severed | Genesis `704515125` (2025-10-11) IS an ancestor of `main`; `main` is 9,441 commits ahead of it, 0 behind (`compare` API status: "ahead") |
| A batch history rewrite ran ~2026-05-25 16:26 PDT (same-second committer restamps) | The restamps are on Jim Wordelman's feature-branch commits, re-stamped by an ordinary `git rebase` onto `f8b9400165` before merge. Normal contributor workflow, not a repo-wide rewrite |
| 69-70 open PRs are true orphans (no merge-base with main) | **All 70 have valid merge-bases** via the compare API (status `diverged`, behind_by 411-1006). They are ordinary stale PRs that can be rebased/merged normally |
| Mechanism: rebase/graft/filter-repo class rewrite, force-pushed | GitHub activity API: **zero force-pushes to `main` since 2026-04-06**. The `main` ref chain is contiguous through 2026-05-25..28 (every event's `before` equals the previous event's `after`) |

## The decisive evidence

1. **Activity API** (`repos/gastownhall/beads/activity?ref=refs/heads/main&time_period=year`):
   continuous `pr_merge`/`push` chain across the suspect window. Force-push events on `main` in the
   last year: 2026-04-06 (maphew, x2), 2026-02-19 (steveyegge), and earlier - nothing in May.
2. **Commits API**: every "root" commit has parents server-side (see table above).
3. **Compare API**: `704515125...main` → `ahead_by: 9441, behind_by: 0`. History intact back to genesis.
4. **Local clone inspection**: `bd-main/.git/shallow` exists and lists exactly the "root" commits
   (e49bc9185, d7469d5ab, 0a61a566b, fc0679b8cc, ...). `git rev-parse --is-shallow-repository` → `true`.
   The clone reflog shows `clone: from https://github.com/maphew/beads.git` at `e1e97e6c5`, which was
   `main`'s head on 2026-05-28 - a depth-limited clone made that day puts the shallow boundary
   precisely at commits merged 2026-05-25..28. That is why the "roots" all date to that window.
5. **All 70 "orphaned" PRs re-checked** against the server one by one: 70/70 `diverged` with a real
   merge-base. Zero orphans. (Raw results: 70-row TSV, PR → status/merge-base/behind-by, archived in
   the bead comment.)

## Answers to the bead's questions

1. **Intentional or accidental?** Neither - no re-root occurred. The repo's history was never rewritten.
2. **Who/what performed it?** Nobody. The "operation" was a `git clone --depth=N` (or equivalent) of
   the fork on ~2026-05-28 creating this machine's `bd-main`.
3. **Why three roots on three dates?** They are shallow-boundary commits. A depth cutoff lands on
   whatever commits sit N deep on each merged lineage; three lineages crossed the boundary.
4. **Is another re-root likely?** The question dissolves. There is no instability in upstream `main`;
   it has only ever fast-forwarded since April. Long-lived PR intake does not need to be frozen.
5. **What practice would have prevented the misdiagnosis?**
   - Before concluding "history rewrite", check `git rev-parse --is-shallow-repository` and
     `.git/shallow`. Parentless commits + shallow file = clone artifact, full stop.
   - Verify ancestry claims against the server (`gh api .../compare/A...B`), not only a local clone.
   - The GitHub **activity API** answers "was main force-pushed, when, by whom" directly and is
     available with plain read access - use it first, not last.

## Remediation done in this session

- `bd-main` unshallowed via `git fetch --unshallow upstream` (full history restored locally).
- Erratum notice added to `reports/orphaned-pr-inventory-2026-07-05.md`.
- mybd-q1c9 closed with these findings; correction comment added to mybd-ufzk.

## Impact on related work

- **mybd-ufzk (disposition of "70 orphaned PRs")**: the *classifications* in the inventory
  (superseded / stale / live) were verified against main's actual content and remain useful. But the
  framing changes completely: the 55 "salvage" PRs do **not** need reimplementation - they are
  normal diverged PRs (behind by 400-1000 commits) that contributors can rebase, or maintainers can
  merge after a routine update. The "close 13 superseded/stale" batch remains valid as-is.
- **No upstream issue should be opened about a "schism"**: there is nothing wrong with the upstream
  repo. Opening one would report a defect that does not exist.
- The "cutover-protocol gap" noted in the 2026-07-05 review sweeps, insofar as it rested on the
  re-root, is likewise moot.

---
_claude-code-fable-5 investigation, 2026-07-05. Evidence gathered via GitHub REST API (activity,
commits, compare endpoints) and local clone inspection; no repo state was modified other than
unshallowing `bd-main`._
