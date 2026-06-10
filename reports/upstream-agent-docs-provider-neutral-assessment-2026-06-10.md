# Upstream Beads Agent Docs: Provider-Neutral Readiness Assessment

- **Local bead**: `mybd-hwtl`
- **Assessed on**: 2026-06-10
- **Upstream reference**: `gastownhall/beads@99ed06b6fb7ce3deedaaee2fbbdf61e37c66883f` (bd-main fast-forwarded from `e1e97e6c5` at assessment start)
- **Scope**: read-only review of agent-facing docs (`AGENTS.md`, `AGENT_INSTRUCTIONS.md`, `CLAUDE.md`, `PR_MAINTAINER_GUIDELINES.md`, `docs/METADATA.md`, `docs/PROJECT_CHARTER.md`, integration docs, `internal/templates/agents/` and `cmd/bd/setup/` generated content)
- **Method**: staged per bead metadata - two parallel read-only explorer sweeps, direct verification of every load-bearing claim, then upstream overlap scan (`scripts/pr-preflight.sh` plus issue search)
- **Prior art**: `reports/agents-upstream-tuning-comparison-2026-05-28.md`, gastownhall/beads#3617 (merged), gastownhall/beads#3541 (closed)

## Executive Summary

Upstream beads agent documentation is already essentially provider-neutral. No model names or ids (`claude-fable-5`, `gpt-5.5`, `opus`, `sonnet`, `haiku`, `fable`, etc.) appear anywhere in agent-facing guidance, generated templates, or setup code. Runtime-specific material is properly quarantined in per-runtime integration docs (`docs/CLAUDE_INTEGRATION.md`, `docs/CODEX_INTEGRATION.md`, etc.), and Anthropic-specific product features (AI compaction, observability metrics) are honestly labeled as implementation details, not presented as universal agent behavior.

Three findings, in descending weight:

1. **One substantive gap**: `docs/METADATA.md:28` documents `execution_reasoning_effort` as "`low`, `medium`, `high`, or `xhigh`" with no note that this is a canonical stored scale that consumers map to their runtime. `xhigh` is Codex's top value; Claude Code's scale tops at `max` and now includes `auto`. A reader on a non-Codex runtime has no documented mapping rule.
2. **One drift item**: `docs/METADATA.md` still says to defer a first-class CLI helper "until upstream issue gh-3541 determines whether schedulers or runners need these fields as a stable CLI surface." That issue closed COMPLETED on 2026-06-03 (resolution: keep hints in metadata, documented in METADATA.md, no first-class helper). The guidance still matches the resolution, but the sentence reads as if the question is open.
3. **One minor staleness risk**: `internal/templates/agents/defaults/beads-section-codex.md` pins "Codex 0.129.0+" for native hook support. Version pins in generated agent content age silently; low priority.

Everything else passes. No upstream changes are required for Fable or any other new model to work with beads agent docs as written.

## Fable Facts Check

Each current fact checked against what upstream docs assert:

| Fact | Upstream docs status |
|------|----------------------|
| Newest Anthropic model id is `claude-fable-5` | No model ids appear anywhere in agent-facing docs or templates. Nothing to update, nothing contradicts. |
| Claude Code Agent tool model aliases are `sonnet`/`opus`/`haiku`/`fable` | No alias lists documented upstream. Correctly absent: alias lists would age with every model release. |
| Claude Code `/effort` includes `auto` (and `CLAUDE_EFFORT` may report a resolved level, not `auto`) | `auto` is unrepresented in the `execution_reasoning_effort` vocabulary and there is no mapping note (Finding 1). No upstream doc references `CLAUDE_EFFORT` at all, so no incorrect claim exists. |
| Effort scales differ across runtimes (Codex `xhigh` vs Claude Code `max`/`auto`) | `docs/METADATA.md:28` exemplifies only the Codex-shaped scale without saying consumers map it (Finding 1). |

## Findings by Area

### Core agent docs (AGENTS.md, AGENT_INSTRUCTIONS.md, CLAUDE.md, PR_MAINTAINER_GUIDELINES.md)

