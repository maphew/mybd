# Cross-runtime session machinery retrospective

**Window:** 2026-07-22 00:00 through 2026-07-25 14:35, America/Whitehorse  
**Runtimes:** Claude Code, Codex CLI, Amp, Kilocode  
**Question:** How well did the machinery run, independent of what the sessions
worked on?

## Bottom line

The machinery is healthy for Codex and mostly healthy for Claude, but it is not
uniformly healthy across runtimes.

- The shared control plane is the strongest part: worktrees, commit signatures,
  Beads sync/recovery, the local verifier, and the PR babysitter are doing useful
  work and preventing unsafe completion.
- Codex sessions showed the best close discipline and isolation. Their tuning
  need is efficiency, not correctness.
- Claude sessions were productive and responsive, but large workflow fan-outs
  accumulated stop-hook and result-shape churn.
- Amp is the material weak point. Recent operational logs show missing semantic
  transcript retention, no observable approval events, a permissive
  `dangerouslyAllowAll` setting, and at least one violation of the serial-Dolt
  rule.
- Kilocode had no session activity in the window, so its current execution
  machinery cannot be assessed.

This is a "keep operating, harden two weak seams" result, not a stop-the-line
result. The two high-priority seams are Amp policy parity and workflow stage /
aggregate-result validation.

## Evidence and confidence

| Runtime | Evidence in window | Confidence | Assessment |
|---|---:|---|---|
| Claude Code | 18 substantive top-level transcripts; 3 noise records excluded | High | Healthy, with orchestration scale and stop-hook churn |
| Codex CLI | 8 interactive roots, including this in-flight audit; child/exec runs correlated to parents | High | Healthy; strongest close/isolation discipline, high tool volume |
| Amp | 4 substantive operational logs plus 1 transport-only log | Medium-low | Guardrails and observability need attention |
| Kilocode | 0 recent session/task records | None for execution | Inactive; no recent behavior to judge |

"Last three days" was interpreted as local calendar time beginning July 22.
There were no substantive Claude sessions beginning July 22, no Amp activity
after July 24, and no Kilocode activity in the window.

Transcript contents can contain private material. This report records only
counts, short operational events, and redacted conclusions. It does not publish
prompts or transcript dumps.

## What is working well

### 1. Close and recovery paths are real, not aspirational

All seven completed Codex roots left an explicit final state. They routinely
distinguished completed local work from queued external gates, retried rejected
Dolt pushes by pulling rather than forcing, froze clean candidate heads, and
handed long validation to the verifier or merge babysitter.

Claude showed the same recovery behavior in several sessions. Remote-ahead Git
and Dolt conflicts were detected, pulled, and retried. Errors were usually
diagnosed rather than hidden. One close check correctly warned about an
unreferenced report and a bead left in progress; the weakness was that the
session ended without evidence that both warnings were repaired.

Across the coordination repo's main branch, 32 of 33 non-merge commits in the
window had an `Agent-Signature` trailer. The one unsigned non-merge report is an
exception worth noticing, not a systemic signature failure.

### 2. Isolation and role separation are generally good

Codex build changes were isolated in linked worktrees. High-risk changes used
one writer plus independent reviewers, avoiding parallel writers. A session
that found another actor's dirty detached checkout left it alone.

Claude also used beads source worktrees extensively. The notable exception was
a coordination report committed directly on `main`; reports are an allowed
root-guard escape hatch, but the repo's default remains a coordination
worktree.

Cross-vendor review was one of the better-performing patterns. Claude and Codex
were used as independent reviewers, findings were adjudicated, and fixes were
rechecked before integration. The evidence supports preserving this policy.

### 3. User steering is effective

Both Claude and Codex absorbed concrete mid-session corrections promptly. The
sessions did not continue visibly pursuing a superseded plan after direct
feedback. Long autonomous sweeps reduce the frequency of steering
opportunities, but not the willingness to respond when the user intervenes.

### 4. The zero-token control plane is earning its keep

The composed Git hooks are enabled, Beads points to the populated `mybd`
database, and `scripts/test-agent-hooks` passes. The newest prime customization
also reduced injected `bd prime` context from about 10.2 KB to 5.1 KB.

The verification queue currently reports recent source candidates as passed.
The `pr-babysit` timer is enabled and active. In the audit window it merged
green handoffs and repeatedly blocked merges while upstream main was red or a
preflight needed agent judgment. That is the desired safety behavior: agents
produce and hand off; the timer waits without model tokens.

## Where the machinery is straining

### 1. Amp lacks policy and evidence parity

Four substantive Amp runs were visible only through executor logs. Every tool
lease received an acknowledgement, but the retained logs do not include enough
semantic result data to establish command success, user authorization, final
outcome, or model/task fit.

One July 23 run issued embedded-Dolt/Beads commands concurrently, then performed
raw Dolt merge/resolve/commit operations. That directly conflicts with this
repo's serial-Dolt rule. Other runs performed cleanup and package-manager trust
changes without retained approval events or complete session-close evidence.

The current Amp settings include `amp.dangerouslyAllowAll` and no visible
repo-specific hook configuration. This may be an intentional personal posture,
but combined with missing retained authorization evidence it is too permissive
for auditing destructive or external actions. Signature discovery also required
an ad hoc retry rather than a single supported helper path.

