# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd prime` for full workflow context.

## Conventions

"gh ..." : use gh cli to interact with GitHub
"gh {number} ..." : use gh cli on gastownhall/beads repo for issue or PR {number}
"bd ..." : use bd cli to interact with beads

### Windows / Daily Housekeeping

On Windows, confirm the `bd` on `PATH` is the expected version before running
housekeeping or bead commands:

```powershell
Get-Command bd
bd --version
Get-Content .beads/.local_version
```

The repo-local source build is `bd-main\bd.exe`. If `bd --version` is older
than `.beads/.local_version` and `bd-main\bd.exe` has the expected version,
replace the stale PATH binary at `C:\Users\Matt\.local\bin\bd.exe` with the
repo-local binary, after confirming no `bd` process is running. Keep a backup
named for the old version.

Several repo scripts are Bash scripts. From PowerShell, run them through Git
Bash rather than invoking them directly:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' scripts/check-beads-config
& 'C:\Program Files\Git\bin\bash.exe' scripts/verify-status
```

PowerShell wrappers are also available beside the extensionless scripts. When
staying in PowerShell, prefer the `.ps1` entrypoint:

```powershell
scripts/check-beads-config.ps1
scripts/verify-status.ps1
```

Run embedded-Dolt `bd`/`dolt` commands serially in this repo. Parallel `bd`
commands can leave Git helper processes or embedded-Dolt locks behind.

Daily start routine:

```powershell
git pull --rebase
bd prime
& 'C:\Program Files\Git\bin\bash.exe' scripts/check-beads-config
bd context --json
git -c safe.directory=A:/dev/mybd/bd-main -C bd-main fetch --all --prune
bd ready
bd list --status=in_progress
& 'C:\Program Files\Git\bin\bash.exe' scripts/verify-status
```

If a newer `bd` refuses to auto-apply pending schema migrations on this
remote-backed database, do not override it casually. Do not run
`BD_ALLOW_REMOTE_MIGRATE=1` unless you are explicitly acting as the single
designated migrator. For ordinary housekeeping, record that schema-sensitive
commands are blocked by the migration gate and continue with read-only checks
that do not require migration. Commands such as `bd stats`, `bd blocked`,
`bd stale`, `bd orphans`, and `bd lint` are useful when schema-compatible, but
they are best-effort checks while the local database is behind the current
binary's schema.

If `bd list` unexpectedly appears empty in this coordination repo, do not
restore `.beads` blindly. Run `scripts/check-beads-config`; the live local
database is `.beads/embeddeddolt/mybd` (issue prefix `mybd-`, synced via the
Dolt remote to maphew/mybd), and stale config can point `bd` at the empty
`beads` bootstrap database.
For the narrow known drift case where `.beads/metadata.json` points at empty
`beads` while `mybd` is populated and has the expected remote, run
`scripts/check-beads-config --fix`. If both databases contain issues, export
both and reconcile manually before changing metadata. Use
`scripts/pre-commit-beads-config` in local commit hooks or CI to reject
accidental `.beads/metadata.json` changes away from `mybd`; intentional
database renames require `MYBD_ALLOW_DB_RENAME=1`.

When working on beads, spawn agents according to their metadata hints.
The checked-in Codex skill for those hints is `.codex/skills/beads-delegation-planner/`; use it when inspecting, triaging, tackling, or delegating beads.

## Agent Delegation: tier subagent models by task complexity

**Owner directive (maphew, 2026-07-03).** Sessions start on a smart model to
understand the problem and build the plan; execution is then delegated to
subagents on the cheapest model adequate for each piece. When spawning
subagents, pick the tier deliberately - do not default everything to the
session model. This is a separate axis from the bead metadata hints above:
those hints say *which bead work* to delegate, this says *which model tier* to
run it on.

Named tiers live in `.claude/agents/` - prefer them over ad-hoc spawns:

- **scout** (haiku, read-only) - searches, file inventories, "where is X",
  summarizing files, running read-only bd/git commands or tests and reporting
  output verbatim.
- **builder** (sonnet, can edit) - well-scoped implementation with a clear
  spec: exact files named, acceptance criteria stated. Give it a spec, not
  a problem.
- **reviewer** (opus, read-only) - correctness review of diffs and designs
  before integration, especially builder output.

Keep in the orchestrator session (no delegation, or `inherit`): design
decisions, ambiguous debugging, anything where the spec doesn't exist yet.

Rules of thumb:
- Prefer several precisely-scoped delegations over one vague one - a
  subagent that must rediscover context you already hold wastes more than
  its model tier saves.
- Escalate rather than retry: if a scout/builder result is wrong or the
  task proved harder than scoped, redo it at a higher tier or in-session
  instead of re-spawning the same tier.
- Do **not** set `CLAUDE_CODE_SUBAGENT_MODEL` - it overrides per-spawn
  model choice and flattens this tiering.
- Subagents share the cwd unless spawned with `isolation=worktree`. Spawn any
  subagent that will commit (e.g. builder) with `isolation=worktree` by
  default, and always isolate when more than one edits files in parallel:
  coordination-repo commits belong in a worktree, never the root checkout. A
  committing subagent that finds itself in the root checkout must stop and
  report rather than commit.

### Cross-runtime delegation: Codex CLI

OpenAI Codex CLI is installed and authenticated on this machine (repo
trusted in `~/.codex/config.toml`; `bd prime` fires via `.codex/hooks.json`
in Codex sessions too). `codex exec` is a fourth executor alongside the
Claude subagent tiers, invoked from any runtime via the shell. Use
`scripts/codex-agent`, which maps the same tier names onto Codex
model/sandbox/reasoning defaults:

```bash
scripts/codex-agent scout    "where is X handled?"          # gpt-5.4-mini, low, read-only, ephemeral
scripts/codex-agent builder  -C .worktrees/mybd/foo "..."   # gpt-5.4, medium, workspace-write
scripts/codex-agent reviewer "assess this design: ..."      # gpt-5.5, high, read-only
scripts/codex-agent reviewer --diff --base main             # structured `codex review` of a branch diff
```

When to route to Codex instead of a Claude subagent:

- **Second opinion across model vendors** - reviews, design assessments, and
  bug hunts where an independent model family catches what same-family
  agents miss. This is the highest-value use: pair `codex-agent reviewer`
  with the Claude `reviewer` agent on the same diff and compare.
- **Quota relief** - Codex bills to the ChatGPT plan, a separate pool from
  Claude. Its tokens do NOT count toward workflow `budget.spent()` or a
  "+Nk" directive, so `log()` Codex delegations in workflows instead of
  assuming the budget captured them.
- **Long mechanical work** that would otherwise burn session context.
- **Bead routing hints** - when a bead's `execution_suggested_model`
  metadata names an OpenAI model (e.g. `gpt-5.5`), route that bead's work
  through `codex-agent` at the tier implied by `execution_agent_type` and
  `execution_reasoning_effort` (see `.codex/skills/beads-delegation-planner/`).

Rules (the wrapper enforces the first two):

- Non-interactive Codex never prompts for approval; the sandbox mode must
  always be set explicitly (`read-only` / `workspace-write` /
  `danger-full-access` - never the last in this repo).
- `builder` must target a linked worktree via `-C`; the wrapper exits 3 on
  a main checkout (`CODEX_AGENT_ALLOW_ROOT=1` to override deliberately).
- Close stdin (`</dev/null`) when scripting - with no prompt argument
  `codex exec` reads the prompt from piped stdin, and with one it appends
  stdin as an extra block. Capture results with `-o <file>` (final message),
  `--json` (JSONL events incl. token usage), or `--output-schema <file>`
  (structured output, analogous to workflow `agent()` schemas).
- Continue a builder or reviewer Codex session with
  `codex exec resume <session-id>` (id is printed in the run header) rather
  than re-explaining context. Scout runs are `--ephemeral` and cannot be
  resumed.
- Commits made by a Codex delegate follow the same signing convention;
  from an orchestrating runtime generate the trailer with
  `AGENT_MODEL=<model> AGENT_REASONING=<effort> scripts/agent-sig.sh codex --trailer`.
- The escalation rule above applies across runtimes: a wrong Codex scout or
  builder result gets redone at a higher tier (either vendor) or
  in-session, not re-spawned at the same tier.
- Codex runs in this repo trigger `bd prime` on session start, and bd/dolt
  must stay serial: do not fan out parallel Codex runs against the
  coordination repo; parallelize in beads source worktrees instead.

## Workflow Orchestration: standing opt-in

**Owner directive (maphew, 2026-07-03): multi-agent Workflow orchestration
is pre-authorized for every substantive task in this repo.** Treat this
section as the explicit, durable user opt-in that the Workflow tool
requires - do not wait for "use a workflow" or the `ultracode` keyword in
a prompt.

- Reach for a workflow whenever a task fans out (multiple files, beads,
  review dimensions, search angles), needs adversarial verification, or
  benefits from per-agent model/effort control. Work solo only on
  conversational turns, single lookups, and trivial mechanical edits where
  orchestration overhead would exceed the work itself.
- **Default token budget: +200k per substantive task.** A "+Nk" directive
  in the current prompt overrides it. The harness only sets a hard
  `budget.total` from an in-prompt directive, so workflow scripts must
  self-enforce the default:
  `const TARGET = budget.total ?? 200_000` - check `budget.spent()`
  between stages, stop spawning as the target nears, and `log()` any
  coverage dropped because of it.
- Inside workflows, tier `agent()` calls per the delegation policy above:
  `model: 'haiku', effort: 'low'` for mechanical stages; omit overrides
  (inherit) for design, judge, and verify stages.
- For verify/judge stages that benefit from vendor diversity, one agent may
  shell out to `scripts/codex-agent reviewer ... </dev/null` (see
  Cross-runtime delegation above). Codex tokens bypass `budget.spent()`,
  so `log()` each Codex call and keep such runs serial in this repo.
- Run bd/dolt operations serially inside workflows - parallel bd commands
  can leave Git helper processes or embedded-Dolt locks behind.
- A *current* prompt saying "no workflow" / "keep it cheap" wins for that
  turn.

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
- Generate the line with `<mybd-root>/scripts/agent-sig.sh` (add `--trailer` for the commit form). It reads live session metadata for Claude Code and Codex; runtimes it cannot auto-detect pass their name as an argument (e.g. `agent-sig.sh kilocode`) and may supply `AGENT_MODEL` / `AGENT_REASONING` env vars.
- **Run it via the Bash tool / Git Bash, never the PowerShell tool.** For Claude Code the `{reasoning}` field is read from `CLAUDE_EFFORT`, which is exported only into Bash-tool subprocesses - the PowerShell-tool environment lacks it (and bash spawned from there inherits the gap), so a PowerShell-tool invocation silently produces `unknown-reasoning`. There is intentionally no `.ps1` wrapper for this script for that reason; the `.sh` extension signals "run through bash". Invoke it as:
  ```bash
  scripts/agent-sig.sh --trailer
  ```
  or explicitly through Git Bash from elsewhere:
  ```powershell
  & 'C:\Program Files\Git\bin\bash.exe' scripts/agent-sig.sh --trailer
  ```
  The script warns on stderr when it falls back to a placeholder, so heed that warning rather than posting the signature.
- Do not infer `{model}` or `{reasoning}` from defaults, model cache, prompt text, or memory. If reliable metadata is unavailable, keep the script's `unknown-model` / `unknown-reasoning` placeholders rather than guessing.

For Amp, read session metadata from the local Amp state, not from the system prompt or memory. The active thread id is in `AMP_CURRENT_THREAD_ID`.

- **Reasoning** and **agent mode** come from the per-turn `agent_state` log lines in `~/.cache/amp/logs/cli.log` (fields `reasoningEffort` and `agentMode`). Fall back to `~/.local/share/amp/session.json` (`lastReasoningEffortByMode[<mode>]`).
- **Model** is recorded per assistant message at `messages[].usage.model` in the thread state file `~/.local/share/amp/threads/$AMP_CURRENT_THREAD_ID.json`. The in-progress thread may not be flushed yet; until it is, fall back to the most recently modified thread file (same `agentMode` maps to the same model).

```bash
tid="$AMP_CURRENT_THREAD_ID"
src="$HOME/.local/share/amp/threads/$tid.json"
[ -f "$src" ] || src="$(ls -t "$HOME"/.local/share/amp/threads/*.json 2>/dev/null | head -1)"
model="$(jq -r '[.messages[]?.usage?.model // empty] | last // empty' "$src" 2>/dev/null)"
model="${model#claude-}"
line="$(grep -F "\"threadId\":\"$tid\"" "$HOME/.cache/amp/logs/cli.log" 2>/dev/null | grep -F '"reasoningEffort"' | tail -1)"
reasoning="$(printf '%s' "$line" | jq -r '.reasoningEffort // empty' 2>/dev/null)"
mode="$(printf '%s' "$line" | jq -r '.agentMode // empty' 2>/dev/null)"
[ -z "$reasoning" ] && reasoning="$(jq -r --arg m "${mode:-smart}" '.lastReasoningEffortByMode[$m] // empty' "$HOME/.local/share/amp/session.json" 2>/dev/null)"
echo "_amp-${model:-unknown-model}-${reasoning:-unknown-reasoning} on behalf of $(git config user.name)_"
```

The model string carries the `claude-` family prefix; since the runtime field is already `amp`, drop only the `claude-` model-family prefix (write `opus-4-6`, not `claude-opus-4-6`). If the thread file is unreadable or the log has no `reasoningEffort`, use `unknown-model` / `unknown-reasoning` rather than guessing.

## Repository Layout

The cwd (`~/dev/mybd/`, repo `maphew/mybd`) is a personal coordination repo, **not** the beads source tree. In these instructions, `<mybd-root>` means the root of this coordination repo, wherever it is cloned on the current machine. The beads working clone is nested at `bd-main/` (gitignored):

| Path | `origin` | `upstream` | Purpose |
|------|----------|------------|---------|
| `~/dev/mybd/` | `maphew/mybd` | - | Coordination: beads issues, notes, agent config |
| `~/dev/mybd/bd-main/` | `maphew/beads` (fork) | `gastownhall/beads` | Beads source - code edits, builds, PRs happen here |

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

#### Coordination-repo worktrees

The same rule applies to the coordination repo itself, not just `bd-main/`.
Coordination-repo work that makes **git commits** must run from a worktree on a
topic branch, created under the tracked-ignored container parallel to the beads
pattern:

`<mybd-root>/.worktrees/mybd/<short-purpose>`

```bash
git worktree add .worktrees/mybd/<short-purpose> -b feat/<short-purpose>
```

Pure **bead-only** sessions may stay in the root checkout: bead state syncs via
Dolt (`bd dolt push`/`pull`), not git, and `export.auto=false`/no-git-ops means
those sessions make no commits to race over.

Why: on 2026-05-29 two agents shared the root checkout (no worktree); one ran
`git checkout` to a new branch mid-session, racing the other's commits. Working
from a per-task worktree keeps each agent's index and HEAD isolated.

A tracked, **opt-in** pre-commit guard backs this convention:
`.githooks/pre-commit`. It fires only in the MAIN checkout (linked worktrees are
a no-op), warns by default, and points you at the worktree command. It is **not**
auto-enabled. The owner turns it on with:

```bash
git config core.hooksPath .githooks
```

Once enabled it composes with `scripts/pre-commit-beads-config` (chained when
the tracker DB is present). Two env knobs tune it:

- `MYBD_ENFORCE_ROOT_GUARD=1` - make a root commit a hard block instead of a warning.
- `MYBD_ALLOW_ROOT_COMMIT=1` - escape hatch for a deliberate root commit
  (config/policy, `.beads` tracker state, `reports/`).

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

From PowerShell on Windows, invoke these via Git Bash as shown in the Windows
housekeeping section.

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

## Documentation Regeneration

When regenerating beads CLI doc artifacts, build `bd` with `CGO_ENABLED=0 -tags gms_pure_go` (or let `scripts/generate-cli-docs.sh` build its own pinned binary). A default CGO build emits the full `bd federation` help tree and produces ~500 lines of spurious federation churn versus CI, which stubs federation. Set `BD_DOCS_ALLOW_CGO=1` only for a deliberate full-federation regen.

## Cold-start handoff

The Session Completion protocol below covers the **warm** handoff (prose a human
reads). This section covers the **cold** handoff: the next actor is often a fresh
agent that reads only `bd prime` + `bd ready` and starts pulling work. Prose in a
closed bead or a report is invisible to it. Before you close a session, self-ask
these three (answer in the handoff, do not just tick them):

1. **What did this session learn that changes how a future agent works - and is
   it in `bd remember` (surfaced at `bd prime`), not only in a report?** Reports
   are not on the cold-start path; memories are.
2. **Is every deliverable/report this session produced reachable from an OPEN
   bead or a memory?** A pointer that lives only in a *closed* bead is a smell -
   a cold agent runs `bd ready`, not `bd list --status=closed`.
3. **Does any bead I touched say "after / gated-on / once X lands" in prose but
   lack a dependency edge?** Prose ordering is invisible to `bd ready`; encode it
   as a `bd dep` edge or the cold agent will pick blocked work.

A warn-only mechanical backstop catches the cheap omissions (unreferenced new
reports, thin new beads, beads left `in_progress`). It never blocks a close:

```bash
scripts/session-close-check            # warn, exit 0 (Windows: scripts/session-close-check.ps1)
scripts/session-close-check --strict   # exit non-zero if any warning fired
scripts/session-close-check --since <git-ref|RFC3339>   # explicit boundary
```

The session boundary comes from `.beads/.session-start` (written at open by the
`bd prime` SessionStart hook) or `--since`; with neither, the session-scoped
checks are skipped with a warning rather than passing silently. The stamp is a
single file, so concurrent sessions in one checkout share a coarse boundary (the
writer keeps the earlier one within a TTL, erring toward more warnings); pass
`--since <git-ref|RFC3339>` when you need precise scoping. If bd is unavailable
(migration gate / lock) the bd-backed checks warn-skip. The judgment prompts
above are the real work; the script is only a backstop. `/session-close` runs the
prompts and the script together.

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

- Use `bd` for ALL task tracking - do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge - do NOT use MEMORY.md files

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
