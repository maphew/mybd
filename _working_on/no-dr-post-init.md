Mine:

Fundamental principle: A project aiming to use beads should have ZERO doctor issues after initialization.

In a clean room, `bd init` followed by `bd doctor` should green across the board.

Make it so.

This is likely a big Epic. Plan accordingly.
Create issues for every error and warning. 
When that's done, work through the list and fix them by handing off to sub-agents, opening a worktree fix branch for each one.
Trigger hand-off when context window reaches 70% consumed (soft limit).

You are finished when there are no errors and warnings, save a final report to History.

---

Enhanced (and edited):

mybd: ~/dev/mybd
scratch: ~/dev/mybd/scratch
system bd binary: ~/.local/bin/bd
dev bd binary: ~/dev/mybd/bd-main/bd, ~/dev/mybd/fix-<issue>/bd, etc.

Create a comprehensive Epic plan to achieve zero doctor issues for a beads-using project in a clean environment (~/dev/mybd/scratch). 

Begin running `bd init` in a new directory to initialize the beads tracking system.
Then execute `bd doctor` to identify all errors and warnings. 

Document every single error and warning as separate issues in mybd, categorizing them by severity and type. 

Once all issues are created, systematically work through each one, creating a dedicated worktree fix branch for each fix attempt. 

IMPORTANT: Always maintain clear awareness of which build directory you are working with at any given time. You must distinguish between the system build directory (system bd) and fix-in-progress development build directory (development bd). The system build directory should be used exclusively for managing issues, running builds, and performing development tasks within the mybd project root. Never use the development build directory for managing issues in the mybd project root - reserve it only for testing and implementing fixes in progress. Before executing any build commands or making changes to the project, verify which build directory context you are in and ensure you are using the appropriate one for the task at hand. If you are uncertain about which build directory to use, default to the system build directory for project root operations.

ALWAYS use system bd with `--no-db` flag (conversely, never use `--no-db` with development bd)

For each issue, engage sub-agents with the specific context needed to diagnose and resolve the problem.
Monitor the context window consumption throughout this process and trigger a handoff to fresh sub-agents when the context reaches 70% (soft limit), preserving all accumulated knowledge in the transition. 

Continue this cycle of issue identification, branch creation, sub-agent handoff, and fixing until `bd doctor` returns zero errors and warnings across the board.

Upon achieving a completely green doctor output, generate a final comprehensive report detailing all issues discovered, all fixes applied, all branches created, and confirmation of the zero-error final state, then save this report to ./History/ for future reference.