The Amp transport log recorded 13 reconnect/decode errors across July 22–23.
Substantive sessions still exchanged leases and acknowledgements, so this looks
like recovered transport noise rather than an outage, but it should remain
observable.

**Action:** `mybd-lq8i.3` — harden Amp guidance, serialized Dolt access,
authorization posture, close evidence, and live signature metadata.

### 2. Workflow fan-out needs stage and result validation, not a hard 200k ceiling

Two recent Claude workflows reported approximately 208k and 284k tokens against
the documented 200k default target. The larger run used 52 agents, then hit a
malformed/null aggregate shape and a batch of failed bead closures.

Owner clarification after this audit: 200k is a soft performance-tuning target,
not a reliability ceiling. Exceptions are acceptable and runs around 500k have
worked well. The 208k/284k totals are useful efficiency observations, not
evidence that token volume caused the malformed result.

The actual reliability concerns are independent: aggregate schemas were not
validated before mutation, and a separate multi-workflow session silently
skipped a required verification stage because `budget.spent()` included an
earlier workflow's spend. Soft-target overruns should be logged and tuned, not
used by themselves to suppress required stages.

**Action:** `mybd-lq8i.4` — isolate per-workflow accounting, preserve required
stages across soft-target overruns, validate aggregate schemas before mutations,
and continue to report budget efficiency.

### 3. Claude stop/goal machinery is noisy at scale

The 18 Claude roots emitted 215 `stop_hook_summary` events. Individual
high-fanout sessions produced 24–55 cycles, and one goal-driven session used
scheduled wakeups. These hooks preserve continuity and close-state visibility,
but the count is large enough that their marginal value should be measured.

There were no explicit Claude context-window compactions in the inspected
roots; one reported about 303k of a 1m-token context. The dominant churn was
continuation/orchestration machinery, not lack of model context.

**Action:** `mybd-lq8i.6` — classify useful versus redundant stop cycles and
tune without weakening close hygiene.

### 4. Codex is correct but expensive in calls and hard to count naively

Five Codex roots used 92–161 tool calls. Three of eight roots compacted context.
No loss of control was observed, but a compact evidence ledger and a cap on
duplicate live-status polling would reduce churn.

The Codex state database contained 129 rows in the window: 8 interactive CLI
roots, 61 subagent rows, and 60 exec/review rows. Structured `codex review`
runs can create a zero-token companion row beside the actual review row, so row
counts are not session counts. The stored token counters total roughly 296
million across roots and delegates; they are useful as a relative volume signal,
not a billing statement.

Model routing was directionally sensible: frontier/high dominated adversarial
review, while Terra/medium handled mechanical scouts and builders. The tuning
opportunity is measurement and polling discipline, not broad demotion.

### 5. CLI and result-shape drift still wastes calls

Across Claude and Codex, repeated avoidable failures included wrong `bd` or
`gh` flags, jq object/array mismatches, stale or incorrect paths, and pulls
blocked by unstaged changes. Most recovered safely, but a cheap capability and
shape probe before mutation would reduce retries.

Final messages should also consistently distinguish:

- session close is clean;
- local candidate is frozen and handed off;
- deliverable is fully green.

The current sessions usually behaved correctly but occasionally used optimistic
wording while external verification remained queued.

## Observability side effects

Entire CLI created 84 checkpoint/transcript commits on its dedicated ref in the
window. The main worktree stayed clean and the packed repository is still
modest, so this is not presently a health problem. It does make `git log --all`
and naïve commit/session inventory noisy. Retrospective tooling should exclude
or deliberately classify Entire refs.

Amp retains recent executor logs but not matching thread JSON in the local
thread store. Kilocode's latest local files predate the audit window. The
existing retrospective ledger covers older Claude sessions and cannot yet
normalize these four stores.

**Action:** `mybd-lq8i.5` — add a read-only, redacted cross-runtime inventory
that normalizes roots/delegates, Codex companion rows, Entire refs, missing
transcripts, and inactive runtimes.

## Priorities

1. **P1 — Amp parity (`mybd-lq8i.3`).** This is the only finding combining
   permissive execution, a concrete policy breach, and inadequate retained
   evidence.
2. **P1 — workflow stage/result gates (`mybd-lq8i.4`).** A shared counter
   silently skipped verification and malformed aggregates reached closure
   logic. Budget overrun alone is not a reliability concern.
3. **P2 — normalized telemetry (`mybd-lq8i.5`).** Without it, every audit pays
   the same classification cost and can miscount Codex or miss Amp evidence.
4. **P2 — stop-hook measurement (`mybd-lq8i.6`).** Likely efficiency win, but
   lower risk than the first two.

Keep the worktree policy, signature trailers, serial recovery on push
conflicts, cross-vendor review, local verification queue, and PR babysitter.
Those mechanisms showed positive evidence and should not be weakened while
tuning overhead elsewhere.

## What did this audit notice that was not on a list?

The key unlisted relationship is that observability itself now changes the
shape of the repository and session stores: Entire adds checkpoint refs, Codex
review adds companion thread rows, Amp keeps executor logs without matching
semantic transcripts, and Kilocode can be installed but inactive. A machinery
audit must normalize instrumentation artifacts before interpreting counts.
