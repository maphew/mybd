# Beads Git Worktree Setup

This directory uses git worktrees to manage multiple branches efficiently.

## Structure

- `.git/` - Main git repository data (shared across all worktrees)
- `bd-main/` - Main branch worktree
- Other branches can be added as additional worktrees at this level

## Creating a New Worktree

```powershell
git -C bd-main worktree add ../feature-name -b feature-name
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
git -C bd-main worktree list
```

## Removing a Worktree

```powershell
git -C bd-main worktree remove feature-name
```

Or remove the directory and prune:
```powershell
Remove-Item -Recurse feature-name
git -C bd-main worktree prune
```

## Notes

- Each worktree has its own working directory state but shares the repository history
- Branches checked out in one worktree cannot be checked out in another simultaneously
- See the [beads repository](https://github.com/maphew/beads) for development guidelines
