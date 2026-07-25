# Session machinery retro, 2026-07-22 → 07-25 — Claude second opinion

**Scope:** all agent sessions on this machine in the last 3 days, across Claude
Code, Codex CLI, Amp, and Kilocode. Question: *is the machinery running well —
not what the sessions did, but how.*

**Method:** independent of (and deliberately parallel to) the Codex-side audit
committed earlier today
([cross-runtime retrospective](2026-07-25-cross-runtime-session-machinery-retrospective.md),
bead `mybd-lq8i.2`). This pass digested **every substantive session
individually** — 17 Claude + 8 Codex interactive transcripts, mechanically
stripped (~17×) then digested by 16 parallel haiku agents against the
`retro/PLAYBOOK.md` rubric — plus mechanical forensics on the pr-babysit patrol
log, verify queue, Amp/Codex logs, and repo hygiene. Digests are in
`retro/digests/` (untracked by policy); recurring findings were registered in
`retro/findings.md` (F-001…F-010) and the ledger updated. A comparison against
the Codex report closes this document.

## Bottom line

The machinery is healthy and — the strongest signal in the window —
**self-correcting**. Effectiveness across 25 digested sessions: Claude mean
≈ 4.4/5 (17 sessions), Codex mean ≈ 3.75/5 (8 sessions); no abandoned work, no
data loss, every incident diagnosed in-session. The window's one hard process
failure (a PR merged onto red CI by one of five parallel sessions on 07-24)
produced, within hours, the pr-babysit patrol — which by 07-25 every session
used correctly.

Four things deserve fixing or tuning, in priority order:

1. **pr-babysit treats transient GitHub states as terminal** — new, not in the
   Codex report. 18 merge tails are currently stranded in `merge-blocked`.
2. **Delegation debris starves the host** — two same-day hard incidents
   (fd exhaustion; /tmp quota) with the enforcement gap still open.
3. **Codex orchestration burns tokens on `wait_agent` polling** — up to ~10M
   tokens of idle waiting in a single session.
4. **`bd --json` output-shape inconsistency** — small, but it taxed 4+ sessions
   and it taxed *this* session too.

Amp remains the observability weak point (corroborating the Codex report — I
verified `amp.dangerouslyAllowAll: true` directly). Kilocode: no activity since
January (CLI) / March (extension); drop it from audit scope until it returns.

## What is working well (keep, don't touch)

- **Cross-vendor review pairs are the standout pattern.** In six sessions the
  Claude and Codex reviewers found *largely disjoint real defects* on the same
  diff — e.g. 5 CI-integrity issues on PR 5004, a P1 TOCTOU on PR 5042, 5 FATAL
  findings on the psxg.2 design v1, 6 findings on workspace-gate. Every pairing
  paid for itself. Already institutionalized in PR_MAINTAINER_GUIDELINES.md.
- **The zero-token control plane earns its keep.** Verify queue: all recent
  candidates passed, logs tidy (104 KB). Patrol: 6 PRs merged autonomously in
  the window while correctly refusing to merge onto red main — stop-the-line
  held twice (07-24 and 07-25 red-main incidents). Worktree discipline: no
  stashes, no gone branches, isolation used by default.
- **Session-close protocol is real.** Multiple textbook closes (a7e557b0,
  4818896e, 14e39d13 digests rate them 5/5 with zero friction); `bd remember`
  knowledge capture appears in nearly every substantive session and measurably
  paid out within the window (the /tmp-quota memory, filed 07-24, was already
  guiding sessions on 07-25).
- **The improvement arc.** Within 72 hours: merge-collision → patrol built,
  reviewed cross-vendor, hardened, universally adopted; `bd prime` truncation
  caused a profile regression → root-caused → `.beads/PRIME.md` override halved
  prime output; dependabot vendorHash churn → root-cause grouping config
  (PR 5038) instead of one-by-one merges; rigid-checklist anchoring → "floor
  not ceiling" hygiene doctrine in AGENTS.md. The machinery's failure→fix loop
  is functioning at high velocity.

