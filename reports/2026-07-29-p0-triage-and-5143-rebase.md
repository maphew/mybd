# P0 queue triage + PR 5143 conflict resolution — 2026-07-29

Session scope: work `bd ready`, batching and delegating, with a freshness check
against the GitHub repo before starting anything. Plus minor housekeeping.

Two pieces of work landed: the `mybd-rr4x` merge block was a real code conflict
that needed a design call to resolve, and the P0 lane audit (`mybd-6ozys`) is
complete — the P0 tier went from **7 beads to 1**.

## 1. Freshness check changed what was worth doing

Checking upstream before starting was load-bearing this session, not ceremony:

| PR | Bead | State at session start |
|----|------|------------------------|
| 5142 | mybd-2qegi | **MERGED** (bead already closed by another actor) |
| 5146 | mybd-a4h6s | **MERGED** (bead already closed by another actor) |
| 5143 | mybd-rr4x | **OPEN, `CONFLICTING`** — the actual merge block |

Two of the three PRs the control-plane memory described as in-flight were
already done. Only 5143 needed a session.

## 2. PR 5143 — the conflict was a genuine semantic collision, not a rebase chore

`mybd-rr4x` had been relabeled `merge-blocked` by the patrol with
`transition=preflight-policy`, i.e. handed back for agent judgment. The cause:
`mergeStateStatus: DIRTY`.

While 5143 sat open, upstream **#5042** landed its own change to the *same
function signature*. Both PRs added a `bool` return to `openServerConnection`:

- **#5042's `created`** — "THIS call's bare `CREATE DATABASE` won the ownership
  arbitration". Threaded to `initSchema` so only the proven creator arms
  `schema.WithFreshBootstrapHeal`.
