# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd prime` for full workflow context.

> **Role note (2026-08-10).** maphew stepped down as a Beads maintainer and is
> now a normal contributor to `gastownhall/beads`. This repo no longer merges,
> closes, labels, or triages upstream work, and the five scheduled automation
> lanes (pr-babysit, verify-babysit, solo-sweep, tri-daily, reap-test-debris)
> were stopped and deleted. The maintainer-era policy is preserved unchanged at
> [archive/PR_MAINTAINER_GUIDELINES.md](archive/PR_MAINTAINER_GUIDELINES.md) for
> reference — do not apply it. See bd memory `maintainer-role-stepped-down`.

## Conventions

"gh ..." : use gh cli to interact with GitHub
"gh {number} ..." : use gh cli on gastownhall/beads repo for issue or PR {number}
"bd ..." : use bd cli to interact with beads

When scripting over bd output, prefer `scripts/bdj <args>` over `bd <args>
--json`: it normalizes the output shape to always be a JSON array (object ->
[object], empty -> []), ending the jq shape-guessing failures (retro F-004).
For any counting, pass `-n 0` - bd listing commands silently cap at 100 rows.

## Repository Layout

The cwd (`~/dev/mybd/`, repo `maphew/mybd`) is a personal coordination repo,
**not** the beads source tree. In these instructions, `<mybd-root>` means the
root of this coordination repo, wherever it is cloned on the current machine.

The beads source is a **bare repo at `.bare/` with `bd-main/` as its main
worktree** (both gitignored). This is not a nested clone — `bd-main/.git` is a
gitfile pointing at `.bare/`, and repo-wide config such as `core.hooksPath` and
the remotes live in `.bare/config`.

| Path | `origin` | `upstream` | Purpose |
|------|----------|------------|---------|
| `~/dev/mybd/` | `maphew/mybd` | - | Coordination: beads issues, notes, agent config |
| `~/dev/mybd/.bare/` | `maphew/beads` (fork) | `gastownhall/beads` | Beads object store |
| `~/dev/mybd/bd-main/` | (worktree of `.bare`) | | Beads source - code edits, builds, PRs happen here |

In `bd-main/`, `main` tracks `upstream/main`; topic branches push to `origin`
(the fork). Do not add a `gastownhall` remote to the cwd repo.

**Never `rm -rf` a path that came out of `git worktree list`.** That list
includes the bare repo itself (`.bare`), and a delete-loop over it destroys the
object store for every worktree at once. Use `git worktree remove`, skip any
entry flagged `bare`, and take a `git bundle create <file> --branches` snapshot
before any bulk prune. Written down 2026-08-10 because exactly this happened;
the bundle is what made it recoverable.

### Worktree Location

Use git worktrees by default, but do not create sibling review/source worktrees
at the `mybd/` repo root.

For Beads source worktrees:

```bash
git -C bd-main worktree add /abs/path/to/<mybd-root>/.worktrees/beads/<short-purpose> <branch>
```

Pass an **absolute** path: a relative path resolves against the git process's
cwd (i.e. `bd-main/`), silently creating `bd-main/.worktrees/...`.

The `mybd/` root should contain only the coordination repo files, the `.bare/`
object store, the `bd-main/` worktree, and ignored container directories such
as `.worktrees/`.

#### Coordination-repo worktrees

Coordination-repo work that makes **git commits** must run from a worktree on a
topic branch:

```bash
git worktree add .worktrees/mybd/<short-purpose> -b <branch>
```

Pure **bead-only** sessions may stay in the root checkout: bead state syncs via
Dolt (`bd dolt push`/`pull`), not git, so those sessions make no commits to
race over.

Why: on 2026-05-29 two agents shared the root checkout; one ran `git checkout`
mid-session, racing the other's commits.

##### Landing a coordination-repo branch

Finish the job: a topic branch is a workspace, not a deliverable. **Merge it to
`main` locally and push — do not open a PR against `maphew/mybd`.**

```bash
git -C <mybd-root> merge --no-ff <branch>   # from the root checkout
git -C <mybd-root> push
git worktree remove .worktrees/mybd/<short-purpose>
git branch -d <branch>
```

This is a single-owner repo: a PR here has no reviewer, so it is a queue with
nobody serving it. Reports in particular go straight to `main`. PRs remain
right for `gastownhall/beads`, where there genuinely is review.

If you cannot land — dirty tree, a decision you need the owner to make — say so
in the handoff **and** file a bead naming the branch. An unlanded branch that
nothing points at is invisible to the cold-start path (`bd ready`).