## Fix/tuning opportunities

### 1. pr-babysit: transient states are treated as terminal (P1, new)

Patrol-log forensics across the window:

| block reason | count | nature |
|---|---:|---|
| `Merge state is UNKNOWN` | 60 | **transient** — GitHub computes mergeability lazily |
| Base branch CI is RED | 67 | correct stop-the-line |
| DIRTY / merge conflicts | 80 | genuine, needs an agent |
| `Merge state is UNSTABLE` | 4 | often transient |

One `UNKNOWN` sighting at patrol time → bead relabeled `merge-blocked` +
unclaimed → tail permanently out of automation, for a state that typically
resolves in under a minute (verified case: mybd-340o / PR 5022, blocked at
15:40Z on `Merge state is UNKNOWN` while base was green). The patrol runs
every 12 minutes — it could simply retain such beads and re-check.

Compounding it: when red-base storms end (main went green 21:02Z tonight),
nothing re-arms the tails that were kicked out during the storm. **18 beads
sit in `merge-blocked` right now.** And nine branches log
`no checks reported on the '<branch>' branch` every 12 minutes, forever —
no-check PRs neither merge nor escalate. Patrol log lines are also
untimestamped raw preflight dumps (459 lines on 07-24 alone), which made this
forensics harder than it should be.

Filed: patrol hardening bead + an immediate re-arm sweep bead (see Follow-ups).

### 2. Delegation debris starves the host (P1, enforcement gap open)

Two hard incidents on 07-24, same class — background delegate work exhausting
a shared host resource:

- **fd exhaustion** (claude/d41b072b): Bash tool unable to spawn *any* process
  for ~45 min; 20+ concurrent background tasks plus leaked embedded-Dolt test
  servers. The zombie-server fix (mybd-q6cz) closed at 17:23Z that day — the
  incident hit 18:46Z, so either the fix wasn't in the running binary or fd
  pressure from task concurrency alone suffices. Watch for recurrence.
- **/tmp quota** (claude/a7573951): ~10 GB of stale per-PR Go caches from past
  Codex builders; EDQUOT killed both the orchestrator's shell and the Codex
  process mid-build.

