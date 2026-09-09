# Retro sweep-2d-0727 — sessions 2026-07-25 (pm) .. 2026-07-27

**Scope:** all substantive mybd × Claude Code sessions since sweep-3d coverage ended —
19 sessions digested (plus 2 skipped-inflight). No new interactive Codex sessions in
window (all 07-25pm..26 rollouts were `codex_exec` delegates, evidence inside parents).
Digests produced by `scripts/codex-agent scout` serially (~30 min wall, Codex quota;
per owner's mid-sweep "usage limit approaching, lean on codex more"). Synthesis in-session.

**Effectiveness:** median 4/5. Distribution: one 5 (61b85b60 rescue triage), thirteen 4s,
three 3s (96d8b3bb, dae40981, 68b8c9f9 — all heavy-rework or incident sessions), one 2
(6d370e33 — ended mid-delegation, two agents stranded). The 2-day window shipped a
release (v1.1.2), ~10 upstream PRs, three new automation lanes (verify-babysit,
close-when-quiet, tri-drift), and a ~186-bead ready-queue drain — at high but mostly
well-spent token cost (~2.9 M output tokens across the 19).

## Fixed-since verifications (the loop closes)

- **F-001 pr-babysit** → verified-fixed: 15 RE-ARMED events, merge-blocked 18 → 9,
  blocks only after budgeted passes. Watch: 5 "checks unavailable" escalations 07-27.
- **F-007 prime truncation** → verified-fixed: zero profile misreads in 19 sessions.
- **F-002 delegation debris** → provisionally clean (0 incidents / 19 sessions).
- **F-006 budget guard** → policy landed (AGENTS.md 10b794c6b); residual is reporting
  accuracy (calling a soft target a "cap"), not silent skips.

## Not holding

- **F-004 bd --json shape drift** — 8 new sightings despite promoted memory idiom.
  The fix location was wrong: a memory nobody consults pre-failure. Escalated to a
  repo-local normalizing wrapper (`scripts/bdj`) + AGENTS.md pointer (bead filed).

## New findings

- **F-011** [bad-tool] bd flag/display semantics mislead scripts — default `--limit`
  caps read as totals (×2, one user-caught), last-one-wins repeated `--status` flags
  (tri-pull duplicate storm, H). House rule `--limit 0` + upstream flag-error ask.
- **F-012** [tokenomics] sessions held open watching tails timers already own — 4
  sightings incl. a ~4 h idle poll (user: "what does that cost?"). The patrol/verify
  infrastructure exists and was bypassed. AGENTS.md rule proposed.
- **F-013** [process] close protocol not re-run after post-close mutations; one
  mid-delegation abandonment (H). Rule: post-close mutation re-arms the protocol;
  never end with unconsumed running delegates.
- **F-014** [environment] cwd/worktree lifecycle slips — 6 minor sightings (removed-
  worktree cwd, wrong-checkout commands, one unsigned comment). Habit fix: absolute
  `git -C`, leave worktree before removing it.
- **F-015** [environment] Entire CLI clobbers tracked .githooks (×2, "again").
- **F-016** [bad-tool] permission classifier + pushed-tag surgery burned v1.1.1 →
  roll-forward policy + pre-tag preflight (#5082); stop retrying after first denial.
- **F-017** [win] freshness-first sweeps + adversarial refutation — ~30% of recon
  fix-claims were false; refutation-before-close kept the queue trustworthy.

## Prompt cookbook seeded (first entries)

Terse continuation grants; scoped autonomy with explicit stop conditions and hazard
notes; lightweight audit challenges ("100 is an oddly perfect number"); direct style
corrections; hazard: decision-vs-execution ambiguity ("hotfix release?").

## Retro-process notes

- Codex-scout digestion worked: 19/19 rc=0, ~65 s and ~3.5 KB each, zero Claude quota
  on Phase 2; digest quality high (quoted evidence throughout). Keep as default.
- Serial loop is the right shape here (bd prime hooks fire in Codex sessions; embedded-
  Dolt stays serial). ~30 min wall is acceptable; don't parallelize against this repo.
- Per-event Monitor on the digest loop was wasteful (each event re-invokes the model);
  a single background-task completion notification suffices. Playbook stays v1.0.
