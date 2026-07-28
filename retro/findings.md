# Findings Register — how maphew × coding agents work together

Cumulative, cross-project, cross-runtime. Maintained per `PLAYBOOK.md`
Phase 3–4. Evidence quotes ≤ 25 words; this file is in a public repo.

Status lifecycle: `candidate` (1 sighting) → `recurring` (2+) → `promoted`
(change made; has verify-by) → `verified-fixed` | `retired`.

## Prompt cookbook

Phrasings and ask-structures with evidence they produce clean runs.
(Populated by promotion of `prompting-pattern` findings.)

Seeded from sweep-2d-0727 (19 sessions, 07-25..27) — these produced clean runs:

- **Terse continuation grants** — "carry on", "yes, carry on", "4430", "start". After a
  report that names concrete follow-ups, two words cleanly authorize the next leg
  (03353724, ca11a7ab, 108e8ad4). Works because the preceding handoff enumerated options.
- **Scoped autonomy with a boundary** — "keep dispatching work as long as you can",
  "tackle ready items … until ~70% context", "Check for freshness against gh repo before
  initiating work", "We are not only ones active here." Names the loop, the stop
  condition, and the hazards; sessions ran hours unattended without steering churn
  (524e528f, 0cfae7ae, 6d370e33).
- **Lightweight audit challenges** — "100 is an oddly perfect number", "it wasn't
  duplicating work". Cheap skepticism that caught a wrong queue metric and an
  overclaimed audit cohort; agents investigated rather than defended (524e528f, 68b8c9f9).
- **Direct style corrections land** — "whoa Opus, you use too many words" produced an
  immediate one-screen handoff (108e8ad4).
- **Hazard**: decision-vs-execution ambiguity — "then a v1.1.1 hotfix release?" and
  "tackle (1)" left prepare/recommend/execute unresolved; state which you want
  (96d8b3bb, dae40981).

## Open findings

### F-001 · [bad-tool] pr-babysit treats transient GitHub states as terminal
- status: promoted
- sightings: 1 (mechanical, high-severity) — patrol.log 07-22..25: 60× `Merge state is UNKNOWN` blocks; verified case mybd-340o/PR5022 blocked on UNKNOWN with green base; 18 beads in `merge-blocked` after the storms; 9 branches spinning "no checks reported" every pass; no re-arm when red base greens.
- cost: automation converts to manual triage backlog; agents pay re-arm sweeps.
- recommendation: patrol retains beads on UNKNOWN/UNSTABLE and re-checks next pass; re-arm red-base kicks when base greens; escalate no-check PRs after N passes; timestamp all patrol log lines.
- promoted-to: scripts/pr-babysit hardening landed 2026-07-25 (mybd-pqs0: bounded transient retry, re-arm sweep, checks-unavailable escalation, timestamped logs; cross-vendor reviewed) + manual re-arm sweep executed (mybd-yay7 closed, 17/18 tails) · verify-by: next retro round finds `merge-blocked` census near zero outside genuine conflicts, and RE-ARMED lines in patrol.log.
- verified (sweep-2d-0727): 15 RE-ARMED lines 07-26..27; census 18 → 9, remainder genuine (failed checks / checks-absent after 10 budgeted passes); UNKNOWNs now tolerated within pass budgets instead of blocking on sight. Watch: 5 beads escalated 07-27 for "checks unavailable" — possibly fork PRs whose CI needs approval; judgment lane, not a patrol bug. → **verified-fixed**.

