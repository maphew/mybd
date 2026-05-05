# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

## Repository Layout

This working directory (`~/dev/mybd/`) is **not** the beads source tree. It is a personal coordination repo for working on beads without polluting upstream with workshop noise. The beads source clone lives nested inside it at `bd-main/` (gitignored).

| Path | Repo | `origin` | `upstream` | Purpose |
|------|------|----------|------------|---------|
| `~/dev/mybd/` (cwd) | `maphew/mybd` | `maphew/mybd` | — | Personal scratch/coordination: beads issues (`.beads/issues.jsonl`), notes, agent config, this CLAUDE.md |
| `~/dev/mybd/bd-main/` | beads source | `maphew/beads` (fork) | `gastownhall/beads` (canonical) | Working clone for actual beads code edits and PRs |

**Implication for agents:**
- Beads code changes, builds (`go build`), and PRs to gastownhall happen in `bd-main/`, not in the cwd.
- The "Branch base for upstream PRs" and "Build & Test" sections below apply when working **inside `bd-main/`**.
- In `bd-main/`, `main` tracks `upstream/main` (canonical) — `git pull` keeps you in sync with gastownhall. Topic branches push to `origin` (your fork) for PRs.
- Do not add a `gastownhall` remote to the cwd `mybd` repo — it is not a fork of beads; it is its own repo.

## Cross-Machine Beads Sync

`.beads/issues.jsonl` is committed to git as the sync channel between machines (3 machines + cloud). On a fresh clone or new machine, install the post-pull import hook **once**:

```bash
./scripts/install-sync-hook
```

Without it, `bd export` on this machine writes the local Dolt's view over the JSONL — erasing issues created on other machines from the committed file. The hook runs `bd import .beads/issues.jsonl` after every `git pull`/`git checkout`, keeping local Dolt in sync with what other machines have published. See `scripts/bd-import-on-pull` and bead `mybd-w16` for the incident that motivated this.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->

## Maintainer PR Review

When triaging, reviewing, landing, closing, or otherwise maintaining pull requests, read and apply [PR_MAINTAINER_GUIDELINES.md](PR_MAINTAINER_GUIDELINES.md). The maintainer policy is to maximize community throughput: find useful contributor value, absorb or transform it locally when practical, preserve attribution, and use request-changes only as a last resort.

## PR Hygiene (CRITICAL)

**One issue per PR, one PR per issue. No piggybacking.**

### Branch base for upstream PRs

(Applies inside `bd-main/`, not the cwd `mybd` repo.) `origin` is `maphew/beads` (fork) and `upstream` is `gastownhall/beads`. `origin/main` may diverge from `upstream/main`. When creating branches for PRs that target **upstream** (gastownhall/beads):

```bash
git fetch upstream
git checkout -b fix/NNNN-description upstream/main
```

**NEVER branch from `origin/main` or local `main` for upstream PRs** — that
drags in every fork-only commit and pollutes the PR history.

Before opening the PR, verify: `git log --oneline HEAD --not upstream/main`
should show ONLY your commits.

### Worktree / agent branches

When spawning agents with `isolation: "worktree"`, the worktree is created
from the current HEAD. If HEAD is not on `upstream/main`, the agent must
rebase onto `upstream/main` before pushing:

```bash
git fetch upstream
git rebase --onto upstream/main origin/main <branch>
```

## Build & Test

(Run inside `bd-main/`.)

```bash
go build -o bd ./cmd/bd          # build
go test -short ./...             # fast tests
go test ./...                    # full suite (before committing)
go test -race ./...              # with race detection
```

## Architecture Overview

_Add a brief overview of your project architecture_

## Conventions & Patterns

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.
