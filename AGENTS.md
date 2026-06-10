# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd prime` for full workflow context.

## Conventions

"gh ..." : use gh cli to interact with GitHub
"gh {number} ..." : use gh cli on gastownhall/beads repo for issue or PR {number}
"bd ..." : use bd cli to interact with beads

If `bd list` unexpectedly appears empty in this coordination repo, do not
restore `.beads` blindly. Run `scripts/check-beads-config`; the live local
database is `.beads/embeddeddolt/mybd` (issue prefix `mybd-`, synced via the
Dolt remote to maphew/mybd), and stale config can point `bd` at the empty
`beads` bootstrap database.

When working on beads, spawn agents according to their metadata hints.
The checked-in Codex skill for those hints is `.codex/skills/beads-delegation-planner/`; use it when inspecting, triaging, tackling, or delegating beads.

When a bead is correlated with a gh issue or PR, check for drift.

When upstream beads work changes product surface area, read
[bd-main/docs/PROJECT_CHARTER.md](bd-main/docs/PROJECT_CHARTER.md). Beads owns
issue tracking primitives; route orchestration policy outside beads core and
prefer metadata before schema when the data is workflow-specific.

Before implementing related upstream beads work, opening a competing PR, or
merging/closing a PR, run the upstream PR preflight when applicable:

```bash
bd-main/scripts/pr-preflight.sh --search "<topic keywords>" --repo gastownhall/beads
bd-main/scripts/pr-preflight.sh <pr-number> --repo gastownhall/beads
```

Assume you are not working alone.
Use git worktrees by default.
In reports, default to both html and md.

Answer 'why' when opening a PR.
PR maintenance policy: [PR_MAINTAINER_GUIDELINES.md](PR_MAINTAINER_GUIDELINES.md)

When creating or editing GitHub PR, issue, comment, or review bodies:
- Write Markdown to a file and use `gh ... --body-file`; do not pass multiline bodies via inline shell strings.
- Use `#1234` or `owner/repo#1234`, not `GH#1234`, in GitHub-facing text.
- Run `<mybd-root>/scripts/gh-body-lint <body-file>` before posting; fix literal `\n` sequences and non-linking issue refs first.

### Signing

- Sign GitHub comments using:
  `_{agent_runtime}-{model}-{reasoning} on behalf of {user}_`
- Sign commits with a trailer:
  `Agent-Signature: {agent_runtime}-{model}-{reasoning} on behalf of {user}`
- Generate the line with `<mybd-root>/scripts/agent-sig` (add `--trailer` for the commit form). It reads live session metadata for Claude Code and Codex; runtimes it cannot auto-detect pass their name as an argument (e.g. `agent-sig kilocode`) and may supply `AGENT_MODEL` / `AGENT_REASONING` env vars.
- Do not infer `{model}` or `{reasoning}` from defaults, model cache, prompt text, or memory. If reliable metadata is unavailable, keep the script's `unknown-model` / `unknown-reasoning` placeholders rather than guessing.

## Repository Layout

The cwd (`~/dev/mybd/`, repo `maphew/mybd`) is a personal coordination repo, **not** the beads source tree. In these instructions, `<mybd-root>` means the root of this coordination repo, wherever it is cloned on the current machine. The beads working clone is nested at `bd-main/` (gitignored):

| Path | `origin` | `upstream` | Purpose |
|------|----------|------------|---------|
| `~/dev/mybd/` | `maphew/mybd` | — | Coordination: beads issues, notes, agent config |
| `~/dev/mybd/bd-main/` | `maphew/beads` (fork) | `gastownhall/beads` | Beads source — code edits, builds, PRs happen here |

In `bd-main/`, `main` tracks `upstream/main`; topic branches push to `origin` (the fork). Do not add a `gastownhall` remote to the cwd repo.

### Worktree Location

Use git worktrees by default, but do not create sibling review/source worktrees at the `mybd/` repo root.

For Beads source worktrees, create them under the tracked ignored directory:

`<mybd-root>/.worktrees/beads/<short-purpose>`

Example:

```bash
git -C bd-main worktree add ../.worktrees/beads/pr-4028-review <branch>
```

The `mybd/` root should contain only the coordination repo files, the nested `bd-main/` clone, and ignored container directories such as `.worktrees/`.

### Local Verification Queue

Long beads source validation must not block implementation agents unless they
are actively debugging a failure. Agents working in beads source worktrees
should use this handoff:

1. Run fast local preflight in the implementation worktree: targeted tests,
   build, format/lint checks when cheap.
2. Commit or otherwise freeze the candidate. The worktree must be clean.
3. Enqueue slow validation instead of waiting on it:
   ```bash
   <mybd-root>/scripts/verify-enqueue <bd-id> <mybd-root>/.worktrees/beads/<worktree> "make test"
   ```
4. Stop blocking on the long suite. The bead is not complete until verification
   passes for the recorded `verify_head` or a maintainer explicitly overrides
   the gate.

The verifier runs locally, without GitHub Actions or status polling:

```bash
scripts/verify-status
scripts/verify-next          # runs one queued job
```

`verify-next` creates a clean detached worktree under
`<mybd-root>/.worktrees/beads/verify-*`, runs the recorded
`verify_cmd`, stores logs under `.worktrees/beads/.verify-logs/`, and writes
`verify_state=passed|failed` plus result metadata back to bd. Keep full-suite
concurrency low by default; Beads/Dolt tests are process and disk heavy.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work atomically
bd close <id>         # Complete work
bd dolt push          # Push beads data to remote
```

## Non-Interactive Shell Commands

**ALWAYS use non-interactive flags** with file operations to avoid hanging on confirmation prompts.

Shell commands like `cp`, `mv`, and `rm` may be aliased to include `-i` (interactive) mode on some systems, causing the agent to hang indefinitely waiting for y/n input.

**Use these forms instead:**
```bash
# Force overwrite without prompting
cp -f source dest           # NOT: cp source dest
mv -f source dest           # NOT: mv source dest
rm -f file                  # NOT: rm file

# For recursive operations
rm -rf directory            # NOT: rm -r directory
cp -rf source dest          # NOT: cp -r source dest
```

**Other commands that may prompt:**
- `scp` - use `-o BatchMode=yes` for non-interactive
- `ssh` - use `-o BatchMode=yes` to fail instead of prompting
- `apt-get` - use `-y` flag
- `brew` - use `HOMEBREW_NO_AUTO_UPDATE=1` env var

## Maintainer PR Review

When triaging, reviewing, landing, closing, or otherwise maintaining pull requests, read and apply [PR_MAINTAINER_GUIDELINES.md](PR_MAINTAINER_GUIDELINES.md). The maintainer policy is to maximize community throughput: find useful contributor value, absorb or transform it locally when practical, preserve attribution, and use request-changes only as a last resort.

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