Worktrees do NOT isolate `git stash`: the stash stack is shared repo-wide.
Agents working in parallel worktrees must not use bare `git stash` — use
`git stash push -m "<branch>-<purpose>"` and apply by exact ref, or commit WIP.

## Contributing upstream

We open PRs against `gastownhall/beads` like any other contributor. We do not
merge, close, label, or request-changes on anyone's PR, and we do not triage
the upstream issue queue.

Before opening a PR, check whether the work already exists — including in this
machine's own unpushed state, which `gh pr list` cannot see:

```bash
bd-main/scripts/pr-preflight.sh --search "<topic keywords>" --repo gastownhall/beads
git -C bd-main log --all --oneline --since=3.days -- <path you are about to edit>
```

The path-scoped query matters: parallel sessions commit locally before pushing,
so "is there an open PR for this?" and "is anyone already doing this?" are
different questions.

### Cross-vendor review before an upstream PR

Run a second model family over the diff before `gh pr create`:

```bash
scripts/pr-open -C <worktree> --base main --search "<topic keywords>"
```

It runs the preflight, then `codex-agent reviewer --diff` on the branch, and
writes findings to `.worktrees/.review-logs/<head-sha>.md`. **Reconcile the
findings before posting** — ask of each "is this a regression or pre-existing?"
A single reviewer's severity ranking is not a verdict.

`scripts/pr-review-gate` (a `PreToolUse` hook in `.claude/settings.json`) blocks
`gh pr create` until a review log exists for the **exact commit** proposed;
amending re-arms it. It stands down when codex is not on PATH. To skip
deliberately, prefix with `MYBD_SKIP_XVENDOR=1` and say why in the handoff.
Smoke-test with `scripts/test-pr-review-gate`.

This matters more as a contributor than it did as a maintainer: nobody here can
wave a rough PR through.

### After a PR is open

Our own open PRs are the contribution surface — they do not merge themselves and
no patrol watches them any more. Keep them rebased and green, respond to review,
and close ones you no longer want rather than leaving them to rot.

## Validation

Run the suite locally before proposing a change. There is no queue and no
babysitter; long runs block the session that started them, so scope tests to
what you touched and run the full suite when it is worth the wait.

Test runs leak `dolt sql-server` processes and temp trees into `$TMPDIR`.
Nothing reaps them automatically any more — check for and clean up your own
debris after heavy runs:

```bash
pgrep -af 'dolt sql-server'
du -sh "${TMPDIR:-/tmp}"/beads-bd-tests-* 2>/dev/null
```

Only kill current-user servers rooted in the suite's own temp-dir patterns, and
never one younger than a run that might still be live.

On hosts where /tmp is a small tmpfs (observed 2026-07-31: 20G tmpfs at 78%,
linker died with 'No space left on device' - a failure that looks nothing like
a disk problem), point Go's scratch space at the home disk before heavy builds
or test runs:

```bash
export GOTMPDIR="$HOME/.cache/gotmp" GOCACHE="$HOME/.cache/gocache"
mkdir -p "$GOTMPDIR" "$GOCACHE"
```

scripts/codex-agent already does this for delegated builds; in-session runs
must do it themselves. Sweep beads-bd-tests-* dirs older than a day.

### Windows / Daily Housekeeping

On Windows, confirm the `bd` on `PATH` is the expected version before running
housekeeping or bead commands:

```powershell
Get-Command bd
bd --version
Get-Content .beads/.local_version
```

The repo-local source build is `bd-main\bd.exe`. If `bd --version` is older
than `.beads/.local_version`, replace the stale PATH binary at
`C:\Users\Matt\.local\bin\bd.exe` with the repo-local binary, after confirming
no `bd` process is running. Keep a backup named for the old version.

Several repo scripts are Bash scripts. From PowerShell, run them through Git
Bash rather than invoking them directly, or prefer the `.ps1` wrapper beside the
extensionless script:

```powershell
scripts/check-beads-config.ps1
```

Run embedded-Dolt `bd`/`dolt` commands serially in this repo. Parallel `bd`
commands can leave Git helper processes or embedded-Dolt locks behind.

Daily start routine:

```powershell
git pull --rebase
bd prime
& 'C:\Program Files\Git\bin\bash.exe' scripts/check-beads-config
bd context --json
git -C bd-main fetch --all --prune
bd ready
bd list --status=in_progress
```

If a newer `bd` refuses to auto-apply pending schema migrations on this
remote-backed database, do not override it casually. Do not run
`BD_ALLOW_REMOTE_MIGRATE=1` unless you are explicitly acting as the single
designated migrator.

