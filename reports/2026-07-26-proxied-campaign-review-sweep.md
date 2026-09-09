# Proxied-Dolt campaign: three-PR review-and-fix sweep (2026-07-26)

**Session goal:** "anything we can do today to help push the proxied dolt initiative along?"

**Answer found:** the bottleneck was three campaign PRs sitting CI-green, mergeable,
and completely unreviewed. All three got a two-vendor adversarial review
(Claude Opus reviewer agents + `codex-agent reviewer --diff` on gpt-5.6-sol),
a same-day fix batch, and a pr-babysit handoff.

## Outcomes

| PR | Bead tail | Verdict | Fix head | Disposition |
|----|-----------|---------|----------|-------------|
| gastownhall/beads#5013 (psxg.5 proxy identity) | mybd-psxg.5 | NEEDS-FIXES → fixed | a9cfebc25 | pushed, handed off (squash) |
| gastownhall/beads#5024 (psxg.5 listener policy, **stacked on #5013**) | mybd-xf2k | NEEDS-FIXES → fixed | d83434010 (rebased onto a9cfebc25) | pushed --force-with-lease, handed off; merge AFTER #5013 |
| gastownhall/beads#5046 (psxg.2 workspace gate part 1) | mybd-hy3x | primitive land-ready; OpenGated blocked | 4ddaf4e28 | split to primitive-only, pushed, handed off |

Full-suite `make test` verification queued for all three heads (verify-babysit drains).

## Review highlights (cross-vendor found disjoint defects, again)

- **#5013 Claude:** Windows handle held across `waitForRecordedProcessExit` made
  crashed-proxy recovery fail unconditionally; Windows `Verify` counted dead
  processes as alive; root-ID mismatch had no CLI recovery; `--force` could
  SIGKILL an unrelated `bd`. **Codex:** pidfd opened after token verification
  (PID-reuse kill race); paired legacy records locked out of the forced recovery
  they exist for; `PidfdSendSignal` ESRCH misreported as failure.
- **#5024 Claude:** listener policy checked only `listener.host` while
  `remotesapi.port`/`cluster`/`listener.socket` bypassed it (all-interfaces or
  `/tmp/mysql.sock` exposure); omitted-host accepted while `localhost` rejected.
  **Codex:** startup interval not fenced by the stop epoch (stop could return,
  then the child publishes a running proxy). Policy decision: managed mode now
  requires an explicit numeric loopback IP.
- **#5046:** the gate primitive survived targeted attack (lock ordering, crash
  recovery, TOCTOU all sound); both blockers were in the bolted-on `OpenGated`
  API (wrong physical-root derivation vs the store's 4-layer mode resolution;
  gate skipped entirely with no metadata.json). Decision recorded on mybd-psxg.2:
  part 1 = primitive only; OpenGated returns in part 2 on a shared resolver.
  Carryover code preserved in session scratchpad `opengated-part2-carryover.md`.

## Follow-up beads filed

- mybd-7qp5 — control-handshake HMAC challenge-response + local-user DoS surface (P2)
- mybd-b56a — root-identity robustness (renamed roots, case variants) via os.SameFile (P2)
- mybd-nsg1 — Windows CI lane for proxied lifecycle tests (P2)
- mybd-fgqv — **triage rescued staged proxied work found in bd-main** (P1; see below)

## Rescue: crashed-session work found in bd-main

bd-main was detached at local-only a8784aebf (2026-07-23) with a staged,
never-committed 194-file changeset (+13588/−1040): proxied-server routing for
maintenance commands (gc/ping/compact/cleanup + integration tests), the
`proxied-local-smoke.yml` upstream workflow (psxg.1's un-PRed CI wiring), and a
CAS proposal doc. None of it is on origin/main. Preserved verbatim as branch
`rescue/staged-proxied-work-20260726` (93410c16b) via `commit-tree` — the
bd-main index/worktree were left untouched. Owner started a separate agent on
mybd-fgqv mid-session; this session made no further bd-main changes.

## What I noticed that isn't on any list

- The `.githooks` clobber pattern (tracked pre-push/prepare-commit-msg hooks
  overwritten, extra untracked hook files dropped) appeared in TWO places:
  bd-main root and the `psxg5-proxy-identity` worktree. Something — likely a
  `bd hooks install` variant or the Entire CLI — is rewriting tracked hooks in
  beads checkouts. Patches preserved in session scratchpad
  (`psxg5-worktree-githooks-dirty.patch`, `worktree-cruft/`). Worth a bead if it
  recurs.
- `mybd-uiiu`'s verify run failed today (exit=1, log in `.verify-logs/`) — that
  lane is another session's in-progress work; not chased here.
- pr-handoff attached #5013's tail to mybd-psxg.5 itself (external-ref set by a
  prior session). When the patrol merges #5013 it may close psxg.5 while #5024
  (same bead's scope) is still in flight — #5024's own tail mybd-xf2k plus the
  follow-up beads carry the remainder, but the campaign epic should not be
  considered psxg.5-complete until BOTH merge.

_claude-fable-5-medium on behalf of maphew_
