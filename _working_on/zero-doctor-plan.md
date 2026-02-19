# Zero Doctor Warnings After `bd init` — Orchestration Plan

**Epic:** mybd-71w — Zero doctor warnings after bd init in clean room  
**Date:** 2026-02-19  
**bd version:** 0.54.0

## Situation

After `bd init` in a fresh git repo (clean room: `~/dev/mybd/scratch/cleanroom`), `bd doctor` reports **10 warnings** immediately and **6 warnings** after committing the generated files. The goal is zero.

## Clean Room Reproduction

```bash
mkdir -p ~/dev/mybd/scratch/cleanroom
cd ~/dev/mybd/scratch/cleanroom
git init && git commit --allow-empty -m "initial commit"
bd init
bd doctor          # 10 warnings
git add -A && git commit -m "bd init"
bd doctor          # 6 warnings
bd doctor --fix --yes
bd doctor          # still 6 warnings
```

## Issue Inventory

### Tier 1: Bugs (fix in bd source code)

| Issue | Warning(s) | Category | Priority | Root Cause |
|-------|-----------|----------|----------|------------|
| **mybd-71w.1** | 3× Federation checks fail: "database not found: beads" | FEDERATION/BUG | P1 | Federation queries use hardcoded database name `beads` instead of actual `beads_mybd`. Peer Connectivity, Federation Conflicts, and Dolt Mode all fail with Error 1049. Meanwhile, `Federation remotesapi` and `Sync Staleness` correctly return N/A. |
| **mybd-71w.2** | Dolt noms LOCK file warning | RUNTIME/BUG | P2 | `bd init` creates an empty (0-byte) LOCK file as a side effect of dolt database initialization but never cleans it up. `--fix` says "no automatic fix available" despite suggesting to run `--fix`. |

### Tier 2: Init UX (fix in bd init workflow)

| Issue | Warning(s) | Category | Priority | Root Cause |
|-------|-----------|----------|----------|------------|
| **mybd-71w.5** | 4 warnings pre-commit: Sync Divergence, JSONL missing, Git Working Tree dirty, missing pre-push hook | INIT/UX | P2 | `bd init` creates files but doesn't `git add`/commit them. Doctor immediately flags the uncommitted state. Init also misses installing pre-push hook (requires separate `--fix --yes`). |

### Tier 3: Check Logic (fix in bd doctor checks)

| Issue | Warning(s) | Category | Priority | Root Cause |
|-------|-----------|----------|----------|------------|
| **mybd-71w.3** | Git Upstream: No upstream configured | GIT/UX | P3 | Warning fires even when no git remote exists at all. Should only warn when origin exists but upstream tracking isn't set. |
| **mybd-71w.4** | Claude Plugin: not installed | INTEGRATIONS/UX | P3 | Warning fires regardless of whether Claude is installed/used. Should be conditional on Claude detection or moved to optional/info tier. |

## Dependency Graph

```
mybd-71w (epic)
├── mybd-71w.1 [P1] Federation DB name bug         ← fix first, highest impact (3 warnings)
├── mybd-71w.2 [P2] Dolt LOCK file after init       ← independent
├── mybd-71w.5 [P2] Init doesn't commit/stage files ← independent  
├── mybd-71w.3 [P3] Git upstream check too eager     ← independent
└── mybd-71w.4 [P3] Claude plugin check always fires ← independent
```

All child issues are independent — can be worked in parallel.

## Execution Strategy

### Important: Build Directory Awareness

- **System bd** (`~/.local/bin/bd`): Use for managing issues in mybd. Always use with `--no-db` flag when outside bd-main.
- **Development bd** (`~/dev/mybd/bd-main/bd` or worktree `bd`): Use only for testing/implementing fixes.
- Never mix them up. Before running any `bd` command, verify which binary and which working directory.

### Workflow Per Issue

1. Create a worktree branch: `git -C ~/dev/mybd/bd-main worktree add ../fix-<issue-id> -b fix-<issue-id>`
2. Update issue status: `bd update <id> --status in_progress` (system bd)
3. Locate relevant source code in the bd codebase (the `bd-main` worktree or new fix branch)
4. Implement fix
5. Test in clean room: rebuild bd, re-run `bd init` + `bd doctor` in scratch
6. Commit, push, close issue

### Recommended Delegation Order

1. **mybd-71w.1** (P1, 3 warnings eliminated) — Find where federation remote-listing queries construct the database name, fix to use the actual database name from config/init
2. **mybd-71w.2** (P2, 1 warning) — Find the dolt init code path, add LOCK cleanup after db creation; or teach doctor to ignore empty LOCK files
3. **mybd-71w.5** (P2, 4 pre-commit warnings) — Modify `bd init` to auto-stage `.beads/` and install all hooks including pre-push
4. **mybd-71w.3** (P3, 1 warning) — Modify the Git Upstream check to skip when no remotes exist
5. **mybd-71w.4** (P3, 1 warning) — Modify Claude Plugin check to only warn when Claude CLI or `.claude/` directory is detected

### Verification

After all fixes, the clean room test must produce:
```
bd doctor v0.x.x  ──────────────  ✓ N passed  ⚠ 0 warnings  ✖ 0 errors
```

## Upstream Cross-Reference (steveyegge/beads)

| Our Issue | Upstream Issue/PR | Status | Relevance |
|-----------|------------------|--------|-----------|
| **mybd-71w.1** (federation DB name) | None found | — | **Unreported upstream.** Novel bug — should file upstream after fixing. |
| **mybd-71w.2** (noms LOCK) | PR #1802 (closed, not merged) | Closed | Attempted LOCK cleanup with >5min age threshold. Right idea, wrong approach for init-created locks (0 sec old). |
| | PR #1850 (merged) | Merged | Added `releaseDiagnosticLocks()` — cleans LOCK between doctor phases, but not after `bd init`. |
| | Issue #1861 (open) | Open | `bd doctor --fix` hangs on Dolt embedded mode — related deadlock class. |
| **mybd-71w.3** (git upstream) | Issue #1095 (open) | Open | Generic `doctor.suppress` config — would solve this. No specific issue filed. |
| **mybd-71w.4** (Claude plugin) | Issue #1095 (open) | Open | Same suppress mechanism solves this. |
| | Issue #1787 (open) | Open | False positive warnings for specific backend configs — same problem class. |
| **mybd-71w.5** (init doesn't commit) | Issue #409 (closed) | Closed | Related init file creation issue. No specific issue for auto-commit gap. |

### Key Takeaways for Implementation

1. **mybd-71w.1 is novel** — no upstream awareness. Highest value fix.
2. **LOCK cleanup (mybd-71w.2)** was attempted in PR #1802 but closed. PR #1850 partially addressed it. The remaining gap is `bd init` not cleaning up after itself.
3. **Warning suppression (mybd-71w.3, .4)** has upstream support via Issue #1095 but no implementation yet. We can either implement `doctor.suppress` or fix the check logic directly.
4. **Init workflow (mybd-71w.5)** has no upstream attention — opportunity to contribute.

## Context for Sub-Agents

- bd source code is in `~/dev/mybd/bd-main/` (Go codebase)
- The bd binary is built with `go build` from the repo root
- Doctor checks are likely in a `doctor` or `cmd/doctor` package
- Federation code is likely in a `federation` package
- The dolt database name pattern is `beads_<prefix>` where prefix comes from config
- The clean room for testing is at `~/dev/mybd/scratch/cleanroom`