### F-002 · [environment] delegation debris starves the host
- status: recurring (2 sightings, both 2026-07-24)
- sightings: claude/d41b072b: "The Bash tool can no longer spawn any process" — 45-min fd-exhaustion outage (20+ background tasks + leaked dolt test servers); claude/a7573951: "the A2 builder's cache pushed the user quota over" — /tmp EDQUOT from ~10 GB stale Go caches.
- cost: hard session outages; human diagnosis time.
- recommendation: enforce GOCACHE/GOTMPDIR under worktree .tmp/ in scripts/codex-agent (memory `codex-builder-tmp-quota` says MUST but wrapper doesn't); watch fd recurrence post-q6cz.
- promoted-to: scripts/codex-agent builder now enforces worktree-local GOCACHE/GOTMPDIR (mybd-jx3o closed 2026-07-25; env passthrough verified live; opt-out CODEX_AGENT_KEEP_GO_ENV=1) · verify-by: no EDQUOT/fd incidents in next ~20 sessions.
- verified (sweep-2d-0727): 19 sessions 07-25..27, zero EDQUOT/fd-exhaustion sightings. → **verified-fixed** pending one more clean round.

### F-003 · [tokenomics] Codex wait_agent polling burn
- status: recurring (4 sightings)
- sightings: codex/fd4998ac (07-24): 15+ 30–60s timeouts, ~150k tokens each, 10.2M total; codex/d90ba750 (07-25): ~2M tokens in wait cycles; codex/06050395, codex/b2c9db33: repeated timeout→success; codex/43e18dc2: ~40 min `gh run watch` yield loops.
- cost: millions of tokens of idle waiting per heavy session (ChatGPT pool).
- recommendation: longer/batched waits; delegate tail-watching to zero-token patterns (patrol); note in AGENTS.md Codex section.
- promoted-to: AGENTS.md Codex-section wait-polling rule (mybd-dpio closed 2026-07-25) · verify-by: next Codex-heavy session shows waits <10% of token total.

### F-004 · [bad-tool] bd --json output shape drift (array vs object)
- status: recurring (5 sightings)
- sightings: claude/15466d7d "Cannot index object with number"; claude/8c29af54 "Cannot index array with string"; claude/f6c0822c (4+ retries); claude/d41b072b jq null-iteration; this audit session (07-25) used `.[0]` defensively.
- cost: a few retries per session, every session that scripts bd.
- recommendation: upstream issue for consistent shapes, or local normalizing helper.
- promoted-to: upstream issue gastownhall/beads#5054 + bd memory `bd-json-shapes` with normalizing jq idiom (mybd-au80 closed 2026-07-25) · verify-by: zero shape-retry sightings after fix lands.
- **NOT holding** (sweep-2d-0727): 8 more sightings in 19 sessions — 03353724, 13e762f9, 6d370e33, 1bdfcf27 (×2), 9b719735, 68b8c9f9, dae40981 (jq choke → duplicate bead created). The memory idiom exists but agents don't reach for it before first failure; upstream fix unlanded. Escalation: ship a repo-local normalizing wrapper (e.g. `scripts/bdj`) that always yields an array, and reference it from AGENTS.md — reopened as recurring until then.

### F-005 · [tokenomics] delegate outputs exceed 256 KB Read cap
- status: recurring (3 sightings)
- sightings: claude/e06b7792 (278 KB dossier), claude/a7573951 (624 KB builder output), claude/f6c0822c (1.1 MB Codex review); sweep-2d-0727: 0cfae7ae (434 KB Codex review), 9b719735 (297 KB Codex review) — all worked around via sed/grep/python. Now 5.
- cost: minutes of slicing per occurrence; risk of missed content.
- recommendation: delegates write structured/paginated outputs; orchestrators request summaries + on-disk detail. Concretely: codex-agent reviewer prompts should demand "final message ≤ ~30 KB findings summary; full detail to the -o file" — promote via delegation docs / wrapper prompt preamble.

### F-006 · [process] turn-wide budget guard misfires in multi-workflow sessions
- status: candidate (1 concrete sighting; high consequence)
- sightings: claude/d41b072b: "no adversarial verification actually ran" — later workflow silently skipped verify stage because an earlier one spent the shared budget.
- owner clarification: 200k is a soft performance-tuning target, not a reliability ceiling; exceptions are acceptable and runs around 500k have worked well. An overrun is not a failure sighting.
- recommendation: per-workflow budget deltas + required-stage gates; log soft-target overruns but do not silently suppress verification. Explicit user hard budgets still win.
- promoted-to: mybd-lq8i.4 (already filed; AGENTS.md soft-target + aggregate-validation rules landed 07-27, commit 10b794c6b) · verify-by: no silent stage skips in next multi-workflow session.
- sweep-2d-0727: no silent stage skips observed. Residual: budget *reporting* drift — 1bdfcf27 announced "budget-capped at ~200k" then spent 224k; 524e528f ran 714k on one verification workflow. Overruns are policy-acceptable; describing a soft target as a cap is not. Fold into the AGENTS.md wording (report soft target as such).

### F-007 · [process] bd prime truncation hid active profile
- status: promoted (fixed in-window)
- sightings: claude/7c0a9e9e (07-25): "why are we running under conservative profile mode?" — team-maintainer memory below preview fold; 30+ min of needless caution.
- promoted-to: .beads/PRIME.md override (10.2 KB → 5.1 KB) + CLAUDE.md explicit profile declaration · verify-by: no profile misreads in later sessions.
- verified (sweep-2d-0727): zero profile misreads across 19 sessions; team-maintainer close protocol executed routinely. → **verified-fixed**.

### F-008 · [environment] Amp posture: dangerouslyAllowAll + no local transcripts
- status: recurring (2 sightings, cross-vendor)
- sightings: codex audit (lq8i.2): serial-Dolt violation 07-23, no approval events retained; this audit verified `"amp.dangerouslyAllowAll": true` and 0 local thread files for the 5 in-window threads (server-side storage).
- promoted-to: mybd-lq8i.3 · verify-by: Amp settings hardened or posture documented as deliberate.

### F-011 · [bad-tool] bd CLI flag/display semantics silently mislead scripts
- status: recurring (5 sightings, sweep-2d-0727)
- sightings: 0cfae7ae: "100 ready items" was the default `--limit` cap, true count 460; 524e528f: user caught it — "100 is an oddly perfect number"; 915209f2 (H): repeated `--status` flags are last-one-wins in bd 1.1.0 → tri-pull mass-duplicated mirror stubs; 61b85b60: `bd list --status=open` returned zero rows via the same flag quirk; dae40981: double-create after jq choke.
- cost: wrong queue metrics reported to owner; a duplicate-stub storm needing cleanup; both human and agent pay.
- recommendation: house rule `bd ready/list --limit 0` for any counting (memory + AGENTS.md); upstream issue asking bd to error on repeated single-value flags and to label capped output as capped. tri-pull itself already hardened (c121bc24b, same day).

### F-012 · [tokenomics] sessions held open watching tails that timers already own
- status: recurring (4 sightings, sweep-2d-0727)
- sightings: 9b719735: ~4 h idle on a 5-min review-poll monitor — user: "been idling quite awhile now. what does that cost?"; ca11a7ab: in-session patrol-watch loops, "Command timed out after 2m 0s"; 96d8b3bb: polled the slow local Dolt suite despite the non-blocking house rule; e4d4db15: #5013 builder blocked ~30 min on a full suite instead of `verify-enqueue`.
- cost: hours of open-session context + polling tokens for zero decisions; the infrastructure to avoid it (pr-babysit, verify queue) already exists and was bypassed.
- recommendation: AGENTS.md rule: once a tail is handed to a patrol/queue, the session records the resume state and **ends** (or schedules a wakeup); builders must freeze + `verify-enqueue`, never await long suites. Extend the "never babysit CI" rule to review-await and patrol-watch.

### F-013 · [process] close protocol skipped after post-close mutations; one mid-delegation abandonment
- status: recurring (5 sightings, sweep-2d-0727)
- sightings: 6d370e33 (H): session ended while two spawned agents still ran — results never consumed, no close protocol; 43f58618: resumed bead mutations after close, no re-run of close-check; 1bdfcf27: follow-up ended at `bd dolt push` only; 70d60b78, 13e762f9 [weak]: pushes reported, close-check not evidenced.
- cost: stranded delegate output, un-backstopped handoffs; the cold-start path loses whatever only the close-check would have caught.
- recommendation: any mutation after a close re-arms the protocol — minimum `bd dolt push` + `scripts/session-close-check`; add a delegation-closure checkpoint: never end a session with unconsumed running delegates (collect, integrate, or hand off to a bead).

### F-014 · [environment] cwd/worktree lifecycle slips
- status: recurring (6 sightings, sweep-2d-0727, all L–M, agent-borne)
- sightings: 13e762f9 + 915209f2: "fatal: Unable to read current working directory" after worktree removal mid-sequence; 03353724: "Wrong cwd again (still in `bd-main`)"; 6d370e33: unsigned GitHub comment from wrong cwd, repaired; e4d4db15: `cd: bd-main: No such file or directory`; 524e528f: relative path broke the signature-trailer step in a rebase worktree.
- cost: a few corrective turns per session; one public artifact (unsigned comment) needed repair.
- recommendation: habit-level fix: absolute `git -C` / absolute script paths for coordination-repo actions from inside source worktrees; `cd` back to the main checkout *before* removing a worktree; re-check `git worktree list` before committing in shared environments.

### F-015 · [environment] Entire CLI clobbers tracked .githooks in worktrees
- status: recurring (2 sightings, sweep-2d-0727)
- sightings: 9b719735: "The Entire CLI has clobbered tracked `.githooks` files ... again"; 6d370e33: "dirty hooks risk shipping upstream" → hazard bead filed.
- cost: unrelated tracked-file churn during delivery; risk of shipping local hook edits upstream.
- recommendation: contain or disable Entire CLI hook mutation in implementation worktrees; the hazard bead from 6d370e33 is the tracking home.

### F-016 · [bad-tool] permission classifier vs release-tag surgery burned a version
- status: candidate (1 sighting, high severity)
- sightings: dae40981: v1.1.1 tag pushed before the lockfile gate ran; classifier then hard-blocked every tag-rewrite phrasing — "every phrasing of moving the pushed v1.1.1 tag stayed hard-blocked" — session burned v1.1.1 and rolled forward to v1.1.2.
- cost: a public version number; ~30 min of blocked retries; both pay.
- recommendation: two rules, both now partially landed: pre-tag preflight (`uv lock --check` etc. — PR #5082 adds it) and "never move a pushed tag — roll forward" as documented release policy; after one clear classifier denial, stop retrying equivalents and switch paths.



### F-009 · [win] cross-vendor review pairs find disjoint defects
- sightings: 6 in-window (cb56a7f0, 15466d7d, a7573951, f6c0822c "disjoint findings again...pairing paid off", b342548b P1 TOCTOU catch, d41b072b 4 defects). Institutionalized in PR_MAINTAINER_GUIDELINES.md + memory. Keep.
- sweep-2d-0727: +8 (108e8ad4 false-positive rejection, ca11a7ab "review gate earned its keep twice" — 2 P1s pre-deploy, 96d8b3bb design redesign, 915209f2 unattended-false-success catch, 0cfae7ae "two cross-vendor-confirmed corruption blockers", e4d4db15 three PRs all needed fixes, 68b8c9f9, 9b719735 nil-context panic blocker). Fully institutionalized; the gate now routinely triggers pre-publication redesigns.

### F-010 · [win] failure→fix latency is hours, not weeks
- sightings: merge collision 07-24 → patrol same day → hardened next day → universal by 07-25; /tmp crash → memory guiding next-day sessions; prime truncation → PRIME.md fix same session.
- note: components that cannot self-correct (patrol kick-outs, debris) are the inverse risk — they decay silently. Anything autonomous needs a re-entry path or a scheduled auditor.
- sweep-2d-0727: +3 (stranded verify queue → verify-babysit timer same session, 13e762f9; tri-pull duplicate storm found + fixed same day, 915209f2; v1.1.1 burn → pre-tag gate PR #5082 same session, dae40981).

### F-017 · [win] freshness-first sweeps + adversarial refutation of fix-claims
- sightings (sweep-2d-0727): 108e8ad4 — "24 of 53 open issue beads already have an open fix PR" caught before implementing; 0cfae7ae — "Spot-verifying the 5 claimed merged fixes before closing"; 524e528f — server-mode/cli-ux sweeps refutation-checked fix-claims against upstream HEAD; drain-strategy report measured ~30% false-positive rate on recon fix-claims. Also lane-respect: 03353724 and 108e8ad4 detected other sessions' live lanes and steered around them.
- why it works: verification against live upstream state before closing/creating beads converts a stale queue into a trustworthy one; ~1/3 of unverified claims would have been wrong.
- recommendation: keep freshness+refutation as the mandatory first stage of every queue sweep (already the de facto pattern; the drain-strategy report is the reference).

## Verified-fixed / retired

- **F-001** (pr-babysit transient-state handling) — verified sweep-2d-0727; entry retained above for the checks-unavailable watch item.
- **F-007** (bd prime truncation) — verified sweep-2d-0727, zero recurrences in 19 sessions.
- **F-002** (delegation debris) — provisionally clean over 19 sessions; confirm next round.
