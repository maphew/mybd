# Triage: johnzook's five open PRs against gastownhall/beads

Date: 2026-07-03
Trigger: John's DM (2026-07-02/03) noting five PRs with zero response, aged a month to a day.
Method: one independent reviewer agent per PR (diff + current upstream/main sources + drift check), followed by an adversarial pass on any "merge before 1.1 stable" verdict. Contributor's own per-PR notes were used as signal, verified independently. Six agents, ~252k tokens.

## Context

- Release state: v1.1.0-rc.2 is the current pre-release (2026-07-02); stable is imminent. Maintainer default: hold merges to main until after stable unless clearly safe/beneficial now.
- All five PRs: git-level MERGEABLE, zero comments, zero reviews, and **zero CI signal** - workflow runs were never approved for this external contributor.
- Upstream preflight (`pr-preflight.sh`) passed for all five apart from the UNSTABLE merge state (which is just "no CI + no review"). No competing PRs.

## Verdict summary

| PR | Title (short) | Risk | Verdict |
|----|----------------|------|---------|
| [#4481](https://github.com/gastownhall/beads/pull/4481) | close dolt pool on failure paths | low | hold to post-stable; land **first** |
| [#4550](https://github.com/gastownhall/beads/pull/4550) | mark `bd query` read-only | low | hold to post-stable; land early |
| [#4479](https://github.com/gastownhall/beads/pull/4479) | SHOW COLUMNS content_hash probe | low | hold to post-stable; pull-forward candidate |
| [#4150](https://github.com/gastownhall/beads/pull/4150) | id-only projection for ResolvePartialID | low | hold to post-stable; land after the small ones |
| [#4480](https://github.com/gastownhall/beads/pull/4480) | filter before counts joins | medium | **needs a one-line test fix** (does not compile), then post-stable |

**Bottom line: hold all five until after v1.1.0 stable.** None clears the freeze-exception bar. #4481 came closest (it fixes a real defect) but the leak is failure-path only, not steady-state, so deferring costs almost nothing. This matches the maintainer's instinct.

**Do now, at zero risk:** approve the CI workflow runs on all five PRs (gets real signal before the post-stable batch), and comment on each PR with the triage verdict so John finally gets a response.

## Per-PR detail

### #4481 - close db pool on any failure path (fix, 1 file, +20/-10)

Correct. Diff base blob is byte-identical to current upstream/main (zero drift). The sentinel-guarded `defer db.Close()` pattern is sound: no double-close, ownership transfer via the ready flag is right, `initDB` keeps its own independent defer. It fixes one genuine defect - the `initSchema` failure branch in `newServerMode` returned without closing the pool - and forget-proofs the rest, which were already correct. John's "leak during failures" framing slightly overstates impact (failure path, not steady-state creep), which lowers urgency, not safety. No regression test included; one asserting the pool closes on an induced initSchema failure would lock it in but is not a blocker. The adversarial pass agreed the code is right and refuted only the *pre-stable timing*, on release-hygiene grounds.

### #4550 - mark `query` command read-only (perf/hygiene, 2 files, +2/-1)

Correct and beneficial. `bd query` is beads' own filter DSL (parses to `query.Node`, calls `SearchIssues*`), not raw SQL, so it is a pure read and was the anomaly among read commands opening the store writable. One honest caveat for the merge note: the PR body's "behavior unchanged" claim is inaccurate. Read-only classification also skips JSONL auto-import, post-command auto-export (including the #4557 SQL-server export path that landed after this PR opened), and auto-push. All consistent with `list`/`search`/`ready`, but observable: `bd query` as first command after a pull may show staler data until a write command runs.

### #4479 - SHOW COLUMNS instead of INFORMATION_SCHEMA probe (perf, 5 files, +252/-19)

Correct and the best-tested of the batch: sqlmock units (present/absent/missing-table/LIKE-wildcard-rejection/error-propagation), a gated real-Dolt parity test against the retired probe, and a benchmark. Bool semantics are provably equivalent; the `_` LIKE wildcard is neutralized by exact Field comparison. John's cross-platform/DB worry is well-contained: the missing-table swallow rides `dberrors.IsTableNotExist`, which `currentVersion()` already trusts on the identical runtime paths, and both embedded and sql-server modes share the same GMS engine. Held only because it sits on the per-connection migration-work-needed path right before a stable cut with no CI signal. If a CPU win is wanted in a 1.1.x patch, this is the cleanest pull-forward.

### #4150 - narrow SearchIssues to id-only projection (perf, 12 files, +463/-139)

No correctness defects found. The generic `searchProjection[T]` refactor faithfully preserves the wisp-merge, dedup, and Pattern-B semantics; the `SkipWisps` hatch survives; all five concrete Storage/Transaction implementers are covered, so no build break. Despite the May 24 open date it was rebased 2026-07-02 and matches current main exactly, including the sqlbuild extraction and prefer-wisp logic that landed in between. Parity test covers 9 filter scenarios at the store level plus a benchmark. Held because it rewires the search core shared by every list/show/search command - a broad hot-path generics refactor with no CI signal does not clear the pre-stable bar. Known review notes: `doltTransaction.SearchIssueIDs` is a documented full-hydration stub (no production caller yet); transaction-level variants and sql-server mode are untested. Roadmap fit is good: one new driver-interface method, consistent with the existing SearchIssues family.

### #4480 - filter main table before counts aggregate joins (perf, 5 files, +347/-3)

The production SQL rewrite is sound and I agree with John's semantics argument: every join is a LEFT JOIN onto a pre-aggregated GROUP BY subquery (one row per main row), the WHERE references only main-table columns or id-keyed correlated subqueries, and placeholder order is preserved - filtering before the joins is result-equivalent while avoiding full-table aggregate materialization. Contract comments pinning the invariant are a nice touch.

**Blocker, verified independently:** the new parity test calls `ptr(1)` but no `ptr` helper exists anywhere in the `internal/storage/dolt` test package (only `ptrString`; confirmed in the PR diff, the fork's tree at head SHA, and upstream/main). The whole dolt test package fails to compile, so the flagship parity test never ran and the PR's "make test green" claim is unsubstantiated. The fix is one line (`func ptr[T any](v T) *T { return &v }`). Per PR_MAINTAINER_GUIDELINES, prefer asking John to push it or absorbing it in a credited follow-up over a request-changes bounce. Minor: the doc comment claims ORDER BY/LIMIT are pushed into the inner subquery; only WHERE is.

## Process gap: why triage never saw these

Filed as **mybd-fry6** (P1). Two independent failures:

1. **The sweep never ran against this database.** Zero `gh-pr-*`/`gh-iss-*` mirror beads exist across all statuses (78 beads total), and there is no `tri-daily` crontab entry on this machine. The tri-* pipeline exists but has never populated the tracker.
2. **The limit cannot reach the backlog anyway.** `tri-pull` defaults to `--limit 100` with gh's newest-first ordering; upstream has 212 open PRs and #4150 sits at position 111. Even a running sweep would have aged #4150 out of view.

Fixes proposed in the bead: schedule `tri-daily` (installer script exists), paginate or raise the limit above the open-PR count, and do a one-time backfill at `--limit 300`.

## Follow-up beads

| Bead | Action |
|------|--------|
| mybd-c1ju | Land #4481 first, post-stable, after green CI |
| mybd-lzjk | Land #4550, note the auto-import/export/push behavior change |
| mybd-8jz8 | Land #4479; pull-forward candidate for a 1.1.x patch |
| mybd-7y4r | Land #4150 after the small ones |
| mybd-psis | #4480: get the one-line `ptr` helper fix, then land |
| mybd-fry6 | Fix the triage sweep (P1) |
