# Ready-queue sweep #2, 2026-08-01 (autonomous, claude-fable-5-high)

Second autonomous ready-queue sweep of the day (the morning sweep's report is
`2026-08-01-ready-sweep-autonomous.md`). Brief: work `bd ready` until dry or
blocked, workflows on, check for existing coverage before claiming,
worktree + branch + tests + PR per task, no product decisions, no history edits.

## Outcome: 4 PRs advanced/opened, 6 patrol lanes armed, 5 beads closed, 4 filed

| PR | What | Bead / lane |
|----|------|-------------|
| gastownhall/beads#4985 | Fix-merged davevan2's preview store-migration gating: all 4 review items (proxied preview policy via new `uow.WithPreview` seam, read-only dry-run target factory, version-marker preservation, non-fatal PostRun read-only refusal) + main merge across the `rootStorePolicy` refactor. Negative controls run (fixes reverted → tests fail). Approved. | mybd-vy09, merge lane |
| gastownhall/beads#4959 | Fix-merged srobroek's gate repo selectors: SF1–SF4 + runner seam + 7 review-round fixes (exit-code restore, pour-time `{{var}}` substitution via `cloneSubgraphInto`, cross-repo discovery made real: hint required, `--workflow` narrowing, explicit `--branch` honored, byte-identical metadata round-trip). Approved. | mybd-dtdm, merge lane |
| gastownhall/beads#5248 (new) | Metrics flusher spawn skipped under `BEADS_TEST_MODE` (rjc123's suggestion, credited); `shouldSpawnFlusher()` extracted and pinned by hermetic tests. Local `make test` **passed** on the PR head. | mybd-syou, merge lane |
| gastownhall/beads#5251 (new) | pr-preflight warn-only PR-gate sample: per-`workflowDatabaseId` grouping, fires only against a known-green base, never blocks (pr-babysit classifier + base-fix exception preserved — regression-tested). | mybd-msll, merge lane |
| gastownhall/beads#5253 (new) | Formula var validation: provided-empty + enum/pattern enforced across cook/pour/wisp/bond/seed incl. proxied paths and bond dry-runs; no-default vars treated as required. | mybd-s8vb, merge lane (mybd-u2r6 closed into it) |
| gastownhall/beads#5223 | Un-wedged our reset-guard PR: resolved the #5221/#5227 squash-stack conflicts (guard kept, newer `isOnlyShebangOrBlank` semantics taken), pushed, re-armed. | mybd-s2j21, merge lane |

Also posted: the dolt `schema-encoding-drift check` false-negative field report
on dolthub/dolt#11133 crediting marcodelpin (mybd-1g7x closed).

## Beads closed with evidence

- **mybd-hggl** — both named flake-fix legs already landed upstream (#4600, #3987 merged; `listenWait=10s` verified on main).
- **mybd-ae0n** — conformance job already split/sharded to 35m+30m (#4633, #4761); the 10m ceiling no longer exists.
- **mybd-fyno** — fix-merge trigger never fired: vishnujayvel addressed all items 07-28; disposition now owner's via mybd-dodi9 / maintainer pushes via mybd-php3l.
- **mybd-qsl2** — Entire back-out verified complete: `.githooks` clean vs upstream, no `.entire/`, backups present, `scripts/test-git-hooks` all green.
- **mybd-u2r6** — fixed in #5253 (rides mybd-s8vb's lane).
- **mybd-1g7x** — reported upstream (comment link on the bead).

## Beads filed

- **mybd-vctrh** — deferred formula follow-ups from #5253 codex review (authored-default validation; extends-resolution in bond dry-run).
- **mybd-4rgyc** — `TestConfigValidateReadOnlyIsHermetic` fails on clean upstream/main (`dolt.gate.lock` debris) while CI stays green — a main.yml-blind-spot sibling of mybd-msll, opposite direction.
- **mybd-wehjh** — gate discover treats `metadata.repo` naming the *current* repo as foreign (heuristics disabled); needs lazy current-slug resolution. Plus residual review nits.
- (annotations) **mybd-avwqg** — reap-test-debris mop verified working in production (the 4 reported servers gone; young ones correctly spared); bead stays open for the prevention leg, with a design caution: plain Pdeathsig is wrong because bd exits while the server must outlive it. **mybd-p8i3** — overlap warning vs in-progress mybd-wfxwe.

## Process notes (for the next cold agent)

- **The wrong-cwd bd trap bit again, subtly**: `bd` run from `bd-main/` reports
  `no issue found` for mybd-* IDs. This session *misread that as "a parallel
  session closed these beads"* (qsl2/p8i3) and initially skipped them — they
  were open all along. If beads "disappear" mid-session, check `pwd` before
  reasoning about parallel sessions.
- Cross-vendor gate loops: codex found new P2s on every re-arm of the formula
  branch (3 rounds). The maintainer reconciliation step is what terminates the
  loop — adopt what's load-bearing, defer follow-up-grade findings to beads,
  say so in the PR body. All deferrals this session are in mybd-vctrh/wehjh.
- The lane E detector was redesigned mid-review (aggregate → per-workflow,
  block → warn-only) because the reviewer proved the original spec could
  never fire for the motivating incident and would have parked every patrol
  lane. Worth remembering: "exactly parallel to the red-base handling" was in
  the spec and was wrong; the reviewer's fixture-based disproof caught it.
- Queue state after this sweep: remaining `bd ready` items are owner-gated
  (tri:human, human-decision, solo-sweep:proposed review), deadline-gated
  (mybd-h8bb due 08-02; mybd-ncx38/nathu due 08-03), wrong-machine (gwxj,
  sk7e's Windows half), blocked (aokv on dashboard steps, cof8 on the
  pull_request_target safety analysis), design-gated (s4h6/alm2 need owner
  semantics), or big campaign epics/cluster sweeps. The migration-schema
  cluster (xmx7.6) overlaps the solo-sweep:proposed batch awaiting owner
  review (mybd-lvzry) — running it autonomously would duplicate/step on that
  lane, so it was left alone.
- The `.worktrees/beads/reset-global-guard` worktree (another session's) still
  has the pre-conflict-resolution branch checked out; its branch ref was
  advanced by this session's push. Left in place; remove after 5223 merges.

Agent-Signature: claude-fable-5-high on behalf of maphew