If `bd list` unexpectedly appears empty, do not restore `.beads` blindly. Run
`scripts/check-beads-config`; the live local database is
`.beads/embeddeddolt/mybd` (issue prefix `mybd-`, synced via the Dolt remote to
maphew/mybd), and stale config can point `bd` at the empty `beads` bootstrap
database. For the narrow known drift case, run
`scripts/check-beads-config --fix`. Use `scripts/pre-commit-beads-config` in
local commit hooks to reject accidental `.beads/metadata.json` changes away from
`mybd`; intentional renames require `MYBD_ALLOW_DB_RENAME=1`.

### General hygiene pass

The routine above is a **floor, not a ceiling**. After the pinned checks, spend
one pass on general hygiene and use judgment about what else looks crufty:

```bash
git worktree list                 # stale/abandoned worktrees (both repos)
git branch --merged main          # local branches already merged
git branch -vv | grep ': gone'    # local branches whose upstream was deleted
git stash list                    # forgotten stashes (shared across worktrees!)
git status --ignored=matching -- . 2>/dev/null | tail -20  # stray untracked cruft
```

Posture: **notice and report; delete only the obviously dead.** Anything
ambiguous goes in the handoff (or a bead) instead of the trash.

Close the pass with: **"What did I notice that isn't on any list?"** — and put
the answer in the session report.

## Agent Delegation: tier subagent models by task complexity

**Owner directive (maphew, 2026-07-03).** Sessions start on a smart model to
understand the problem and build the plan; execution is then delegated to
subagents on the cheapest model adequate for each piece. Pick the tier
deliberately — do not default everything to the session model.

Named tiers live in `.claude/agents/`:

- **scout** (GPT-5.6 Terra, medium reasoning, read-only) — searches, file
  inventories, "where is X", summarizing files, running read-only bd/git
  commands or tests and reporting output verbatim. Prefer calling
  `scripts/codex-agent scout -o <file> "<task>" </dev/null` directly from the
  orchestrator.
- **builder** (sonnet, can edit) — well-scoped implementation with a clear
  spec: exact files named, acceptance criteria stated. Give it a spec, not a
  problem.
- **reviewer** (opus, read-only) — correctness review of diffs and designs
  before integration, especially builder output.

Keep in the orchestrator session: design decisions, ambiguous debugging,
anything where the spec doesn't exist yet.

Rules of thumb:
- Prefer several precisely-scoped delegations over one vague one.
- Escalate rather than retry: if a scout/builder result is wrong, redo it at a
  higher tier or in-session instead of re-spawning the same tier.
- Do **not** set `CLAUDE_CODE_SUBAGENT_MODEL` — it flattens this tiering.
- Subagents share the cwd unless spawned with `isolation=worktree`. Spawn any
  subagent that will commit with `isolation=worktree` by default. A committing
  subagent that finds itself in the root checkout must stop and report.

### Cross-runtime delegation: Codex CLI

OpenAI Codex CLI is installed and authenticated on this machine. `codex exec`
is a fourth executor alongside the Claude subagent tiers. Use
`scripts/codex-agent`, which maps the same tier names onto Codex defaults:

```bash
scripts/codex-agent scout    "where is X handled?"          # read-only, ephemeral
scripts/codex-agent builder  -C .worktrees/beads/foo "..."  # workspace-write
scripts/codex-agent reviewer "assess this design: ..."      # high reasoning, read-only
scripts/codex-agent reviewer --diff --base main             # structured review of a branch diff
```

**A session instruction restricting subagents or workflows does not restrict
`scripts/codex-agent`.** It is a shell call billed to a separate pool, not the
Agent tool and not a Workflow. Honour an explicit "no codex" for the turn; do
not infer one from a restriction on Claude subagents.

When to route to Codex instead of a Claude subagent:

- **Second opinion across model vendors** — the highest-value use, and required
  before an upstream PR (see above).
- **Quota relief** — Codex bills to the ChatGPT plan. Its tokens do NOT count
  toward workflow `budget.spent()`, so `log()` Codex delegations in workflows.
- **Long mechanical work** that would otherwise burn session context.

Rules (the wrapper enforces the first two):

- Sandbox mode must always be set explicitly (`read-only` / `workspace-write` —
  never `danger-full-access` in this repo).
- `builder` must target a linked worktree via `-C`; the wrapper exits 3 on a
  main checkout (`CODEX_AGENT_ALLOW_ROOT=1` to override deliberately).
