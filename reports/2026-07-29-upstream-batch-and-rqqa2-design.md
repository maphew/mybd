# Upstream batch + rqqa2 root-cause — 2026-07-29 (part 2)

Companion to [reports/2026-07-29-p0-triage-and-5143-rebase.md](2026-07-29-p0-triage-and-5143-rebase.md),
which covers the same session's PR 5143 conflict resolution and the P0 lane audit.
This part covers the upstream PR work and the `mybd-rqqa2` design pass.

The through-line: **four of the five items below were caught by a verification
step, not by the first analysis.** That is the finding worth carrying forward,
more than any individual fix.

## 1. `mybd-rqqa2` (P0, gh 4052) — root-caused, then the fix failed review twice

The bead said "writes report success when Dolt is unreachable". The real defect
is narrower and more specific.

`serverOpenCanAutoStart` (`internal/storage/dolt/store.go:1668`) already requires
`isLocalHost(cfg.ServerHost)`, so a genuinely *remote* unreachable server does
fail closed today. The live defect is the **local port retarget** at
`store.go:1476-1500`: dial fails → `EnsureRunningDetailed` auto-starts a new
server on an ephemeral port serving `resolvedBeadsDir` → the mismatch is
announced on **stderr only** → `cfg.ServerPort` is overwritten → the write lands
in whatever database that new server serves, exit 0, success message.

The existing identity gate does not catch it: `verifyProjectIdentity` compares
local `metadata.json` `_project_id` against the DB's, and the auto-started server
serves the *same* project directory, so identity matches. Identity verification
is orthogonal to this defect — PR 5143 does not cover it.

**Why it can't simply fail closed:** retargeting is correct in the common case
where the recorded port is a stale ephemeral leftover. The discriminator has to
be the port's *provenance*, which `store.go:1232-1241` was discarding by taking
only `.Port` from `DefaultConfig`. Cheap to fix — `DefaultConfig` already
evaluates its sources as separate early-return branches.

### The two review catches

**Catch 1 — the spec had one axis; the problem has two.** The first
implementation was correct, tested, and negative-controlled, and it *missed the
defect's headline scenario*. In shared-server mode `DefaultConfig` swaps
`beadsDir` to `SharedServerDir()`, so the port resolves from the **shared**
directory's port file → classified non-authoritative → retargets freely. But
auto-start calls `EnsureRunningDetailed(resolvedBeadsDir)` with the **repo's**
`.beads`. Shared server down → repo-local server → different database → silent
write. Exactly the issue's title.

The missing axis: not just *who asserted the port*, but *which directory it
belongs to*. A port that resolves from a different server directory than the one
auto-start would create is never a benign refresh.

**Catch 2 — the guard disarmed itself after one invocation.** `doltserver.Start()`
writes the port file (`doltserver.go:1291`, and `:1176` on the adopt path)
*inside* `EnsureRunningDetailed`, i.e. **before** the guard runs. The port file
outranks `config.yaml` in the resolution chain. So:

1. Configured port down → auto-start on ephemeral `Q` → `Start()` writes the port
   file = `Q` → guard fires → error. Correct.
2. User retries. `DefaultConfig` now resolves `Q` **from the port file**
   (non-authoritative) → the server on `Q` is up → dial succeeds → the auto-start
   branch is never entered → silent write to the repo-local database.

The guard fires exactly once, then permanently disarms. That is arguably worse
than no guard: the user sees an error, retries, it "works", and concludes the
first error was transient.

Shared mode is unaffected (`DefaultConfig` reads the shared dir's port file, not
the repo-local one `Start()` just wrote).

**Generalized and recorded** as `bd remember fail-closed-check-prior-side-effects`:
when adding a fail-closed guard, audit what state was written *before* the
decision point, and make the regression test call the guarded path **twice** — a
one-shot test cannot see a self-disarming guard.

### Disclosed tradeoff

