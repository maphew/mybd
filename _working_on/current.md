Title: frictionless beads init workflow

Description: goal: remove all friction from a new beads initialization workflow. e.g. starting from scratch create a new project, initialise beads, and run through all core bd commands. Create issues for every error and warning. When that's done, work through the list and fix them using sub-agents, opening a worktree fix branch for each one.

✓ Created issue: mybd-6o6
  Title: frictionless beads init workflow
  Priority: P2
  Status: open

Issue completed, next is to test that it worked:

The branch 'bd-init-combined-fixes' contains all of the work from above. The bd.exe in current dir is built from it.

  ❯ ./bd version
  bd version 0.49.6 (ab248fa0: bd-init-combined-fixes@585777b8810b)

Goal: remove all friction from a new beads initialization workflow. e.g. starting from scratch create a new project, initialise beads, and run through all core bd commands. Create issues for every error and warning. When that's done, work through the list and fix them by handing off to sub-agents, opening a worktree fix branch for each one.

When there are no errors and warnings, save a report to History, and use it to open a PR upstream using gh cli.
