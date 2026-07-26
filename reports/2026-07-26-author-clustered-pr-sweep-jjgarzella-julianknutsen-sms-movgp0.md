# Author-clustered PR sweep — 2026-07-26

Session: remote-control, clusters ordered jjgarzella ×2 → julianknutsen ×7 →
seanmartinsmith ×5 → MovGP0 ×4 → kevglynn (skipped). 16 PRs dispositioned or
confirmed-tended; 2 fix-merges pushed to contributor branches; 1 decline; 5
retire-with-attribution; 1 design-collision report; 1 owner decision queued.

## jjgarzella ×2 (oldest unanswered, 75+ days)

- **#3875 (needs+waits_for dep collision) — fix-merged on contributor branch,
  patrol bead mybd-pbmf.** Force-pushed `c1904b9ef → 53e8fd31a` (lease-guarded):
  rebase onto main; same dedup applied to the `depends_on` loop; and the July-14
  review's pre-fanout-window gap closed **provenance-scoped** — collapsed edges
  carry `also_blocks: true` metadata and only flagged edges block on
  spawner-open (a global gate change broke documented all-children semantics,
  `TestIsBlocked_WaitsForDefaultGate`). Bonus pre-existing bug found and fixed:
  `cloneSubgraph` dropped `dep.Metadata`, silently resetting every poured
  waits-for gate (would already have broken `any-children` in formulas).
- **#3876 (on_complete executor) — declined per the gascity#2947 maintainer
  ruling** (on_complete scoped out of beads; Gas City `drain` canonical).
  Value ledger posted: #3781 + #3874 merged, #3785 superseded, #3875 landing.
  Delayed close beaded (grace to 2026-07-29). Follow-up **mybd-bxlu**: beads
  still parses/pours the silent no-op `OnCompleteSpec` (GH issue 3782) —
  resolution is warn/remove, not an executor.

## julianknutsen ×7

Cluster was already well-tended (#4916/#4907/#4859 reviewed 07-23/24 awaiting
author; #4715/#4697/#4682 self-parked by the author's own review pipeline
pending his rebase). The one stale item:

- **#4581 (hosted-gateway conn churn) — fold attempt found a real feature
  collision**, bead **mybd-h8bb**. Main independently landed a second
  credential-command subsystem (`internal/creds` + `ApplyGatewayCredential`,
  mint-once-at-open) overlapping the PR's per-dial `BeforeConnect` re-mint.
  Two failing tests prove it in both directions (gateway path never sets
  `CredentialCommand` → PR's re-mint never activates; PR's
  `resolveServerCredential` predates the embedded/server split → runs commands
  in embedded mode). Main's own gap remains real: pooled reconnects after token
  rotation dial with a stale username. Status comment posted offering
  split-land of FIX 1 (ignored-tx pool borrow, no overlap) with proceed-by
  2026-08-02. WIP merge preserved: local branch `pr-4581-fold`, commit
  `7fcd354a4`, worktree `.worktrees/beads/pr-4581-fold` — **do not push**.
  Trust-boundary open question: PR's `TrustedDoltCredentialCommand` honors
  central config; main's is env-only.

## seanmartinsmith ×5 — complete

All five Windows test-hardening PRs (#3797 #3801 #3802 #3806 #3812) were
already absorbed by main commit `7865493f7` (PR #4600, 2026-07-07), which
names all five and carries `Co-authored-by: sms`. Retirement comments posted
on all five; delayed closes (from 2026-07-28) in **mybd-qy7m**; salvage bead
mybd-8chd.1 closed; #3812 leg noted resolved in mybd-hggl.

## MovGP0 ×4

- **#4325 (Windows CGO toolchain Makefile fix) — fix-merged**, patrol bead
  **mybd-k51r**. One conflict (INSTALLING.md → docs/getting-started/), merge
  commit `b71bdf162` pushed to `MovGP0:build/4324`, Linux build verified.
- **#4316/#4317/#4318 (bd attachment + Jira/Linear sync, ~11.7k lines) —
  substantive design review posted** (first real answer in 7 weeks; included an
  apology for the misfired bug-triage template that was their only prior
  reply). Verdict: owner-decision-required → likely redesign preserving the
  contributor's CLI/schema/hash work under his attribution. Blockers: `prune`
  can permanently destroy the only copy of bytes via a branch-scoped
  reachability index; migration 0050 collides; ~660 doc lines target the
  deleted Docusaurus tree. **Owner decision queued: mybd-982o
  (`human-decision`): must attachment bytes survive `bd dolt push` + clone?**
  Yes → bytes into Dolt (blob, size-capped; prune/fsck disappear). No →
  metadata-only references; Jira/Linear trackers become the byte home.

## kevglynn ×5 — deliberately skipped

mybd-ds4v is another session's live lane (updated 2026-07-26 04:10Z, #4329
mid-fix-merge there; #3717 explicit hold; #3395 owner decision; newer trio
awaiting author). No double-work.

## Noticed, not on any list

- `bd human <id>` as documented in CLAUDE.md does not exist in the current bd
  binary — `bd human` is a help-menu command. Used a `human-decision` label on
  mybd-982o instead. CLAUDE.md (and any agent muscle memory) needs updating.
- The `cloneSubgraph` metadata-drop bug (fixed inside the #3875 push) is the
  same bug *class* as the labels-drop #3784/#3785 — template cloning keeps
  losing fields added to primitives after it was written. If a third field
  joins Labels and Metadata, factor a copy-everything helper.
- maphew's 2026-06-16 "repro sweep" template comment misfired onto at least 4
  feature PRs (all of MovGP0's); apologies posted in-thread. Worth checking
  whether other authors got the same misfire.
- 16 worktrees under `.worktrees/beads/` — several from parallel lanes; left
  untouched per the shared-state posture. `pr-4581-fold` is deliberately kept.

Agent: claude-fable-5-medium on behalf of maphew
