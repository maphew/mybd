
## Summary

The CLI reference documentation (`docs/CLI_REFERENCE.md`, `website/docs/cli-reference/*.md`) is manually maintained and drifts out of sync with actual commands. We implemented a new `bd help --all` feature in PR #1699 (which walks the live Cobra command tree) and auto-generate these docs; now merged to main.  

## Motivation

- `bd help --all` produces a complete ~5700-line markdown reference from live code
- Manual docs (`docs/CLI_REFERENCE.md` at 937 lines) are incomplete and lag behind
- Website docs (`website/docs/cli-reference/`) duplicate effort and diverge from reality
- Inspiration came from Fossil SCM which emits single-source-of-truth from the binary itself

## Expansion Plan

### Phase 1: Per-command doc generation

Add a `bd help --doc` flag (or `bd doc` subcommand) that outputs markdown for a single command:

```bash
bd help --doc sync > website/docs/cli-reference/sync.md
bd help --doc create > website/docs/cli-reference/create.md
```

Output format should include Docusaurus frontmatter:
```markdown
---
id: sync
title: bd sync
sidebar_position: 10
---
# bd sync
...
```

### Phase 2: Batch generation script

Add `scripts/generate-cli-docs.sh` that:

1. Iterates all top-level commands via the command tree
2. Generates one `.md` file per command group (or per command)
3. Adds Docusaurus frontmatter for website integration
4. Generates `docs/CLI_REFERENCE.md` as a single combined file

```bash
#!/bin/bash
# scripts/generate-cli-docs.sh
BD=./bd
OUT=website/docs/cli-reference

for cmd in $($BD help --all --list); do
  $BD help --doc "$cmd" > "$OUT/${cmd}.md"
done

# Also regenerate the combined reference
$BD help --all > docs/CLI_REFERENCE.md
```

### Phase 3: CI freshness check

Add a CI step that:
1. Builds `bd`
2. Runs doc generation
3. Diffs against committed docs
4. Fails if they diverge (forces docs to stay in sync)

```yaml
- name: Check CLI docs freshness
  run: |
    make build
    ./bd help --all > /tmp/cli-ref.md
    diff docs/CLI_REFERENCE.md /tmp/cli-ref.md
```

### Phase 4: Integrate with llms-full.txt generation

Replace `scripts/generate-llms-full.sh` static file concatenation with live-generated CLI reference content, keeping the conceptual docs from `website/docs/` for context.

## Design Considerations

- **Cobra has `cobra/doc` package** — generates markdown/man/yaml docs from command tree. Consider using it instead of custom walker, but its output format may need customization for Docusaurus.
- **Frontmatter injection** — need a mapping of command to sidebar_position for Docusaurus ordering
- **Supplementary prose** — some docs have conceptual explanations beyond just flag listings. Consider a convention like `website/docs/cli-reference/sync.extra.md` that gets appended to generated output.
- **Generated file markers** — add `<!-- AUTO-GENERATED: do not edit manually -->` headers

## Existing Infrastructure

- `cmd/bd/help_all.go` — `writeAllHelp()` and `writeCommandHelp()` already walk the Cobra tree
- `cmd/bd/prime.go` — `bd prime --full` outputs condensed CLI reference for AI context
- `scripts/generate-llms-full.sh` — concatenates static docs into `llms-full.txt`
- `docs/CLI_REFERENCE.md` — manually maintained (to be replaced)
- `website/docs/cli-reference/` — Docusaurus pages (to be auto-generated)
