# Project Instructions for AI Agents — Claude Code

@AGENTS.md

Shared cross-agent instructions live in [AGENTS.md](AGENTS.md) (imported above): conventions, signing, the bd issue-tracker workflow, session-completion protocol, and maintainer PR review. This file adds only the deeper operational detail specific to this repo's beads/upstream workflow.

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

> The bd issue-tracker workflow and the mandatory session-completion / push protocol are defined in [AGENTS.md](AGENTS.md) (imported at the top of this file).

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