- **5143's `dbAlreadyExisted`** — "the database was proven to exist before this
  call". Forces project-identity verification even when `CreateIfMissing` is
  true (GH#4637).

The tempting resolution is to keep one and derive the other, since across most
paths they are inverses. **They are not inverses**, and the place they diverge
is the one that matters:

> On the **Gateway** branch, existence is never probed. Both signals must be
> `false` there. `!created` would evaluate to `true` — wrongly forcing identity
> verification on a gateway open, which is the exact case 5143 documents as
> deliberately excluded (gateway identity is *reconciled* by
> `resolveInitProjectID`, not *enforced* at open).

Collapsing them would have silently broken gateway `init`, including re-init.

### Resolution

`openServerConnection` now returns a `serverConnFacts{created, alreadyExisted}`
struct rather than a bare bool, with the non-inverse relationship documented **on
the type** — specifically so a future cleanup pass does not "simplify" one field
into the other and reintroduce the gateway break.

Also folded in during the rebase: the identity gate stays **above** `initSchema`
(so a foreign database is rejected before bd writes DDL and Dolt commits into
it), and the moved `initSchema` call now carries #5042's `created` argument.

### Verification on the rebased head `b40f0a3c6`

- `go build ./...` and `go vet` clean.
- `go test ./internal/storage/dolt/ -run 'CrossProject|ProjectIdentity|Identity|FreshBootstrapHeal|Gateway'`
  → **18 pass, 0 fail**.

That deliberately includes **#5042's own** `TestFreshBootstrapHealNotArmedWhenDatabasePreexists`
and `TestFreshBootstrapHealSelfHealsAfterMidPassFailure` — the tests this
resolution could plausibly have broken — alongside 5143's six identity cases
(foreign-rejected, matching-succeeds, new-database, both soft-skips, and the
gateway-skip pin).

PR is now `MERGEABLE`. `make test` re-enqueued to the verify queue; merge tail
re-handed to the pr-babysit patrol. Explanatory comment posted upstream.

## 3. P0 lane audit (`mybd-6ozys`) — 7 → 1

Every one of the six P0s got a recorded disposition with a stated re-escalation
trigger. Upstream freshness was re-checked in-session for all five backing
issues: **all still OPEN, none referenced by any merged commit on
`upstream/main` (423afdcb2)** — so nothing was quietly fixed. But four of the
five have **zero upstream comments** since May/June.

| Bead | Issue | Disposition | Why |
|------|-------|-------------|-----|
| mybd-rr4x | 4637 | **KEEP P0**, claimed, active | Fix in flight (above) |
| mybd-rqqa2 | 4052 | **KEEP P0** | Only one with first-party verification vs current main (2026-07-27 @ c989b6b87) |
| mybd-sc70 | 4379 | P0 → **P1**, consolidated under `mybd-rqqa2` | Same defect, reported from the other side |
| mybd-tgqsj | 3905 | P0 → **P1**, consolidated under `mybd-agf58` | Unverified v1.0.4-era, 0 comments |
| mybd-mznh | 4381 | P0 → **P1**, consolidated under `mybd-agf58` | Unverified v1.0.x-era, 0 comments |
| mybd-1hao | 4521 | P0 → **P1**, `human` retained | Blocked on an owner design call since 2026-07-17 |

### The finding behind the downgrades

P0 had drifted to mean *"severity if the report is true"* rather than *"verified
critical"*. Two tests now applied:

1. **Is it verified against current main by us**, not merely reported?
2. **May an agent act on it today**, or is it human-gated?

`mybd-1hao` is the clearest case of the second: severe (journal corruption), but
correctly blocked since 2026-07-17 because `manifest_recovery.go` holds an
explicit stance *against* auto-repair for this case, and reversing that is not
an agent's call. A P0 no agent may act on is queue noise — it displaces
verified work and erodes what P0 means.

The first test matters because of a specific local prior: the **v1.1.2 write-path
rework invalidated many v1.0.3/1.0.4-era reports**. Sibling `mybd-5vvos` — a
consolidated *six*-failure-mode data-integrity report in the same family as
3905/4381 — was verified **FIXED on v1.1.2** on 2026-07-28, trigger mechanism
removed. So "reproduce against current main first" is the right gate for the
whole family, and `mybd-agf58`'s acceptance already requires it.

Two consolidation vehicles already existed and were reused rather than
duplicated: `mybd-agf58` (embedded-mode silent lost-write family, umbrella
gh 4135) and `mybd-rqqa2` (unreachable-server write path). `related` dep edges
were added so the links are visible to `bd`, not just prose.

**Caveat carried forward on `mybd-sc70`:** its proposed remedy — the always-on
offline write-spool carried on our fork — was reviewed as PR 4520 and **closed
upstream 2026-07-27** as REDESIGN/DECLINE (two confirmed correctness blockers
plus a storage-boundary violation). Whoever picks up `mybd-rqqa2` should not
re-propose the spool without engaging that review; the direction should be
fail-closed on the write path, not buffer-and-replay.

**Cheapest next probe**, recorded on `mybd-mznh`: its fallback triggers on
*missing config*, so the repro is "rename the config key, watch which database
the write lands in" — no concurrency harness needed. That is the fastest way to
prove or kill the whole `mybd-agf58` family.

## 4. Delegation note — a scout run that returned nothing

The P0 freshness recon was first delegated to `codex-agent scout`. It came back
**100% UNVERIFIED** on all five issues, for two compounding reasons:

1. `codex-agent scout` runs `sandbox=read-only`, so `git fetch` fails (cannot
   write `FETCH_HEAD`). The prompt had asked it to refresh `upstream/main`.
2. The GitHub API was intermittently unreachable from this machine — visible
   independently in the pr-babysit patrol log, which logged repeated
   `error connecting to api.github.com` and skipped sweeps.

Redone in-session as one Bash call with a retry loop: five `gh issue view` calls,
all five resolved on the first or second try.

The scout behaved **correctly** — it was told to retry then mark UNVERIFIED
rather than guess, and it did exactly that. The fault was in the prompt. Rules
recorded as `bd remember scout-codex-readonly-no-fetch`:

- Never put "fetch upstream" in a scout prompt. Refresh refs in the orchestrator
  *before* delegating; tell the scout to read existing refs only.
- For gh-dependent recon, either give an explicit retry-then-UNVERIFIED
  instruction, or just run the loop in-session — five `gh` calls cost far less
  than a delegation round-trip that returns nothing.

## 5. Housekeeping

- Removed two now-dead beads worktrees whose PRs merged today and whose trees
  were clean: `.worktrees/beads/doctor-fix-port` (#5142) and
  `.worktrees/beads/draincall-tx` (#5146). Branches retained.
- Stash stack empty; no local branches with a `gone` upstream; verify-log
  buildup only 656K. Nothing else needed action.

### What I noticed that isn't on any list

**The pr-babysit patrol is degrading silently under network failure.** The
patrol log shows `gh pr view failed or returned malformed data; retained
silently (3/10)` and `(4/10)` across several beads, plus
`review: gh pr list failed; sweep skipped`. That is the intended
unreadable-checks retry budget working as designed — but the budget is being
consumed by a *local network outage*, not by anything about those PRs. If the
outage persists across ~10 passes (~2h), beads will hit `merge-blocked` /
`close-blocked` for a reason that has nothing to do with their state, and a
human gets paged for a Wi-Fi problem.

Not fixed here, and not obviously worth fixing — but worth someone deciding
deliberately: a connection error is distinguishable from malformed data, and
arguably should pause the patrol rather than spend a bead's retry budget. Filed
as **`mybd-ihsnv`**.

## Handoff

- **`mybd-rqqa2` is the single actionable unclaimed P0** and is real engineering
  work, not triage. Fix direction: make the auto-start fallback fail the write
  rather than silently retarget it. Read the PR 4520 caveat above first.
- `mybd-rr4x` stays claimed and `in_progress` until the patrol merges 5143.
- `mybd-agf58` is now the single entry point for the embedded-mode silent
  lost-write family; start with the `mybd-mznh` missing-config probe.
