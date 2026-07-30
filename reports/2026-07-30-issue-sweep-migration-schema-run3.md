# Issue sweep: theme:migration-schema (run 3) — 2026-07-30

Unattended solo-sweep lane. Theme had **8 open `tri:claim` stubs** (down from 12
at the 2026-07-26 sweep); all 8 examined, none skipped, cap of 12 not hit.
Nothing published, nothing closed — dispositions below are proposals, each
recorded on its stub as `solo-sweep:proposed`.

## Dispositions

| bd | gh | p | proposed | evidence |
|----|----|---|----------|----------|
| mybd-ltbf2 | 4138 | 1 | **close** | Fixed by PR #4139, **verified merged** 2026-05-24, merge_commit `8ae4c3c67b3d035b4b9d9efd90dbfeee14460107`; `git log main --grep=4139` returns it, so it is on main. That commit added `ignored/0007_recompute_wisp_is_blocked.up.sql`, the backfill `0006_add_wisp_is_blocked` omitted; later NULL-hardened by `ignored/0015` (b445e1a2d). Runtime recompute covers wisps symmetrically (`issueops/blocked_state.go`, close/reopen/dependencies call sites). Issue open only because nobody closed it — zero comments since filing. |
| mybd-ypqx | 5033 | 1 | **consolidate → mybd-n0147** | Not fixed: no PR/commit anywhere references 5033. Root cause found in code (below). New 2026-07-26 reporter comment adds a 4-clone repair matrix; sharpest datum: clearing the cursor then running a bd command repopulated it 0→11 *without creating any tables*. |
| mybd-lvss | 4356 | 1 | **keep-open** | Not fixed (empty timeline crossrefs, `git log --all --grep=4356` empty). Same root-cause site as 5033, but **not folded**: maphew has an active upstream lane and the untrack half is destructive cross-clone. New superlzyguy 2026-07-26 independent confirmation *with a minimal repro* answers maphew's 2026-06-16 repro request. |
| mybd-efzs | 4800 | 1 | **keep-open** | PR #4504 **verified merged** 2026-07-28, merge_commit `b4ac3619896780c8f09166646ce944d1f86cdf6d` — and verified *not* a fix: maphew's own 07-28 upstream scope note explains the repairs short-circuit on a pristine store while this issue's mechanism (`dolt_nonlocal_tables` writes bypassing the working set) is different. The `tri:stale` + tri-drift flags are self-inflicted by that comment; propose removing `tri:stale`. |
| mybd-ghh34 | 3886 | 1 | **keep-open** | Dead letter: 0 comments, empty timeline, `updated_at` still the filing timestamp, no commit references it in 79 days. Same "nothing to commit" family as 4800 but a different entry point (bootstrap commit-init). Could not check whether #4504's idempotency work reaches that path — see caveats. |
| mybd-ztve | 5061 | 1 | **flesh-out** | Live, nothing attempted (0 comments, empty timeline, no commits). Already absorbed gh 4274 in sweep 1, so it represents a 2-issue group. Note adds acceptance criteria + the `schema.go` MigrateUp / `embeddeddolt/store.go:263,383` code path. Verify against post-#4504 main first — #4504 touched exactly this territory. |
| mybd-133z1 | 3495 | 1 | **flesh-out** | 95 days dormant, 0 comments, one `subscribed` event, no commits. Not stale though: `--reinit-local` is live and is the *recommended replacement* for deprecated `--force` (`cmd/bd/init_safety.go`, guard asserted in `init_guard_test.go`). Note adds acceptance criteria for both reported harms. |
| mybd-k4s27 | 3059 | 3 | **flesh-out** (split; new bead mybd-qcshp) | 2778 occurrences / 1189 files; `go.mod:1` still `github.com/steveyegge/beads`. PR #3060 **verified merged** (merge_commit `1cbde7ee738d76555565a2d6e3235727c3a6d891`, confirmed on main) and verifiably incomplete — issue closed 04-06, **reopened 04-07**. Mechanical non-module subset carved into mybd-qcshp; module rename stays here as an owner call maphew explicitly deferred. |

