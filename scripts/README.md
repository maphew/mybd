# Upstream triage + review scripts

Tooling for managing the firehose of issues + PRs on `gastownhall/beads`. Two
loops: **triage** (decide what to do) and **review** (do the PR work, resumable
across machines).

## Daily workflow

```
1. tri-pull                     # fetch new untriaged items into bd
2. bd ready                     # see queue, decide per-item:
     close / defer / claim / human
3. tri-review <id>              # for claimed PRs: worktree + scaffold + checks
4. (read, edit pr-reviews/NNNN.md, optionally tri-checkpoint)
5. tri-submit <id> --approve    # post review + close bd + label upstream

For non-PR triage stubs: tri-close <id> [--reason=...]
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

## tri-review (PR work loop)

```bash
scripts/tri-review mybd-XXX                  # claim, worktree, build+lint, scaffold note
scripts/tri-review #3482                     # accepts PR# directly (resolves via external_ref)
scripts/tri-review mybd-XXX --tests          # also run go test ./... (slow)
scripts/tri-review mybd-XXX --no-checks      # skip build/lint, just scaffold
scripts/tri-review mybd-XXX --reuse-worktree # don't fetch/recreate (resuming)
```

Effects:
- Fetches PR branch into `bd-main/` (origin/pull/NNNN/head:pr-NNNN-review)
- Creates worktree at `~/dev/mybd-tri/<NNNN>/`
- Runs `go build ./...` + `golangci-lint --fast` (or `go test ./...` with `--tests`)
- Scaffolds `_working_on/pr-reviews/<NNNN>.md` with auto-computed signals (size, age,
  type, mergeable, CI checks, closes-issues, build/lint/test status)
- Logs `review-started: worktree=... note=...` to bd notes (timestamped + hostname)
- Sets bd status to `in_progress`

If the review note already exists, it is left untouched — you keep your work.

## tri-resume (cross-machine)

```bash
scripts/tri-resume          # show all in-flight PR reviews
scripts/tri-resume --json   # machine-readable
```

Lists every bd issue with `status=in_progress` and a `gh-pr-*` external_ref:
bd-id, PR#, whether worktree exists on *this* machine, age of the review note,
last checkpoint or title. Use it when you sit down at any machine to pick up
where you (or another machine of yours) left off.

## tri-checkpoint (graceful machine switch)

```bash
scripts/tri-checkpoint <id> "stopped at concerns section, need to verify test coverage"
scripts/tri-checkpoint #3482
```

Appends a checkpoint note to bd, commits review-note + bd state changes (if
any), `git pull --rebase`, `git push`. Worktree branches are local-only by
design; if you've made commits in the worktree you want to keep, push them
manually first (e.g., to a `wip/` branch on your fork).

## tri-submit (finalize)

```bash
scripts/tri-submit <id> --approve
scripts/tri-submit <id> --request-changes
scripts/tri-submit <id> --comment
scripts/tri-submit <id> --approve --dry-run    # preview
```

Reads `pr-reviews/<NNNN>.md`, posts as a `gh pr review --<verdict>`, then
calls `tri-close` to close bd + apply upstream `triaged`. Refuses if the
note's `Verdict:` line is still `TBD`.

## Existing artifacts

- `_working_on/upstream_pr_triage.md` — manual T1–T5 ranking with scoring rubric
- `_working_on/pr-reviews/NNNN.md` — per-PR detailed review notes (now scaffolded by tri-review)

## Configuration (env vars)

- `TRI_UPSTREAM` — upstream repo (default `gastownhall/beads`)
- `TRI_WORKTREE_BASE` — worktree parent dir (default `~/dev/mybd-tri`)
- `TRI_BD_MAIN` — canonical upstream checkout (default `<project>/bd-main`)
- `TRI_REVIEWS_DIR` — review notes dir (default `<project>/_working_on/pr-reviews`)

## Layer 2 (filed as beads, not built yet)

cron/loop daily auto-pull · smart classifier (auto-priority from rubric) ·
close-on-merge sync · bd close hook → upstream label · epic/batch grouping
for stacked PRs · weekly triage metrics. See `bd ready`.