**Verdict: provider-neutral.** A grep for model names, effort vocabularies, `CLAUDE_EFFORT`, and `ultrathink` across these files returns exactly one hit in the whole set: `docs/METADATA.md:28`. The execution metadata keys (`execution_agent_type`, `execution_suggested_model`, `execution_reasoning_effort`, `execution_mode`, `execution_parallel_group`) are listed by name in `AGENTS.md` and `AGENT_INSTRUCTIONS.md` without exemplifying any model or effort values. The instruction that "Model and reasoning effort are normally fixed at launch, so reading metadata after delegation is too late" is runtime-agnostic and correct for both Claude Code and Codex.

### docs/METADATA.md (the one substantive gap)

Current text, line 28:

> | `execution_reasoning_effort` | Suggested reasoning effort, such as `low`, `medium`, `high`, or `xhigh`. |

The "such as" hedge makes the values advisory, but the doc never states the design rule that makes the key portable: the stored value is a canonical scale, and a consumer on a runtime with a different scale maps it rather than dropping it. Without that sentence, an agent on Claude Code seeing `execution_reasoning_effort=xhigh` has no documented warrant to translate it to `max`, and an agent writing hints does not know whether runtime-local values like `auto` belong in the field.

The companion key `execution_suggested_model` has the same latent question (is `gpt-5.5` binding for a Claude consumer?) and the same fix: one sentence stating the value is a capability-tier suggestion that consumers on another provider substitute, not a hard pin. Note this mapping rule already exists in mybd's local delegation-planner skill wording; what would go upstream is the principle (canonical scale, consumer maps, tier not brand), not the mybd-specific examples or skill text.

### docs/METADATA.md gh-3541 reference (drift)

> Do not add a first-class helper such as `bd show <id> --execution` or `bd plan <id> --json` yet. Keep using the JSON/JQ snippet until upstream issue gh-3541 determines whether schedulers or runners need these fields as a stable CLI surface.

gastownhall/beads#3541 closed COMPLETED on 2026-06-03. The substance still holds (the resolution was metadata-only, documented in METADATA.md), but the sentence should state the resolution rather than point at an open question. One-line rewording.

### Generated templates and setup code (internal/templates/agents/, cmd/bd/setup/)

**Verdict: provider-neutral by design.** Profile selection (`minimal` for hook-enabled runtimes like Claude Code, Gemini, Copilot CLI; `full` for AGENTS-first runtimes like Codex, Factory, OpenCode, Mux) is driven by runtime capability (hooks), not by model or provider identity. The behavioral profiles in `beads-section*.md` (Conservative / Minimal / Team-maintainer) govern git/sync policy and contain no model or effort content. No template conditions content on provider.

Minor: `beads-section-codex.md` pins "Codex 0.129.0+" for native hooks. Harmless today, silently stale tomorrow. Not worth a standalone PR; fix opportunistically.

### Per-runtime integration docs

**Verdict: scoped correctly.** `docs/CLAUDE_INTEGRATION.md`, `CODEX_INTEGRATION.md`, `COPILOT_INTEGRATION.md`, `COPILOT_CLI_INTEGRATION.md`, `AIDER_INTEGRATION.md`, and `docs/SETUP.md` each name their target runtime in the title and do not present runtime-specific mechanics as universal. `docs/SETUP.md` explicitly distinguishes hook-first from AGENTS-first runtimes.

### Anthropic-specific product features (not agent guidance)

`docs/CLI_REFERENCE.md` (AI compaction and semantic diff require `ANTHROPIC_API_KEY`, marked legacy where applicable) and `docs/OBSERVABILITY.md` (token counters labeled Anthropic, `anthropic.messages.new` span) accurately describe a provider-specific implementation and label it as such. This is product surface, not agent-doc neutrality, and is out of scope for this assessment. If beads ever generalizes its AI features to other providers, these docs follow the code.

### Stale model references

None found. No `claude-3`, `gpt-4`, or other aged model families in active docs. The only historical model mention is a CHANGELOG entry ("AI-powered summarization using Claude Haiku") describing a past implementation, which is appropriate where it is.

## Overlap / Collision Scan

Run before proposing anything, per bead instructions and session request.

