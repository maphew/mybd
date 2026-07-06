---
description: Cold-start-readiness check before ending a work session - runs the 3 judgment prompts plus the mechanical backstop, then the standard close/push.
allowed-tools: Bash(*), Read(*), Grep(*)
---

Run the cold-start handoff before closing this session. The goal: a FRESH agent
that reads only `bd prime` + `bd ready` must be oriented. See the "Cold-start
handoff" section of AGENTS.md.

## 1. Judgment prompts (the real work - answer each in prose)

Answer these honestly for the current session, then act on any gap:

1. **What did this session learn that changes how a future agent works?** Is it
   in `bd remember` (surfaces at `bd prime`), not only in a report? If it's only
   in a report, add a memory with `bd remember`.
2. **Is every deliverable/report reachable from an OPEN bead or a memory?** A
   pointer that lives only in a closed bead is invisible to `bd ready`. If so,
   file or reopen a bead, or add a memory.
3. **Does any bead you touched say "after / gated-on / once X lands" in prose
   but lack a dependency edge?** Encode it with `bd dep add` so `bd ready`
   respects the ordering.

## 2. Mechanical backstop

```bash
scripts/session-close-check
```

Treat each `WARN:` as a prompt to fix (add a memory, reference the report from an
open bead, close/hand off the in_progress bead), not as a blocker. Re-run until
clean or until you've consciously accepted each warning.

## 3. Standard session completion

Then follow the Session Completion protocol in AGENTS.md:

```bash
git pull --rebase
bd dolt push
git push
git status   # MUST show "up to date with origin"
```

Report what a fresh agent should pick up next.
