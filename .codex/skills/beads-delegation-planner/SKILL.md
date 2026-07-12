---
name: beads-delegation-planner
description: Plan and consume execution metadata for bd/beads issues. Use when Codex inspects, triages, claims, tackles, or delegates beads; assign or read suggested agent type, model, reasoning effort, execution mode, and parallel group using the documented execution_* metadata keys.
---

# Beads Delegation Planner

## Overview

Use this skill to make beads directly actionable for agent execution and delegation. When inspecting a bead, automatically check its metadata for documented execution hint keys and treat those values as the default routing plan unless the user gives a conflicting instruction.

Store machine-readable routing guidance in issue metadata. Use notes for rationale, ownership slices, exact prompts, and other prose that should remain readable by humans.

## Workflow

1. Load project context with `bd prime` if it has not already been loaded in the session.
2. Inspect candidate issues with `bd ready`, `bd show <id> --json`, and local code search as needed. Use JSON output when metadata may affect execution.
3. If execution metadata exists, consume it by default: agent type, model, reasoning effort, execution mode, parallel group, and verification state should steer the plan unless the user overrides them.
4. If execution metadata is missing, incomplete, or stale, assign flat metadata keys from the documented set below. Preserve existing useful values unless the issue content makes them stale.
5. Update issues with repeated `bd update <id> --set-metadata key=value` flags. Prefer targeted key updates over `--metadata` whole-object replacement.
6. Verify with `bd show <id> --json` or exported JSONL inspection when the user asks for confirmation.

For multiple beads, batch commands only when values are identical and the update remains easy to audit. Otherwise update each bead separately.

## Metadata Keys

Use the documented execution hint keys from `bd-main/docs/METADATA.md` exactly. Omit keys that do not add useful routing signal; absence means no override.

```json
{
  "execution_agent_type": "worker",
  "execution_suggested_model": "gpt-5.6-sol",
  "execution_reasoning_effort": "medium",
  "execution_mode": "delegated",
  "execution_parallel_group": "catalog",
  "verify_state": "queued",
  "verify_head": "abc123...",
  "verify_branch": "feature/example",
  "verify_cmd": "make test",
  "verify_log": "/path/to/log",
  "verify_result": "exit=0",
  "verify_started_at": "2026-05-28T03:00:00Z",
  "verify_finished_at": "2026-05-28T03:20:00Z",
  "verify_enqueued_at": "2026-05-28T02:55:00Z",
  "verify_worktree": "/path/to/source/worktree",
  "verify_runner": "host:pid"
}
```

Allowed and recommended values:

