# Daily report and housekeeping - 2026-09-02

Session: Claude Code (fable-5-1), framation (Fedora Bluefin-dx). Tracked as
`mybd-ekt9z`.

## Headline: Homebrew tools vanished from agent shells; PR gate silently off

`scripts/check-beads-config` failed with `dolt not on PATH`, and `gh` and
`codex` were missing too. All three live in `/home/linuxbrew/.linuxbrew/bin`.
The Bluefin image updated on 2026-09-01 (44.20260901) and its
`/etc/profile.d/brew.sh` now appends the brew bin dir only in interactive
shells (`$- == *i*`). Claude Code's Bash tool is non-interactive, so the
session shell never sees it. Shell snapshots from 2026-08-12/13 still contain
the linuxbrew path; today's does not.

Why it matters more than a missing binary: `scripts/pr-review-gate` exits 0
when `codex` is absent ("no codex, no gate - it degrades instead of
deadlocking"). On this host that means the red-team + cross-vendor gate has
been silently disabled for every Claude Code session since the image update.
Nothing warned.

- Session workaround used here: `export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH`.
- Filed **`mybd-zvups`** (P1 bug) with three candidate durable fixes: a brew
  PATH line in the chezmoi-managed `~/.bashrc` (owner call), a loud failure
  mode in `pr-review-gate` when codex is absent on a host that has `.codex/`,
  and a brew-bin fallback probe in `codex-agent` / `check-beads-config`.
- Recorded as bd memory `framation-brew-path-in-agent-shells` so the next
  session sees it at `bd prime`.
- The `index-babysit` systemd unit kept working throughout (it carries its
  own PATH), which is why its flags on `mybd-ykt9f` never stopped.

## Routine checks

- `git pull --rebase`: brought in the 2026-08-28 Windows-side report.
  `bd dolt pull`: complete.
- `scripts/check-beads-config` (after the PATH fix): ok. hooksPath
  `.githooks`, database `mybd`, 2271 issues before this session's beads.
- bd 1.2.2 (`6c124203e`) matches `.beads/.local_version`.
- `bd ready`: 24 at start. Top: `mybd-koabx` (P0 fleet shepherd),
  `koabx.1`/`koabx.2` (5974, 5641 conflicts), `mybd-ign2i` (5986),
  `mybd-py4xs`, `mybd-ykt9f`, `mybd-hli9`.
- In progress (4, none touched): cebxh, itgj, lq8i.3, 0nzhq.1.
- `index-babysit.timer`: active, firing every 30 min, ~33s per run. Tonight
  it auto-ticked two more boxes in gastownhall/beads#5711 (5693, 5631 closed);
  the index stands at 5 ticked / 41 open.
- `bd-main`: fetched, fast-forwarded 54 commits to `upstream/main`
  (`c0d8da42d`). Upstream cut **v1.3.0-rc.1** on 2026-08-31.
- No leaked `dolt sql-server` processes. Swept four empty/12K
  `beads-bd-tests-*` dirs from 2026-08-24. `/tmp` tmpfs at 56%, home at 60%.
- Upstream `Main` workflow on `main`: latest runs cancelled/blank, not a
  failure signal for our PRs.

## Upstream PR fleet

Sixteen maphew-authored PRs open against `gastownhall/beads` (17 on 08-28;
**PR 5064 merged 2026-08-29**, its `pr5064-rebase` worktree and branch
removed this session). No real check failures anywhere in the fleet.

| State | PRs | Bead |
|---|---|---|
| CONFLICTING | 5974 | `mybd-koabx.1` |
| CONFLICTING | 5641 | `mybd-koabx.2` |
| CONFLICTING | 5636 (CHANGELOG.md, gate.go, gate_test.go) | **`mybd-koabx.3`** (new) |
| CHANGES_REQUESTED | 5986, bee-ghosttrack 09-03, MERGE-AFTER-FIXES | `mybd-ign2i` |
| CHANGES_REQUESTED | 5648, bee-ghosttrack 09-03, MERGE-AFTER-FIXES | **`mybd-koabx.4`** (new) |
| CHANGES_REQUESTED | 5202, steveyegge 08-10 | `mybd-cebxh` (in progress) |
| MERGEABLE, clean | 5651 5645 5642 5635 5634 5633 5632 5630 5316 5243 | `mybd-koabx` |

5636 had been flagged by the babysitter since at least 09-01 with no bead;
5648's review landed tonight. Both now have P1 children under `mybd-koabx`,
and the fleet bead's notes point at this report.

## General hygiene

- Coordination repo: clean, only `main` locally, no stashes, no gone
  branches. Ignored cruft unchanged (`.kilo/`, `tmp/`, `worktrees/`).
- Source worktrees after pruning 5064: `list-trunc-parity`, `pr5202-rebase`,
  `pr5243-fix`, `search-all-fields`, all clean. This host never had the
  135-worktree backlog the Windows box reported on 08-28.
- `.beads.backup-pre-recovery` (1.8G): its gate `mybd-obnzd` closed on
  2026-08-24 and the 08-28 report confirms Windows on bd 1.2.2. Not deleted
  here; a DB backup is an owner call. Filed `mybd-d65mi` (P3).

## What did I notice that isn't on any list?

- A guardrail that "degrades instead of deadlocking" is a guardrail that can
  be turned off by an unrelated OS update, and nobody finds out until a
  daily check trips over a side effect. `pr-review-gate` should at least say
  so loudly on every `gh pr create` it waves through. That is the sharper
  half of `mybd-zvups`.
- The babysitter's duplicate-flag problem noted on 08-21 is still present:
  the same three "needs a session" comments repeat every cycle on
  `mybd-ykt9f`. Reading that stream is now the slowest part of the daily
  routine.
- bee-ghosttrack is reviewing our PRs (5986, 5648 tonight) with structured
  MERGE-AFTER-FIXES verdicts and reproduced test runs. That is a faster
  review loop than the fleet has had since the role change; worth serving
  those two promptly while the reviewer is engaged.
