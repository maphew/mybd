# Retro round-01 - sessions 2026-08-22 .. 2026-09-03

**Scope:** the five newest surviving mybd × Claude Code sessions
(552c75b0, ea4ecd33, 00f5a9e5, 26c6e0be, 23263d7f). This is *not* the batch the
ledger seeded on 2026-07-14: those 14 rows are now `lost` (see below). Digests
produced by five parallel Claude `haiku` subagents over jq-stripped transcripts
(~270 k subagent tokens total, ~50 s wall); synthesis in-session.

**Ledger repair.** The 14 `pending` rows seeded 2026-07-14 (June/July session
ids) have no transcripts on disk: Claude Code's 30-day cleanup ran before
`cleanupPeriodDays=730` was set on 2026-08-16. Verified - `ls
~/.claude/projects/*/<id>*.jsonl` returns nothing for all 14. They are marked
`lost` with a note rather than deleted, so the campaign's coverage gap stays
visible. Practical consequence: **the retro pipeline must run inside the
transcript retention window**; queueing sessions for "later" is queueing them
for deletion.

**Effectiveness:** median 4/5 - two 5s (552c75b0 assess-then-land under one
8-word grant; 23263d7f three-bead serve run), three 4s (ea4ecd33 upstream
feature PR, 00f5a9e5 daily routine + stalled-bead audit, 26c6e0be daily
housekeeping that found a P1 environment regression). No 3s, no partials, no
abandonments - the strongest batch so far. All five ran with minimal steering;
four of five closed with the full protocol.

## Fixed-since verifications (the loop closes)

- **F-012 idle tail-watching** → clean across the batch. Long pipelines
  (`pr-open`, red-team, CI) ran as background tasks reconciled by completion
  notification, not by polling: 552c75b0 "zero blocking on long waits",
  ea4ecd33 used Monitor with an until-loop after the harness rejected a leading
  `sleep`, 23263d7f had no idle at all. → **verified-fixed** (watch: one stale
  Monitor event in 552c75b0 reported a red-team failure from a superseded
  round; the agent correctly ignored it).
- **F-013 close protocol** → clean: 26c6e0be, 00f5a9e5 and 552c75b0 each ran
  `bd dolt push` + `git push` + `session-close-check`; 23263d7f confirmed
  everything pushed. No unconsumed delegates at any session end. → verified
  over 5 sessions; keep watching.
- **F-002 delegation debris** → second consecutive clean round (0 EDQUOT / fd
  incidents in 24 sessions). → **verified-fixed**.
- **F-004 bd --json shape drift** → zero sightings, first clean window since
  the finding opened. `scripts/bdj` + the AGENTS.md pointer appear to have
  worked. → provisionally holding; confirm next round.

## Not holding

- **F-014 cwd/worktree lifecycle slips** - 4 more sightings (now 10). Character
  has changed, though: every one was caught and repaired by the agent with no
  user turn spent. The remaining *fixable* piece is narrow - `agent-sig.sh`
  invoked by relative path from a linked worktree returns empty, forcing a
  manual trailer amend.

## New findings

- **F-018** [bad-tool] **H** - the Codex/ChatGPT content classifier kills
  red-team runs as "possible cybersecurity risk". 2 sightings, 6 killed rounds;
  ea4ecd33 fell back to `MYBD_SKIP_REDTEAM=1`. This is the mandatory adversarial
  gate failing open on an external moderation decision.
- **F-019** [environment] **H** - linuxbrew dropped off non-interactive agent
  PATHs (Bluefin image change ~2026-09-01); `gh`/`dolt`/`codex` vanished and the
  PR review gate stood down *silently* for ~2 days. Found by a routine daily
  session, not by the gate. Fixed same-week (mybd-zvups).
- **F-020** [bad-tool] - `bd list` in the coordination repo blocked on the
  serial-Dolt lock until the 2-minute harness timeout (exit 143) instead of
  failing fast.
- **F-021** [tokenomics] - a final handoff summary was truncated mid-sentence,
  losing the "what I noticed that isn't on any list" item; recovered only
  because the user asked a follow-up.
- **F-022** [process] - the retro pipeline outran transcript retention: 14
  queued sessions were deleted before they were mined.

## Prompt cookbook additions

- **Bead ids plus an explicit why-order** - "start with mybd-zvups since it
  re-arms the PR gate, then koabx.4 and ign2i". Three ids, one clause of
  rationale, zero clarifying questions; the run scored 5/5.
- **One-line grant on a resumed thread** - "yep, let's bring this home" after a
  reboot lost an overnight session. Works because the agent re-established state
  from live sources (branch, issue, review logs) before acting.
- Reinforced: invoking a documented routine by name ("daily report",
  "run daily report and housekeeping") maps straight onto the AGENTS.md
  workflow, though the barest form costs the agent one memory lookup.

## Retro-process notes

- Five parallel Claude `haiku` digest agents cost ~270 k subagent tokens and
  ~50 s wall - cheaper in wall-clock than the serial Codex-scout loop used in
  sweep-2d-0727, more expensive in Claude quota. Digest quality was good but
  one agent invented a tag (`[wrong-cwd]`) outside the taxonomy; pin the tag
  list harder in the rubric next round.
- Parallel digesting is safe here only because nothing in Phase 2 touches
  bd/dolt. Unchanged rule: bd stays serial.
- The stripped-transcript recipe held: 370 KB–1.45 MB raw → 15–68 KB stripped
  (~20-25x), all five under the 150 KB chunking threshold.
- **Ledger hygiene gap the playbook should carry:** Phase 1 says order
  newest-first, but says nothing about *re-checking* that queued rows still
  have transcripts. Add a liveness check to Phase 1 before taking a batch.
  Playbook stays v1.0 pending that edit.

## Stop rules (Phase 5)

**None fired.** (1) Saturation - no: five new findings. (2) Promotion backlog  - 
no: unpromoted actionable findings stand at 3 (F-014, F-018, F-013-pending),
well under ~10. (3) Staleness horizon - not reached; the batch is 1–11 days
old. Worth noting that stop rule 3 was pre-empted by *retention*, not
staleness: the old sessions were not skipped as stale, they were destroyed.

## Round 2 seed

Next five candidates from the same store, newest-first, all ≥100 KB and not yet
in the ledger:

| session_id | started | size_kb |
|---|---|---|
| c4191491-5263-4e9f-993c-374361da21d6 | 2026-08-22 | 997 |
| b1cbc399-fdfa-4c95-8d24-f10bfb7fbd68 | 2026-08-22 | 502 |
| 2ee6e618-32c6-40f8-91c7-55fe28c9ecd3 | 2026-08-22 | 300 |
| e0615235-f385-4b49-9f39-57c4d2ea3577 | 2026-08-22 | 257 |
| 0e6f64e2-dd01-49a6-b7b2-abbf0de46f60 | 2026-08-18 | 179 |
