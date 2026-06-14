---
name: beads-stealth
description: Initialize or use beads in stealth mode for a project that does not use beads, with issue data stored in a separate syncable repository. Use when the user says "init with stealth", "stealth beads", "use beads without touching this repo", or asks for external BEADS_DIR setup.
---

# Beads Stealth Mode

Use this skill when a user wants beads task tracking in a project that should not contain beads files, git hooks, or commits.

## Goal

Set `BEADS_DIR` to a dedicated external beads repository, then run `bd init --stealth` from the target project. This keeps the target repo clean while allowing `bd dolt pull` and `bd dolt push` to sync through the dedicated beads repo.

## Preferred Command

From any target project, use the generic helper from this coordination checkout:

```bash
/var/home/matt/dev/mybd/scripts/bd-stealth-init --remote git@github.com:OWNER/PROJECT-beads.git
```

If the user has not provided a remote, initialize local stealth mode without sync:

```bash
/var/home/matt/dev/mybd/scripts/bd-stealth-init
```

If the user wants the setting to persist in that project and accepts a local project file change:

```bash
/var/home/matt/dev/mybd/scripts/bd-stealth-init --set-envrc --remote git@github.com:OWNER/PROJECT-beads.git
```

## Agent Workflow

1. Run the helper from the target project directory unless the user supplies an explicit project path.
2. Use `--remote` when the user supplies a private repository URL for sync.
3. Use `--repo-dir` when the user supplies a desired local beads-data repository path.
4. Use `--set-envrc` only when the user explicitly wants persistent per-project environment configuration.
5. After setup, run beads commands with `BEADS_DIR` exported or prefixed inline.

## Manual Fallback

Use these commands if the helper is unavailable:

```bash
mkdir -p ~/project-beads
cd ~/project-beads
git init
bd init --prefix project
git remote add origin git@github.com:OWNER/project-beads.git

cd ~/target-project
export BEADS_DIR=~/project-beads/.beads
bd init --stealth
bd dolt pull || true
bd dolt push
```

## Constraints

- Do not commit `.beads`, hooks, or beads metadata to the target project.
- Do not write `.envrc` unless requested.
- Prefer private remotes for stealth beads data.
- If `bd dolt pull` fails on a newly created remote, continue to `bd dolt push` unless there is evidence of real remote data divergence.