- `scripts/pr-preflight.sh --search "execution metadata reasoning effort model"`: **no open PRs**. The METADATA.md wording change collides with nothing.
- `scripts/pr-preflight.sh --search "AGENTS.md docs"`: two open PRs.
  - **gastownhall/beads#4237** "docs: align agent maintainer conventions" (maphew, open, REVIEW_REQUIRED) - the prior tuning-comparison follow-up: signing convention, `scripts/gh-body-lint`, maintainer final-reread rule, managed-marker refresh. It touches `AGENTS.md`, `AGENT_INSTRUCTIONS.md`, `PR_MAINTAINER_GUIDELINES.md`, `docs/AGENT_SIGNING.md`, `docs/SETUP.md`, and templates. It does **not** touch `docs/METADATA.md` or any effort/model vocabulary, so the proposals below do not collide with it. Sequencing rule: any new PR touching `AGENTS.md`/`AGENT_INSTRUCTIONS.md` should wait for or rebase onto #4237; a METADATA.md-only PR is independent.
  - gastownhall/beads#3773 (init symlink fix) - unrelated to doc content.
- Issue search "reasoning effort": only gastownhall/beads#3541, closed COMPLETED 2026-06-03 (origin of the execution metadata convention; resolution was metadata-only, examples added to METADATA.md).
- Issue search "provider neutral model": no hits.
- gastownhall/beads#3617 (storage-driver boundary in AGENTS.md): merged; context only.

## Recommendations

Filtered through the bead's gate: *demonstrably worthwhile for ALL collaborators*, and no import of mybd-personal workflow.

### Propose upstream (passes the gate)

A single small `docs/METADATA.md`-only PR:

1. **Add the mapping rule to `execution_reasoning_effort`** (one or two sentences): the stored values form a canonical advisory scale; runtimes with different native scales map the value rather than dropping it (e.g. a runtime whose scale tops out below or above `xhigh` uses its nearest equivalent), and writers should store canonical values, not runtime-local ones like `max` or `auto`. Worthwhile for every consumer on every runtime; no provider needs to be named.
2. **Add the tier rule to `execution_suggested_model`** (one sentence): the value is a capability-tier suggestion; consumers on a different provider substitute a same-tier model rather than ignoring the hint. Deliberately give no example model ids - that is what keeps the doc from aging.
3. **Reword the gh-3541 sentence** to past tense: the issue resolved to keep execution hints metadata-only with no first-class CLI helper; the JSON/JQ snippet remains the supported access path.

This PR is independent of #4237 (no shared files) and preflight shows no competing open work.

### Do not propose upstream (fails the gate)

- **Model alias enumerations** (e.g. documenting `sonnet`/`opus`/`haiku`/`fable` or Codex model names in METADATA.md or integration docs). One explorer sweep suggested this; rejected here. Alias lists go stale with every model release, and absence of model names is precisely why upstream currently needs no changes for Fable. The tier-not-brand sentence (above) captures the durable part.
- **Runtime effort-scale tables** (Codex `xhigh` vs Claude Code `max`/`auto` vs others). Same aging problem; the canonical-scale-plus-mapping sentence covers it without naming vendors.
- **mybd workflow imports**: `scripts/agent-sig` mechanics, verify-queue keys (`verify_state` etc.), delegation-planner skill wording, mybd report conventions. Local coordination policy. (Signing is already in flight upstream as #4237 in a generalized form; nothing further to add from this assessment.)
- **CLI/code changes** of any kind. The charter says metadata before schema, and #3541's resolution already settled this; nothing here justifies reopening it.

### Sequencing

1. `docs/METADATA.md` wording PR can go anytime (no collisions).
2. Anything touching `AGENTS.md`/`AGENT_INSTRUCTIONS.md` waits for #4237 to land first. Currently nothing in this assessment requires touching those files.
3. The Codex `0.129.0+` version pin: fold into the METADATA.md PR only if trivially verifiable as still-correct; otherwise leave for an opportunistic template touch.

## Bottom Line

Upstream beads agent docs need **no changes for Fable specifically**. They achieved provider neutrality the robust way: by not naming models at all. The one worthwhile upstream improvement is generic, not Fable-driven - documenting that `execution_reasoning_effort` and `execution_suggested_model` are canonical advisory values that consumers map to their own runtime and provider. That is a three-sentence METADATA.md PR with a clean preflight.

---

_claude-fable-5-high on behalf of matt wilkie_
