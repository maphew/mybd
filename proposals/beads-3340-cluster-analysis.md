# Beads PR pile and the #3340 cluster — analysis and triage

> Working analysis, not a charter. Generated 2026-05-16. State snapshots reflect what GitHub returned that day; PRs and issues evolve.
>
> Authored by Claude Opus 4.7 (1M context) on behalf of maphew.

## What this document is

Two threads tangled together:

1. A deep look at the **#3340 cluster** — the issues and PRs orbiting `bd`'s embedded-Dolt flock and its git-origin / Dolt-remote policy.
2. A candid read on **where maphew can plant his feet** given coffeegoddd's raised quality bar, harry-miller-trimble's draft plugin architecture, julianknutsen's release prep, and 138 open PRs.

Not a decision. A working document to think with.

## Contents

- [The cluster, mapped](#the-cluster-mapped)
- [Issue-by-issue](#issue-by-issue)
- [Why another agent could not reproduce #3340](#why-another-agent-could-not-reproduce-3340)
- [What is actually mergeable today](#what-is-actually-mergeable-today)
- [Strategic options for maphew](#strategic-options-for-maphew)
- [Honest read on PROJECT_CHARTER.md](#honest-read-on-project_chartermd)
- [Suggested next moves](#suggested-next-moves)
- [Data appendix](#data-appendix)

---

## The cluster, mapped

Two sub-clusters orbiting one architectural seam: git tooling (commit, push, hooks) reaching into embedded-Dolt, gated by a single per-store flock plus the beads pre-commit hook that shells back into `bd`.

### Sub-cluster A — flock re-entry deadlocks

```
#3340 (issue, open) ──fixed by── #3626 (PR, OPEN, CI green, mergeable=clean, 15 days old)
                                 siblings:
                                   #3740  CLOSED, merged — push-side variant (pmgledhill102)
                                   #3598/#3599  another commit-site variant
```

`bd dolt remote add` auto-commits `.beads/config.yaml` via `commitBeadsConfig()`. The `git commit` runs **without** `--no-verify`, which fires beads' own pre-commit hook, which shells out to `bd export`, which blocks on the flock the parent `bd` already holds. Three near-identical bugs at three different commit/push sites; #3340 is the last one outstanding.

### Sub-cluster B — git origin / Dolt remote policy

```
#3354  CLOSED — 102 GB disk fill (tmp_pack_* leak)
   └─ root cause → #3356 CLOSED — bd init registers Dolt remote unconditionally
        └─ fix → #3357 MERGED (kevglynn) — gates AddRemote on refs/dolt/data
             └─ over-corrected the v1.0.2 "init-in-clone wires sync" UX
                  └─ → #3937 issue, OPEN (maphew) — restates the policy
                       └─ → #3940 PR, OPEN (maphew) — implements items (2),(3),(6)
```

#3357 was correct for #3356 (no more 15 GB/day of leaked `tmp_pack_*` files). It also removed the convenience users remembered from v1.0.2 — `bd init` in a freshly cloned repo no longer wires the Dolt remote. #3937 is the policy proposal (five flows: init-with-origin, init-without, push-without, bootstrap, pull, doctor). #3940 implements three of them: keep init local, lazy-adopt on push, surface the exact command in `bd doctor`.

### Why both sub-clusters belong together

- Both are about state divergence between the **Git layer** and the **Dolt sub-storage**.
- Both are gated by the same embedded flock and the same pre-commit hook.
- Both are flows that *seem* like they should "just work" but cross an architectural seam that coffeegoddd's planned storage and server changes will reshape.

That's why these PRs feel mootable — and why telling them apart matters.

---

## Issue-by-issue

### Sub-cluster A — flock re-entry deadlocks

#### #3340 — `bd dolt remote add/remove` deadlocks in embedded mode

`open · issue · author: alingenhag · created 2026-04-19 · re-confirmed 2026-05-16`

Holds the exclusive embedded-Dolt flock while calling `git commit` without `--no-verify`. The beads pre-commit hook then re-enters `bd` via `bd export`, which calls `WaitLock()` and blocks forever. Two call sites (`dolt.go:749` for `remote add`, `dolt.go:962` for `remote remove`), both routed through `commitBeadsConfig`. Reporter re-confirmed today the bug is present on main at `6ec5244e0`, and that the related #3740 fix is for a different re-entry path, not this one. https://github.com/gastownhall/beads/issues/3340

#### #3626 — `fix(dolt): skip git hooks in commitBeadsConfig`

`open · PR · author: alingenhag · created 2026-05-01 · mergeable=clean · CI green`

One-line production change: `exec.Command("git", "commit", "--no-verify", "-m", msg)`. Mirrors the precedent already at `cmd/bd/init.go:1309`. Adds a 113-line regression test (`TestDoltRemoteAddRemoveDoesNotDeadlockWithBeadsHooks`) that installs real hooks and times out at 30 s — fails on main, passes on fix. Diff: +119 / −1 across 2 files. Requested reviewer: coffeegoddd. Zero reviews submitted in 15 days. https://github.com/gastownhall/beads/pull/3626

Notable: the existing embedded test suite uses `initGitRepoAt` which sets `core.hooksPath=/dev/null`. That is precisely why the bug went undetected; this PR is the first test in the suite to exercise the hook with realistic config.

#### #3740 — `fix(dolt): skip git hooks on internal push of refs/dolt/data` (merged)

`closed/merged · PR · author: pmgledhill102`

The **push-side sibling** of #3340. Same root pattern (re-entry through git hooks against the embedded-Dolt cache-mirror), different commit site. PR description explicitly distinguishes itself from #3626: "#3626 is the commit-side sibling for `commitBeadsConfig`; the same root pattern, different commit site." A reader skimming this without opening #3626 might conclude #3340 is already fixed. It is not.

---

### Sub-cluster B — git origin / Dolt remote policy

#### #3354 — embedded Dolt git-remote-cache leaks `tmp_pack` files (102 GB / 7 days)

`closed · issue · author: kevglynn · created 2026-04-19`

102 GB in `.beads/embeddeddolt/<db>/.dolt/git-remote-cache/<hash>/repo.git/objects/pack/` across 412 files in 7 days on a 460 GB MacBook Pro. Actual database content: 300 KB. Files accumulated because every Dolt fetch against a plain-git origin (no `refs/dolt/data`) failed and left the tmp file behind. https://github.com/gastownhall/beads/issues/3354

#### #3356 — `bd init` registers git origin as Dolt remote even when remote has no Dolt data

`closed · issue · author: kevglynn · created 2026-04-19`

Direct cause of the #3354 disk fill. `bd init` set `syncURL` from git origin and called `AddRemote("origin", syncURL)` whenever `syncURL != ""`, without gating on the presence of `refs/dolt/data`. The clone path correctly gated on `syncFromRemote`; the `AddRemote` and `sync.remote` persistence paths did not. https://github.com/gastownhall/beads/issues/3356

#### #3357 — `Skip Dolt remote registration for plain git source repos during init` (merged)

`closed/merged · PR · author: kevglynn`

Fixed #3356 by introducing `syncURLFromConfig` and gating `AddRemote` + `sync.remote` persistence on `syncFromRemote || syncURLFromConfig`. Correct fix for the disk-fill bug. Side effect: removed the v1.0.2 convenience where `bd init` in a freshly cloned repo silently wired the Dolt remote. That side effect motivates the rest of sub-cluster B.

#### #3909 — `fix(init): use git origin as default Dolt remote` (closed, maphew)

`closed · PR · author: maphew`

First attempt at restoring the v1.0.2 convenience under the #3357 safety guard. Bundled several concerns (init, bootstrap, hooks, JSONL fallback, docs, generated website docs, test harness). Closed in favor of the narrower #3937 / #3940 split.

#### #3937 — `bd dolt: consistently adopt git origin as the Dolt remote`

`open · issue · author: maphew · created 2026-05-13`

Restates the policy in five flows: init-with-origin, init-without-origin, push-without-remote, bootstrap, pull, doctor. Coffeegoddd's only comment: "this worked correctly in bd 1.0.2 but was broken after that somewhere along the way, needs investigation into where the regression occurred." https://github.com/gastownhall/beads/issues/3937

A regression-tracing comment on #3940 identifies the exact commit (`ac085df8c`, the #3357 merge). **That answer is on #3940, not #3937 where coffeegoddd actually asked it.** One-line ping needed.

#### #3940 — `fix(dolt): adopt git origin on first push`

`open · PR · author: maphew · created 2026-05-14 · mergeable=clean · CI green`

Implements policy items (2), (3), (6) from #3937: keep init local when no git origin; lazy-adopt origin at `bd dolt push` time; show the exact `bd dolt remote add origin <url>` command in `bd doctor`. Diff: +367 / −58 across 9 files. Requested reviewer: `beads-maintainers` team. No human reviews submitted. https://github.com/gastownhall/beads/pull/3940

Risk of becoming partially moot under coffeegoddd's storage refactor: real but bounded. The policy itself (lazy adopt at explicit-push time) is UX, not storage. The call sites in `cmd/bd/sync_remote.go` and `cmd/bd/dolt.go` may shift under the refactor.

---

## Why another agent could not reproduce #3340

The #3626 manual repro is solid *if the bd pre-commit hook actually fires*:

```bash
cd "$(mktemp -d)" && git init -q
bd init --prefix=repro
timeout 10 bd dolt remote add origin http://example.com:7007/mydb \
  && echo OK || echo HUNG
```

Five things break the reproduction while leaving the bug intact:

1. **`bd init --stealth`** skips installing the pre-commit hook. If the agent followed a "no git mutations" rule (the project's own session-completion guidance has this flavor), they may have used stealth.
2. **`core.hooksPath=/dev/null`** leaking from a parent env. Every embedded test in beads sets this via `initGitRepoAt`; if the agent ran inside a test harness or had it in shell config, the hook is silently neutralized.
3. **`bd` not on `PATH`** inside the hook subprocess. The hook shells out to `bd export`; if it cannot find the binary, the hook errors fast and the deadlock vanishes — replaced by a misleading "hook failed" exit.
4. **Conflation with the already-merged #3740.** That PR's description begins with "this is the push-side sibling of #3340; #3626 is the commit-side, still pending." An agent skimming only #3740 would mark the whole class fixed.
5. **Windows or non-POSIX flock semantics.** The embedded flock is POSIX-shaped; Windows behavior differs.

alingenhag's 2026-05-16 status update on #3340 is decisive: bug present on main at `6ec5244e0`, the offending line is unchanged, #3740 is a different re-entry path. The other agent likely hit (1), (2), or (4). If maphew has the agent transcript, the setup commands or the references list will show which.

---

## What is actually mergeable today

### #3626 — textbook new-bar PR

- `mergeable=clean`, 30+ CI runs green (every embedded-Dolt shard + 3 upgrade-smoke channels).
- Diff: +119 / −1, 2 files. Production change is **one line**; the rest is a regression test.
- Identifies and fixes a CI blind spot (`core.hooksPath=/dev/null` everywhere in the existing test suite).
- Mirrors an in-tree precedent (`cmd/bd/init.go:1309`).
- 15 days old. Requested reviewer: coffeegoddd. Zero reviews submitted.
- Author re-pinged this morning: "rebased onto current main, ready for review/merge."
- Risk of becoming moot under the storage refactor: low. `commitBeadsConfig` exists regardless of storage engine; the fix is harmless if the underlying flock is later removed.

Either it should land, or it deserves a public "deferred pending storage refactor, revisit by $date" comment. Silence is the failure mode that frustrates contributors into not trying again.

### #3940 — also clean

Same green status. Author is maphew. Risk of partial moot under the refactor is real but bounded — the policy is UX-shaped, the call sites are storage-shaped. Worth asking coffeegoddd directly before pushing on review.

### Queue context

- **138 open PRs** (gh search).
- **Zero PRs merged by coffeegoddd or julianknutsen in the recent window** returned by `gh search`. The "merging has ground to a halt" framing in the Discord message is borne out by the data.
- julianknutsen has **4 open PRs** all created or updated this week (#3989, #3990, #3991, #3943), all release-blocker shaped, all green.

---

## Strategic options for maphew

In order of force-multiplier:

### 1. Land #3626 or get it explicitly deferred

It is exactly the kind of PR coffeegoddd described as new-world. A co-maintainer review from maphew — visibly applying the new-bar checklist (minimal change, root cause, regression test, in-tree precedent) — costs ~20 minutes and either lands the PR or surfaces the reason it is parked. Either outcome unblocks alingenhag and signals to other contributors that meeting the new bar pays off.

### 2. Close the loop with coffeegoddd on #3937

He asked: *"this worked correctly in bd 1.0.2 but was broken after that somewhere along the way, needs investigation."* The investigation already happened — `ac085df8c` (PR #3357), captured in a comment on #3940. That answer is on the implementation PR, not on the issue he commented on. A one-line ping on #3937 referencing the SHA is free attention-debt repayment.

### 3. Lock down Julian's CLI surface

julianknutsen "needs support for a few new CLI arguments to take advantage of [perf improvements]" before the early-next-week release. That is a small, scopable contribution that meets the new bar trivially (flag + test + doc). Ask him directly which flags. Deliver one with the same shape as #3626. Visible to him; lands in the release; unambiguous value.

### 4. Triage, do not architect

138 open PRs. PR_MAINTAINER_GUIDELINES.md already gives the categories: easy-win, fix-merge, needs-review, cherry-pick, split-merge, retire, reject. As a co-maintainer, maphew has permission to actually run them. A weekly pass on 10–15 PRs moves more value than another design document. Coffeegoddd's quality bar *is* a triage spec: minimal change, root cause, regression test, in-tree precedent — any PR that fails it on first read is fix-merge or retire-with-attribution.

### 5. Battle-test the charter; do not rewrite it

PROJECT_CHARTER.md is well aligned with the quality bar. Three gaps:

- **It is not on the agent default reading path.** `bd-main/CLAUDE.md` and `bd-main/docs/CLAUDE.md` point to AGENTS.md and PR_MAINTAINER_GUIDELINES.md. Only PR_MAINTAINER_GUIDELINES.md references the charter, and only when a PR changes Beads' product surface area. Agents authoring features will not consult it. If maphew wants design-time consultation, the charter needs an inbound link from AGENTS.md or `docs/CLAUDE.md`'s architecture section.
- **It says "absorb useful work when practical" but does not authorize "retire — superseded by upcoming refactor" with a date.** That is the missing outcome for the current moment: coffeegoddd has said "many PRs will be unnecessary after my storage and server changes," but there is no public maintainer outcome for saying that to a contributor without it reading as ghosting.
- **It and PR_MAINTAINER_GUIDELINES.md do not cross-reference each other.** They are the two halves of one answer.

Cheap battle test: hand both docs to an agent, ask it to triage 20 open PRs strictly under them, and watch where it gets stuck or makes the wrong call. The stuck points are the gaps that bind.

---

## Honest read on PROJECT_CHARTER.md

It is on the right track. The boundaries (core / orchestration / storage / schema / integration) match how coffeegoddd is signaling. The "review posture" section — *fences not bounce messages, absorb useful work, preserve attribution* — is consistent with PR_MAINTAINER_GUIDELINES.md.

What it does not do is reduce the PR pile. It is a *what belongs where* doc. The pile needs a *what to do with it today* doc. PR_MAINTAINER_GUIDELINES.md is closer to that, but does not yet authorize the maintainer outcome the current moment most needs: **retire — superseded by upcoming refactor, with a date marker and revisit policy.**

The 130-PR pile is not a charter problem. It is a queue throughput problem with a charter-shaped boundary policy underneath. The fastest way to validate the charter is to run triage and see where the docs fail you.

---

## Suggested next moves

In order of when they pay off:

**Today, ~30 minutes.**
- One-line comment on #3937: regression SHA `ac085df8c` (PR #3357), pointing at the longer note on #3940.
- New-bar review on #3626, applying the checklist in public: minimal change, root cause, regression test, in-tree precedent, CI green, mergeable clean. Either request merge or ask coffeegoddd for an explicit deferral decision.
- Direct message to julianknutsen: which CLI flags does the release need?

**This week.**
- Triage 15–20 of the oldest open PRs against PR_MAINTAINER_GUIDELINES.md.
- Land any of Julian's release PRs you can credibly review.
- Take one CLI-flag scope from Julian and ship it.

**This month.**
- A small PR adding the "retire — superseded by upcoming refactor" outcome to PR_MAINTAINER_GUIDELINES.md, with a date marker convention.
- Cross-link PROJECT_CHARTER.md and PR_MAINTAINER_GUIDELINES.md.
- Add a charter pointer to AGENTS.md so design-phase agents see it.

---

## Data appendix

State snapshots as of 2026-05-16.

### #3626

```
head: alingenhag:fix/3340-dolt-remote-deadlock → base: gastownhall:main
mergeable: true | mergeable_state: clean
draft: false | state: open
additions: 119 | deletions: 1 | changed_files: 2
created: 2026-05-01T18:36:48Z | updated: 2026-05-16T10:20:43Z
requested_reviewers: coffeegoddd
reviews submitted: 0
checks: 30+ completed/success (all embedded-dolt shards, build, upgrade smoke)
```

### #3940

```
head: maphew:fix/git-origin-adoption → base: gastownhall:main
mergeable: true | mergeable_state: clean
draft: false | state: open
additions: 367 | deletions: 58 | changed_files: 9
created: 2026-05-14T16:03:19Z | updated: 2026-05-15T14:40:55Z
requested_reviewers: (none individual) | requested_teams: beads-maintainers
reviews submitted: 0
checks: 30+ completed/success
```

### Queue

```
Total open PRs (gh search):           138
Page-1 of /pulls?state=open:          100
julianknutsen open PRs:                 4  (3989, 3990, 3991, 3943; all this week)
julianknutsen merged in recent window:  0
coffeegoddd  merged in recent window:   0
```

### Cluster IDs at a glance

| ID    | Type  | State           | Author          | Sub-cluster | Role                                      |
| ----- | ----- | --------------- | --------------- | ----------- | ----------------------------------------- |
| 3340  | issue | open            | alingenhag      | A           | The deadlock                              |
| 3626  | PR    | open / clean    | alingenhag      | A           | Fix for #3340                             |
| 3740  | PR    | closed / merged | pmgledhill102   | A           | Push-side sibling, already landed         |
| 3598  | PR    | closed          | —               | A           | Earlier commit-site variant               |
| 3354  | issue | closed          | kevglynn        | B           | 102 GB disk fill                          |
| 3356  | issue | closed          | kevglynn        | B           | Root cause of #3354                       |
| 3357  | PR    | closed / merged | kevglynn        | B           | Fix; introduced the v1.0.3 regression     |
| 3909  | PR    | closed          | maphew          | B           | First-pass restore; superseded            |
| 3937  | issue | open            | maphew          | B           | Policy proposal (5 flows)                 |
| 3940  | PR    | open / clean    | maphew          | B           | Implements items (2),(3),(6) of #3937     |

### Links

- https://github.com/gastownhall/beads/issues/3340
- https://github.com/gastownhall/beads/pull/3626
- https://github.com/gastownhall/beads/pull/3740
- https://github.com/gastownhall/beads/issues/3354
- https://github.com/gastownhall/beads/issues/3356
- https://github.com/gastownhall/beads/pull/3357
- https://github.com/gastownhall/beads/pull/3909
- https://github.com/gastownhall/beads/issues/3937
- https://github.com/gastownhall/beads/pull/3940
