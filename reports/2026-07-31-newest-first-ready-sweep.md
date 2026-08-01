# Newest-first `bd ready` sweep — 2026-07-31

Session brief: work the `bd ready` queue autonomously from the **newest** end
(a parallel session was working from the oldest), check each candidate is not
already covered by a branch or PR before claiming, one worktree/branch/tests/PR
per task. Do not merge, do not decide product questions, do not touch history.

Queue depth at session start: **100 ready beads**.

## Headline

The single most important finding is not a fix — it is that **the P0 I claimed
was already being fixed by the parallel session, and I did not discover that
until I had a complete, tested fix of my own in hand.** Details and the process
lesson are in [§1](#1-p0-main-red-14h--duplicate-work-caught-late). No competing
PR was opened.

Net upstream output this session: **two substantive comments posted** (one PR
review, one issue correction that recommends a close), **zero PRs opened**,
**zero merges** — the last by instruction.

## 1. P0: main red 14h — duplicate work, caught late

**mybd-5p561** (P0, filed by the owner 21:12Z): `gastownhall/beads@main` red
since 08:52Z; 11 migrate-mode tests failing on both runners with
`workspacegate: acquiring <dir>/.beads.gate.lock: context canceled`.

### What I established independently

- **Culprit: `6d81e1c73` (#5093)**, confirmed by locating the
  `acquireExclusiveWorkspaceGates(rootCtx, ...)` call it introduced in
  `acquireMigrateGates`.
- **Mechanism:** `PersistentPostRunE` called `rootCancel()` and left the
  `rootCtx` package global pointing at the context it had just canceled. A real
  `bd` process exits immediately after, so it never mattered; the `cmd/bd` test
  binary runs many commands per process, so every test after any successful
  in-process command inherited a dead root context. #5093 made migrate the first
  consumer to care.
- **Reproduced it**, which mattered because the tests pass in isolation and the
  failure reads as flake. A three-line probe that runs `rootCmd.Execute()` with
  `["version"]` and then reads `rootCtx` reports `context canceled`, and the
  next migrate test emits the CI error byte-for-byte.
- Built the fix, had it reviewed, and applied the review's findings.

### The miss

`scripts/pr-preflight.sh --search "workspacegate rootCtx context canceled
migrate gate"` returned **"No open PRs matched this search"** — and it was
right at the moment I ran it. **#5204 was opened at 22:13Z**, part-way through
my investigation. I found it only later, while listing our own recent PRs for
an unrelated bead.

The check was run, in the right place, and still did not protect me, because
preflight is a point-in-time query and the work window was hours long. On a
stop-the-line P0 the probability that someone else is on it is at its highest,
which is exactly when a single up-front check is least sufficient.

**Recommendation for the next agent, not filed as a bead because it is a habit
rather than a defect:** on a P0, re-run preflight (or just `gh pr list --author
<you> --limit 5`) immediately before writing the commit, not only before
starting. Cheap, and it is the moment the answer can have changed.

### Disposition

#5204 is a **strict superset** of what I had. Same deferred-`PersistentPostRunE`
clear registered first so LIFO runs it last (which I had converged on only after
review feedback), **plus** `PersistentPreRunE` publishing through
`setRootContext`, **plus** `acquireMigrateGates` reading `getRootContext()`.

So: no competing PR. My branch and worktree were deleted. What I had that theirs
did not went to #5204 as a review comment
([issuecomment-5147969568](https://github.com/gastownhall/beads/pull/5204#issuecomment-5147969568)):

1. **A comment #5204 falsifies.** `TestChokepointSharedExcludesMigrateExclusive`
   in `cmd/bd/workspace_gate_test.go` documents the leak as *current production
   behaviour*. After #5204 that is wrong, and it is the first place a future
   reader lands when they hit anything context-shaped in `cmd/bd`. #5204 does
   not touch that file. Exact replacement text supplied; **mybd-zz04j** filed so
   it survives if the author does not fold it in.
2. **A surviving asymmetry.** #5204 routes PreRunE through `setRootContext` but
   the telemetry re-wrap ~35 lines later is still a bare global assignment, so
   `getRootContext()` returns a span-less context until `syncCommandContext()` —
   and *forever* for the `skipsStoreInit` commands #5204 just fixed. Cancellation
   is unaffected (same cancel parent), so this is observability only and not a
   regression. Narrowed **mybd-3xire** to exactly this remainder.
3. Independent reproduction evidence, plus a practical note: `cmd/bd` takes
   ~9 minutes on a warm box, so a plain `go test ./cmd/bd/` **silently dies on
   Go's default 10m timeout** and prints a truncated failure list that reads as
   real breakage. Two of my own runs were wasted this way before a reviewer
   caught it. Use `-timeout 60m`.

Beads: **mybd-5p561 closed as duplicate** of mybd-fciu9, which owns the fix.
Its second acceptance criterion (the base-red detection gap) is discharged in §2.

`#5204` was still `OPEN` / `UNSTABLE` (no failures, jobs pending) at session
end. **Merging it is deliberately left to the owner or the patrol** — the
brief said not to merge, and stop-the-line makes it the one PR that most wants
a human eye rather than fewer.

## 2. The base-red detector went blind (duplicate, deduped)

mybd-5p561 also asked why no `base-red` bead was raised across 14h of red main,
when the *same morning's* outage was caught correctly (mybd-xm6rc, raised
06:05Z, auto-closed 08:45Z).

Verified answer: **the lane only observes base health through parked merge
lanes.** `red_base_note` / `green_base_note` are called only from inside
`pr-babysit`'s merge-lane loop, so `RED_BASE_SIGHTINGS` is empty when no lane is
armed, and `red_base_escalate` returns early. The morning's 14 parked lanes all
merged when main went green at 08:18Z; main broke again 34 minutes later into an
empty queue and nothing was left to notice.

The close of mybd-xm6rc at 08:45Z was **correct** — main genuinely was green
then. This is not a false-recovery bug; it is a blind spot that opens precisely
when the queue drains, which is right after a merge burst — when a
base-breaking commit is most likely to have just landed.

I filed this as mybd-s9fcm and then found the parallel session had already filed
**mybd-sopqb** with the stronger writeup (it verified `merge-when-green=0`,
`close-when-quiet=0`, `merge-blocked=0` at the time of the miss).
**mybd-s9fcm closed as duplicate.** Their sibling **mybd-01yzj** covers the
related circular deadlock: the PR that fixes a red base is parked by its own
base being red.

## 3. gh 3887 is fixed on main — verified, and the stated root cause is wrong

**mybd-0zfum** asked me to post a correction upstream: gh 3887 and the ready-
gating audit both describe the grandchild gap as "propagation is one level per
recompute rather than a transitive walk", which is not the mechanism.

Verifying the claim **changed the conclusion**, so the comment went further than
the bead scoped it.

The bead's mechanism analysis is right: `RecomputeIsBlockedInTxWithResult`
already loops to a fixpoint, and the real limit is batch membership
(`WHERE i.id IN (…)`). But its prescribed fix — "close the ID set over
descendants before recomputing" — **is already implemented**.
`expandByParentChildDescendantsInTx` is a batched breadth-first descendant
closure and is the tail call of every affected-set builder. I walked every
`RecomputeIsBlockedInTx` call site in the tree — `issueops/{bulk_ops,promote,
delete,blocked_merge}.go`, `dolt/{ephemeral_routing,wisps}.go`,
`domain/db/{issue,dependency}.go`, `domain/issue_delete.go` — and **none passes a
raw, unclosed set**.

So I built `bd` at `9973e9628` and ran the issue's own repro, plus two harder
ordering cases:

| case | result |
|---|---|
| the repro as written | only `A`, `A.1`, `A.2` ready — matches the issue's own "After fix" block |
| great-grandchild `B.1.1.1` created **after** the blocking dep | correctly excluded (so it is not a one-shot at dep-add time) |
| close `A` and its children | whole `B` subtree unblocks together |

The third case is the one I would not have thought to run from the bead text: a
fix that propagates only on the way *in* leaves a subtree permanently stuck,
which is worse than the reported bug.

Posted as
[issuecomment-5148007828](https://github.com/gastownhall/beads/issues/3887#issuecomment-5148007828),
**recommending gh 3887 be closed as fixed** — with the honest caveat that I only
exercised the embedded/`issueops` path, and the issue says the original fix
touched the DoltStore path too. **I did not close it**; that is a maintainer
disposition, not this session's call.

Residual work in this area is gh 4138's shape: rows **never recomputed at all**
(e.g. left behind by a migration), which is a different bug from a set that is
too small.

**Correction fed back to mybd-zelnn**, whose report (§3.6) is the source of the
now-disproven claim and whose PR (maphew/mybd#24) is *still open* — so it can be
fixed before it lands.

> **Update (2026-07-31).** Both PRs were closed unmerged and their reports
> landed on `main` by direct commit, which is how the other 110 reports in this
> directory arrived; the audit's §3.6 carries the correction inline. See the
> AGENTS.md "Landing a coordination-repo branch" note added at the same time —
> the two open report-PRs were the reason a correction had to be coordinated
> across branches at all.

## 4. `conditional-blocks` is a synonym for `blocks` — verified, escalated

**mybd-jrbuu**: the failure branch of a molecule goes ready on the success path.

Confirmed end-to-end on the CLI, not just by reading:

```
bd dep add <fallback> <main> --type conditional-blocks
bd ready                                   # fallback NOT ready   (correct)
bd close <main> --reason "completed successfully"
bd ready                                   # fallback IS ready    (wrong)
```

And the scope is wider than the bead states. Every `conditional-blocks` /
`DepConditionalBlocks` reference outside tests treats it **identically to
`blocks`** — the mark/unmark arms, `loadBlockingDependersForIDsInTx`, the
`AffectedBy*` switches, `cycles.go`, `dependencies.go`, `transaction.go`,
`domain/issue.go:1241`, `dependency_queries.go:936`. No code path anywhere reads
an outcome.

**Root of the root:** there is nowhere to read one from. `internal/types/types.go`
enumerates the entire status set — `open`, `in_progress`, `blocked`, `deferred`,
`closed`, `pinned`, `hooked`. There is no success/failure distinction on a bead
at all. So this is not merely "`is_blocked` is a boolean with nowhere to put the
outcome"; **the status model has nowhere to put it either.** As shipped,
`conditional-blocks` is a pure synonym for `blocks`, and the "B runs only if A
fails" semantics exist in a comment at `cmd/bd/mol_bond.go:567` and nowhere else.

Stopped there deliberately. Every repair implies a product decision this session
was told not to make: introduce a terminal outcome on close? make
`conditional-blocks` unblock only on failure and auto-skip on success? or retire
it as a distinct type? Those are different products, not different
implementations. Bead labelled **`human-decision`** and returned to `open`/
unassigned so it surfaces for the owner rather than looking claimed.

> **Correction (2026-07-31, review of maphew/mybd#25).** "Root of the root" is
> wrong, and it is the strongest-worded claim in this report — which is the
> lesson. The outcome mechanism exists:
>
> ```go
> // internal/types/types.go
> var FailureCloseKeywords = []string{"failed", …, "won't fix", "canceled",
>                                     "abandoned", "error", "timeout", "aborted"}
>
> // IsFailureClose returns true if the close reason indicates the issue failed.
> // This is used by conditional-blocks dependencies: B runs only if A fails.
> func IsFailureClose(closeReason string) bool { … }
> ```
>
> The outcome lives on `close_reason`, not on `status` — so the status
> enumeration above is accurate but answers the wrong question. `IsFailureClose`
> has **zero production callers** (`grep` finds only `types_test.go`), so the
> observed behaviour and the CLI repro in this section stand unchanged. What
> changes is the disposition: the "different products" framing assumed the
> semantics had never been chosen. They were chosen, encoded as a keyword list,
> documented against `conditional-blocks` by name, and then not wired into arm
> A. **mybd-jrbuu's `human-decision` label should be re-examined** — "wire the
> existing helper or delete it" is a narrower question than the three-way
> product fork above.
>
> Why the sweep missed it: §4's search was token-based — every
> `conditional-blocks` / `DepConditionalBlocks` reference, enumerated by file.
> `IsFailureClose` carries neither token in its name, only in its doc comment.
> The section's confidence ("No code path anywhere reads an outcome") outran the
> search that backed it, which is the same failure this report diagnoses in
> other agents' beads two sections below.

## 5. `bd admin reset` — hypothesis converted to verified root cause

**mybd-3bevm** (P1) carried an incident from 2026-07-21 with an explicitly
unverified hypothesis. `bd -C <temp-repo> admin reset --force` removed the global
`C:\Users\Matt\.beads`, `bd-main/.git/hooks/{pre-commit,post-merge,post-checkout}`,
and bd-main's repo-local `beads.role`.

**Static analysis only. I did not run `bd admin reset`** — the defect under
investigation is that it reaches outside its stated target, and this machine has
live global state. The hypothesis was correct and decomposes into three
independent defects, plus a fourth not in the bead:

- **D1 — `-C` never changes directory.** `applyChangeDirSelection`
  (`cmd/bd/main.go:736-751`) only does `os.Setenv("BEADS_DIR", …)`. No `os.Chdir`
  exists on the `-C` path, so every subsystem resolving from cwd keeps pointing
  at the caller's repo. The flag's help text promises `git -C` semantics it does
  not implement.
- **D2 — `runReset` unions two independently-resolved targets.**
  `git.GetGitCommonDir()` (cwd-derived) and `beads.FindBeadsDir()`
  (`BEADS_DIR`-derived) with no coherence check; `collectResetItems` takes hooks
  from one and `.beads` from the other. `performReset(items, _, _ string)`
  discards both directory arguments, so there is no last-chance check either.
- **D3 — the ancestor walk has no upper boundary.**
  `FindBeadsDirFrom` (`internal/beads/beads.go:633`) walks to the filesystem
  root; `repoRoot` is used only to *classify* a hit, never to stop. So
  `-C <dir-with-no-.beads>` does not error — it climbs out and returns the first
  ancestor `.beads`. On Windows temp dirs live under the user profile, so that
  ancestor is the global one. `hasBeadsProjectFiles` carries a comment saying it
  exists to stop `~/.beads` being returned, but it is a **content** guard, not a
  **boundary** guard: it holds only while the global `.beads` is not a real
  project.
- **D4 (new, filed as mybd-n7j2z, P1)** — `isBdHook` returns true if any of a
  hook's first 10 lines merely *contains the substring* `"beads"`. Any hook that
  mentions beads is deleted as if bd installed it. This repo's own composed,
  git-tracked `.githooks/pre-commit` (which chains `bd hooks run`) matches, and
  the `.backup` restore only fires for hooks bd itself displaced. This is very
  likely the actual mechanism behind the hook removals: D2 explains *which repo*
  was hit, D4 explains *why those files* were considered bd's to delete.

**Correction to the bead's acceptance criterion 2**, which assumes `--force` and
target-widening are entangled: they are not. `force` only selects
`showResetPreview(items)` vs `performReset(items, …)` — both consume the same
`items`, computed before the branch. The target set was already wrong in dry-run;
the preview would have printed the global path. There is nothing to disentangle.

Did not implement: the fix shape is a product choice (does `-C` become a real
chdir, changing behaviour for every command? or does reset alone re-derive its
git root?). Noted on the bead that **AC1 alone is safe to implement without
choosing**, since refusing to act on disagreement only ever converts a
destructive action into an error.

## 6. Queue hygiene: four merged PRs with beads left `in_progress`

**mybd-z43u4** was a cold-start pointer bead: six PRs opened by an earlier
session, none merged, all on `in_progress` beads and therefore invisible to
`bd ready`. Verified every one against GitHub. Four had merged hours earlier and
their beads were still open:

| PR | bead | merged |
|---|---|---|
| #5185 | mybd-1fisj | 08:18:10Z |
| #5188 | mybd-fjc1o | 16:41:38Z |
| #5189 | mybd-g4vgq | 16:41:42Z |
| #5190 | mybd-n0147 | 16:41:46Z |

All four closed on merge evidence. Before closing mybd-fjc1o I checked its
"FLAGGED FOR MAINTAINER" note (that `bd sync` was gated too, a behaviour change
for automation relying on implicit adoption) rather than letting it vanish into
a closed bead — the merged change resolves it: `--yes` for scripted opt-in,
`--no-adopt` / `BD_NO_REMOTE_ADOPT=1` to disable, `--no-adopt` winning over
`--yes`, and 22 CHANGELOG lines. No follow-up bead needed.

Only `maphew/mybd#24` (mybd-zelnn) remains open, and it is an owner decision
that mybd-zelnn already carries. **mybd-z43u4 closed.**

Also corrected: this bead's own description still led with a stop-the-line note
naming #5185 as the fix for red main. That was true at 08:18Z; main went red
again 34 minutes later from an unrelated cause.

## What I noticed that isn't on any list

**Two sessions, working from opposite ends of a 100-deep queue, collided on the
newest item within the same hour.** The oldest-first/newest-first split is a good
way to divide a long queue, but it gives no protection at all on the item both
sessions would rank first on other grounds — a P0 stop-the-line. Priority
overrides queue position for any agent behaving sensibly, so "start from
opposite ends" silently degenerates to "both start at the P0" whenever one
exists. The dedup cost this session was one complete fix, one reviewer pass, and
several full-suite runs.

Cheap mitigation, if the pattern repeats: whoever picks up a P0 claims it
*first* and pushes the branch early even when unfinished — the branch name is
visible to `git branch -r` in a way an unclaimed intention is not. Not filed as a
bead because it is a habit for the human dispatching the sessions, not a code
change.

Second, smaller: three separate beads this session (mybd-zelnn §3.6,
mybd-jrbuu, mybd-3bevm) carried confident mechanism claims that only survived
verification **in part**. All three were written by agents reading code without
running it. The audit-style bead is a genuinely useful artifact, but its claims
should be read as hypotheses until someone executes them — §3 in particular
would have sent an implementer to write a recursive CTE that already exists.

## Beads touched

| bead | action |
|---|---|
| mybd-5p561 | closed — duplicate of mybd-fciu9 (#5204 owns the fix) |
| mybd-z43u4 | closed — all six PRs dispositioned |
| mybd-1fisj, mybd-fjc1o, mybd-g4vgq, mybd-n0147 | closed on merge evidence |
| mybd-0zfum | closed — correction posted upstream, gh 3887 recommended for close |
| mybd-s9fcm | filed, then closed as duplicate of mybd-sopqb |
| mybd-jrbuu | verified, labelled `human-decision`, returned to open/unassigned |
| mybd-3bevm | root cause verified and recorded; left open (fix shape is a product call) |
| mybd-3xire | filed, then narrowed to the telemetry-span remainder after #5204 |
| mybd-zz04j | filed — stale comment in `workspace_gate_test.go`, blocked on #5204 |
| mybd-n7j2z | filed — `isBdHook` substring over-match (P1) |
| mybd-zelnn | commented — §3.6 correction, PR still open so it can be fixed first |

## Verification performed

- Reproduced the P0 locally and confirmed the fix removed the leak; confirmed
  the two regression tests I wrote **failed without the fix** before trusting
  them.
- `go vet` clean; full `cmd/bd` suite run under CI flags (`-race -short -skip
  '^TestEmbedded'`) — and note the 10m-default-timeout trap in §1.
- gh 3887: built `bd` at `9973e9628` and ran three behavioural cases.
- `conditional-blocks`: reproduced on the CLI end-to-end.
- `bd admin reset`: **code reading only, deliberately not executed.**

_claude-opus-5-high on behalf of maphew_
