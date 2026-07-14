# Agent Session Retrospective Playbook

**Version:** 1.0 (2026-07-14) · **Portable:** yes — this file plus a `LOCAL.md`
adaptation is everything a fresh agent needs to run one retrospective round in
any project, under any coding-agent runtime.

## Purpose

Mine past agent sessions for evidence about **how the human and their coding
agents work together** — not about any one project. Output: cumulative,
evidence-backed recommendations that reduce friction and increase velocity.

Improvement dimensions (the finding taxonomy — tag every finding with one):

| Tag | Meaning |
|---|---|
| `prompting-pattern` | Phrasings/structures in the human's asks that helped or hurt |
| `under-specified` | Agent guessed wrong because the ask lacked a constraint |
| `over-specified` | Constraints that wasted effort or blocked better solutions |
| `missing-skill` | A reusable procedure that should exist but doesn't |
| `detrimental-skill` | A skill/command that fired and made things worse |
| `missing-tool` | Capability gap (script, MCP server, permission, hook) |
| `bad-tool` | A tool that exists but misbehaves |
| `mishandled-tool` | Tool is fine; the agent used it wrong |
| `tokenomics` | Context/token waste: re-reads, giant outputs, compaction churn, re-priming |
| `model-task-mismatch` | Wrong tier for the work; escalation loops; redone delegations |
| `process` | Workflow friction: unclosed sessions, stranded work, duplicate tracking |
| `environment` | Sandbox, OS, auth, path quirks |
| `win` | A pattern that worked well — candidate to amplify/standardize |

## Units

- **Session** — one top-level interactive conversation with an agent runtime.
  Sub-agent runs (spawned subagents, `codex exec` calls made *by* a session)
  are evidence *within* their parent session, not sessions themselves.
- **Batch** — exactly **5 substantive sessions**, assessed together.
- **Round** — one execution of Phases 1–4 on one batch. A round is sized to
  fit one agent session; the state files make the exercise resumable forever.
- **Campaign** — all sessions for one (project × runtime) scope.

## State files (all in this `retro/` directory)

| File | Tracked in git? | Contents |
|---|---|---|
| `PLAYBOOK.md` | yes | this procedure (portable) |
| `LOCAL.md` | yes | per-repo adaptation: paths, tracker wiring, commit protocol |
| `ledger.tsv` | yes | one row per known session: scope, id, date, size, status, batch |
| `findings.md` | yes | cumulative findings register — **the** long-lived output |
| `batches/round-NN.md` | yes | one-page synthesis per round |
| `digests/*.md` | **no** (gitignored) | per-session digests; may quote transcripts → never publish |

**Privacy rule:** transcripts can contain secrets, tokens, and private paths.
Digests stay untracked. Anything that IS committed (`findings.md`, `batches/`)
must be redaction-checked: no credentials, no long verbatim transcript dumps,
quotes ≤ 25 words. This matters doubly in public repos.

---

## Phase 0 — Data source map (once per machine/runtime)

Locate the session stores. Verified layouts as of 2026-07-14:

**Claude Code** — `~/.claude/projects/<slugified-cwd>/*.jsonl`, one file per
session (top-level files only; subdirectories hold tool results/sidechains).
JSONL `type` field: `user`, `assistant`, `system`, plus noise types
(`attachment`, `file-history-snapshot`, `queue-operation`, …). Assistant lines
carry `message.model` and full `message.usage` token breakdowns.

**Codex CLI** — `~/.codex/sessions/YYYY/MM/DD/rollout-<ts>-<id>.jsonl`.
First line is `session_meta`; filter on `.payload.originator` / `.payload.source`:
`codex-tui`+`cli` = interactive session (retro unit); `codex_exec`+`exec` =
delegated run (attach to parent by cwd+timestamp); `source` containing
`subagent` = spawned child (attach to `parent_thread_id`).

**Amp** — `~/.local/share/amp/threads/T-*.json`, one JSON per thread with
`messages[]` (role, content, `usage.model`).

**Any other runtime / fallback evidence** (works even with no transcripts):
git log trailers (`Agent-Signature:` here), issue-tracker history, PR/commit
timestamps vs session dates, `reports/` retro-docs.

## Phase 1 — Inventory & batching (mechanical, ~zero model tokens)

1. Enumerate sessions for the campaign scope into `ledger.tsv`
   (see LOCAL.md for ready-made commands). Columns:
   `scope  runtime  session_id  started  size_kb  status  batch  note`
   Status values: `pending | skipped-trivial | skipped-subagent | skipped-inflight | digested | synthesized`.
2. Filter substantive: mark `< 100 KB` (Claude/Codex) or `< 8 messages` (Amp)
   as `skipped-trivial` unless a note says otherwise. Mark sub-agent runs
   `skipped-subagent`. Mark the currently-running session `skipped-inflight`.
3. Order **newest-first** — recent sessions reflect current tooling, so their
   findings are actionable immediately; old sessions mostly reveal already-
   fixed friction (see stop rule 3).
4. Take the next 5 `pending` rows → that's this round's batch. Assign batch
   number in the ledger.

## Phase 2 — Per-session digest (cheap model tier)

**2a. Strip mechanically first** (jq/scripting, zero model tokens). Keep: user
text, assistant text, tool names + first ~120 chars of input, error results,
model + output-token usage, timestamps. Drop: full tool results, thinking,
attachments, snapshots. Verified compression on a real 1.5 MB Claude Code
transcript: → 88 KB ≈ 22 k tokens (~17×). Recipes per runtime in LOCAL.md.

