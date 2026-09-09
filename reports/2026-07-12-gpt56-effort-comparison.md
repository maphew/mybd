# GPT-5.6 reasoning-effort comparison: one level lower (2026-07-12)

Bead: mybd-uh7s. Follow-up to the GPT-5.6 tier migration (mybd-q8gd, commit
78d4d048a). The official migration guide advises: "preserve your current
reasoning effort as the baseline, then compare one level lower" — GPT-5.6 is
claimed to maintain quality with fewer tokens. This report tests that advice
on the repo's two Codex delegation tiers using real, replayable tasks.

## Method

All runs strictly serial (repo rule), via `codex exec`/`codex review` with
explicit `-m` and `model_reasoning_effort` pins, cold context each run.
Scenarios are grounded in completed work whose sessions/worktrees were still
on this machine:

**Scout tier (gpt-5.6-terra): medium (tier default) vs low.** Three recon
tasks with independently verified ground truth:

- **S1** (from mybd-q8gd): which script maps delegation tiers to Codex
  models; per-tier model/effort/sandbox; builder root-guard exit code and
  override env var. GT: `scripts/codex-agent`; terra/medium/read-only
  (ephemeral), terra/medium/workspace-write, sol/high/read-only; exit 3;
  `CODEX_AGENT_ALLOW_ROOT=1`.
- **S2**: session-close-check boundary semantics. GT: stamp
  `.beads/.session-start` written by the `bd prime` SessionStart hook; no
  stamp and no `--since` → session-scoped checks skipped with a warning;
  bd unavailable → bd-backed checks warn-skipped.
- **S3** (from mybd-0bxs / beads PR 4350): summarize the diff vs merge-base
  `672d942` in worktree `.worktrees/beads/pr-4350-harmonize`. GT: 6 files
  (`cmd/bd/mol_bond.go`, `cmd/bd/routed.go`, `cmd/bd/dep.go`, two new test
  files, CHANGELOG), mol bond routing operands to the target's database with
  regression tests.

**Reviewer tier (gpt-5.6-sol): high (tier default) vs medium.** Two real
reviews replayed with identical prompts/scope against a same-day pre-migration
baseline (gpt-5.5, high):

- **R-4722**: free-form exec review of the beads PR 4722 CLI-docs pipeline
  (worktree `pr-4722-review`). Baseline found: route/doc-id collision
  overwrite (Medium), single-file TOC depth (Low), code-fence rewrite leakage
  (Low), ASCII-only route names (Low).
- **R-4350**: structured `codex review` vs merge-base `672d942` (worktree
  `pr-4350-harmonize`). Baseline verdict: "patch is correct", 0 findings,
  confidence 0.83.

Grading: pass / partial / fail against ground truth (scout) or
baseline-finding overlap plus false-positive check (reviewer), graded by the
orchestrator with repo access. Tokens from codex `--json` usage events
(exec) or the session rollout `token_count` (review). Wall time measured
around each run.

## Results

### Scout tier (gpt-5.6-terra)

| Scenario | Effort | Grade | Wall | Output tok (reasoning) | Input tok (cached) |
|---|---|---|---|---|---|
| S1 codex-agent map | medium | pass | 13s | 468 (0) | 45,255 (19,968) |
| S1 codex-agent map | low | pass | 12s | 478 (0) | 43,596 (30,720) |
| S2 session boundary | medium | pass | 18s | 701 (13) | 73,570 (55,040) |
| S2 session boundary | low | pass | 24s | 656 (20) | 88,601 (73,984) |
| S3 PR 4350 diff summary | medium | pass | 11s | 407 (27) | 53,590 (30,720) |
| S3 PR 4350 diff summary | low | pass | 13s | 416 (44) | 53,621 (30,720) |

All six runs fully correct: exact answers, correct `path:line` citations,
quoted evidence. The `low` runs were not visibly worse anywhere — S2-low even
cited one extra legitimate hook site (`.claude/settings.json`) the medium run
skipped, and both S3 summaries correctly described the mol-bond routing
behavior change, matching the diff and the baseline session's verdict.

The reason it is a wash: terra spends almost no reasoning tokens on recon at
either setting (0–44), so "one level lower" has nothing to remove. Token and
wall-time differences are noise.

### Reviewer tier, R-4722 free-form review (gpt-5.6-sol vs gpt-5.5 baseline)

