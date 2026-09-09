# Orchestration-layer landscape: is the mybd stack reinventing the wheel?

**Date:** 2026-07-29
**Question (owner):** pr-babysit, verify-next, and solo-sweep are an orchestration
layer on top of beads. Am I recreating a management layer that already exists
(Gas Town, Gas City, Agentsview, Entire, others)?
**Method:** deep-research workflow — 5 search angles, 20 sources fetched, 100
claims extracted, 25 adversarially verified (3 skeptic votes each): 24 confirmed,
1 refuted. 105 subagents, ~3.6M tokens.

## Verdict

**Partially reinventing, deliberately — and the duplicated parts are the cheap
parts.** The field has converged on two designs: hosted event-driven services
(Kodiak, Mergify, GitHub merge queue / Agent HQ) and always-on LLM-agent
supervision (Gas Town / Gas City). The mybd stack occupies a third point —
**deterministic, local-first, credential-scoped, human-gated** — that no
surveyed tool implements. The real asset is not the bash; it is the invariants
(fail-closed rules, allowlist regression suite, "sessions produce, only the
patrol merges"), which any adopted framework would force re-verification of
inside someone else's architecture.

## Layer-by-layer (all claims verified 3-0 unless noted)

### merge-when-green — commoditized, but only as hosted infrastructure

- **Kodiak** (mature since ~2019): label-triggered auto-merge once CI +
  approvals pass. Deployed as a hosted GitHub App or self-hosted *webhook
  service* (Docker + Redis) — never a local timer. Incompatible with GitHub's
  "require merge queue" protection; partially absorbed by native auto-merge.
- **Mergify Test Insights** (GA **2026-07-24**): productized automatic
  flaky-test rerun/detection — absorbs pr-babysit's flake-rerun-once logic,
  but SaaS, and scoped to Mergify's framework plugins (pytest/rspec/vitest/
  playwright).
- **GitHub merge queue**: owns merge *serialization* (speculative stacked
  testing), auto-merges after queue testing; a poor fit for per-PR babysitting
  of an individual PR's checks.
- **Gas Town Refinery**: verified real implemented code
  (`internal/refinery/`: batch.go, engineer.go, score.go, safety_stop.go,
  GitHub + Bitbucket PR providers). A Bors-style batching/bisecting merge
  queue — a *superset* of the merge lane, riding the token-spending fleet.

All require installing infrastructure on (or controlling) the target repo.
pr-babysit runs on maintainer credentials alone. None cover close-when-quiet,
review-needed, or base-red. **Verdict: function duplicated, form not.**

### verify queue — no surveyed equivalent

Gas Town's git-worktree "hooks" overlap only at the storage substrate: theirs
are *persistent per-agent workspaces* surviving crashes; verify-next worktrees
are *ephemeral clean checkouts* per run. Nothing surveyed does a local
verification queue recording `verify_cmd`/`verify_head` in an issue tracker and
writing pass/fail back. Everything else assumes hosted CI.

### Unattended supervision — the architectural fork

Gas Town/City's unattended layer is LLM-agent-driven end to end: Witness/Deacon
/Dogs are AI agents doing intelligent triage; Gas City is "a
controller/supervisor loop that reconciles desired state to running state"
(explicit Kubernetes analogy), targeting 24×7 agent-checks-agent operation.
**Architecturally opposite** to zero-token timer-fired oneshots. The token-cost
asymmetry is the core adoption tradeoff: our patrol passes cost zero model
tokens; theirs inherently spend.

### solo-sweep — nearest analogues, neither close

- **DraftCat/FixClaw** (commercial SaaS): propose-only issue triage with
  human-gated publication by default — proves the *posture* has a market, but
  it's hosted, not allowlist-sandboxed.
- **GitHub agent automation controls for Issues** (public preview
  **2026-07-23**): platform-level gating of AI-proposed issue actions. Watch
  this — it's the platform slowly growing our propose-only lane natively.

No surveyed tool combines local execution + permission allowlist + read-only
credential scope + propose-never-publish.

### Entire — complementary, not overlapping

Owns only session capture/checkpointing (transcripts indexed beside commits on
`entire/checkpoints/v1`). Verifier probed for issue queues, merge automation,
verification queues, unattended orchestration: zero mention. Already chained in
our `.githooks/`. Caveat: entire.io teases a broader platform; scope may grow.

### GitHub Agent HQ — the platform-native fleet manager

