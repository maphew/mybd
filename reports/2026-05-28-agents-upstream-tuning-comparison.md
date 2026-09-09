# AGENTS.md Upstream Tuning Comparison

- **Local bead**: `mybd-6d9g`
- **Compared on**: 2026-05-28
- **Upstream reference**: `gastownhall/beads@a011761e5ed40da7b0203ff33f4d4de81dc54094`
- **Local sources**: `AGENTS.md`, `CLAUDE.md`, `PR_MAINTAINER_GUIDELINES.md`
- **Upstream sources**: `bd-main/AGENTS.md`, `bd-main/CLAUDE.md`, `bd-main/AGENT_INSTRUCTIONS.md`, `bd-main/PR_MAINTAINER_GUIDELINES.md`, agent section templates
- **Alignment source**: `../gascity/AGENTS.md`, `../gascity/CLAUDE.md`

## Executive Summary

Most of the durable guidance from `mybd/AGENTS.md` has already moved upstream in better form: `gastownhall/beads` now has a short compatibility `AGENTS.md`, deeper operational guidance in `AGENT_INSTRUCTIONS.md`, explicit project-charter and storage-boundary pointers, PR preflight, maintainer PR policy, symlink-safe setup behavior, and generated integration markers with profile/hash metadata.

The remaining upstream-worthy gaps are narrower:

1. Add a shared **agent signing convention** for GitHub comments/reviews and commits.
2. Add a **GitHub body-file linting convention** to avoid literal `\n` rendering and non-linking issue refs.
3. Refresh upstream's checked-in generated `AGENTS.md` integration block so it uses the current `v:1 profile:* hash:*` marker format.
4. Reconcile **execution metadata naming**: upstream instructions still describe `execution_*` keys, while the local delegation planner uses flatter `agent_role`, `recommended_model`, `reasoning_effort`, and related keys.
5. Copy the local PR maintainer guideline "final reread" rule upstream.

Do not upstream local coordination details such as `maphew/mybd` repository layout, the nested `bd-main/` clone, the local verification queue, report defaults, or `gh {number}` shorthand. Those belong in the coordination repo.

## Source Comparison

| Area | mybd guidance | upstream beads guidance | Recommendation |
|------|---------------|-------------------------|----------------|
| Entry point shape | `AGENTS.md` contains local coordination rules plus a generated bd block. `CLAUDE.md` imports it. | `AGENTS.md` is a compatibility entry point and points to `AGENT_INSTRUCTIONS.md`; `CLAUDE.md` stays intentionally short. | Keep upstream shape. It reduces drift across agent entrypoints. |
| Project scope | Local `AGENTS.md` does not carry the project charter directly. | Upstream points agents to `docs/PROJECT_CHARTER.md` before feature work and to the storage boundary before storage changes. | Already upstream-worthy and present. Consider backporting this pointer to mybd only if useful locally. |
| PR maintenance | Local `PR_MAINTAINER_GUIDELINES.md` emphasizes contributor protection, transform/absorb, attribution, and a final reread of PR state. | Upstream has the same policy plus a charter pointer, but lacks the local final reread rule. | Upstream should add the final reread rule. Local should add upstream's charter pointer. |
| GitHub body hygiene | Local requires Markdown body files, `#1234`/`owner/repo#1234`, and `scripts/gh-body-lint` before posting. | Upstream PR guidelines require body file/heredoc and rendered verification, but do not mention `gh-body-lint` or issue-ref linting. | Upstream should add a small `scripts/gh-body-lint` equivalent or fold this into an existing script. |
| Agent signatures | Local defines comment signatures and `Agent-Signature:` commit trailers, including runtime/model/reasoning discovery rules. | Upstream has normal commit-message issue IDs and attribution rules, but no agent signature convention. | Upstream should adopt the convention with runtime metadata as optional/best-effort and unknown placeholders when unavailable. |
| Delegation metadata | Local skill uses flat keys: `agent_role`, `recommended_model`, `reasoning_effort`, `execution_mode`, `isolation`, etc. | Upstream instructions mention older `execution_agent_type`, `execution_suggested_model`, `execution_reasoning_effort`, `execution_mode`, `execution_parallel_group`. | Upstream should either document both as aliases during transition or pick one canonical schema. Prefer flat keys if Gas City will consume them. |
| Generated bd integration | Local generated block has `<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:... -->`. | Upstream source code supports version/profile/hash markers, but checked-in `AGENTS.md` on `upstream/main` still has `<!-- BEGIN BEADS INTEGRATION -->`. | Refresh the checked-in block using setup/render machinery, not manual edits inside the managed section. |
| Worktrees | Local says source worktrees belong under `<mybd-root>/.worktrees/beads/<purpose>`. | Upstream has general Git worktree guidance and uses direct PR workflow. | Keep local. The path is coordination-repo-specific. |
| Verification queue | Local has `scripts/verify-enqueue`, `verify-next`, and `verify-status`. | Upstream tells agents to run normal tests directly. | Keep local unless upstream adopts the queue scripts. |
| Gas City alignment | Local explicitly treats beads as nested source used by orchestration work. | Upstream charter says orchestration policy belongs outside beads. Gas City says beads is the universal task store and SDK role behavior must be user supplied. | Current upstream charter is aligned. Metadata schema should stay generic enough for Gas City without naming Gas City roles. |

## PR Maintainer Guidelines Delta

The two PR maintainer policy files are mostly aligned. Upstream has one important addition local does not: when a PR changes product surface area, read `docs/PROJECT_CHARTER.md` and use scope boundaries to decide whether value belongs in core, metadata, integration, plugin, orchestration, or external tooling.

