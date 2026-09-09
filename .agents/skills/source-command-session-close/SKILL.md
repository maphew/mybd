---
name: "source-command-session-close"
description: "Run the migrated session-close command: verify cold-start readiness, repair durable Beads handoff gaps, run the mechanical backstop, and complete the repository's standard close/push workflow."
---

# Source command: session-close

Use this skill when the user asks to run the migrated source command
`session-close`.

## 1. Judge cold-start readiness

Answer each question for the current session, then act on any gap:

1. What did this session learn that changes how a future agent works? Put that
   knowledge in `bd remember`, not only in a report.
2. Is every deliverable or report reachable from an open bead or a memory? Add
   a durable pointer when one is visible only from a closed bead.
3. Does any touched bead express ordering such as "after", "gated on", or
   "once X lands" only in prose? Encode that ordering with `bd dep add`.

The goal is to orient a fresh agent that reads only `bd prime` and `bd ready`.
See the Cold-start handoff section of `AGENTS.md` for repository policy.

## 2. Run the mechanical backstop

Use the repository-required shell. From Git Bash, run:

```bash
scripts/session-close-check
```

From PowerShell on Windows, invoke that same script explicitly through Git Bash:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' scripts/session-close-check
```

Treat each `WARN:` as a prompt to fix or consciously accept, not as a blocker.
Re-run until clean or until every remaining warning is explicitly accounted for.

## 3. Complete the session

Follow the Session Completion protocol in `AGENTS.md`, including its quality,
tracker, commit, Dolt-sync, Git-push, and final-status requirements. Report what
a fresh agent should pick up next.
