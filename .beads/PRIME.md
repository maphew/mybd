# Beads session rules (mybd)

- Profile: **team-maintainer** (`agent.profile` in bd config). Commit, `bd dolt push`,
  and `git push` are routine work; an explicit in-prompt "do not commit/push" overrides.
- Track ALL work in bd (`bd ready` / `create` / `--claim` / `close`). No TodoWrite,
  no markdown TODOs. `bd remember` for cross-session knowledge; search with
  `bd memories <keyword>` (never bare `bd config list` — it dumps all memories, 64KB).
- Session close: close finished beads → quality gates → commit → `bd dolt push` →
  `git push` → `scripts/session-close-check`.
- Commands: `bd --help` (70+); workflow details in AGENTS.md.
