---
description: Set up a private GitHub Dolt repo for personal beads and configure sync for the current project
allowed-tools: Bash(*), Read(*), Write(*), Edit(*), Glob(*), Grep(*)
---

Set up personal beads with Dolt sync for the current project.

## Context

The user wants personal beads (issue tracking) that are:
- **Not in the project repo** — won't pollute PRs or be visible to collaborators
- **Synced across machines** via a private GitHub repo using Dolt's native sync
- **Per-project** — each project gets its own personal beads database

## Steps

### 1. Determine project name

Infer the project name from the current git repo:

```bash
basename "$(git rev-parse --show-toplevel 2>/dev/null || basename "$PWD")"
```

Confirm with the user: "Setting up personal beads for **<project-name>**. OK?"

### 2. Determine GitHub username

```bash
gh api user --jq .login
```

If `gh` is not authenticated, ask the user for their GitHub username.

### 3. Create the local beads directory

```bash
mkdir -p ~/.beads-planning/<project-name>
cd ~/.beads-planning/<project-name>
git init
bd init --prefix plan
```

If `~/.beads-planning/<project-name>` already exists, ask the user if they want to reconfigure or abort.

### 4. Create the private GitHub repo

```bash
gh repo create beads-planning-<project-name> --private --description "Personal beads for <project-name>" --confirm
```

### 5. Configure Dolt remote and push

```bash
cd ~/.beads-planning/<project-name>
bd dolt remote add origin git+ssh://git@github.com/<username>/beads-planning-<project-name>.git
bd dolt push
```

### 6. Configure the project to see personal beads

```bash
cd <original-project-dir>
bd config set repos.additional "~/.beads-planning/<project-name>"
```

### 7. Verify

```bash
bd list  # should work (may be empty)
```

### 8. Print bootstrap instructions

Print instructions the user can run on another machine:

```
# On your other machine, after cloning <project-name>:
mkdir -p ~/.beads-planning/<project-name>
cd ~/.beads-planning/<project-name>
git init
bd init --prefix plan
bd dolt remote add origin git+ssh://git@github.com/<username>/beads-planning-<project-name>.git
bd bootstrap   # or: bd dolt pull
cd <project-dir>
bd config set repos.additional "~/.beads-planning/<project-name>"
```

Tell the user: "Done. Use `bd dolt push` / `bd dolt pull` in `~/.beads-planning/<project-name>` to sync."