Local has one important operational guard upstream does not:

> Before finishing, re-read the PR, latest comments, review threads, and linked issues; address or explicitly note any unresolved action items.

That rule is worth upstreaming because it prevents stale maintainer actions after a long review or after another maintainer comments. It fits the existing upstream policy without adding project-local assumptions.

Suggested cross-pollination:

- Add upstream's charter paragraph to local `PR_MAINTAINER_GUIDELINES.md`.
- Add local's final-reread rule to upstream `PR_MAINTAINER_GUIDELINES.md`.
- Keep both documents focused on maintainer behavior, not generated bd workflow content.

## Agent-Signature Evaluation

The local convention is upstream-worthy, but only if it is documented as a lightweight audit trail, not as a mandatory identity guarantee.

Recommended upstream form:

```text
Sign GitHub comments/reviews:
_{agent_runtime}-{model}-{reasoning} on behalf of {git_user}_

Sign commits with a trailer:
Agent-Signature: {agent_runtime}-{model}-{reasoning} on behalf of {git_user}
```

Rules that should carry upstream:

- Use runtime/session metadata when reliably available.
- Use `unknown-model` or `unknown-reasoning` instead of guessing.
- Do not infer model or reasoning effort from prompt text, cache files, defaults, or memory.
- Keep `Co-authored-by:` for contributor attribution; `Agent-Signature:` records agent execution context and does not replace attribution.

Gas City alignment: this convention is compatible with Gas City's "role behavior is user-supplied configuration" rule because it records agent runtime context without adding role logic to beads. If Gas City later consumes these signatures, it can parse them as metadata rather than requiring beads core to understand agent roles.

Potential caveat: upstream should avoid embedding runtime-specific database paths in the main cross-agent instructions. Put runtime-specific lookup recipes in a supplemental doc, for example `docs/AGENT_SIGNING.md`, so `AGENTS.md` stays short.

## Refresh-Safe Generated Blocks

Generated bd integration blocks must remain managed by beads setup code. The current upstream implementation already supports this:

- `internal/templates/agents/render.go` renders sections with `v`, `profile`, and `hash` metadata.
- `cmd/bd/setup/agents.go` detects legacy markers with `<!-- BEGIN BEADS INTEGRATION` and replaces stale content.
- `cmd/bd/setup/agents_marker_test.go` covers legacy-to-new replacement and stale marker refresh.

The upstream proposal should therefore avoid hand-editing generated block bodies in checked-in agent files. Shared guidance should live in one of these places:

- durable, project-specific source docs: `AGENTS.md`, `AGENT_INSTRUCTIONS.md`, `PR_MAINTAINER_GUIDELINES.md`, or a new `docs/AGENT_SIGNING.md`
- generated template bodies: `internal/templates/agents/defaults/*.md`
- setup/render code and tests when the generated content changes

If a checked-in file contains a legacy marker, refresh it by running the relevant setup/render path or by replacing the whole generated section with renderer output. Do not edit inside `<!-- BEGIN BEADS INTEGRATION ... -->` and `<!-- END BEADS INTEGRATION -->` as if it were hand-owned prose.

## Proposed Upstream Issue or PR

Preferred shape: one small upstream PR, because this is documentation and template hygiene with low implementation risk.

Suggested title:

```text
docs: align agent instructions with maintainer and signing conventions
```

Suggested scope:

1. Add `docs/AGENT_SIGNING.md` with the comment signature and `Agent-Signature:` trailer convention.
2. Link that signing doc from `AGENTS.md` and `AGENT_INSTRUCTIONS.md` near commit/PR workflow guidance.
3. Add a short `PR_MAINTAINER_GUIDELINES.md` bullet requiring a final reread of PR comments, review threads, and linked issues before finishing maintainer action.
4. Add or wire `scripts/gh-body-lint` for GitHub body files, or document the body-file linting rule if upstream already has an equivalent script in progress.
5. Refresh the checked-in `AGENTS.md` managed bd integration block to the current marker format using setup/render output.
6. Decide and document the execution metadata key schema. If changing keys is too broad for this PR, file a follow-up issue that explicitly reconciles `execution_*` and flat delegation keys.

Suggested PR body "Why":

```markdown
Why:

Agent-maintained PR work now crosses Codex, Claude, and orchestration repos. The existing upstream instructions already cover project scope, storage boundaries, contributor protection, and generated bd integration blocks. This PR carries over the remaining portable conventions from the mybd coordination repo: agent execution signatures, body-file hygiene for GitHub comments/reviews, a final PR-state reread before maintainer actions, and refresh-safe generated AGENTS.md handling.

The goal is to make maintainer actions auditable and less drift-prone without moving mybd-specific coordination policy into beads core.
```

If this is filed as an issue instead of a PR, keep the same scope and acceptance criteria:

- Signing convention documented without guessing unavailable model/reasoning metadata.
- GitHub body-file hygiene documented or linted.
- Maintainer PR policy includes final reread rule.
- Generated integration blocks remain renderer-owned and checked-in marker format is current.
- Execution metadata schema conflict is resolved or tracked as a follow-up.

## Local Follow-Up

Local `PR_MAINTAINER_GUIDELINES.md` should adopt upstream's charter pointer:

```markdown
Read [bd-main/docs/PROJECT_CHARTER.md](bd-main/docs/PROJECT_CHARTER.md) when a PR changes Beads' product surface area. Scope boundaries should guide where value lands: core, metadata, integration, plugin, orchestration layer, or external tool.
```

That is local repo tuning, not a blocker for upstream.

---

_codex-gpt-5.5-medium on behalf of matt wilkie_
