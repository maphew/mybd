---
description: Layer 2 issue triage - mirror upstream into bd, classify each stub to a one-line disposition, emit a short digest. Never posts text upstream.
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*), Agent(*)
---

Run the pinned triage procedure. The deliverable of triage is a DISPOSITION
per item plus one sentence of why - not an essay. This command exists because
free-form triage drowned readers in text (owner feedback, 2026-07-07). Follow
the procedure and the caps exactly; do not improvise extra output.

Hard rules, non-negotiable:

- **Never post text to upstream GitHub.** No `gh pr review`, `gh pr comment`,
  `gh issue comment`. Do not run `tri-submit`. The only upstream writes allowed
  are text-free `triaged` labels via `scripts/tri-close`.
- Run all bd/gh-writing steps **serially** (embedded-Dolt locking).
- Classification subagents are **read-only** and cheap (scout tier).

## 1. Mechanical sync (Layer 1)

```bash
scripts/tri-pull          # mirror new untriaged upstream items into bd
scripts/tri-sync          # close stubs whose upstream item is terminal
```

Record the counts they report for the digest header. If either fails on gh
auth or rate limits, report and stop.

## 2. Classify (Layer 2)

Build the worklist: open bd stubs with a `gh-(pr|iss)-NNNN` external_ref and
no existing `tri:*` label:

```bash
bd list --status=open --limit 0 --json \
  | jq -r '.[] | select(.external_ref != null and (.external_ref | test("^gh-(pr|iss)-[0-9]+$")))
           | select(((.labels // []) | map(startswith("tri:")) | any) | not)
           | "\(.id) \(.external_ref) \(.title)"'
```

For each item, produce a classification with EXACTLY this shape (read-only
scout subagents may fetch `gh pr view` / `gh issue view` for signals; batch
several items per subagent):

- `disposition`: one of `close` | `defer` | `claim` | `human` | `needs-info`
- `priority`: P0-P4
- `reason`: **max 200 characters**, one sentence
- `confidence`: high | medium | low

Disposition guide: `close` = obsolete, duplicate, already-handled upstream,
or clearly not actionable by us; `defer` = real but not now; `claim` = we
should do it and the spec is clear; `human` = judgment call the owner must
make (contentious, social, or high-stakes); `needs-info` = cannot classify
from available signals.

## 3. Record (serial)

For each classified item, one bd update:

```bash
bd update <id> --add-label "tri:<disposition>" --priority <Pn> \
  --append-notes "[triage $(date -u +%Y-%m-%d)] <reason>"
```

For `close` dispositions with **high** confidence only, also run
`scripts/tri-close <id> --reason="<reason>"` (closes the stub and applies the
text-free upstream `triaged` label). Medium/low confidence closes stay open
with the `tri:close` label for the owner to confirm.

## 4. Digest (the only human-facing output)

Write `reports/triage/YYYY-MM-DD.md` (md only, no html). Format, strictly:

```markdown
# Triage digest - YYYY-MM-DD

Pulled N new, auto-closed M terminal, classified K.

| bd | ref | disp | P | conf | reason (<=200 chars) |
|----|-----|------|---|------|----------------------|
```

One row per item, one line per row. After the table, at most two short
sections:

- **Flagged for human** - the `human` and low-confidence items, one line each,
  with the single question the owner must answer.
- **Coverage** - anything skipped (rate limits, fetch failures, window
  truncation reported by tri-pull).

The whole digest must stay under ~80 lines. If the item count would exceed
that, keep the flagged items as rows and collapse the rest into per-disposition
counts, noting the collapse in Coverage.

## 5. Report back

In the conversation, give ONLY: the counts line, the flagged-for-human items,
and the digest path. Do not restate the table. Do not close this command's
work with a session push unless the user asks; the digest file plus bd labels
are the deliverable.
