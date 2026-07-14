# 2026-07-13 session: 12-PR triage-stub sweep + canonical agent hooks (mybd-gcok)

Orchestrated session (Claude Fable 5, high). Freshness-checked and dispositioned
all 12 open upstream-PR triage-stub beads via a review workflow (12 reviewer
agents + maintainer action), and landed the P1 agent-hooks bug in this repo.
Upstream main was green before, during, and (pending final runs) after the batch;
every merge went through `PR_PREFLIGHT_BLOCK_RED_BASE=1` preflight.

## Upstream PR dispositions (gastownhall/beads)

| PR | Bead | Disposition | What happened |
|----|------|-------------|---------------|
| #4334 | mybd-737w | merge | `--claim` honors custom active-category statuses (ClaimableSourceStatusesInTx); branch refreshed, full CI green, merged. |
| #4338 | mybd-bu00 | merge | `bd close` updates `.beads/last-touched` per documented contract; merged. |
| #4229 | mybd-77zi | fix-merge | Global `--no-color` flag. Branch update exposed one stale Mintlify doc line — the single root cause of all 3 red checks (doc-flags, Build Artifacts, PR Policy). Regen pushed; merged. |
| #4095 | mybd-94fd | fix-merge | `bd ready` FIFO within priority tier (quad341 carrying kevglynn's #4065). Two repairs pushed: domain/db pagination fixtures flipped to oldest-first, then protocol contract test `TestProtocol_ReadyDefaultOrdering` + `r2Less` comparator moved to the new ASC contract. Corpus goldens unaffected (fixture has distinct priorities). Full CI green; merged. |
| #4337 | mybd-11m3 | fix-merge | Epic lint accepts "Acceptance Criteria" heading. Conflicts were all Mintlify `website/` deletions; resolved, regen zero-drift; merged. |
| #4347 | mybd-p2m8 | fix-merge | `bd list --external-ref` exact-match filter. Docs regen for both new flags (also caught pre-existing stale `--external-contains` line); workflow runs approved; merged. |
| #4335 | mybd-686r | fix-merge | Custom PRIME.md gets memory injection; `--memories-only` no longer leaks template. Obsolete website/ edits dropped; merged. |
| #4336 | mybd-nsoh | fix-merge | `--no-memories` flag, stacked on #4335. Rebased onto main after #4335 landed; `--memories-only` precedence and #4230's doltSync gating verified coexisting. Full CI green; merged. |
| #4186 | mybd-jhmm | fix-merge | `bd show` propagates iterator errors. Four `FatalErrorRespectJSON` call sites (helper removed on main) migrated to `return HandleErrorRespectJSON(...)` with `result.Close()`; embedded show suite green; merged. |
| #4230 | mybd-07j5 | fix-merge | Dolt-hint suppression reworked to separate the git-remote axis (`localOnly`) from the new dolt-sync axis (`doltSync`); 5 new two-axis test cases; merged. |
| #4232 | mybd-da7r | fix-merge | `--set-metadata` always stores JSON strings. Non-PR-CI surfaces aligned (proxied integration test, oracle-a DIVERGENCE PIN prose — pins are documentation, runner ignores them per PROVENANCE.md). Upgrade-smoke failure was a Go-module-proxy flake; rerun green; merged. |
| #4694 | mybd-ij26 | retire | Superseded: backends feature (1fc38ba77/c79bb32bc, landed 2026-07-10) handles SQLite aliased-UPDATE at the dialect layer (`sqlitedialect/translate.go`); embedded Dolt/GMS accepts aliased UPDATE. Closed with thanks + repro invitation. |

Score: 11 merged, 1 retired — all 12 stubs dispositioned.
All repairs were pushed to contributor branches (all allowed maintainer edits);
contributor commits and attribution preserved; every maintainer commit carries
an Agent-Signature trailer.

### Review-quality notes

- The review workflow's adversarial verify stage self-cancelled on its token
  budget guard (review stage alone exceeded the 200k default target at ~500k).
  Compensated with per-PR preflight + orchestrator checks; worth splitting
  future sweeps into two workflow invocations so verify keeps its own budget.
- The #4095 reviewer caught the domain/db fixtures but missed the protocol
  contract test — CI caught it. Contract tests (`cmd/bd/protocol`) are a
  standing blind spot for ordering changes: grep `cmd/bd/protocol` whenever a
  PR changes user-visible ordering.
- #4229 showed the branch-refresh trap: green checks that predate a docs-layout
  migration (Mintlify) go red after `gh pr update-branch` when the PR adds CLI
  surface. Regen-on-branch is the standard fix (one commit, three checks green).

## mybd-gcok: canonical cross-platform agent hooks (P1, closed)

Merged on mybd main (`d0b938cd5..c6cfea5e1`):

- `.codex/hooks.json` now uses the canonical four-event `bd codex-hook`
  lifecycle (SessionStart/PreCompact/PostCompact/UserPromptSubmit) instead of
  direct `bd prime` calls; the session-stamp hook is cross-platform
  (`sh scripts/session-start-stamp`) in its own sibling entry.
- `.claude/settings.json` moved to `bd prime --hook-json`; stamp call
  made `sh`-invoked; entire-hooks and permissions untouched.
- bd-managed marker sections installed in `AGENTS.md` and `CLAUDE.md`;
  `bd setup codex --check` and `bd setup claude --check` both exit 0.
- New regression harness `scripts/test-agent-hooks`: config schema, four-event
  presence, cross-platform command resolution (no drive letters / bash.exe /
  PROGRA~1), and session-start-stamp TTL behavior (4 cases). All pass.
- All four `bd codex-hook` events + stamp verified exit-0 on Linux.
  Windows-host verification split to **mybd-gwxj**.

Key mechanism (also in `bd remember`
`bd-setup-codex-claude-check-require-byte-exact`): the setup checkers demand
byte-exact canonical entries/marker blocks; custom hooks must live in separate
sibling entries, and marker blocks should be owned by `bd setup`, not
hand-written pointers.

## Loose ends / next session

- **mybd-gwxj**: verify hooks on a Windows host (sh-on-PATH question).
- Upstream main runs for the merge batch were in_progress at close; the batch
  is 10 independently-green PRs, but confirm Main/Regression conclude green.
- Beads-source worktrees `pr-4XXX-fix` under `.worktrees/beads/` removed at
  session close (branches remain in bd-main for re-checkout if needed).
