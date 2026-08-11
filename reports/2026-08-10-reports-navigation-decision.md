# Reports corpus navigation: recommendation (mybd-0nzhq)

**Date:** 2026-08-10
**Status:** recommendation for owner sign-off; the supporting tooling (mybd-0nzhq.1) is implemented and tested on Linux pwsh, pending a Windows smoke run.

## Question

The reports corpus is ~135 tracked Markdown files and growing by several per week. How should it stay navigable without new infrastructure, while preserving reports as the durable "why" record?

## Recommendation

Adopt the two-layer model already prototyped, and nothing heavier:

1. **Authored layer - `reports/README.md` reading room.** A hand-curated index whose Active Threads section groups reports by ongoing question, not by date. Curation is deliberate editorial work done at session close, in the same commit discipline as the reports themselves. Each thread reads: narrative and reading links, then open questions, then live bead context.

2. **Derived layer - `scripts/report-room.ps1`.** A deterministic, zero-inference joined reader: it parses the authored threads, hydrates referenced `mybd-*` beads with one batched read-only `bd show --json`, computes exact age facts, and renders a disposable offline HTML page (temp dir, never tracked, never under `reports/`). `check -Json` gives the same facts as machine-readable structured output for future agent skills.

## What was considered and rejected

- **Static site generator or GitHub Pages** - hosting, build chain, and a second rendering pipeline to keep honest; the corpus's consumers are one human and their agents, both local.
- **Tracked HTML twin** - explicitly banned by the 2026-07-07 md-only policy; drift between twin and source was the original failure mode.
- **Agent-driven browsing as the primary interface** - spends inference on navigation, varies between runs, and slow for the "returning after time away" first job. Agents remain free to read the same `check -Json` output.
- **Date-only archive with no curation** - the corpus already has this (filenames sort chronologically); it answers "what happened when" but not "where does this question stand", which is the re-entry job.

## Costs and boundaries

- Curation debt: unthreaded reports accumulate silently. Mitigation: `check` reports `unthreaded_since_latest` as an informational finding, so staleness of the reading room itself is measurable.
- The reader is read-only by contract: no `bd serve`, no mutation, tests are fixture-driven. HTML output is self-contained with no remote assets.
- v1 non-goals stand: no semantic clustering, no full-text search, no `$report-curator` skill. Revisit only if the corpus outgrows hand curation.

## Decision requested

Approve this two-layer model as the standing navigation policy for `reports/` (or amend). On approval, mybd-0nzhq closes; the reader bead mybd-0nzhq.1 closes after its Windows smoke run.
