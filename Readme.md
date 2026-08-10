# mybd — personal coordination repo for Beads work

This repo (`maphew/mybd`) holds issue tracking, notes, reports, and agent
configuration for my work on [Beads](https://github.com/gastownhall/beads). It
is **not** the Beads source tree.

I am a **contributor** to Beads, not a maintainer (stepped down 2026-08-10).
This repo opens PRs and files issues upstream; it does not merge, close, label,
or triage other people's work.

## Layout

| Path | What |
|------|------|
| `.beads/` | bd (Beads) issue database — Dolt-backed, synced via `bd dolt push`/`pull` |
| `.bare/` | bare object store for the Beads source (`origin` = `maphew/beads`, `upstream` = `gastownhall/beads`) |
| `bd-main/` | main worktree of `.bare` — where code edits, builds, and PRs happen |
| `.worktrees/beads/` | throwaway Beads source worktrees |
| `.worktrees/mybd/` | worktrees for commits to *this* repo |
| `scripts/` | helper scripts (see `scripts/README.md`) |
| `reports/` | session reports — the retroactive "why" behind decisions |
| `retro/` | agent-collaboration retrospectives |
| `archive/` | superseded policy kept for reference |

`.bare/`, `bd-main/`, and `.worktrees/` are gitignored.

Note `bd-main/` is a **worktree**, not a nested clone: `bd-main/.git` is a
gitfile pointing at `.bare/`, and shared config (remotes, `core.hooksPath`)
lives in `.bare/config`.

## Working here

```bash
bd prime                  # load Beads context
bd ready                  # what's available
scripts/check-beads-config
```

Commits to this repo go through a worktree on a topic branch, then merge
directly to `main` — no PRs here, there is no second reviewer:

```bash
git worktree add .worktrees/mybd/<purpose> -b <branch>
# ...work, commit...
git merge --no-ff <branch> && git push    # from the root checkout
```

Beads source worktrees take an **absolute** path (a relative one resolves
against `bd-main/`):

```bash
git -C bd-main worktree add "$PWD/.worktrees/beads/<purpose>" <branch>
```

**Never `rm -rf` a path from `git worktree list`** — that list includes `.bare`
itself. Use `git worktree remove`, and snapshot with
`git bundle create <file> --branches` before any bulk prune.

## Agent instructions

See [AGENTS.md](AGENTS.md) (shared) and [CLAUDE.md](CLAUDE.md) (Claude Code
entrypoint). Agents track all work in bd — no markdown TODO lists.

## Notes

`bd dolt pull` / `bd dolt push` work but are slow (roughly 20-30 seconds) and
must be run serially. Do not fresh-bootstrap this repo or run unbounded Dolt
remote operations; see [dolthub/dolt#11236](https://github.com/dolthub/dolt/issues/11236)
and bead `mybd-iihf`.