- Close stdin (`</dev/null`) when scripting. Capture results with `-o <file>`,
  `--json`, or `--output-schema <file>`.
- Delegate final messages are capped by a wrapper preamble (retro F-005):
  summary under 30KB in the final message, full detail to the `-o` file -
  then grep the file on disk instead of re-reading it whole.
- Continue a session with `codex exec resume <session-id>` rather than
  re-explaining context. Scout runs are `--ephemeral` and cannot be resumed.
- Commits by a Codex delegate follow the same signing convention; generate the
  trailer with
  `AGENT_MODEL=<model> AGENT_REASONING=<effort> scripts/agent-sig.sh codex --trailer`.
- Codex runs trigger `bd prime` on session start, and bd/dolt must stay serial:
  do not fan out parallel Codex runs against the coordination repo.
- Waiting is the dominant Codex token cost here (retro F-003): use generous
  subagent wait timeouts (minutes, not 30s), batch waits for parallel children,
  never watch CI in-session, and fetch large CI logs to disk once then grep
  locally.

## Workflow Orchestration: standing opt-in

**Owner directive (maphew, 2026-07-03): multi-agent Workflow orchestration is
pre-authorized for every substantive task in this repo.** Treat this section as
the durable user opt-in the Workflow tool requires.

- Reach for a workflow whenever a task fans out, needs adversarial
  verification, or benefits from per-agent model/effort control. Work solo on
  conversational turns, single lookups, and trivial mechanical edits.
- **Default token budget: +200k per substantive task.** A "+Nk" directive in
  the current prompt overrides it. Workflow scripts must self-enforce:
  `const TARGET = budget.total ?? 200_000`.
- **The 200k default is a soft performance target, not a reliability ceiling.**
  Overrunning it to complete a required verification stage is correct; silently
  *skipping* a required stage to stay under target is the failure mode.
  - `budget.spent()` is shared across ALL workflows in the turn. A later
    workflow must subtract earlier spend explicitly.
  - **Validate stage aggregates before acting on them.** `parallel()` and
    `pipeline()` resolve failed agents to `null`. Always `.filter(Boolean)`,
    schema-check shape before mutating stages, and `log()` how many items were
    dropped.
- Tier `agent()` calls per the delegation policy: `model: 'haiku',
  effort: 'low'` for mechanical stages; inherit for design/judge/verify.
- Run bd/dolt operations serially inside workflows.
- A *current* prompt saying "no workflow" / "keep it cheap" wins for that turn.

When a bead is correlated with a gh issue or PR, check for drift.

When upstream beads work changes product surface area, read
[bd-main/engdocs/PROJECT_CHARTER.md](bd-main/engdocs/PROJECT_CHARTER.md).

