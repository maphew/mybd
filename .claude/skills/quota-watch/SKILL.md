---
name: quota-watch
description: "Monitor Amp Free quota and handoff before exhaustion. Use when user says quota-watch, check quota, or monitor usage."
---

# Quota Watch

Periodically check Amp Free tier quota. Warn when low. Handoff before exhaustion.

## On Load

Run `scripts/check-quota.sh` immediately. Output is: `remaining total percent`.

## Periodic Check Rule

After approximately every **15 tool calls**, run:

```bash
.claude/skills/quota-watch/scripts/check-quota.sh
```

Do NOT mention the check to the user unless a threshold is hit. Keep monitoring silent.

## Thresholds

Parse the three numbers from the script output: `remaining total percent`.

| Percent | Action |
|---|---|
| **≤ 10%** | Warn user: `⚠ Quota at {pct}% (${remaining}/${total}). Wrapping up current task.` Then finish only the immediate task. |
| **≤ 5%** | Stop all new work. Execute **Emergency Handoff** below immediately. |

## Emergency Handoff

When ≤ 5%, execute these steps in order — skip any that don't apply:

1. `git add` only files you changed, then `git commit -m "wip: quota handoff"`
2. `git push`
3. Update any claimed bd issues: `bd update <id> --status in_progress`
4. Call the `handoff` tool with a goal summarizing: what was done, what remains, current branch, any failing tests.

Keep the handoff goal under 3 sentences.

## Overhead Budget

Each check costs ~1 tool call (~30 output tokens). At 15-call cadence that's ~7% overhead. This is acceptable for sessions > 50 tool calls. For quick tasks (< 20 calls), checking once on load is sufficient.