Mission control (cross-surface command center), Claude + Codex natively hosted
(public preview, no extra subscription, extended to Business/Pro 2026-02-26),
issue→agent dispatch via the Assignees dropdown incl. multi-agent fan-out,
branch controls + one-click conflict resolution. All cloud-hosted, Copilot-tied,
metered per session. Overlaps but cannot replace local-first beads-queued lanes.

## Gas Town / Gas City adoption ledger

Closest comparator: **built on beads as universal substrate** (tasks, mail,
sessions, convoys are all beads; bd 0.57.0+ is a hard prerequisite; store is
pluggable with bd as default). Gas Town v1.0 2026-04-03; Gas City is the
engine extracted from it (zero hardcoded roles; Gas Town and Ralph are pack
configurations — 2-1 vote on the packs claim; the "rewritten from scratch as
SDK" phrasing was *refuted* 1-2). Gas City v1.1.1 tagged 2026-07-19 — ~3 months
old. Most critical third-party review: "functionally mature but strategically
immature."

| Buys | Costs |
|------|-------|
| Batched/bisecting merge queue (Refinery) | Always-on token spend for supervision |
| Crash-surviving persistent agent worktrees | Framework commitment (engine + packs), not drop-in lanes |
| Fleet supervision at 20-30 concurrent agents | Abandoning the zero-token / human-gated posture |
| Same beads substrate, native composition | Unverified cohabitation with the mybd Dolt DB + sync remote |

One maintainer against one upstream repo does not have Gas Town's problem.

## Recommendation

1. **Keep the stack.** It is not duplication; it is an unoccupied design point
   whose constraints (no upstream infra control, zero marginal supervision
   cost, fail-closed outward actions) are the fit-for-purpose features.
2. **Watch, don't migrate:** (a) whether Gas City's exec/subprocess runtime
   packs can express zero-LLM-token deterministic lanes — if yes, our lanes
   could become a pack rather than a parallel system; (b) GitHub's agent
   automation controls for Issues as a possible native propose-only substrate.
3. **Reconsider only on scale change** — many concurrent agents or multiple
   upstream repos is where bespoke bash maintenance overtakes framework cost.
4. Entire stays; it's a different layer and already integrated.

## Open questions (from the research)

- Can Refinery be adopted standalone against an existing beads DB without the
  Mayor/Deacon/Witness fleet, and at what per-merge token cost vs. zero?
- Can Gas City packs express zero-token deterministic lanes?
- What do the unassessed targets own (esp. Agentsview, Vibe Kanban,
  claude-flow, Anthropic scheduled/cloud Claude Code) — does any implement
  propose-only unattended runs or allowlist sandboxing?
- Would Gas City's prefix-isolated bead store cohabit with the mybd Dolt DB
  and `refs/dolt/data` sync, or does adoption mean a separate store + migration?

## Coverage caveats

No verified claims for: Agentsview, Conductor, Terragon, Sculptor, Vibe Kanban,
claude-flow, OpenHands, Devin, Cursor background agents, Claude Code
cloud/teleport, CrewAI/LangGraph/Temporal, or GitHub native merge queue beyond
the blog sources cited. The "nothing else does zero-token/propose-only"
conclusion is argument-from-absence over a partial survey. Gas Town/City
evidence skews first-party (Yegge posts + project docs); maturity claims are
self-assessed. High time-sensitivity: Mergify's flake feature GA'd five days
before this report; Gas City is three months old; expect material drift within
a quarter.

## Key sources

- https://github.com/gastownhall/gastown · https://github.com/gastownhall/gascity
- https://github.com/gastownhall/gascity/blob/main/docs/getting-started/how-gas-city-works.md
- https://steve-yegge.medium.com/gas-town-from-clown-show-to-v1-0-c239d9a407ec
- https://steve-yegge.medium.com/welcome-to-gas-city-57f564bb3607
- https://tenzinwangdhen.com/posts/gastown-good-bad-ugly/ (third-party review)
- https://github.com/chdsbd/kodiak · https://kodiakhq.com/docs/self-hosting
- https://docs.mergify.com/changelog/2026-07-24-automatic-flaky-test-detection-and-prevention/
- https://github.blog/news-insights/company-news/welcome-home-agents/ (Agent HQ)
- https://github.blog/changelog/2026-02-04-claude-and-codex-are-now-available-in-public-preview-on-github/
- https://github.com/entireio/cli · https://www.thoughtworks.com/radar/tools/entire-cli
- https://renezander.com/guides/fixclaw-ai-github-triage/ (DraftCat propose-only triage)
- https://dev.to/pwd9000/human-in-the-loop-agentic-devops-govern-ai-automation-in-github-issues-472h