`config.yaml` and `metadata.json` are **git-tracked by default** — confirmed in
the project's own `.beads/.gitignore` template (`cmd/bd/doctor/gitignore.go`),
which ignores only `dolt-server.pid/.log/.lock/.port/.activity`. So treating a
pinned port as authoritative means a fresh clone that inherited a collaborator's
`dolt.port`, with no local server, gets a hard error where today it auto-starts
silently. This is a real behavior change and belongs in the PR description as a
deliberate, disclosed choice rather than a support surprise. The asymmetry favors
failing closed (an actionable error vs. silent data divergence), but it is
maintainer-tunable — the narrower alternative is "env var + shared-server only".

## 2. PR 5160 (DustinHolden) — declined, after verifying the decline

A reviewer concluded the PR would *reintroduce* the bug it fixes. Because that is
a decline of a contributor PR, both blocking claims were re-verified in-session
before acting:

- `main` already carries the fix (`34936e260`, comment follow-up #4235); no
  duplicate versions remain.
- The PR's numbering is the **inverse** of what shipped (PR: `0048`=longtext /
  `0049`=widen; main: the reverse). `git merge-tree --write-tree` exits 1 with
  four rename/rename conflicts.

GitHub reported the PR `MERGEABLE` throughout. It is stale — the local
`merge-tree` is authoritative. Worth remembering the next time a merge-state
field is used as a gate.

Declined as already-fixed rather than as wrong, with credit: the contributor
independently reached the same three collisions the maintainer had, including the
non-obvious `ignored/0005` one. Handed to the `close-when-quiet` lane (window
opens 2026-08-02).

**The part worth keeping**, filed as `mybd-075zn` with attribution:
`internal/storage/schema/cli_migrations.go:39` dispatches on a literal *filename
string* with a `default: return sqlText` fallthrough. Renaming that migration
makes the case unreachable — no compile error, no failing test — and the
fresh-schema CLI bundle silently falls back to raw DDL. Nothing guards it.

## 3. PR 5159 (`--team-server`) — approved with one pre-merge ask

All three gates verified as *tightened*, not bypassed: the migrate gate is
short-circuited before `MigrateUpWithLock` and before any `CREATE DATABASE`;
forward-drift delegates to the same `schema.CheckForwardDrift`; remote-migrate
never ran on the proxied path at all.

**Pre-merge ask (verified in the diff):** `SkipIdentity` gates *only*
`issue_prefix` and `_project_id`. `repo_id`, `clone_id`, `last_import_time` and
`CreateRemote` remain unconditional — so every teammate's init writes their
per-clone fingerprints, and a Dolt remote pointing at *their* git origin, into
the operator's shared database. The gateway path already solves exactly this
~800 lines away via `shouldWriteInitStateToDB`. The two modes assert the same
policy ("the server owns this database") and should share the predicate.

Filed `mybd-xjbub` for the structural gap: the proxied path has **no runtime
project-identity verification** — `cmd/bd/main.go:1348-1358` short-circuits
before `validateWorkspaceIdentity`, and proxied mode never constructs a
`DoltStore`. This predates 5159, but `--team-server` is what makes shared,
operator-owned, `--database`-selectable targets a supported case. It is the
proxied-path sibling of the shared-server gap PR 5143 closes — same policy,
different code path, so 5143 does not cover it.

## 4. PR 4697 (julianknutsen) — re-reviewed, and it un-blocked two of our beads

The PR was **completely re-authored** (head `9123e061`), and the highest-value
outcome was a scoping fact, not a finding:

> **Slice 4 is gone. Nothing in the branch reverses a migration.**

Verified directly: the migration diff is additive only (`0062_add_claim_fence`,
`ignored/0019_add_wisp_claim_fence`); `0055_move_leases_to_table` is untouched;
`wisps are never leased` is preserved. That was the sole reason the PR sat behind
the unanswered "should wisps be leasable?" owner ruling.

Consequences recorded on the beads themselves:

- **`mybd-phpm4`** (OWNER RULING) — no longer gates anything in flight. The
  question may still deserve an answer on its merits, but it should not sit as an
  urgent owner gate. Forward-looking note left: if it ever returns "wisps are not
  ownership-bearing work", `ignored/0019` is the one file to revisit, as a
  follow-up migration rather than a revert.
