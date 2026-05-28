---
name: beads-delegation-planner
description: Plan and consume delegation metadata for bd/beads issues. Use when Codex inspects, triages, claims, tackles, or delegates beads; assign or read recommended model and reasoning effort, prepare background worker/explorer instructions, group parallel work, and update issue metadata with flat delegation keys using bd update --set-metadata.
---

# Beads Delegation Planner

## Overview

Use this skill to make beads directly actionable for agent delegation. When inspecting a bead, automatically check its metadata for delegation keys and treat those values as the default execution plan unless the user gives a conflicting instruction.

Store delegation guidance in issue metadata only. Do not put delegation plans in notes, design, descriptions, or markdown TODO files unless the user explicitly asks for prose documentation.

## Workflow

1. Load project context with `bd prime` if it has not already been loaded in the session.
2. Inspect candidate issues with `bd ready`, `bd show <id> --json`, and local code search as needed. Use JSON output when metadata may affect execution.
3. If delegation metadata exists, consume it by default: role, model, reasoning effort, execution mode, isolation, parallel group, ownership, dependencies, verification state, and reason should steer the plan unless the user overrides them.
4. If delegation metadata is missing, incomplete, or stale, assign flat metadata keys from the schema below. Preserve existing useful values unless the issue content makes them stale.
5. Update issues with repeated `bd update <id> --set-metadata key=value` flags. Prefer targeted key updates over `--metadata` whole-object replacement.
6. Verify with `bd show <id> --json` or exported JSONL inspection when the user asks for confirmation.

For multiple beads, batch commands only when values are identical and the update remains easy to audit. Otherwise update each bead separately.

## Metadata Schema

Use these flat keys exactly:

```json
{
  "agent_role": "worker",
  "recommended_model": "inherit-default",
  "reasoning_effort": "medium",
  "execution_mode": "background",
  "isolation": "none",
  "parallel_group": "A",
  "ownership": "src/catalog/**;tests/catalog/**",
  "delegation_dependencies": "imgr-123",
  "delegation_reason": "bounded implementation in catalog scan modules",
  "delegation_source": "mixed",
  "delegation_source_detail": "role:inferred;model:inferred;ownership:existing",
  "verify_state": "queued",
  "verify_head": "abc123...",
  "verify_branch": "feature/example",
  "verify_cmd": "make test",
  "verify_log": "/path/to/log",
  "verify_result": "exit=0",
  "verify_started_at": "2026-05-28T03:00:00Z",
  "verify_finished_at": "2026-05-28T03:20:00Z",
  "verify_runner": "host:pid"
}
```

Allowed and recommended values:

- `agent_role`: `worker`, `explorer`, `reviewer`, `verifier`, `planner`, `maintainer`, or `human`.
- `recommended_model`: `inherit-default` by default. Use a concrete model only when the bead has a clear need, such as `gpt-5.5` for high-risk design, security, storage, or cross-repo work, or `gpt-5.4-mini` for mechanical, low-risk cleanup.
- `reasoning_effort`: `low`, `medium`, `high`, or `xhigh`. Default to `medium`; use `high` for ambiguous implementation or broad codebase impact; use `xhigh` for critical concurrency, data loss, storage, migration, or maintainer policy decisions.
- `execution_mode`: `background` for delegable work, `foreground` for work the current agent should do directly, `interactive` when user decisions are expected.
- `isolation`: `none`, `worktree`, `readonly`, `sandbox`, or `fork`. Use `worktree` for code edits by default in repositories that expect worktrees. Use `readonly` for explorer/reviewer tasks.
- `parallel_group`: short stable group name such as `A`, `B`, `docs`, `tests`, `storage`, or `blocked`. Same group means the tasks can run together or should be coordinated together, depending on local convention; explain in `delegation_reason` when unclear.
- `ownership`: semicolon-separated paths, globs, modules, or responsibility slices. Keep it concrete enough to prevent overlapping agent edits.
- `delegation_dependencies`: comma-separated bead IDs, PR numbers, branch names, or external refs that should complete first. Use an empty string only when explicitly clearing a stale value.
- `delegation_reason`: one concise sentence explaining why this delegation shape fits the bead.
- `delegation_source`: `explicit`, `inferred`, `existing`, or `mixed`.
- `delegation_source_detail`: semicolon-separated provenance notes like `role:explicit;model:inferred;ownership:existing`.
- `verify_state`: local slow-validation state: `queued`, `running`, `passed`, or `failed`.
- `verify_head`: commit SHA that must be validated. Treat this as the source of truth, not the current branch tip.
- `verify_branch`: branch name recorded when verification was enqueued.
- `verify_cmd`: shell command to run in a clean verification worktree, usually `make test`.
- `verify_log`: local path to the verifier log.
- `verify_result`: compact result such as `running`, `exit=0`, `exit=1`, or `worktree-add-failed`.
- `verify_started_at` / `verify_finished_at`: UTC timestamps written by the verifier.
- `verify_runner`: local verifier identity, usually `host:pid`.