Assume you are not working alone.
Use git worktrees by default.
Write reports as md only — no html twins (policy 2026-07-07; read long Markdown
with [`mdo`](https://github.com/maphew/mdo)). Reports are tracked in git
deliberately: they are the retroactive "why" record behind decisions that commit
messages don't carry.

Answer 'why' when opening a PR.

When creating or editing GitHub PR, issue, comment, or review bodies:
- Write Markdown to a file and use `gh ... --body-file`; do not pass multiline
  bodies via inline shell strings.
- Use `#1234` or `owner/repo#1234`, not `GH#1234`, in GitHub-facing text.
- Run `<mybd-root>/scripts/gh-body-lint <body-file>` before posting.

### Signing

- Sign GitHub comments using:
  `_{agent_runtime}-{model}-{reasoning} on behalf of {user}_`
- Sign commits with a trailer:
  `Agent-Signature: {agent_runtime}-{model}-{reasoning} on behalf of {user}`
- Generate the line with `<mybd-root>/scripts/agent-sig.sh` (add `--trailer`).
- **Run it via the Bash tool / Git Bash, never the PowerShell tool.** The
  `{reasoning}` field is read from `CLAUDE_EFFORT`, exported only into
  Bash-tool subprocesses; a PowerShell-tool invocation silently produces
  `unknown-reasoning`. There is intentionally no `.ps1` wrapper.
  ```bash
  scripts/agent-sig.sh --trailer
  ```
- Do not infer `{model}` or `{reasoning}` from defaults, model cache, prompt
  text, or memory. If reliable metadata is unavailable, keep the
  `unknown-model` / `unknown-reasoning` placeholders rather than guessing.

For Amp, read session metadata from the local Amp state, not from the system
prompt or memory. The active thread id is in `AMP_CURRENT_THREAD_ID`.

- **Reasoning** and **agent mode** come from the per-turn `agent_state` log
  lines in `~/.cache/amp/logs/cli.log` (`reasoningEffort`, `agentMode`). Fall
  back to `~/.local/share/amp/session.json`.
- **Model** is at `messages[].usage.model` in
  `~/.local/share/amp/threads/$AMP_CURRENT_THREAD_ID.json`. Until the
  in-progress thread is flushed, fall back to the most recently modified thread
  file.

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

Drop only the `claude-` model-family prefix (write `opus-4-6`).

## Git hooks

A tracked, **opt-in** `.githooks/` tree backs the worktree convention: the
root-commit guard (`.githooks/pre-commit`, fires only in the MAIN checkout,
warns by default), `scripts/pre-commit-beads-config`, and the bd hook events.
It is **not** auto-enabled. Turn it on with:

```bash
git config core.hooksPath .githooks
```

`bd hooks install --beads` is known to silently flip `core.hooksPath` to
`.beads/hooks`, deactivating this set — `scripts/check-beads-config` warns on
that drift and `--fix` restores `.githooks`. Smoke-test with
`scripts/test-git-hooks`. Two env knobs tune the root-commit guard:

- `MYBD_ENFORCE_ROOT_GUARD=1` — make a root commit a hard block.
- `MYBD_ALLOW_ROOT_COMMIT=1` — escape hatch for a deliberate root commit.

## Non-Interactive Shell Commands

**ALWAYS use non-interactive flags** with file operations. `cp`, `mv`, and `rm`
may be aliased to `-i` on some systems, hanging the agent on a y/n prompt.

```bash
cp -f source dest           # NOT: cp source dest
mv -f source dest           # NOT: mv source dest
rm -f file                  # NOT: rm file
rm -rf directory            # NOT: rm -r directory
```

Others that may prompt: `scp`/`ssh` (`-o BatchMode=yes`), `apt-get` (`-y`),
`brew` (`HOMEBREW_NO_AUTO_UPDATE=1`).

## Documentation Regeneration

When regenerating beads CLI doc artifacts, build `bd` with
`CGO_ENABLED=0 -tags gms_pure_go` (or let `scripts/generate-cli-docs.sh` build
its own pinned binary). A default CGO build emits the full `bd federation` help
tree and produces ~500 lines of spurious churn versus CI. Set
`BD_DOCS_ALLOW_CGO=1` only for a deliberate full-federation regen.

## Cold-start handoff

The Session Completion protocol covers the **warm** handoff (prose a human
reads). This covers the **cold** handoff: the next actor is often a fresh agent
that reads only `bd prime` + `bd ready`. Prose in a closed bead or a report is
invisible to it. Before closing a session, self-ask these three:

1. **What did this session learn that changes how a future agent works — and is
   it in `bd remember` (surfaced at `bd prime`), not only in a report?**
2. **Is every deliverable/report this session produced reachable from an OPEN
   bead or a memory?** A pointer that lives only in a *closed* bead is a smell.
   **A branch is a deliverable.**
3. **Does any bead I touched say "after / gated-on / once X lands" in prose but
   lack a dependency edge?** Prose ordering is invisible to `bd ready`.

A warn-only mechanical backstop catches the cheap omissions. It never blocks:

```bash
scripts/session-close-check            # warn, exit 0 (Windows: .ps1)
scripts/session-close-check --strict   # exit non-zero if any warning fired
scripts/session-close-check --since <git-ref|RFC3339>
```

The session boundary comes from `.beads/.session-start` (written by the
`bd prime` SessionStart hook) or `--since`. If bd is unavailable the bd-backed
checks warn-skip. The judgment prompts above are the real work; the script is
only a backstop. `/session-close` runs both.

## Beads Issue Tracker

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
bd dolt push          # Push beads data to remote
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or
  markdown TODO lists
- Run `bd prime` for detailed command reference
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files
- Search memories with `bd memories <keyword>`, never bare `bd config list`

**Architecture in one line:** issues live in a local Dolt DB; sync uses
`refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export.

## Session Completion

1. **File issues for remaining work**
2. **Run quality gates** (if code changed) — tests, linters, builds
3. **Update issue status** — close finished work, update in-progress items
4. **Push to remote**:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status
   ```
5. **Clean up** — clear stashes, prune remote branches
6. **Hand off** — summarize changes, validation, issue status, blocked steps

This repo runs `agent.profile=team-maintainer` (owner directive maphew
2026-07-08): commit, sync, and push are routine work here. That knob is about
*this* repo's git flow and is unaffected by the upstream role change — an
explicit in-prompt "do not commit"/"do not push" still overrides.
