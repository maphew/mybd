# 2026-08-11 — PR/issue feedback sweep: three MERGE-AFTER-FIXES reviews answered

Session goal (owner prompt): scan the open upstream PRs and issues for
comments and reviews to address, work autonomously, update bd, report.

## What arrived since the last session

The fleet of 17 open PRs was scanned at ~09:00 UTC. All 17 were CI-green.
New feedback, all post-dating the previous session's final pushes:

1. **Three adversarial reviews from steveyegge (Fable "bee", 2026-08-10
   ~19:34), all CHANGES_REQUESTED / MERGE-AFTER-FIXES**: #5202 (import
   skip-invalid), #5092 (doltversion contract p1), #5229 (examples tidy).
   No replies had been posted yet — the reviews landed after the last
   session's 5202 lint push.
2. **GraemeF rebased #3861** out of draft (our nudge), added an
   instrument-carried attribute merge, and asked whether anything is known
   to kill the shared `tracker_pkg_shared` dolt server mid-CI-job.
3. **vishnujayvel rebased #4858 himself** — the deferred carry (mybd-h9w5)
   is moot.
4. **marcodelpin's validation run on #4380**: both stock main *and* the
   #5064 fix panic identically (`invalid hash length: 19`) on his
   pre-0059-cursor drifted fixture — migration 0059's `INSERT … SELECT`
   dies inside dolt before the guarded v53 re-key is ever reached.
5. **ecuthiell**: #5579 (CRLF gitignore dupes) was fixed by merged #5605.
6. **PR #5277 had merged** (2026-08-10) — stale in_progress bead closed.

## Review fixes shipped (all pushed, replied on-thread, reviewer pinged)

### #5229 — `6fa19bb1f`
- Blocking: job-level `continue-on-error` reports the check run as FAILURE
  (only the workflow-run conclusion flips), which pr-preflight gates on.
  Moved to **step level** per the repo's cygwin-leg precedent, with
  outcome-guarded `::warning` annotations.
- Codex cross-check on the fix caught that the surviving job-level
  `timeout-minutes` would CANCEL the job — red by a different door. Final
  shape: no job-level timeout; every step carries its own
  `continue-on-error` + `timeout-minutes`. The job cannot conclude red.
- Module-cache restore added (repo-wide `beads-go-mod-v2` key).
- PR body's "One thing for you to decide" section rewritten (its
  conclusion had inverted, as the review said).

### #5092 — `6c3d60d55` + `280908b5f`
- Per-command `dolt version` fork on the store-open hot path: added
  `ProbeWithPolicyCached` — a cross-process JSON cache in the user cache
  dir keyed by (real path, size, mtime). Steady state is zero forks (one
  stat); binary change re-probes; hard errors never cached; every cache
  failure fails open. Chose memoization over probe-at-spawn deliberately
  (spawn decision lives inside `proxy.GetCreateDatabaseProxyServerEndpoint`;
  crossing that layer is part-2's revalidation work).
- Windows: PATHEXT completion for extensionless `BEADS_DOLT_BIN`
  (exact-spelled path wins; decoy regression test), behavioral tests
  converted to platform-aware `.cmd` stubs, and a focused windows-latest
  CI job so the platform branches actually execute at PR time.
- Advisory now repeats at most once per day (warn stamp in the same cache)
  instead of once per command; docs state the cadence.
- Nits: Ctrl-C no longer prints the install hint; stat-branch taxonomy
  aligned; ParseVersion laxity documented; PR body's inverted fork-count
  claim corrected in place.
- Codex round on the fix found two real issues, both fixed: `bd init`'s
  local `--quiet` shadows the persistent flag (advisory printed under
  `bd init -q`; quiet is now a parameter), and the troubleshooting doc
  advertised the unwired sidecar resolution source (deferred to part 2).
  Codex's third claim — `.cmd` files can't be exec'd directly — was
  refuted (CreateProcess implicitly spawns cmd.exe for batch files; the
  BatBadBut advisory class exists *because* of that; args here are
  static). The new Windows CI job is the live proof either way.

### #5202 — `99b766c4a` + `1b9194118`
- Blocking: on the proxied route `--skip-invalid` was a silent no-op for
  validation-class rejects — the reviewed comment claimed the vocabulary
  was unreachable there, and the review correctly said it isn't:
  `importVocabularyProxied` now reads it via the provider's
  `ConfigUseCase` in one `RunTxRead`, and the proxied branch runs the same
  `partitionImportRecords` as classic. Verified end-to-end against a real
  proxied dolt server (new integration subtest): strict fails pre-batch
  naming the source line; `--skip-invalid` imports the rest and
  quarantines the bad row verbatim.
- `--dry-run` no longer writes — or **deletes** — the `--rejects` file
  (writeRejectFile's stale-cleanup branch fired on dry runs).
- CHANGELOG entry added; dead `importLocalResult.Rejected` removed.
- Coverage added for the whole advertised contract: restore-path two-tier
  reject handling, auto-import quarantine + all-refused stamp,
  proxied threading, dry-run filesystem contract.
- Two nits deliberately declined with reasons on the record (unbounded
  JSON `InvalidRecords`, auto-import fallback double-processing).
- Codex round on the fix added three more, all real: over-length labels
  now partitioned (they pass `PrepareIssueForInsert` but abort at
  `AddLabelInTx`), and `writeRejectFile` writes temp-then-rename so a
  planted symlink at the implicit quarantine path is replaced rather than
  followed, and rewrites always land 0600 instead of inheriting a laxer
  pre-existing mode.
- Process note: the worktree was one commit behind the PR head (last
  session's gosec-lint push) — caught at push time as a non-fast-forward,
  resolved by rebase. Fetch the PR branch before building on a reused
  worktree.

## Other threads handled

- **#3861 (GraemeF)**: replied as a fellow contributor — the failure
  signature is the shared Dolt container dying mid-run (RequireDoltContainer
  harness); no known recurring flake; runner memory pressure the leading
  suspect; flagged the missing `docker logs` teardown as the observability
  gap worth a tiny PR if the rerun reproduces.
- **#4380 (marcodelpin)**: scope proposal posted — #5064 stays scoped to
  the v53 re-key (his arm-2 run proves the guard sound); pre-0059-cursor
  drift should get detect-and-refuse classification plus its own issue
  (offered to draft; his find, his call). Tracked in mybd-qcy1m.
- **#4858 (vishnujayvel)**: carry withdrawn with thanks; mybd-h9w5 closed.
- **#5579**: closed as resolved by #5605.
- **mybd-jxlgz**: closed (PR #5277 merged upstream).

## bd state

- Created + worked: mybd-7fk58 (5229, closed), mybd-569kb (5092, closed),
  mybd-swrrf (5202, closed on push), mybd-qcy1m (4380 boundary, open —
  awaiting marcodelpin/steward response, then file the upstream issue).
- Closed stale: mybd-jxlgz, mybd-h9w5.
- Fleet: 16 open PRs (5277 merged); 3 of them now re-reviewable with
  fixes pushed and reviewer pinged.

## Lessons

- The reviewer's "ping me on the re-push" is the contract now that no
  patrol exists: replies posted same-day on all three reviews.
- Codex cross-vendor rounds on *the fixes themselves* caught two real
  defects (job-timeout cancellation on 5229, init `-q` shadowing on 5092)
  and one refutable claim — reconcile-don't-obey continues to pay.
- CreateProcess batch-file semantics are worth remembering: `.cmd` test
  stubs are fine from Go's os/exec for static args (BatBadBut is the
  citation), so Windows test enablement doesn't need compiled helper exes.
