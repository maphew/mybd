# Postmortem-to-guardrail pipeline (2026-08-16)

Bead: mybd-uqzt8. Owner request: mine sessions for friction, classify each
finding into a mechanical fix (wrapper assertion / hook / gitattribute) or a
bead — documentation only as a last resort — implement the guardrails with
regression tests, and report friction-class coverage for the last 20 sessions.

## What shipped

| Piece | Kind | What it prevents |
|---|---|---|
| `scripts/session-mine` | miner (Mine stage) | nothing directly — detects redo-after-error, unguarded destructive ops, first-run test failures, wrong-cwd errors in transcripts; wired into `session-close-check` as check 6 |
| `scripts/agentbin/bd` root assertion | wrapper pre-flight | bd invoked with no `.beads/` in cwd or any ancestor → exit 198 instead of binding the wrong/empty database (`MYBD_BD_ANYWHERE=1` overrides) |
| `scripts/destructive-guard` | Claude Code PreToolUse(Bash) hook | `rm -r` on `.bare` paths; `rm -r` composed with `git worktree list` (the 2026-08-10 data-loss shape); repo-wide `-X theirs/ours` merges; checkout/restore takeovers naming memory files. Inline `MYBD_ALLOW_*=1` escapes, visible in the transcript |
| `.githooks/pre-commit` marker guard | git hook (all worktrees, before the linked-worktree early-exit) | staged conflict markers reaching a commit, via git's own `diff --check` detector (`MYBD_ALLOW_CONFLICT_MARKERS=1` for deliberate literals) |
| `.gitattributes` `merge=binary` on `retro/*.tsv`, `retro/findings.md`, `MEMORY.md`, `memory/**` | gitattribute | silent text auto-merge of memory-bearing files — a both-sides merge now conflicts loudly, keeping ours in the worktree |
| `scripts/test-guardrails` | regression suite (27 checks) | every check fails if its guardrail is removed or unwired (including the settings.json and session-close-check wiring) |

Validation: `scripts/test-guardrails` all 27 pass; `scripts/test-git-hooks`,
`scripts/test-session-close-check`, `scripts/test-amp-parity` still pass
after the pre-commit / close-check / bd-shim modifications.

## Mining the last 20 sessions

`scripts/session-mine --last 20 --summary` over
`~/.claude/projects/-var-home-matt-dev-mybd` (window ≈ 2026-08-02..08-16),
cross-read against the retro campaign register (`retro/findings.md`, which
covers the deeper history the miner's heuristics can't reach):

- 2× new-test-first-fail (test-index-babysit, test-amp-parity — both fixed
  in-session)
- 1× redo-after-error (`bd remember` re-run after an error)
- 2 sessions with pre-flighted (guarded) destructive ops; 0 unguarded after
  exempting `git worktree remove`, which is the safe verb
- 0 wrong-cwd signature hits in this window (F-014's six sightings were the
  late-July window); one **live** F-004 hit during this very session
  (`bd update --claim --json` returned an array; `.id` index failed)

## Friction classes: coverage and residual risk