- `execution_agent_type`: suggested worker class, usually `explorer`, `worker`, or `mixed`.
- `execution_suggested_model`: concrete model for the parent agent or spawned subagent. Leave unset unless the bead has a clear need, and treat a pin as a capability tier, not a brand: frontier tier (`gpt-5.6-sol`, `claude-fable-5`) for high-risk design, security, storage, or cross-repo work; fast tier (`gpt-5.6-terra`) for mechanical, low-risk cleanup. Legacy pins on old beads map by tier, not slug: `gpt-5.5`/`gpt-5.4` -> `gpt-5.6-sol`, `gpt-5.4-mini` -> `gpt-5.6-terra`. Consumers on a different provider substitute their own model of the same tier rather than dropping the hint. Exception: the Claude fast tier (haiku) is retired in this repo (owner directive 2026-07-07, see AGENTS.md scout tier) - fast-tier hints, including legacy `claude-haiku-4-5` pins on old beads, execute via `scripts/codex-agent scout` (gpt-5.6-terra, medium reasoning), not haiku.
- `execution_reasoning_effort`: `low`, `medium`, `high`, or `xhigh`. This is the canonical stored scale; consumers map to their own runtime (Claude Code: `xhigh` -> `max`; Fable's `auto` is acceptable when no override is warranted). Default to leaving it unset for normal work; set `high` for ambiguous implementation or broad codebase impact; set `xhigh` for critical concurrency, data loss, storage, migration, or maintainer policy decisions.
- `execution_mode`: `local` when the current agent should do the work directly, `delegated` when it should be spawned or handed off, or `staged` when exploration/planning should happen before local implementation.
- `execution_parallel_group`: short stable group name such as `A`, `B`, `docs`, `tests`, `storage`, or `blocked`. Same group means the tasks can run together or should be coordinated together, depending on local convention; explain in notes when unclear.
- `verify_state`: local slow-validation state: `queued`, `running`, `passed`, or `failed`.
- `verify_head`: commit SHA that must be validated. Treat this as the source of truth, not the current branch tip.
- `verify_branch`: branch name recorded when verification was enqueued.
- `verify_cmd`: shell command to run in a clean verification worktree, usually `make test`.
- `verify_log`: local path to the verifier log.
- `verify_result`: compact result such as `running`, `exit=0`, `exit=1`, or `worktree-add-failed`.
- `verify_enqueued_at`: UTC timestamp written when the job is queued.
- `verify_worktree`: source or clean verification worktree path, depending on queue state.
- `verify_started_at` / `verify_finished_at`: UTC timestamps written by the verifier.
- `verify_runner`: local verifier identity, usually `host:pid`.

## Heuristics

Prefer `execution_agent_type=worker` when the bead calls for bounded implementation or tests with clear ownership. Prefer `explorer` for codebase investigation, root cause analysis, reproductions, or issue archaeology where writes are not expected. Prefer `mixed` when useful work should be staged, such as exploration followed by implementation, PR maintenance followed by local integration, or verification after a candidate exists.

Leave `execution_suggested_model` unset unless the bead's risk profile justifies overriding the runtime default. Model recommendations should be sparse and defensible; reasoning effort carries most of the routing signal.

Choose `execution_reasoning_effort=low` for mechanical renames, docs copy edits, simple generated-file updates, or narrowly specified test additions. Choose `medium` for normal implementation, bug fixes with a local reproduction, and straightforward PR processing. Choose `high` for unfamiliar subsystems, multi-file behavior changes, concurrency-adjacent bugs, or changes that need careful test strategy. Choose `xhigh` for P0/P1 data loss, storage integrity, sync correctness, migrations, security, or changes that could strand user work.

Use `execution_mode=delegated` for background or handoff work, `local` for work the current agent should do directly, and `staged` when an explorer or planner should first reduce uncertainty before another agent implements.

When delegating code-writing workers, include worktree/isolation requirements in the prompt from repo instructions rather than inventing metadata keys. Ownership should be disjoint across parallel workers; record it in notes or the delegated prompt. Prefer `cmd/bd/**;internal/foo/**;tests/foo/**` over vague labels like `backend`. For PR maintenance beads, ownership can be `gh:<owner>/<repo>#<number>;local integration branch`.

## Verification Queue

When a beads source worker finishes implementation but the remaining gate is a
slow local suite, do not leave the worker idle watching tests. The worker should
run fast preflight, commit or otherwise freeze the candidate, then enqueue slow
validation from the coordination repo:

```bash
scripts/verify-enqueue <bd-id> <beads-worktree> "make test"
```

The verifier runs:

```bash
scripts/verify-status
scripts/verify-next
```

Completion or merge decisions must compare the candidate being considered with
`verify_head`. A `verify_state=passed` result only gates that exact commit. If
the branch moves after verification, enqueue a new run. A failed verification
should be routed back to the owner with `verify_log` and `verify_result`; do not
ask the implementation worker to poll long-running tests unless active debugging
is needed.

## Update Pattern

Use this shape for single-issue updates:

```bash
bd update <id> \
  --set-metadata execution_agent_type=worker \
  --set-metadata execution_reasoning_effort=medium \
  --set-metadata execution_mode=delegated \
  --set-metadata execution_parallel_group=catalog
```

Quote values containing spaces, semicolons, globs, shell metacharacters, or empty strings.

Record rationale, ownership, exact prompts, and dependency explanations in notes or real bead dependencies. Use metadata only for values that automation should parse.

## Delegating From Metadata

When the user says to tackle, process, work, continue, or delegate a bead, first inspect that bead's metadata. The user should not need to say "spawn worker" or "use metadata hints"; those are implied by the bead metadata unless explicitly overridden.

Translate metadata directly:

- `execution_agent_type=worker`: spawn or hand off a worker when `execution_mode` calls for delegation; include ownership from notes and say the worker is not alone in the codebase.
- `execution_agent_type=explorer`: spawn or hand off an explorer when the task is read-only and specific.
- `execution_agent_type=mixed`: stage the work; usually have an explorer/planner reduce uncertainty before implementation or verification.
- `execution_suggested_model`: use the suggested model only when the delegation tool supports it.
- `execution_reasoning_effort`: pass the same effort only when the delegation tool supports it.
- `execution_mode=delegated`: spawn or hand off the work according to the active runtime's delegation rules.
- `execution_mode=local`: keep the work in the current agent unless the user overrides it.
- `execution_mode=staged`: split exploration, implementation, and/or verification into explicit phases.
- `execution_parallel_group`: group spawned work so non-overlapping beads can run together and related beads can coordinate.
- `verify_state=queued`: a verifier can pick up the bead with `scripts/verify-next`; implementation agents should not wait synchronously for the long suite.
- `verify_state=passed`: treat the gate as satisfied only for the recorded `verify_head`.
- `verify_state=failed`: inspect `verify_log` and route the failure back to the owner or maintainer.

If metadata conflicts with the user's current instruction, follow the user's instruction and consider updating stale metadata. If metadata is partial, use present keys and infer only the missing pieces.

Never spawn an agent solely because metadata exists; obey the active runtime's delegation rules and user authorization requirements.
