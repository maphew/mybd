# GitHub Repro Worklist Audit

Work item: `mybd-pxzp`

The generated worklist in `github-repro-worklist-2026-06-16.{md,json}` is a refreshed inventory and first-pass classifier, not a trusted final list of recipe-present items.

Trusted inventory counts:

- Open issues: 263
- Open PRs: 212
- Total open items: 475
- Already labeled `has-repro`: 7

The classifier's `needs-verification` bucket is too broad:

- `needs-verification`: 369 total
- issues: 218
- PRs: 151

This conflicts with the epic baseline of 185 recipe-present items. Treat the broad bucket as a queue for second-pass triage, not as proof that each item has a runnable reproduction recipe.

Known weaknesses:

- Symptom words such as "expected", "actual", "observed", "fail", "panic", and "error:" identify bug reports but do not necessarily identify runnable recipes.
- Any code fence or command-looking line currently counts as a recipe, which pulls in PR templates, tests, docs snippets, and implementation examples.
- PRs need special handling: many should route to linked issues, not be independently verified from PR body text.
- Environment classification is noisy because terms such as `https://`, `remote`, and `gh ` are broad.

Recommended next step: tighten the recipe classifier with a second-pass audit before using the worklist for broad labeling decisions.
