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

---

# Continuation leg ("carry on"), same day

## ecuthiell — 4 new PRs (opened 2026-07-26)

- **#5073 / #5074 / #5076 approved** (conformance timeout budgets; native repro
  fixtures replacing POSIX-shebang fakes with parent-PID-bound self-reexec;
  docsmint path assertion) — all green, handed to patrol (mybd-gfpf /
  mybd-1eag / mybd-pfts).
- **#5075 (CI lint overhaul, +3.5k) — split-merge.** Deep review found the
  ~15-line core (windows cross-lint closes #4991, fmt-check exit-status fix,
  linter pin) buried in ~2.7k lines of host-identity binding that is red on
  two deterministic bugs: a PowerShell `AppendAllLines` overload failure that
  makes the native lane unable to go green, and a macOS `MAKE_HOST`
  path-equality check that is *latent in main.yml* (push-to-main only — would
  red main post-merge). Also: the CGO=1 native-Windows lint lane provably adds
  zero coverage (no `windows && cgo` files exist). Review COMMENT posted (no
  CHANGES_REQUESTED); core extracted as **maintainer PR #5083** with
  `Co-authored-by: Ewen Cuthiell`, patrol bead mybd-toeu; remainder gated in
  **mybd-buds**.

## mybd-qaeo fix-push sweep (harry-miller-trimble + vishnujayvel) — complete

All fixes specified by the 07-24 reviews implemented on contributor branches,
approved, patrol-handed:

- **vishnujayvel**: #4832 and #4829 — author had already pushed the exact
  requested fixes himself on 07-26 (responsive; approved as-is). #4830 —
  maintainer commit `8701e7514` (mode-appropriate remotes path, authoritative
  empty `repo_state.json`, corrupt-state warning + 3 tests). Patrol:
  mybd-n6fn / mybd-lrca / mybd-vzk6.
- **harry-miller-trimble**: five fix commits pushed (#4793 `47a947d5d` incl.
  main-merge + legacy-sweep removeClosed; #4790 `03cdecbfe` provenance-correct
  `config show`; #4789 `b245c5372` generated-doc revert; #4788 `1957fd6de`
  pre-open title validation + proxied test; #4787 `d1f5af812` Args-validator
  rejection). Recurring theme fixed uniformly: validation running after
  store-open and missing the proxied path. Consolidated comment on #4793.
  Patrol: mybd-x7xz / 96cs / deml / r8jp / 92ud.
- #4430 dropped from scope — absorbed by another session (07-25 report).
- New bug filed: `TestCLI_CreateRejectsEmptyTitle/FlagTab` leaves the shared
  cobra `--title` flag dirty (pre-existing on main; cascades in full-suite runs).

## Noticed this leg