**2b. One digest agent per stripped transcript** — cheapest adequate tier
(they read ~25 k tokens, apply a fixed rubric, write ~1–2 k). Run the 5 in
parallel if the runtime allows. Each writes `digests/<runtime>-<id8>.md`:

```markdown
# <runtime>/<id8> — <date> — <project>
meta: model(s)+effort | wall-clock span | msg count | output-tokens total
task: what was asked (1–3 lines; note if the ask evolved mid-session)
outcome: done-verified | done | partial | abandoned | unclear
  evidence: commits/PRs/issues/files produced, or user's closing sentiment
effectiveness: 1–5
  5 done+verified, little steering, cost ∝ task · 4 done, minor friction
  3 done but heavy steering/redo loops · 2 partial handback · 1 abandoned/wrong
friction:              # 0..n items, THE payload
- [tag] [H|M|L] what happened — evidence: "≤25-word quote" (who bore the cost: human|agent|both)
wins:
- [win] what worked and why it worked
delegation: subagents/exec runs spawned; tier fit right/over/under; redos
user-style: phrasings that produced clean runs or confusion (short quotes)
recs: 0–3 candidate recommendations, each tagged
```

Digest agents must quote *evidence*, not impressions — a finding without a
quote or a concrete event is an impression and gets marked `[weak]`.
High-signal markers to hunt for: user interruptions and corrections
("no, I meant", "stop", "again?"), permission-prompt stalls and denials,
tool-error retry loops, compaction events, questions the agent asked that the
opening prompt should have answered, redone subagent work, sessions that end
without closing protocol, apologies.

## Phase 3 — Batch synthesis (smart model tier — judgment work)

Inputs: the 5 digests + current `findings.md`. Steps:

1. For each friction/win item: **match against existing findings** — if it
   recurs, append the new evidence line and bump the count; else add a new
   `candidate` finding.
2. **Fixed-since check:** for older findings, note whether this batch's
   (newer or older) sessions show the friction absent after some change —
   move toward `verified-fixed`.
3. Write `batches/round-NN.md` (≤ 1 page): sessions covered, effectiveness
   scores, new findings, recurrences, promotions proposed, and **process
   notes on the retro itself** (rubric gaps, digest quality — this playbook
   is also under retrospection; bump its version when you change it).
4. Update `ledger.tsv` statuses.

`findings.md` entry format:

```markdown
### F-NNN · [tag] short title
- status: candidate → recurring → promoted → verified-fixed | retired
- sightings: N — <runtime>/<id8> (date): "quote"; …
- cost: who pays and roughly how much (turns, tokens, wall-clock, mood)
- recommendation: the specific change, and where it would live
- promoted-to: <link/path once acted on> · verify-by: what future sessions should show
```

## Phase 4 — Promotion (recommendations → durable change)

A finding is **actionable** at ≥ 2 independent sightings (or 1 with high
severity). Route by kind:

| Finding kind | Durable home |
|---|---|
| prompting pattern (human side) | "Prompt cookbook" section at top of `findings.md` |
| agent behavior rule | CLAUDE.md / AGENTS.md / runtime memory (`bd remember`, auto-memory) |
| missing / broken skill | create or fix the skill; note the trigger phrase |
| permissions / hooks / config | runtime settings (e.g. allowlists, SessionStart hooks) |
| model–task matching | the repo's delegation-tier table |
| missing tool | script it, adopt it, or file it in the issue tracker |

Every promotion gets a tracked task in the project's issue tracker **and** a
`verify-by` line — the closed loop: a later round must confirm the friction
actually disappeared, else the finding reopens.

## Phase 5 — Iterate

Run rounds until a stop rule fires:

1. **Saturation** — two consecutive rounds add zero new findings (only
   recurrences): switch to maintenance cadence (one round per ~20 new
   sessions, or monthly).
2. **Promotion backlog** — > ~10 unpromoted actionable findings: stop mining,
   start promoting. Mining faster than fixing is waste.
3. **Staleness horizon** — sessions predating the last major process overhaul:
   mine only for `prompting-pattern`/`user-style` signal (human habits age
   slowly; tooling friction findings from that era are mostly already fixed).

**Cost per round** (measured basis): 5 stripped transcripts ≈ 110–125 k tokens
read on the cheap tier + ~10 k digest output; synthesis reads ~15 k on the
smart tier. Budget ≈ 150–250 k tokens/round all-in. If a second vendor's CLI
is available (e.g. Codex from a Claude session), digesting there is free
quota relief — log it, since it bypasses budget accounting.

## Porting to a new project or runtime

1. Copy `PLAYBOOK.md` into `<project>/retro/` (or point at a central copy —
   a personal coordination repo is the natural home, and a **single shared
   `findings.md`** across projects is where cross-project patterns emerge;
   per-project you only need a ledger and digests).
2. Write `LOCAL.md`: session-store paths for the runtimes used there, strip
   recipes, tracker wiring, commit/close protocol, model tiers available.
3. Seed `ledger.tsv` (Phase 1) and open a standing "run next retro round"
   task in that project's tracker so cold-start agents find it.

**Round entry point (give this to any agent):**
> Run one retrospective round per `retro/PLAYBOOK.md` + `retro/LOCAL.md`.
> Pick the next batch from `retro/ledger.tsv`, execute Phases 2–4, update the
> state files, and close per LOCAL.md.