The lesson was captured as bd memory `codex-builder-tmp-quota` ("MUST set
GOCACHE/GOTMPDIR under the worktree's .tmp/") — but `scripts/codex-agent`
still doesn't set these defaults. Guidance-by-memory where the wrapper could
enforce. Filed as a chore.

### 3. Codex orchestration: wait_agent polling burn (P2)

Codex sessions were correct but paid heavily for synchronous waiting:

- fd4998ac: 15+ consecutive 30–60s `wait_agent` timeouts, ~150k tokens *per
  timeout line*; session totaled 10.2M tokens, most from idle waits.
- d90ba750: ~2M tokens across 6+ wait/retry cycles.
- 06050395 / b2c9db33: repeated timeout→timeout→success patterns.
- 43e18dc2: ~40 min of `gh run watch` 30-second yield loops.

Claude sessions in the same window handled identical waits with zero-cost
notification patterns (Monitor tool, background tasks, `pr-handoff`). The gap
is runtime-specific: Codex lacks (or its sessions here don't use) an
event-driven wait. Tuning: longer wait intervals, batch waits, or delegate
tail-watching to the zero-token patrol pattern. Filed as guidance task;
overlaps the intent of `mybd-lq8i.4` but is Codex-side, not workflow-side.

### 4. bd --json output shape (P2, recurring tax)

`bd show`/`bd create --json` return arrays where agents expect objects; 4+
sessions burned retries on `Cannot index array with string` (15466d7d,
8c29af54, f6c0822c — which needed 4+ retries — and d41b072b; this audit
session hit it as well). Cheap fix with high sighting count: upstream issue
for shape consistency, or a repo helper that normalizes. Filed.

### Smaller notes

- **Read-limit workarounds recur** (3 sightings): task outputs of 278 KB,
  624 KB, 1.1 MB exceeded the 256 KB Read cap; agents fell back to
  sed/grep/python slicing. Structured/paginated delegate outputs would help.
- **Signature-trailer drift on delegated commits** (1 sighting, 3 commits):
  builder commits carried the orchestrator's tier string. Minor; agent-sig in
  delegated contexts deserves one line in AGENTS.md.
- **Sleep-guard works**: 3 sessions tried `sleep`-loops, were blocked by the
  harness, and each converged on the correct async pattern within one turn.
  Working as designed.
- **Stale verify worktree** for a superseded head
  (`verify-mybd-psxg.2-2e6071a8…`) left behind; obviously dead, noted for
  cleanup rather than deleted (parallel-session caution).
- **Retro campaign state was dormant**: today's *two* independent machinery
  retros (Codex's and this one) both ran while `retro/ledger.tsv` sat stale
  since 07-14 and `findings.md` was empty — the campaign scaffolding wasn't on
  either session's cold path. This commit seeds both files; the open retro
  round bead should keep them warm.

## Comparison with the Codex-side report

**Agreements (independent convergence — treat as high-confidence):** control
plane strong and worth protecting; close/recovery discipline real; cross-vendor
review keep; workflow budget gates needed (`mybd-lq8i.4` — my evidence adds
d41b072b, where a turn-wide `budget.spent()` silently skipped a verification
stage); Amp is the policy/observability weak point (`dangerouslyAllowAll`
verified directly; local thread transcripts genuinely absent — server-side
now); Kilocode inactive.

**This report adds:** the patrol transient-state bug and the 18 stranded
tails (the Codex report praised the patrol's blocking behavior without
spotting that part of it misfires); the resource-debris incident class with
its open enforcement gap; the quantified Codex wait_agent burn; the bd JSON
shape tax; the intra-window improvement arc as the headline health signal.

**Codex adds (not independently verified here, no reason to doubt):** the
Amp serial-Dolt violation on 07-23; Claude stop-hook counts (215 events /
18 roots); Entire checkpoint-ref noise in `git log --all`; Codex state-DB
row-classification pitfalls. Their `mybd-lq8i.3/.5/.6` remain the right homes.

**Method note:** per-session digests surfaced incident mechanics (quotes,
retry loops, exact costs) that store-level scouting couldn't; store-level
scouting surfaced aggregates (stop-hook counts, token totals) that digests
couldn't. A future round should do both deliberately — that's now noted in
`retro/findings.md`.

## Follow-ups filed

| bead | what | priority |
|---|---|---|
| `mybd-pqs0` | patrol: retry transient UNKNOWN/UNSTABLE; auto re-arm red-base kicks when base greens; escalate no-check PRs; timestamp log lines | P1 |
| `mybd-yay7` | triage/re-arm the 18 current `merge-blocked` tails now that main is green | P1 |
| `mybd-jx3o` | codex-agent: enforce GOCACHE/GOTMPDIR under worktree `.tmp/` in the wrapper, not just memory | P2 |
| `mybd-au80` | bd --json shapes: upstream issue (or local normalizing helper) for array/object drift | P2 |
| `mybd-dpio` | Codex orchestration: polling-burn guidance | P2 |
| existing `mybd-lq8i.3/.4/.5/.6` | Amp parity, workflow gates, telemetry, stop-hook churn | as filed |

## What did I notice that isn't on any list?

The machinery's biggest asset this window wasn't any component — it was the
**failure-to-fix latency** (hours, not weeks). The biggest liability is the
inverse at the automation edges: components that *can't* self-correct (patrol
kick-outs, debris accumulation) decay silently until a human or a retro looks.
Anything autonomous needs either a re-entry path or a scheduled auditor.

---
*Sources: 25 session digests (retro/digests/, untracked), pr-babysit
patrol.log, verify-status, Amp cli.log, Codex rollout scan, repo hygiene
scan. Transcript quotes ≤25 words per privacy rule; digests stay local.*