| Friction class (source) | Mechanically prevented now? | By what | Residual risk |
|---|---|---|---|
| bd invoked outside repo root (mybd-tshg3; F-014 family) | **Yes** | agentbin/bd shim exit 198 | Shim is opt-in via PATH prepend; a direct call to the real binary bypasses it. Claude sessions get it only if PATH is set (Amp guardrails section already prescribes this) |
| worktree prune / `rm -rf` hitting `.bare` (2026-08-10 incident) | **Yes** (Claude Code sessions) | destructive-guard shapes 1–2 | Hook fires only in Claude Code; Codex/Amp/manual shells unguarded — for those, the AGENTS.md rule + bundle-snapshot habit remain the only net |
| merge auto-resolution clobbering memory files | **Yes** | `merge=binary` attrs + destructive-guard shape 3 | Only listed path patterns are covered; a new memory-bearing file needs an attribute line. `merge=binary` keeps OURS — theirs' additions still need hand-carry at resolve time |
| conflict markers surviving into a commit | **Yes** (where hooks active) | pre-commit marker guard | `.githooks` is opt-in (`core.hooksPath`); `--no-verify` bypasses; `bd hooks install --beads` can silently flip hooksPath (check-beads-config warns) |
| redo-after-error commands (mined 1/20; F-004 class) | Partially | `scripts/bdj` for the jq-shape class; miner surfaces the rest at close | Not blockable in general — retries are normal iteration. Recurring identical redos should each get their own wrapper/bead (that is the pipeline) |
| first-run failures of new tests (mined 2/20) | No — by design | miner reports; red-team gate already forces adversarial test runs before upstream PRs | None to remove: a first-run test failure that gets fixed in-session is the process working |
| wrong-cwd operations (F-014, 6 sightings late July) | Partially | bd shim (bd half); miner check 6 surfaces the rest | General `cd`-lifecycle slips (removed-worktree cwd, relative paths in worktrees) remain judgment; a `git -C`/absolute-path habit is prose-only |
| destructive ops w/o pre-flight (miner class b) | **Yes** for the historically fatal shapes | destructive-guard | Guard covers the named shapes, not every destructive verb; `git reset --hard`/`branch -D`/force-push are mined and reported but not blocked (legitimate daily use; blocking would overfire) |
| bd `--json` shape drift (F-004, recurring; hit again this session) | Partially | `scripts/bdj` normalizer exists | Upstream unlanded; agents still reach for `bd --json` first — the miner now counts each redo so recurrence is measured, but a hook rewriting commands would overreach |
| bd flag/display semantics (F-011: `--limit` cap, repeated `--status`) | Partially | `bdj -n 0` convention; AGENTS.md counting rule | Upstream behavior unchanged; conventions are prose |
| session tail-watching (F-012) / close-protocol skips (F-013) | No | session-close-check + this pipeline's check 6 warn | Behavioral, not blockable; check 6 now makes the skip visible at close |
| Entire CLI clobbers tracked .githooks (F-015) | No | — | Still open; hazard bead from 6d370e33 is the tracking home |
| delegate outputs > 256 KB Read cap (F-005) | Partially | codex-agent wrapper preamble caps final messages | Non-codex delegates uncapped |

## Classification calls made (Step 2)

- Mechanical guard: the four named recurring issues (all shipped, above).
- Miner-only (no block): redo-after-error, first-run test failures —
  blocking would fight normal iteration; the pipeline's job is to count
  them so the third recurrence becomes a wrapper, not a memory.
- Bead, not guard: F-015 (Entire CLI) — needs containment design, not a
  regex; already tracked.
- Documentation: only the AGENTS.md section describing the machinery itself.

## Notes for the next round

- `git worktree remove` was deliberately exempted from the miner's
  destructive set after the first 20-session pass flagged only landing
  sequences — the safe verb refuses dirty/bare worktrees.
- destructive-guard uses two views of the command (same design as
  pr-review-gate): verbs are detected on a quote-blanked copy (so `echo
  "rm -rf .bare"` is not an invocation), target paths on a quote-stripped
  copy (so `rm -rf ".bare"` cannot hide behind quoting). Heredoc BODIES are
  still scanned — a heredoc writing a script that itself contains
  `rm -rf .bare` will block; take the inline escape hatch. Known residual:
  a destructive command wrapped entirely in `bash -c "..."` reads as a
  quoted string and passes; mined, not blocked.
- Cross-vendor review (codex reviewer, pre-PR) found 2 P1 bypasses (quoted
  paths defeated the matcher; `-R`/`--recursive` spellings unrecognized)
  and 3 P2s (restore --ours/--source uncovered; miner mined the wrong
  transcript dir from linked-worktree sessions; bare test runners
  unattributed). All five fixed with regression cases named for the
  finding. The gate earned its keep again (F-009).
- The hook layer only defends Claude Code sessions. If Codex/Amp sessions
  recur in the destructive-op mining, the next mechanical step is a `git`
  shim in `scripts/agentbin` mirroring destructive-guard's shapes.
