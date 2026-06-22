# Beads Git Worktree Setup

This directory uses git worktrees to manage multiple branches efficiently.

## Structure

- `.git/` - This metadata repository (`maphew/mybd`)
- `main/` - Main `maphew/beads` worktree
- Other branches can be added as additional worktrees at this level

## Creating a New Worktree

```powershell
git -C main worktree add ../feature-name -b feature-name
cd ../feature-name
# start hacking
```

Or from the root directory:
```powershell
git worktree add ./feature-name -b feature-name
cd ./feature-name
```

## Switching Between Worktrees

Each worktree is independent. Simply `cd` into the desired directory:
```powershell
cd bd-main
cd feature-name
```

## Listing Worktrees

```powershell
git -C main worktree list
```

## Removing a Worktree

```powershell
git -C bd-main worktree remove feature-name
```

Or remove the directory and prune:
```powershell
Remove-Item -Recurse feature-name
git -C main worktree prune
```

## Notes

- Each worktree has its own working directory state but shares the repository history
- Branches checked out in one worktree cannot be checked out in another simultaneously
- See the [beads repository](https://github.com/maphew/beads) for development guidelines
- mybd remote sync note: the existing `A:\dev\mybd` clone is repaired; `bd dolt pull` / `bd dolt push` work but are slow (roughly 20-30 seconds) and must be run serially. Do not fresh-bootstrap/clone this repo or run unbounded Dolt remote operations; see [dolthub/dolt#11236](https://github.com/dolthub/dolt/issues/11236) and bead `mybd-iihf`.

## Current Worktrees

- **main**: from steveyegge/beads. Sync frequently, don't change (always branch first)

## Metadata

- **_working_on/**: {worktree}.md - the current area of focus. Ephemeral, move into history when done.
- **_history/**: {worktree}/{worktree}_yyyy-mm-dd.md - where date is last-modified
