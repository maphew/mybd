# 2026-08-12 wind-down sweep: fleet triage, 5243 fix, 31 bead closures, conversion queue

Session working epic **mybd-ykt9f** (IC transition wind-down, owner directive
2026-08-12). Three workflows + one in-session code fix. All bd mutations serial
in-session; workflow agents were read-only (gh/git/file reads).

## Phase 1 — reviewed trio wrap-up (mybd-1xa46, closed)

CI verified green on all three MERGE-AFTER-FIXES PRs after yesterday's fix
pushes: 5229 (99 pass at 3d9e177fb), 5092 (103 pass incl. the new Windows
doltversion job at 6ba5c0ea7), 5202 (99 pass at 1b9194118; the close/reopen
retrigger worked — the head had never had a single workflow run). Nothing left
on our side; awaiting steveyegge re-review.

## Phase 2 — PR fleet triage (workflow, 14 agents, mybd-koabx)

13/14 non-reviewed PRs: green CI, mergeable, zero unanswered feedback, neither
carry-PR author (jakelindsay87/4730→5635, halaprix/5065→5642) has returned.
Verdict: healthy-await-review; no closes warranted.

**PR 5243 needed action** — its own 2026-08-02 codex self-review had flagged a
should-fix redirect regression (disposition fix-merge) that sat unaddressed for
10 days. Fixed in-session:

- Root cause: `activeRepoPathForRouting` read the live `BEADS_DIR` env var as
  "explicit selection", but `prepareSelectedCommandContext` sets `BEADS_DIR`
  for **every** command, so a plain `.beads/redirect` bound `beads.role` to the
  storage root instead of the workspace.
- Fix `3adb95aeb`: selection provenance captured at process start + `-C` flag;
  regression test drives the real startup rebind with a real redirect
  (verified red on old logic, green on new).
- Cross-vendor round caught a real P1 in my own fix: `.beads/.env`-provided
  `BEADS_DIR` (loadBeadsSelectionEnvFile) loads after process start and would
  have lost its explicitness. Fixed in `764bdbe4c` + end-to-end test.
- Bonus: provenance-based logic cured 5 of 6 pre-existing intra-suite
  `BEADS_DIR`-leak test failures observed on baseline in the nested worktree.
- Pushed, commented on the PR. Note: the cmd/bd test slice is order-flaky in
  nested-worktree checkouts independent of any change (empirically confirmed
  mybd-rgs2i, which was reclassified from close-candidate to convert-upstream
  on this evidence).

## Phase 3 — bead triage (workflow, 8 agents over 92 open/in-progress beads)

| Verdict | Count | Action taken |
|---|---|---|
| close-obsolete | 37 | **31 closed** with value-extraction notes; 2 blocked (psxg: open children; r5u2: human gate pt1vk); 3 (t7mk/t7mk.7/hli9) dependency-blocked by decision bead pdvy — ride on it; 1 (rgs2i) reclassified |
| convert-upstream | 29+rgs2i | 18 high-confidence verified against upstream/main by a third workflow (below); 12 medium queued unverified |
| pr-fleet-tied | 8 | stay open until their PR resolves (koabx cebxh itgj pp5hv reg9t qcy1m xb9h + 5202-tail) |
| personal-keep | 14 | stay open (lq8i retro family, codex-agent/session tooling, personal config) |
| owner-decision | 4+2 | see list below |
| winddown-infra | 1 | the epic itself |

### Owner decisions outstanding

- **mybd-pdvy** — escalate gh-4249 vs fork-carry pure-Go releases; t7mk family
  closure rides on this.
- **mybd-2yok** — publish venue for engdocs architecture survey (drafts ready).
- **mybd-0nzhq** — reports-navigation memo sign-off.
- **mybd-cof8** — trigger-actor widening is a security-boundary call.
- **mybd-r5u2** — human gate mybd-pt1vk blocks a close the bead itself
  recommends.
- **mybd-psxg** — epic close pending psxg.3 (conversion queue) and psxg.4
  (deferred until 2026-08-24, tied to PR 5092).

## Phase 3b — upstream conversion verification (workflow, 18 agents)

18 agents verified the high-confidence conversion candidates against
upstream/main (4ad99760b) with existing-issue dedup. Outcome: 12 still-valid,
3 already fixed on main (o97vm via PR 5205; x5d49's regen half via
docs-autofix PR 4653; 3c9o's residue via PR 5083), 2 already filed/covered
(t7mk.6 = gh 4249; d0u3f exists only on PR 5202's branch, reclassified
fleet-tied), 1 cannot-verify (rgs2i - but this session independently obtained
a live repro; evidence appended to the bead, queued for root-cause).

### Filed today

- gastownhall/beads#5689 <- mybd-b56a (RootID rename/case-variant bricking, 15s opaque timeout)
- gastownhall/beads#5690 <- mybd-wehjh (gate discover treats self-repo metadata.repo as foreign)
- gastownhall/beads#5691 <- mybd-s3yn (ListCLIRemotes hardcodes context.Background())
- gastownhall/beads#5692 <- mybd-jbw3 (unbounded claim scan defeats BEADS_MAX_ROWS)
- gastownhall/beads#5693 <- mybd-8l6x (settings.json unconditional rewrite drops trailing newline)

### Queued (verified but not yet filed — pace filings, avoid a 30-issue burst)

mybd-vctrh (formula validation gaps), mybd-ykaa (shared cobra flag test
pollution), mybd-7qp5 (proxy handshake hardening), mybd-lfos (port-collision
allocator RFC), mybd-43lf (doctor encoding-corruption detection), mybd-o4u1w
(-C outside-git residual - reference PR 5243 when filing), mybd-zz04j (stale
workspace_gate_test comment - consider a tiny PR instead of an issue).
Full verified drafts preserved in
[2026-08-12-winddown-issue-drafts.md](2026-08-12-winddown-issue-drafts.md);
queue tracked by bead mybd-i921i.

### Medium-confidence, unverified queue

mybd-y18b mybd-vv48x mybd-atp2s mybd-jart4 mybd-u28eh mybd-nsg1 mybd-569g
mybd-5zvr mybd-3xire mybd-psxg.3 mybd-d8q0 mybd-qnva

## State after this session

- Beads: 92 open/in-progress at session start -> 51 after (41 closed today:
  1xa46 + 31 triage + 4 verify-closed + 5 filed-closed).
- Upstream PRs: 17 open, all green/mergeable; 5243's known regression fixed;
  reviewed trio awaits steveyegge re-review. 5 new upstream issues filed.
- Owner queue: pdvy (gates t7mk/t7mk.7/hli9/t7mk.6 closure), 2yok, 0nzhq,
  cof8, r5u2 (gate pt1vk), psxg (children psxg.3/psxg.4).
- Workflows this session: pr-fleet-triage (14 agents), bead-winddown-triage
  (8 agents x 92 beads; first run lost to API 529s, resumed on sonnet),
  upstream-issue-verify (18 agents). All bd/dolt mutations serial in-session.