- vishnujayvel now responds within days — future reviews of his PRs can lean
  on request-then-wait rather than fix-push; re-check before spending builder
  time (two of three builder slots were no-ops because he'd already fixed).
- statusCheckRollup lies: it aggregates stale runs (showed 7 failures on a
  fully-green PR). `gh pr checks` is the check-state source of truth;
  preflight's failed-checks count inherits the rollup problem.

---

# Leg 3 ("carry on" ×2): the waiting-on-us queue

Ranked every open contributor PR by "author replied, maintainer silent" and
worked the list. 18 more PRs dispositioned this leg.

## Approved and with the patrol (8)

- **#3906** (quad341 Lite foundation) — final maintenance push: main merged,
  `leases.granted_node` classified lite (author had already wired the #4160
  comparator himself). Patrol mybd-9rd1t, squash. **#3458 decision posted**
  (mybd-7kcg, option c): re-cut atop Lite as method+benchmark — quad341's
  compile-fact correction retired the months-old "land the bench file alone"
  plan and is credited on-thread.
- **#4751/#4752** (remuscazacu) — #4752's conformance response verified;
  #4751 renumbered a second time maintainer-side (0015→0017; main outran him).
- **#4813/#4820** (kevglynn's new pair) + **#4735** (Mosnar Beadazzle entry) —
  responses verified, approved.
- **#4535** (Kevinwochan Kiro recipe) — maintainer rebase, generated docs
  reverted to release pin.
- **#4480** (johnzook counts filter-before-join) — deep re-review verified the
  whereSQL invariant against all four post-branch clauses and ran the parity
  test 11/11 on real Dolt. Discovery beaded: pr-risk CI compiles but never
  executes non-conformance dolt tests (the gap that hid the original break).

## Decisions and dispositions (7)

- **#4720 vs #4350** — July 12 supersession REVERSED with apology: #4720
  survives (blockers verified delivered; #4350 now 425 behind, conflicted);
  j-s-au's two-phase-open + route-error-propagation get ported with
  attribution; #4720's never-executed fork CI approved.
- **#4804** (atbrace migration-lock fast path) — sentinel fix adversarially
  verified sound; approve-after-rebase posted (1 hunk vs #5012) + one
  structural ask: sentinel write must be non-fatal. Review's own error re
  rekeyAuxRowIDs acknowledged; author's correction accepted.
- **#4504** (Rome-1 CALL-migration idempotency) — approve-in-principle
  (kevglynn's 07-11 verification held), gated on rebase; sequencing note vs
  #4804 (same schema files).
- **#4753** (dredozubov external capability blockers) — both blockers verified
  closed at head; fork CI approved (was zero-run); three should-fixes posted
  (tree-predicate widening, silent permanent fail-closed on proxied foreign
  projects, parent-filter parity).
- **#4520** (marcodelpin spool) — driver-routing correction accepted, narrow
  pre-dial-probe retry budget green-lit as fresh PR, PR closed warmly.
  **#4808** — flake identified as the #5042-fixed family; review items stand.
- **#4376** (sarendipitee resolver) — retired: main's #4939 independently
  landed the same substring-rejection with tests.
- **#3612** (gt-rm-0306, oldest PR) — retired with credit: bug real on main,
  branch ~1100 behind, design owned by julianknutsen's first-principles
  cross-db-deps thread. Bead ensures the silent-drop bug gets a tracking issue.

## Direction disclosures (2)

- **#4415** (MarkAtwood flat-file backend) — told plainly: don't hold for
  #4859 (superseded by tombstone policy); main's Dolt-only contraction
  disclosed; plugin path via duncan4123's #4561 offered as the charter-fit
  home; full in-tree design review available on request.
- **#4133** (Zireael dolt TCP fix, 64 days unreviewed) — apology first;
  split verdict: config half superseded by main's #4986-hardened YAML path
  (would reintroduce a data-loss bug as-is); handshake-drain half is genuinely
  novel and wanted, but must move to the per-command fail-fast probe (the
  actual storm source) with a re-poll-on-drain-timeout fix. Author given the
  narrow-it-yourself vs maintainer-lands choice; hamchowderr given the
  measurement that would actually prove the mechanism (their unit-test
  validation measured nothing — 3 of 4 new tests are log-only stubs).

## Noticed this leg

- Three separate contributors were waiting behind GitHub's fork-CI approval
  gate with ZERO executed checks (#4720, #4753) — "green locally, silence
  from CI" reads to them as maintainer neglect. Worth a patrol job that
  auto-approves runs for PRs with an engaged review thread.
- Migration-number collisions burned contributors twice this week (#4751
  twice, #4316, #4916). The renumber is always mechanical; a bot comment on
  conflict ("your migration number was taken, next free is NNNN") would save
  a round-trip each time.
- Review-response turnaround among regulars is now often same-day
  (vishnujayvel, atbrace, kevglynn, R0SEWT, remuscazacu, dredozubov) — the
  bottleneck has inverted: contributors wait on re-review, not the reverse.
  Re-review-on-response should be treated as the highest-leverage daily lane.