## Heuristics

Prefer `worker` when the bead calls for bounded implementation or tests with clear ownership. Prefer `explorer` for codebase investigation, root cause analysis, reproductions, or issue archaeology where writes are not expected. Prefer `reviewer` for PR review, CI failure review, regression risk assessment, or patch vetting. Prefer `verifier` for mechanical local validation, full-suite execution, and log capture after implementation has produced a clean candidate. Prefer `planner` for decomposing an epic into beads. Prefer `maintainer` for GitHub PR triage, landing, closing, or attribution-sensitive work. Use `human` when the bead is primarily a product, policy, access, or credential decision.

Use `inherit-default` unless the bead's risk profile justifies overriding the runtime default. Model recommendations should be sparse and defensible; reasoning effort carries most of the routing signal.

Choose `reasoning_effort=low` for mechanical renames, docs copy edits, simple generated-file updates, or narrowly specified test additions. Choose `medium` for normal implementation, bug fixes with a local reproduction, and straightforward PR processing. Choose `high` for unfamiliar subsystems, multi-file behavior changes, concurrency-adjacent bugs, or changes that need careful test strategy. Choose `xhigh` for P0/P1 data loss, storage integrity, sync correctness, migrations, security, or changes that could strand user work.

Set `isolation=worktree` for code-writing workers unless the repo instruction says otherwise. Use `readonly` for explorers and reviewers. Use `fork` only when a separate repository fork or remote branch is explicitly part of the plan.

`ownership` should be disjoint across parallel workers. Prefer `cmd/bd/**;internal/foo/**;tests/foo/**` over vague labels like `backend`. For PR maintenance beads, ownership can be `gh:<owner>/<repo>#<number>;local integration branch`.

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
  --set-metadata agent_role=worker \
  --set-metadata recommended_model=inherit-default \
  --set-metadata reasoning_effort=medium \
  --set-metadata execution_mode=background \
  --set-metadata isolation=worktree \
  --set-metadata parallel_group=A \
  --set-metadata 'ownership=src/catalog/**;tests/catalog/**' \
  --set-metadata delegation_dependencies=imgr-123 \
  --set-metadata 'delegation_reason=bounded implementation in catalog scan modules' \
  --set-metadata delegation_source=mixed \
  --set-metadata 'delegation_source_detail=role:inferred;model:inferred;ownership:existing'
```

Quote values containing spaces, semicolons, globs, shell metacharacters, or empty strings.

## Delegating From Metadata

When the user says to tackle, process, work, continue, or delegate a bead, first inspect that bead's metadata. The user should not need to say "spawn worker" or "use metadata hints"; those are implied by the bead metadata unless explicitly overridden.

Translate metadata directly:

- `agent_role=worker`: spawn a worker; include ownership and say the worker is not alone in the codebase.
- `agent_role=explorer` or `reviewer`: spawn an explorer when the task is read-only and specific.
- `agent_role=verifier`: use the local `scripts/verify-*` queue for mechanical validation instead of spawning a normal implementation worker.
- `recommended_model=inherit-default`: omit model override.
- `reasoning_effort`: pass the same effort only when the delegation tool supports it.
- `execution_mode=background`: spawn and continue local non-overlapping work.
- `isolation=worktree`: tell the agent to use or remain within the assigned worktree.
- `delegation_dependencies`: inspect or satisfy dependencies before spawning, or explain why they do not block the current work.
- `ownership`: copy the ownership slice into the delegated prompt and use it to avoid overlapping edits.
- `verify_state=queued`: a verifier can pick up the bead with `scripts/verify-next`; implementation agents should not wait synchronously for the long suite.
- `verify_state=passed`: treat the gate as satisfied only for the recorded `verify_head`.
- `verify_state=failed`: inspect `verify_log` and route the failure back to the owner or maintainer.

If metadata conflicts with the user's current instruction, follow the user's instruction and consider updating stale metadata. If metadata is partial, use present keys and infer only the missing pieces.

Never spawn an agent solely because metadata exists; obey the active runtime's delegation rules and user authorization requirements.
