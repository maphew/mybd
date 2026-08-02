# Oldest-PR sweep — 2026-08-02

**Charter:** open, unmerged, non-draft upstream PRs older than 50 days. Understand the author's intent, salvage what is sound, politely decline the rest, consolidate overlaps. Worktree + branch + tests + PR per salvage. Session: claude-fable-5-high.

**Queue at start:** 23 PRs (2026-04-21 → 2026-06-09).

## Collision handling (first finding of the session)

A second fable-5 session (using codex-gpt-5.6-sol reviewers) was mid-sweep on the *same queue* when this session started — its reviews on 3777/3837/4284/4206 and a salvage update on 3395 landed 06:18–06:35Z, minutes before this session's first read. Detected by listing newest maphew-authored comments and reading signature lines. Response: carved a disjoint execution slice keyed on PR number, claimed beads before touching anything, left coordination notes on each claimed bead. Zero collisions over the session. Protocol saved as bd memory `parallel-session-collision-check`.

## Dispositions executed (this session's slice)

| PR | Age | Author | Outcome |
|----|-----|--------|---------|
| 3548 | 97d | kingfly55 | **Declined** (design): per-update history suppression is the wrong layer — per-issue `--no-history`/`--ephemeral` + tiered compaction cover the need, and silent audit-trail gaps are a sharp edge. Comment posted, close-when-quiet lane armed (bead `mybd-hbyl4`, opens 08-05, any author reply re-queues for a human). |
| 3563 | 96d | shaunc | **Salvaged — superseded by [#5276](https://github.com/gastownhall/beads/pull/5276)**: full re-cut of server-mode host inference (#3545) + host-aware error hints (#3518) onto current main, Co-authored-by shaunc. 12 codex review rounds hardened it well beyond the original (see below). Original closed with credit. Full `make test` **passed** locally at the PR head; merge tail with patrol (`mybd-07m1h`). |
| 3610 | 94d | octo-patch | **Salvaged in place**: maintainer-owned MiniMax-provider branch refreshed against main (1227 commits of drift; 7 conflicts), then a codex pass found the flagship flow broken — MiniMax key routed to MiniMax but still requested the Claude default model. Fixed (`DefaultAIModelFor`: MiniMax-M2 default, `MINIMAX_MODEL`/`ai.model` override), plus a shell-hint bug and a live-API test leak. Pushed to contributor branch, merge tail with patrol (`mybd-fherz`), verify queued. |
| 3612 | 94d | gt-rm-0306 | **Closed on schedule** (retire comment 07-26, grace past). The real bug it found now has a dedicated tracker, [#5272](https://github.com/gastownhall/beads/issues/5272) (dep list/show silently drop cross-rig + `external:` targets), cross-linked from #4769 so the two symptom threads converge. Bead `mybd-g04fm` closed. |
| 3859 | 84d | GraemeF | **Nudged**: consolidation proposal posted (fold 3861 into one series atop the 07-07 fix-merge; concrete what-moved notes; ~2-week window, then absorb with attribution). Bead `mybd-do1mx` updated, released. |
| 4133 | 71d | Zireael | **Salvaged — superseded by [#5277](https://github.com/gastownhall/beads/pull/5277)**: the drain half landed maintainer-side exactly as the 07-26 disposition promised (author silent through the 08-02 deadline). Shared `DrainAndCloseProbe`/`ProbeSQLServer` across all 8 MySQL probe sites, F7 re-poll fix, tests; config half retired (superseded by #4986). Codex review: **0 findings**. Original closed with credit to Zireael + hamchowderr. Orphan-server angle already tracked (#4282) — no new issue needed. Beads `mybd-tkvtf` closed, `mybd-jxlgz` merge tail. |
| 4167 | 68d | Shockwave2k | **Closed as intended** ("showcase — do not merge", 0 comments ever). Its 12 still-unlanded round-trip optimizations preserved in tracking issue [#5273](https://github.com/gastownhall/beads/issues/5273) with full credit; close comment maps what already landed (#4617 etc.) vs. what's open, and invites a real PR. Bead `mybd-5mpy5` closed. |

## Left to other owners (deliberate, not skipped)

- **3395, 3777, 3837, 4284, 4206** — parallel session's slice (fresh reviews on all five today). 3395 also gated on owner decision `mybd-juqgs`.
- **3717** — explicit maphew hold (07-14) stands.
- **3458** — decided (option c, `mybd-7kcg`); re-cut sequencing in motion elsewhere.
- **4242** — superseded by #5243, merge tail already armed (`mybd-5g9n5`, `mybd-tmheo`).
- **4175, 4288, 4348** — author-reply windows expire 2026-08-03 (`mybd-qwffl`, `mybd-nathu`); acting a day early on someone else's dated window would be queue-jumping.
- **4316/4317/4318** — MovGP0 trio, gated on owner decision `mybd-982o` (attachment durability semantics).

Queue arithmetic: 23 = 7 executed + 5 parallel session + 11 blocked/dated/in-motion. **Nothing is untracked.**

## What the 3563 salvage turned into (worth reading)

The re-cut started as "port a 30-line inference" and the cross-vendor loop (12 rounds, codex gpt-5.6-sol high) kept finding real integration gaps: two mode resolvers that could disagree, lifecycle commands (`start`/`stop`/proxy-migration) that would manage a *local* server against a *remote* config, port resolution pairing a stale local port file with a remote host, `bd context` reporting `embedded` beside a remote endpoint, metadata-less workspaces bypassing inference entirely. The durable fix was consolidating all inference into one shared `HostImpliesServerMode()` on the effective host precedence chain. Lesson recorded in the PR body; one pre-existing SDK yaml-visibility gap documented rather than smuggled in. This is what "salvage with reasonable effort" cost: ~1 day of iteration, but the contributor's diagnosis and tests survive, and the bug class is closed properly.

## Handoff

- Patrol owns: **5276** (verified green locally), **5277**, **3610** (merge lanes); **3548** (close-when-quiet, opens 08-05).
- Verify queue: `mybd-jxlgz` (5277) and `mybd-fherz` (3610) queued; `mybd-07m1h` (5276) passed.
- Due 08-03: `mybd-nathu` (4288/4348 re-port if authors stay silent), `mybd-qwffl` (4175 follow-up).
- Due ~08-16: GraemeF pair absorb (3859+3861) if no reply to today's nudge.
- Open question (what I noticed that isn't on any list): the two sessions today independently chose the same queue with no mutual-exclusion primitive — claims can't exclude (same user), so the only guard is the comment-signature check now in bd memory. If parallel autonomous sweeps become routine, a lightweight lane-reservation convention (a bead per queue-slice, claimed at sweep start) would make the disjoint-slice negotiation explicit instead of forensic.

_claude-fable-5-high on behalf of matt wilkie_