| Run | Findings | Baseline recall | Wall | Output tok (reasoning) | Input tok (cached) |
|---|---|---|---|---|---|
| baseline gpt-5.5 high | 4 | — | (this morning) | 8,183 (4,428) | 609,483 (527,104) |
| sol high | 12 | 4/4 | 231s | 7,352 (4,552) | 488,452 (391,424) |
| sol medium | 8 | 3/4 | 96s | 2,760 (1,290) | 154,250 (120,576) |

**sol-high strictly dominates the gpt-5.5-high baseline**: it recovered all
four baseline findings and added eight more, at ~10% fewer output tokens.
The two new **High** findings were verified against the code by the
orchestrator: (1) the `"pages"` lookup in `spliceCLINav` is unscoped — when
the `"CLI Reference"` group lacks a `pages` key, `strings.Index` walks into
the *next* group's array and rewrites the wrong navigation; (2) the bracket
matcher counts `[`/`]` bytes with no JSON-string awareness, and the code
comment explicitly (incorrectly) assumes string contents can't confuse it —
true only for generated slugs, not the pre-existing hand-editable array.

**sol-medium kept every finding that matters most**: both verified Highs,
the destructive/non-atomic generation, the `commandDocID` collision
(baseline's top finding), TOC depth, and code-fence rewrites — 8 findings at
37% of high's output tokens and 42% of its wall time. It missed one baseline
Low (ASCII-only route links) and three of high's unique Mediums (symlink
deletion, stale-artifact drift pass, stale-binary probe). It also produced
one verified finding neither high nor baseline reported: the drift check's
`git diff --quiet` freshness gate ignores untracked generated files
(`check-cli-docs-drift.sh:173`). No false positives in either run — every
spot-checked finding held up.

### Reviewer tier, R-4350 structured `codex review` (clean-patch control)

Baseline and both replays agree the patch is clean — this cell tests whether
lower effort starts inventing findings (false positives) or loses the
confidence to call a patch correct. It does neither.

| Run | Findings | Verdict | Confidence | Wall | Output tok (reasoning) | Input tok (cached) |
|---|---|---|---|---|---|---|
| baseline gpt-5.5 high | 0 | correct | 0.83 | (this morning) | 11,572 (7,785) | 2,009,403 (1,922,560) |
| sol high | 0 | correct | 0.87 | 199s | 6,193 (3,453) | 1,243,223 (1,168,128) |
| sol medium | 0 | correct | 0.86 | 56s | 1,744 (598) | 230,462 (197,376) |

sol-medium reached the same verdict at ~15% of the baseline's output tokens
and ~11% of its input, in under a minute — and still ran the focused
mol-bond tests (correctly using the repo's `gms_pure_go` build tag).
Confidence was essentially unchanged (0.86 vs high's 0.87, above the
baseline's 0.83).

## Caveats

- n=1 per cell; codex outputs are nondeterministic. Directional only.
- Scout/reviewer costs here are wall-time and tokens, not dollars — Codex
  bills to the ChatGPT plan.
- Reviewer "quality" is judged by overlap with a same-family baseline plus
  orchestrator verification, not by an independent oracle.

## Recommendation

The migration guide's claim held everywhere we could measure it, with one
asymmetry worth encoding:

1. **Scout (terra): keep `medium`.** Effort level made no measurable
   difference in quality, tokens, or latency on recon tasks — terra spends
   near-zero reasoning tokens on them at either setting. `low` is a safe
   quota lever, but there is nothing to save.
2. **Reviewer (sol): keep `high` as the tier default for maintainer-gate
   reviews.** On the findings-rich task, high surfaced 4 findings medium
   missed (3 Medium severity — symlink deletion, stale-artifact drift pass,
   stale-binary probe). For a gate whose job is completeness, that tail is
   the point.
3. **`medium` on sol is a legitimate fast-review mode, not a degraded one.**
   It caught both verified High findings, produced zero false positives
   across both tasks, matched the clean-patch verdict with unchanged
   confidence, and cost 2.5–4× less time and ~3–7× fewer tokens. For quick
   second opinions and pre-commit sanity passes, invoke it as:
   `scripts/codex-agent reviewer -c model_reasoning_effort='"medium"' ...`
4. **The migration itself is validated a second way**: sol-high beat the
   same-day gpt-5.5-high baseline on both quality (12 vs 4 findings, all
   verified spot-checks real) and cost (~10% fewer output tokens; ~40%
   less input on the structured review).

Untested: `xhigh`/`max` on the hardest review shapes (the guide suggests
comparing them); multi-run variance (all cells here are n=1).
