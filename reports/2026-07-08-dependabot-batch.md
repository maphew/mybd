# Dependabot batch clearance — gastownhall/beads, 2026-07-08

Bead: mybd-unwf. Session cleared the entire open dependabot queue: 13 PRs open
at start, 8 more opened by dependabot mid-session in response to our merges and
config change, 21 total dealt with, 0 open at close.

## Outcomes

| PRs | Outcome |
|-----|---------|
| #4495 #4496 #4497 #4498 #4499 | Merged as-is (GH Actions bumps, CI green) |
| #3831 | Closed superseded (x/term 0.43.0 already on main) |
| #4386 #3825 #4457 | Absorbed into maintainer PR **#4663** (merged), closed |
| #4265 #4264 #3638 | Absorbed into maintainer PR **#4672** (merged), closed |
| #3829 | Merged after `@dependabot recreate` (landed 2.5.2) |
| #4664 #4665 #4666 #4667 #4669 #4670 #4671 | New batch, merged as-is (CI green) |
| #4668 | Merged after recreate + manual run-unblock (see below) |

## Why the absorptions (the part commit messages don't carry)

**Pip batch (#4663).** The dependabot `pip` ecosystem edits only
`pyproject.toml` and never regenerates `uv.lock`, while the Package Gate (MCP)
runs `uv sync --locked` — so every beads-mcp bump was structurally unable to
pass CI, forever. Landing the three bumps one-by-one would also have meant
three mutually conflicting lockfile regens. #4663 combined them with one
`uv lock`, and — the durable fix — switched `.github/dependabot.yml` from
`pip` to the `uv` ecosystem. Proof it worked: the very next dependabot batch
(#4666–#4671) arrived with `uv.lock` updates included and merged untouched.

**Go batch (#4672).** The three go.mod bumps had been stuck CONFLICTING since
May: each one merging invalidates the others' branches, and dependabot refused
to rebase because humans had edited the branches ("edited by someone other
than Dependabot"). #4672 landed all three in one CI cycle and moved the whole
`go.opentelemetry.io/otel` family to 1.44.0 in lockstep rather than
dependabot's mixed per-module versions. It also needed a `default.nix`
vendorHash update — go.sum changes always invalidate the pinned Nix
fixed-output hash, which is another reason solo go bumps rot in this repo
(a nix automation now pushes that commit on dependabot PRs, but its push makes
dependabot refuse subsequent rebases — the #4668 story).

## Operational gotchas (also in `bd remember dependabot-maintenance-gotchas`)

1. Workflow runs on recreated/bot-pushed dependabot branches stall as
   `action_required` (triggering actor `github-actions[bot]`). The approve
   API 403s for non-fork PRs; `POST /repos/{r}/actions/runs/{id}/rerun` as a
   human user unblocks them.
2. Embedded-Dolt CI shards show transient FAILURE conclusions mid-run; judge
   a PR only at zero pending checks. (All four "mass Dolt failures" observed
   mid-session evaporated on completion.)
3. The nix vendorHash automation's commit counts as an external edit →
   `@dependabot rebase` is refused; use `@dependabot recreate` and re-unblock
   the gated runs.

_claude-fable-5-high on behalf of matt wilkie_
