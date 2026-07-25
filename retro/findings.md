# Findings Register — how maphew × coding agents work together

Cumulative, cross-project, cross-runtime. Maintained per `PLAYBOOK.md`
Phase 3–4. Evidence quotes ≤ 25 words; this file is in a public repo.

Status lifecycle: `candidate` (1 sighting) → `recurring` (2+) → `promoted`
(change made; has verify-by) → `verified-fixed` | `retired`.

## Prompt cookbook

Phrasings and ask-structures with evidence they produce clean runs.
(Populated by promotion of `prompting-pattern` findings.)

*— none yet —*

## Open findings

### F-001 · [bad-tool] pr-babysit treats transient GitHub states as terminal
- status: promoted
- sightings: 1 (mechanical, high-severity) — patrol.log 07-22..25: 60× `Merge state is UNKNOWN` blocks; verified case mybd-340o/PR5022 blocked on UNKNOWN with green base; 18 beads in `merge-blocked` after the storms; 9 branches spinning "no checks reported" every pass; no re-arm when red base greens.
- cost: automation converts to manual triage backlog; agents pay re-arm sweeps.
- recommendation: patrol retains beads on UNKNOWN/UNSTABLE and re-checks next pass; re-arm red-base kicks when base greens; escalate no-check PRs after N passes; timestamp all patrol log lines.
- promoted-to: scripts/pr-babysit hardening landed 2026-07-25 (mybd-pqs0: bounded transient retry, re-arm sweep, checks-unavailable escalation, timestamped logs; cross-vendor reviewed) + manual re-arm sweep executed (mybd-yay7 closed, 17/18 tails) · verify-by: next retro round finds `merge-blocked` census near zero outside genuine conflicts, and RE-ARMED lines in patrol.log.

### F-002 · [environment] delegation debris starves the host
- status: recurring (2 sightings, both 2026-07-24)
- sightings: claude/d41b072b: "The Bash tool can no longer spawn any process" — 45-min fd-exhaustion outage (20+ background tasks + leaked dolt test servers); claude/a7573951: "the A2 builder's cache pushed the user quota over" — /tmp EDQUOT from ~10 GB stale Go caches.
- cost: hard session outages; human diagnosis time.
- recommendation: enforce GOCACHE/GOTMPDIR under worktree .tmp/ in scripts/codex-agent (memory `codex-builder-tmp-quota` says MUST but wrapper doesn't); watch fd recurrence post-q6cz.
- promoted-to: scripts/codex-agent builder now enforces worktree-local GOCACHE/GOTMPDIR (mybd-jx3o closed 2026-07-25; env passthrough verified live; opt-out CODEX_AGENT_KEEP_GO_ENV=1) · verify-by: no EDQUOT/fd incidents in next ~20 sessions.

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

### F-005 · [tokenomics] delegate outputs exceed 256 KB Read cap
- status: recurring (3 sightings)
- sightings: claude/e06b7792 (278 KB dossier), claude/a7573951 (624 KB builder output), claude/f6c0822c (1.1 MB Codex review) — all worked around via sed/grep/python.
- cost: minutes of slicing per occurrence; risk of missed content.
- recommendation: delegates write structured/paginated outputs; orchestrators request summaries + on-disk detail.

### F-006 · [process] turn-wide budget guard misfires in multi-workflow sessions
- status: candidate (1 concrete sighting; high consequence)
- sightings: claude/d41b072b: "no adversarial verification actually ran" — later workflow silently skipped verify stage because an earlier one spent the shared budget.
- owner clarification: 200k is a soft performance-tuning target, not a reliability ceiling; exceptions are acceptable and runs around 500k have worked well. An overrun is not a failure sighting.
- recommendation: per-workflow budget deltas + required-stage gates; log soft-target overruns but do not silently suppress verification. Explicit user hard budgets still win.
- promoted-to: mybd-lq8i.4 (already filed) · verify-by: no silent stage skips in next multi-workflow session.

### F-007 · [process] bd prime truncation hid active profile
- status: promoted (fixed in-window)
- sightings: claude/7c0a9e9e (07-25): "why are we running under conservative profile mode?" — team-maintainer memory below preview fold; 30+ min of needless caution.
- promoted-to: .beads/PRIME.md override (10.2 KB → 5.1 KB) + CLAUDE.md explicit profile declaration · verify-by: no profile misreads in later sessions.

### F-008 · [environment] Amp posture: dangerouslyAllowAll + no local transcripts
- status: recurring (2 sightings, cross-vendor)
- sightings: codex audit (lq8i.2): serial-Dolt violation 07-23, no approval events retained; this audit verified `"amp.dangerouslyAllowAll": true` and 0 local thread files for the 5 in-window threads (server-side storage).
- promoted-to: mybd-lq8i.3 · verify-by: Amp settings hardened or posture documented as deliberate.

## Wins register (patterns to amplify)

### F-009 · [win] cross-vendor review pairs find disjoint defects
- sightings: 6 in-window (cb56a7f0, 15466d7d, a7573951, f6c0822c "disjoint findings again...pairing paid off", b342548b P1 TOCTOU catch, d41b072b 4 defects). Institutionalized in PR_MAINTAINER_GUIDELINES.md + memory. Keep.

### F-010 · [win] failure→fix latency is hours, not weeks
- sightings: merge collision 07-24 → patrol same day → hardened next day → universal by 07-25; /tmp crash → memory guiding next-day sessions; prime truncation → PRIME.md fix same session.
- note: components that cannot self-correct (patrol kick-outs, debris) are the inverse risk — they decay silently. Anything autonomous needs a re-entry path or a scheduled auditor.

## Verified-fixed / retired

*— none yet —*