Net: 1 close, 1 consolidate, 3 flesh-out, 3 keep-open. Two new engineering
beads filed.

## Root-cause map

**Group A — the `ignored_schema_migrations` cursor (gh 5033 + gh 4356).** New
bead **mybd-n0147** (p1). One table causes both symptoms. `schema.go`
`currentVersion()`/`atLatest()`/`migrationWorkNeeded()` (1038-1047, 1030, 576)
trust the cursor rows and only special-case a *missing* cursor table, never a
cursor claiming tables that do not exist — so a clone inheriting the tracker
short-circuits the 0006/0007/0015 ignored series and never creates
`wisps`/`wisp_dependencies` (**5033**). The same table is in
`doltIgnorePatterns` (258-265) and re-seeded from `MigrateUp` (404) at every
store open, so where it was committed to HEAD before `dolt_ignore` took effect
it is rewritten and re-diffed forever (**4356**). There is no untrack path
(`DOLT_RM`/`dolt_rm`/`DOLT_REMOVE` appear nowhere in Go source) and no
verify-then-reapply self-heal. Two independent fleets confirm.

**Group B — the "nothing to commit" migration-commit class (gh 4800, 3886,
5061).** Anchor stays mybd-efzs. Three distinct commit sites: 0040's frozen
internal `DOLT_COMMIT`, bootstrap's commit-init, and the store-open
compat-migration commit. #4504 landed in this territory 2026-07-28 but is
confirmed not to close 4800; whether it incidentally covers 3886 or changes
5061's no-op-commit half is **unresolved** and is the cheapest next check in
the theme.

**Group C — unrelated singletons.** gh 3495 (`--reinit-local` destructiveness)
and gh 3059 (steveyegge references) share nothing with A or B; 3059 is only
theme-labelled `migration-schema` in the "repo move" sense. New bead
**mybd-qcshp** (p3) for 3059's mechanical subset.

## Confidence and caveats

- **The blocking limitation of this run: `bd-main`'s local `main` is
  `dbbf3a961` (2026-07-27), behind `upstream/main` `423afdcb2`, and behind the
  #4504 merge `b4ac36198` (2026-07-28).** Every code observation here is from a
  three-day-stale working tree. This matters most for Group B: the tree shows
  0040 with four bare internal `CALL DOLT_COMMIT('-Am',…)` and
  `migration_repairs.go` `preMigrationRepair` switching only on `case 47`/`53`
  with no `case 40`/`41` — which is exactly what *pre*-#4504 looks like, so it
  is not evidence about current main. I have no write verb and could not fetch.
  A session with a fetched clone should re-read 0040 and
  `migration_repairs.go` before any Group B fix work.
- **Confident:** all three "merged" claims name a PR number, an API
  `merged: true` with timestamp, and a `merge_commit_sha`; #4139 and #3060 were
  additionally confirmed present on local `main` by git log. The #4504 claim
  rests on the API alone (the commit object exists locally but is not in local
  main's ancestry — consistent with being behind, not with being unmerged).
- **The one close I propose (mybd-ltbf2) is the one to sanity-check first** if
  you check anything. It is the only disposition that discards a p1, and its
  file-level evidence comes from the stale tree — though the merge itself
  cannot be undone by that staleness.
- **Deliberately not asserted:** that gh 3886 is fixed (could not check the
  path), that gh 3495's two harms still reproduce (flag exists; implementation
  unread), and that 4356 should fold into mybd-n0147 (owner-active lane, and
  the fix is destructive cross-clone).
- **Two traps worth carrying forward for future freshness passes.** (1) gh 3059
  was closed-then-reopened around a genuinely merged PR that genuinely did not
  finish — a "merged PR referenced → close" rule closes it wrongly. (2)
  mybd-efzs's `tri:stale` + tri-drift flags were triggered by *our own*
  upstream comment, not reporter activity; drift signals should discount
  self-authored comments the way the pr-babysit review lane already does.
- No blocked commands, no rate limiting. Both fan-out recon agents completed;
  one flagged the same clone-staleness gap independently.
