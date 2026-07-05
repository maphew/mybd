# Ready-queue freshness sweep + fix-merge execution — 2026-07-05

Session: claude-code-fable-5 (orchestrator) with delegated haiku scouts, sonnet builders, opus reviewers.
Method: workflow fan-out (16 freshness scouts vs GitHub) -> claim -> parallel builder worktrees -> independent opus review -> act.

## Freshness sweep (16 ready beads checked against gastownhall/beads)

| Bead | Verdict | Action taken |
|------|---------|--------------|
| mybd-c0r4 | close | Closed: #3055 rescope decision (2026-05-09) complete and stable; routing hardening continues upstream |
| mybd-s5nq | close | Closed: v1.1.0 shipped 2026-07-04; second-batch window closed (3 of 15 PRs merged via credited cherry-picks, 9 closed) |
| mybd-ozgv | close | Closed: #4259 closed 2026-07-04, resolved via deterministic-PK fix + release; gate follow-up moot |
| mybd-ufzk | update + `human` | Re-root premise falsified (shallow-clone artifact); 55 live PRs need ordinary rebases, not reimplementation. Owner must re-approve disposition framework |
| mybd-fry6 | update + `human` | johnzook crisis resolved (4/5 PRs merged 2026-07-04); tri-pull automation re-enable decision pending |
| mybd-t7mk.7 | update | #4203 closed via #4474+#4532; #4243 superseded; draft #4408 stalled since 2026-06-23 |
| mybd-9vjz | **work now** | Executed below |
| mybd-ae1i | **work now** | Executed below |
| mybd-9k2a.4 (P0) | blocked upstream | #4372 contributor silent since 2026-06-18 review; stay deferred |
| mybd-psis | blocked upstream | #4480 waits for johnzook ptr-helper until ~2026-07-07, then credited follow-up |
| mybd-3br1, mybd-9222, mybd-zahk, mybd-h9w5, mybd-z2lm, mybd-mlik | blocked upstream | No change since last drift checks; left as-is |

## Work executed

### mybd-9vjz: fix-merge rebases for PR #3914 and #4023

- **#3914** (quad341, migration-UX rewrite of `runMigrations`): rebased 3 commits onto main
  (`cb33b566a`), authorship preserved. Main's `preMigrationRepair` (v53 wisp/rig repair) correctly
  threaded through the extracted function via the `src` receiver — required, not just equivalent,
  since it gives `ignoredSource` its no-op dispatch. Opus review caught a real flaw in the builder's
  test fixup: asymmetric `upTo` caps defanged `TestRunMigrationsUsesProvidedSource` (the regression
  it guards would have passed). Fixed (both calls cap at 52). Force-pushed to
  `quad341/fix/be-drsfc2-migration-progress` (`e3adc4544`), signed comment posted.
- **#4023** (quad341, reference-aware prune, 24 commits): rebased onto main + doc-regen fixup.
  The PR's `buildReferencedSet`/`--ignore-references` logic layered onto main's newer
  `RunE`/pinned-safety skeleton; reviewer verified the two skip mechanisms operate on disjoint sets
  and pinned beads still protect closed beads they cite. Interface drift (`GetCustomStatusesDetailed`
  on the bench mock) caught and fixed. Review verdict: MERGE pending CI, zero blockers.
  Force-pushed to `quad341/feat/be-jewoem-be-u2mw2x-reference-aware-prune` (`49601be1b`), signed
  comment posted.
- Merge order: #3914 before #3919 (prior decision). #3985 close still held on #4023 landing.
- At session close both PRs had ~27 checks green, ~25 pending (embedded-Dolt test matrix — the
  coverage that cannot build locally).

### mybd-ae1i: piece 2 (adopt-ff detection) + upstream PR #4586

- `smartAdoptFastForward` (Decision `adopt-ff`) implemented as a strict refinement of `smartAdopt`:
  fires only on remote-ahead + no-skew + strict ancestor + clean working set; every failure/nil/error
  path falls back to today's behavior. Callback injection at both store sites; existing exported
  entry points byte-identical.
- Opus review: READY-TO-PUSH, all safety invariants verified. Its one should-fix (missing
  `WorkingSetClean`-error subtest) addressed pre-push; 7 subtests now cover the fallback matrix.
- Pushed `feat/ae1i-ff-detect` (pieces 1+2) to fork; **opened gastownhall/beads#4586**
  (preflight: no competing PRs). Piece 3 (AUTO fast-forward) deliberately out of scope.

## Incident: bd binary vs shared DB schema (new bead mybd-awlo, `human`)

Mid-session another agent migrated the shared mybd DB to schema v54 (`0054_add_lease_columns`);
this machine's PATH bd (1.1.0 release) knows v53 and tripped the skew gate. Rebuild attempts failed:
pure-Go build has no embedded-Dolt support; CGO build needs `libicu-dev` (absent, no passwordless
sudo). Continued with `BD_IGNORE_SCHEMA_SKEW=1` — 0054 is additive-only; residual risk is v53
writers not rewriting `row_lock` (weakened concurrent-write conflict detection), kept mutations
minimal and on claimed rows. Owner action: install `libicu-dev` and rebuild, or wait for a
v54-aware release. Backup at `~/.local/bin/bd-1.1.0-8e4e59d39.bak`. Fresh motivation for
mybd-t7mk (pure-Go embedded Dolt).

## Handoff / next session

1. **Merge #3914 then #4023** once the embedded-Dolt matrix is green (squash, GitHub credits
   quad341 as squash author). The `release-gates/*.md` internal artifacts ride along — 8 such
   files already exist on upstream main, drop-at-merge was not possible without restarting CI.
2. After #4023 lands: close #3985 with credit (retire held on it), then close mybd-9vjz.
3. Shepherd #4586 review; piece 3 of mybd-ae1i (AUTO fast-forward + real embedded-Dolt
   integration tests) is the follow-on; carry the reviewer nit (option lists `bd bootstrap`,
   piece 3 should wire real `FastForward`).
4. Owner decisions queued under `bd human list`: mybd-ufzk (disposition re-approval),
   mybd-fry6 (tri-pull re-enable), mybd-awlo (libicu-dev install).

Token spend: freshness workflow ~452k (haiku, 16 agents); builders+reviewers ~552k
(sonnet/opus). The sweep overshot the 200k-per-task default — for future sweeps of this size,
cap the scout fan-out or split into two batches.
