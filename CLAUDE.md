# Project Instructions for AI Agents — Claude Code

@AGENTS.md

Shared cross-agent instructions live in [AGENTS.md](AGENTS.md) (imported
above): conventions, repository layout, signing, the bd issue-tracker workflow,
contributing upstream, and the session-completion protocol.

This file is intentionally short. Do not copy workflow, build, storage, or UI
rules here; those details drift quickly when repeated across agent entrypoints.

## Role

maphew is a **contributor** to `gastownhall/beads`, not a maintainer (stepped
down 2026-08-10). We open PRs and file issues; we do not merge, close, label, or
triage other people's work. The scheduled automation lanes that assumed merge
rights are gone. See bd memory `maintainer-role-stepped-down` and
[archive/PR_MAINTAINER_GUIDELINES.md](archive/PR_MAINTAINER_GUIDELINES.md)
(historical, do not apply).

## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT
use markdown TODOs, task lists, or other tracking methods.

```bash
bd ready --json                          # unblocked work
bd create "Title" --description="..." -t bug|feature|task -p 0-4 --json
bd update <id> --claim --json            # claim atomically
bd close <id> --reason "Completed" --json
bd remember --key <key> "fact"           # cross-session knowledge
bd memories <keyword>                    # search memories
```

Types: `bug`, `feature`, `task`, `epic`, `chore`.
Priorities: `0` critical, `1` high, `2` medium (default), `3` low, `4` backlog.

Workflow: check `bd ready` → `bd update <id> --claim` → implement → link
discovered work with `--deps discovered-from:<parent-id>` → `bd close`.

Quality: use `--acceptance` and `--design` when creating; `--validate` to check
description completeness.

Lifecycle: `bd defer` / `bd supersede`; `bd stale` / `bd orphans` / `bd lint`
for hygiene; `bd formula list` / `bd mol pour <name>` for structured workflows.

### Sync

bd stores issue history in Dolt. Each write auto-commits to Dolt history; use
`bd dolt push`/`bd dolt pull` for remote sync. Do not treat
`.beads/issues.jsonl` as the sync protocol — it is a passive export.

For more detail run `bd prime`.