- **`mybd-3tch4`** (shepherd the migration-repairs split) — **scope dissolved**.
  The author dropped the repairs helpers entirely with a verification argument
  instead of splitting them. There is no slice left to shepherd. Recommended
  close; explicitly recommended *against* re-splitting the branch, which has
  already been re-authored once.

Verdict: approve with comments. The fence is a real CAS (WHERE-clause conjunct
plus `row_lock` commit-conflict replay, so two claimers cannot both win), and no
non-test SQL path writes `assignee` without bumping. Findings are improvements:
the coverage test's hardcoded file whitelist, the argued-but-not-demonstrated
concurrency claims (no test spawns racing claimers), `bd lease disarm` unable to
distinguish convergence from budget exhaustion, and a positional-param interface
shape that #5008 had explicitly rejected — offered to absorb that one
maintainer-side rather than send the branch back again.

## 5. A regression in today's `main` — `mybd-1t4fq`

Chasing a CI failure on 5143 found something bigger. The same shard failed on
**5143 and 5159** — two unrelated PRs — so neither caused it. It traces to #5150
(`423afdcb2`, merged today, tip of main), which made events/comments ids
**content-derived**.

Comments list with `ORDER BY created_at ASC, id ASC`
(`internal/storage/issueops/comments.go:29`, `:88`). Per `derivedid.go:25-27`,
`created_at` participates in the digest only as its **`DATETIME(0)`** text — one
second of granularity. So comments written in the same second tie on the primary
sort key, and the `id ASC` tiebreaker is now a content hash carrying no insertion
order.

**A correction I had to make mid-session:** I first recorded that the wrong order
was deterministic for fixed comment text. It is not — `InsertDerivedComment`'s
digest includes `issueID`, which is fresh per run, so the permutation varies run
to run. That makes it *worse*: under a same-second tie, roughly five of six runs
come out wrong.

**Local non-reproduction, and why it is consistent:** four consecutive runs with
`BEADS_TEST_PROXIED_SERVER=1` all passed here. This box is slow enough that each
`bd comment` invocation lands in a *different* second, so `created_at` breaks the
tie before `id` is consulted. Fast CI runners collide. Two practical corollaries:
repeating the integration test on a slow machine proves nothing, and **a green
patrol flake-rerun is luck, not evidence.**

Reported on #5150 as "likely regression, flagging not asserting", with the
non-reproduction disclosed. Deliberately no patch proposed: the obvious lever —
widening `created_at` precision — would reshape every derived id, since the
`DATETIME(0)` text is bound verbatim as a digest input. Giving comments an
ordinal is likely closer to intent (events already "keep local multiplicity
through ordinals"), but that interacts with comments deliberately collapsing onto
identical rows, so it is the author's call.

Also note this is **user-visible**, not just a test bug: any two comments posted
in the same second display out of order.

## Delegation notes

- A `codex-agent scout` recon returned **100% UNVERIFIED**: the scout sandbox is
  read-only so `git fetch` fails, and the GitHub API was intermittently
  unreachable. The scout behaved correctly — told to retry then mark UNVERIFIED,
  it did exactly that rather than guess. The fault was the prompt. Recorded as
  `bd remember scout-codex-readonly-no-fetch`.
- Both builder passes on `rqqa2` were correct *for the spec given*; both spec
  gaps were mine. Escalating to a review pass rather than re-spawning the same
  tier is what caught them.

## Handoff

- `mybd-rqqa2` stays claimed; third builder pass in flight. Disclose the
  git-tracked-port tradeoff in the PR description when it opens.
- `mybd-1t4fq` — **do not open a PR before #5150's author picks a direction.**
- `mybd-phpm4` and `mybd-3tch4` both want an owner decision to defer/close now
  that 4697 un-blocked them.
- `mybd-xjbub`, `mybd-075zn`, `mybd-ihsnv` are new and unclaimed.
