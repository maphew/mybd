# Upstream triage scripts

Tooling for managing the firehose of issues + PRs on `gastownhall/beads`. The
goal is to make `bd ready` your daily triage queue instead of re-scanning the
GitHub dashboard.

## Workflow

```
1. tri-pull              # fetch new untriaged upstream items into bd
2. bd ready              # review the queue, decide one-pass per item
3. tri-close <id>        # close + apply 'triaged' label upstream (auto)
   or bd defer / bd update --notes='human: ...' for non-close decisions
```

Re-running `tri-pull` daily is idempotent. It only mirrors items lacking the
`triaged` label upstream and skips any already in bd (matched by `external_ref`).

## tri-pull

```bash
scripts/tri-pull              # full pass: issues + PRs, limit 100 each
scripts/tri-pull --limit 30   # smaller batch
scripts/tri-pull --prs-only
scripts/tri-pull --issues-only
scripts/tri-pull --dry-run    # preview
```

Each created bd issue:
- `external_ref`: `gh-pr-NNNN` / `gh-iss-NNNN` — the structured upstream link
- `title`: the upstream title verbatim
- `description`: URL, author, created date, labels, draft flag, decision options
- `priority`: P3 default; **P4** for dependabot bots and drafts
- `type`: `bug` if title starts `fix(`/`fix:`, `feature` if `feat(`/`feat:`, else `task`

The heuristic priority/type is intentionally crude — Layer 1 is *get items into
bd*, not auto-rank them. You set the real priority during triage.

## tri-close

```bash
scripts/tri-close mybd-XXX                      # close + label upstream
scripts/tri-close mybd-XXX --reason="dupe of #1234"
scripts/tri-close mybd-XXX --skip-label         # close bd only (rare)
scripts/tri-close mybd-XXX --dry-run            # preview
```

Reads `external_ref` to know which upstream PR/issue to label. Refuses to act
on bd issues without a `gh-(pr|iss)-NNNN` ref — use `bd close` directly for
non-triage stubs.

## Triage decision tree (per item in `bd ready`)

| Decision  | What to run                                              | When                                        |
|-----------|----------------------------------------------------------|---------------------------------------------|
| **close** | `tri-close <id> --reason="..."`                          | Won't engage; dupe; out of scope; rejected  |
| **defer** | `bd defer <id> --until="next monday"`                    | Re-look later; not actionable now           |
| **claim** | `bd update <id> --claim` + flesh out desc, set real priority | You'll actually do the work                 |
| **human** | `bd human <id>` (or add `--notes="human: <Q>"`)          | Need a maintainer call before deciding      |

For `claim`: the stub becomes the real working bead. Add proper description,
acceptance criteria, dependencies, etc. The `external_ref` stays so the link
to upstream survives.

## Configuration

Override the upstream repo with `TRI_UPSTREAM` env var (default
`gastownhall/beads`):

```bash
TRI_UPSTREAM=other/repo scripts/tri-pull
```

## Existing artifacts

- `_working_on/upstream_pr_triage.md` — manual T1–T5 ranking with scoring rubric
- `_working_on/pr-reviews/NNNN.md` — per-PR detailed review notes

These predate the tooling. When you `claim` a stub, link to the matching
review note in the bd description if one exists.

## Layer 2 (planned, not built yet)

See bd issues for cron auto-pull, smart classifier, batch grouping, and metrics.
