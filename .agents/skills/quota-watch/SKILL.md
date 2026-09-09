---
name: quota-watch
description: "Check and monitor Amp Free quota without changing repository or remote state. Use when the user says quota-watch, check quota, or monitor usage."
---

# Quota Watch

Monitor the Amp Free daily quota and warn before it is exhausted.

## Check quota

Resolve `scripts/check-quota.sh` relative to this `SKILL.md`, then run it with
Bash. The script prints one numeric percentage, such as `18`.

Run it immediately when this skill loads. If it fails or prints anything other
than one numeric value, report that quota could not be determined and include
the error. Do not silently treat a failed check as sufficient quota.

For long tasks, repeat the check after approximately every 15 tool calls. For
tasks under 20 tool calls, the initial check is enough. Keep successful checks
silent unless a threshold is reached.

## Thresholds

Evaluate the lowest threshold first:

- At **5% or less**, stop starting new work and perform the emergency handoff.
- At **10% or less**, warn: `⚠ Amp Free quota is at {percent}%. Wrapping up the current task.` Finish only the immediate task.

## Emergency handoff

Do not commit, push, or change external state solely because quota is low.

1. Capture the current task, branch and worktree, changed files, test results,
   claimed Beads issues, completed work, and remaining work.
2. Update an already-claimed Beads issue only when the active repository policy
   authorizes that routine tracker update and the command is available.
3. Return a self-contained handoff in the final response. If the runtime offers
   a dedicated handoff mechanism, use it only when already authorized; otherwise
   the final response is the handoff.

Keep the handoff concise, but include enough detail for a fresh agent to resume.
