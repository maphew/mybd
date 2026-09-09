# Ready-work batch and the vishnujayvel wave-2 queue — 2026-07-28/29

Session shape: pick up `bd ready`, check every item against GitHub before starting,
batch and delegate. Four threads ran in parallel — three beads-source fixes in
isolated worktrees, and the upstream PR queue.

## Headline

- **The contributor waiting queue is drained.** `mybd-aayb` closed after verifying
  every entry PR-by-PR against GitHub rather than trusting the 07-25 snapshot.
- **PR #5101 is a data-loss fix, not output polish.** On `main`, the single-issue
  delete path gates the preview on `if !force` and the destructive branch below it
  never consults `dryRun`. So `bd delete <id> --force --dry-run` **actually deletes**.
  Approved and merged.
- **PR #5065 was stopped by a round-trip invariant that two independent model
  families found separately** — the strongest signal available that a finding is
  real rather than reviewer noise.
- **vishnujayvel replied on all 12 previously-reviewed PRs**, accepted our findings,
  and itemized exactly which changes they want pushed maintainer-side. That is
  now one batch: `mybd-php3l`.

## Upstream PRs handled

| PR | Author | Outcome |
|----|--------|---------|
| #5101 | idirectships | Approved, merged by patrol |
| #5099 | jacobhausler | Approved, merge lane armed |
| #5065 | halaprix | Comment review, two blockers, absorb offer open |
| #5129 | vishnujayvel | Re-review: approve with one should-fix |
| #5135 | vishnujayvel | Re-review: still needs changes, narrowly |
| #5142 | ours | Opened: doctor identity guard |
| #5143 | ours | Opened: identity check on the CreateIfMissing path (P0) |
| #5121 | vishnujayvel | Requested maintainer commit pushed (`e8f3cbf78`) |
| #5123 | vishnujayvel | Requested maintainer commits pushed (`bdf815444`) |
| #4329 | kevglynn | Cross-note on the #5065 collision |

### #5101 — forced dry-runs

The contributor's framing undersold it. `cmd/bd/delete.go:136` gates the preview on
`if !force`, and nothing below consults `dryRun`, so `--force --dry-run` deletes for
real. The PR's `if dryRun || !force` gate closes it. Verified the rest against code:
`force` only widens dependent discovery in `issueops/delete.go`, and the `dryRun`
return precedes every mutation on all four backends. One thing that looked like a
bug and was not: the error path calls `outputDeletionPreview` and then
`outputJSONError`, which would be two JSON documents — except the first writes to
stdout and the second to stderr.

### #5065 — the value of dual-vendor review

Two reviewers on different model families, run independently, returned the *same
two blockers*:

1. `StripGitHubSyncBlock` removes from the first start marker to the first end
   marker, while the renderer always appends its block at the end. An unpaired
   start marker — trivially produced by editing the visible `## Beads` section in
   GitHub's web editor, since HTML comments are invisible there — makes the next
   pull delete everything between. Measured, not hypothesized.
2. `ExtractBDIDFromGitHubSyncBlock` scans the *whole* body for `<!-- bd:` with no
   block, token, or prefix validation. A contributor copy-pasting a synced body into
   a new issue repoints an unrelated local bead and rewrites its `external_ref`.

Both are silent data loss. Posted as a comment review with an offer to implement the
fixes maintainer-side with authorship preserved (`mybd-fezwm`, deadline 2026-08-04).

## Beads-source work

Three fixes built in isolated worktrees, each independently reviewed before opening.
Both reviews came back **needs-changes**, and both sets of findings were real — worth
recording, because the temptation with builder output is to trust the green tests.

- **`mybd-2qegi`** — `doctor --fix` dials a fresh connection whose port resolution is
  independent of the store doctor diagnosed with, so a stale port file can aim DELETEs
  at another database. Now `#5142`. The review caught that `RecomputeBlocked` was left
  unguarded (bulk UPDATE plus a `DOLT_COMMIT` into another project's history, and it
  runs *last*, after every guarded fix has aborted) and that the guard was
  over-strict: hard-aborting on a missing project id would have permanently broken
  shared-server workspaces, which cannot self-heal because `CheckProjectIdentity`
  short-circuits when `.beads/dolt` is absent. Both fixed before opening.

- **`mybd-rr4x` Part A** — run the identity verifier when the target database already
  exists, even on the `CreateIfMissing=true` init path. Now `#5143`. The reviewer ran
  a negative control (revert only the gate; the new test fails), confirming a genuine
  regression test rather than a tautology. Three real gaps came out of it: a remaining
  bypass where `CREATE DATABASE IF NOT EXISTS` returning "database exists" *proves*
  pre-existence yet left `dbExists` false; a gateway carve-out whose comment
  contradicted what the caller did with the value; and gate ordering that let a
  foreign database receive bd's DDL and Dolt commits *before* being rejected. All
  three fixed, and the rework made the condition simpler rather than more complex.

- **`mybd-a4h6s`** — apply the `drainCall` pattern from merged #4504 to 16
  transaction-pinned `CALL DOLT_*` sites, where poisoning is worse because a pinned
  connection cannot be discarded by the pool. The review found the conversion itself
  flawless at all 16 sites, and the *exclusions* wrong: `concludeOpenMerge` and
  `CommitWithConfig` were excluded on the reasoning that they run on a freshly
  acquired connection used once — but that connection goes back to the pool via
  `putConn`, and being returned to the pool while busy is the poisoning source, not a
  defence against it. `pullWithAutoResolve` — the single most on-thesis site, where a
  tolerated `DOLT_PULL` error is explicitly downgraded to nil and the same pinned
  transaction keeps going — was excluded entirely. Rework in flight.

All three are queued in the local verify queue rather than blocking a session on the
slow suite.

## Operational findings

- **`scripts/codex-agent scout` has no network.** Its read-only sandbox blocks
  `api.github.com`, so any `gh`-based recon fails after burning tokens — twice today,
  ~75k total. Codex is still the right tool for local source reading, which is where
  the cross-vendor value is. Fetch GitHub data to disk first, then point it at files.
  Recorded as memory `codex-scout-no-network`.
- **A bead's disposition can go stale under an active lane.** `mybd-k6zxf` still held
  a close-after-grace plan for #4376 while another session was refreshing that branch
  to land it. Annotated rather than executed. The check that caught it was reading
  GitHub before acting, not reading the bead.
- **The review-needed lane works.** It queued 20 PRs while this session ran, correctly
  distinguishing new arrivals from author replies and contributor pushes. The manual
  waiting-queue measurement that `mybd-aayb` was built around is now an audit tool,
  not the mechanism.

## Open threads

`mybd-php3l` is the big one: 12 PRs where the contributor has already told us exactly
which commits they want from us. Two are in progress (#5121, #5123). Also open:
`mybd-fezwm` (#5065 absorb, 08-04), `mybd-ma4ry` (#4329 / #5065 dedup collision),
`mybd-hk7hm` (legacy ADO `parent` row migration), and the follow-ups filed off the two
reviews: `mybd-h1vz1`, `mybd-jlgdx`, `mybd-2cxve`, `mybd-1s7pl`.
