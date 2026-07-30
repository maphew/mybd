# Issue sweep: theme:concurrency (run 2) — 2026-07-30

Second pass over the same 5 open `tri:claim` stubs run 1 swept on 2026-07-26
(`reports/2026-07-26-issue-sweep-data-integrity-concurrency.md`, which retired
0 of 18). Run 1 closed nothing and opened four hold lanes; run 2 exists to
resolve those holds. Theme is fully covered — 5 open stubs, 5 dispositioned,
none deferred for scope.

Unattended solo-sweep lane: every disposition below is a **proposal**. Batch is
`bd list -l solo-sweep:proposed`.

## Dispositions

| bd | gh | proposed | evidence |
|----|----|----------|----------|
| mybd-rkn87 | 4331 | **close** | Mechanism is gated off, not merely patched: `4990c8309` (#4170, gates auto-import off entirely in server mode), `1cf833734` (#3691), `1f82e00fb` (#3960) — all three verified present on `upstream/main` by ancestry. Empirically confirmed 2026-07-28 on a v1.1.2 + dolt-sql-server-2.2.2 rig under mybd-xvw9d (`reports/2026-07-28-v112-verification-close-drafts.md:21-35`): stale jsonl never imported, DB rows survived. Siblings 4245/3948/3880 were already closed on this exact basis; 4331 was never added to the family list. No PR names 4331. |
| mybd-ad63 | 4371 | **consolidate** | Umbrella mybd-agf58 (created 2026-07-29) already names gh 4371 as a member, but ad63 has **no dep edge**, so the membership is prose-only and invisible to `bd ready`. Non-atomicity confirmed still live in direct/embedded mode (`internal/storage/domain/issue.go:557-590`: AddLabels then RemoveLabels as two sequential calls, no row_lock rewrite). |
| mybd-zwurw | 3575 | **keep-open** | Zero GitHub activity in 3 months (empty timeline, verified not truncated; 0 comments). The one merged family PR, 4675, does not mention 3575 at all. Half-answered: distinct-actor double-claim is fenced by merged work, same-actor is not — and the issue text never says which the reporter had. |
| mybd-zgxf | 4657 | **keep-open** | Both hold-PRs verified **NOT merged**: 4682 `mergeable_state=dirty`, 4697 clean but labeled `status/review-failed`. The 2026-07-27 redirect to 5006/5008 checks out — both verified merged (`a45199a54`, `6e8af8bf8`). Residue (same-actor) untouched by all of it. |
| mybd-1hao | 4521 | **keep-open** | `updated_at == created_at == 2026-06-30`, 0 comments — no delta since the P0-triage check one day earlier (mybd-6ozys, 2026-07-29). That disposition stands verbatim; no further recon spent. |

Net: 5 examined, 1 proposed close, 1 consolidate, 3 keep-open. One new
engineering bead: **mybd-tj5iz** (P1).

## Root-cause map

**Group A — claim cannot fence parallel same-user sessions** (mybd-zwurw,
mybd-zgxf) → new bead **mybd-tj5iz**.

The cross-actor half of this class is now closed by merged work, each merge
verified individually this run rather than inferred from a reference: 4675
`65078a93e`, 5006 `a45199a54`, 5008 `6e8af8bf8`, **5066 `13d2c8d6b`
(2026-07-27 — new since run 1)**, 4727 `639c56f81`, 4911 `607df586d`. PR 5066's
own commit message calls itself "the last unfenced cross-actor takeover path in
the CLI"; I read the diff — it fences `assign`/assignee-set, **not** `--claim`,
so it is adjacent, not a fix.

What survives is the same-actor case: same-user claims are documented idempotent
success (#2821), so two sessions running as one user cannot mutually exclude.
Both upstream issues describe half of this without naming it. Upstream candidate
is `claim_fence` (4697 slice 1), unmerged. This repo already works around the
gap by convention — AGENTS.md "Role split, not claims", written after the
2026-07-24 #4942 incident — which is why the bead's first question is whether
the fence belongs in beads core at all, not how to build it.

**Group B — non-atomic multi-mutation writes** (mybd-ad63) → existing umbrella
mybd-agf58, needs a dep edge.

New finding that sharpens the scope decision ad63's 2026-07-22 note asked for:
the two modes have **diverged**. Proxied is now genuinely transaction-guarded —
`cmd/bd/update_proxied_server.go:135-227` spans read, ApplyUpdate (the add+remove
pair) and commit in one unit of work, and retries the whole attempt on
serialization failure; the comment at :85-92 names the retired bug class
verbatim. Direct/embedded still applies add and remove as separate sequential
calls. So the exit-0-partial-apply symptom is structurally prevented in one mode
and structurally reachable in the other.

**Group C — journal corruption / stale locks** (mybd-1hao) → parked on an owner
design ruling, not on evidence. Only stub here whose blocker is a decision.

## Confidence and caveats

- **The one close is the one to scrutinize.** mybd-rkn87 rests on a verified
  merged gate plus an empirical rig verdict — the strongest evidence class
  available here — but **no PR or commit names gh 4331**, and the 07-28 rig ran
  a *single* writer while 4331 asserts a *concurrent-mutate* race. My reasoning
  that concurrency is moot (a race needs a triggering write; the trigger is
  gated off unconditionally in server mode) is code-reading, not a two-writer
  repro. A 2-writer variant of the existing rig would settle it cheaply. If you
  want the sweep's stated 30% false-positive rate to bite somewhere, expect it
  here.
- **A near-miss worth institutionalising.** GitHub returned a non-null
  `merge_commit_sha` (`644a3297e`) for PR 4697 while `merged: false` — that is
  the speculative test-merge SHA. A sweep that treated `merge_commit_sha` as
  proof of merge would have closed mybd-zgxf, a live p2, on a phantom. Verify
  `merged: true` *and* the SHA, never the SHA alone.
- **All four upstream issues I checked have literally empty timelines** (3575,
  4657, 4371, 4331 — confirmed against the `/events` endpoint too, so not an
  endpoint artifact). Combined with zero comments and `updated_at ==
  created_at`, the cross-reference channel gave no signal at all for this theme;
  every real link was prose inside PR bodies or commit messages. Timeline
  enumeration was still worth running — it is what upgrades "no fix PR found"
  from search-inference to verified, which is the caveat mybd-agf58 was carrying.
- **mybd-ad63's consolidation is contingent.** mybd-agf58 is itself still
  `solo-sweep:proposed` and un-executed. If you reject agf58, ad63 reverts to a
  standalone keep-open.
- **Verified merged, and I am confident in these:** 4675, 5006, 5008, 5066,
  4727, 4911, plus 4990c8309 / 1cf833734 / 1f82e00fb on `upstream/main` by
  ancestry. **Verified NOT merged:** 4682, 4697.
- **Not verified, and I did not try:** whether gh 3575's reporter used distinct
  `BEADS_ACTOR` values. The issue does not say and has zero comments; asking
  requires posting upstream, which this lane may not do. That ambiguity is the
  whole reason 3575 stays open rather than closing on the merged CAS work.
- Nothing was blocked. `scripts/solo-recon` covered the timeline enumeration
  that run 1 had to skip. Two notes were rejected before landing — once for the
  substring "human", once for flag-like tokens in prose — so per-stub notes
  write flag names in words.
- Two subagents (sonnet) did the mechanical timeline/merge/code-path recon;
  every merge claim they returned was re-verified in-session before use, and
  one of their own findings (the 4697 speculative SHA) is the near-miss above.
  One stale claim of theirs I discarded: they reported no bd stub exists for
  4371/4331, which is wrong — they queried a label form this tracker does not use.
