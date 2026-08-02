# Issue sweep — theme:cli-ux, solo-sweep run 14 (2026-08-02)

Unattended lane. Proposals only; nothing published, closed, or committed except
this file. Procedure: `reports/2026-07-26-triclaim-drain-strategy.md`.

**This run completes theme:cli-ux.** Runs 12 and 13 dispositioned the p1/p2
stubs; the 11 remaining were all p3, so the whole tail fit under the 12-stub
cap. No stubs were left unreached.

All code claims read at `upstream/main` **a6b51bd36** (2026-08-02). The prior
verify pass was against `c989b6b87` (2026-07-27), six days stale — two of its
findings needed correction, noted below. All 11 upstream issues are still OPEN;
none has a comment newer than 2026-06-16.

## Dispositions

| bead | upstream | disposition | evidence |
|---|---|---|---|
| mybd-03jmk | 3102 | flesh-out | Feature absent (`cmd/bd/update.go` has inline notes flags only). Timeline names commit `6294e461cbeb` "feat(update): add --notes-file and --append-notes-file flags" (2026-05-28) — resolves via API but **not merged**: `compare main...6294e461` = diverged, ahead 84. No surviving PR. |
| mybd-e6x29 | 4068 | flesh-out | No `verbose` token in `cmd/bd/dolt.go`. Timeline names commit `42c063f1b60c` (2026-05-31) — **not merged**: diverged, ahead 108. No surviving PR. Upstream's "gated on storage rewrite" claim not re-verified. |
| mybd-pah7v | 3529 | flesh-out | Half-fixed, path finally pinned. `stats` **is** in `readOnlyCommands` (`cmd/bd/main.go:154`); `memories` is **not**, though `cmd/bd/memory.go:201` defines it as "List or search persistent memories". One-line fix → mybd-b25fy. |
| mybd-agjb | 4438 | consolidate | Umbrella, upstream-deferred to Dolt Server v2. Error-tolerance half largely landed: `isDoltNothingToCommit` guards throughout `internal/storage/dolt/`, plus `d3e35b8be` (#5242, **verified on upstream/main**) extending it to `EmbeddedDoltStore.Commit`. Actionable slice → mybd-b25fy. |
| mybd-lh3kc | 2908 | flesh-out | No top-level `claim` command at main; functionality exists only on `bd update` / `bd close` flags. Timeline empty. Zero-arg auto-claim UX still unimplemented. |
| mybd-kqm7 | 4397 | flesh-out | Exclusion error still live at `cmd/bd/create.go:448` (was :427 — line moved, behaviour unchanged). Real defect is discoverability: neither flag's help text names the other. |
| mybd-bj0x | 4503 | flesh-out | Both installers still hardcode `releases/latest`: `scripts/install.sh:298,750` and `install.ps1:185,83`. No version arg or env var. **Path correction:** `install.sh` moved off the root in `4e15bedd0`; the 07-27 note sends you to the wrong place. |
| mybd-xfmr8 | 4908 | flesh-out | In-repo `winget/SteveYegge.beads.installer.yaml` is **dead, not merely stale**: pinned to 0.30.7 with an all-zeros arm64 `InstallerSha256` placeholder — never submittable. It *does* carry `PortableCommandAlias`, which is the trap. Proves the template is not the publish source. |
| mybd-h5pky | 3496 | keep-open | Reported repro fixed at main (jj-secondary workspace resolution present in `internal/routing/routing.go`); stale `(GH#2950)` citation survives verbatim at `routing.go:60`. **Collision:** mybd-w7yc (gh-pr-4242, `bd -C` role detection) is `in_progress` in another lane and may be using this as evidence. |
| mybd-yyks | 4776 | keep-open | Premise refuted: `cmd/bd/list.go:421` defaults `--limit` to 50 (`workapi.DefaultListLimit`), plus the `MaxRows` cap layer — both predate the issue, which asks for a *looser* default of 500. Cannot rule out `--limit 0` / `--tree` / an old build. |
| mybd-f2kq | 4506 | keep-open | Temp paths consistently derive from `os.TempDir()` (`internal/storage/dolt/circuit.go:88-92,368`; `internal/doltserver/sweep.go:34-38`), so `TMPDIR` redirection likely already satisfies this. Issue names no path, command, or OS. Needs a reporter question. |

**Counts:** flesh-out 7, keep-open 3, consolidate 1, **close 0**.

Zero closes is the honest outcome, not a shortfall: nothing in this batch was
fixed upstream since filing. The two closest calls (4776, 4506) are
"not reproducible as described", which needs a reporter round-trip, not a
maintainer verdict.

## Root-cause map

**A. Abandoned complete implementations (3102, 4068) → new bead mybd-8ab4p, p3.**
Both features were fully implemented on branches that diverged from main and
were never merged; both issues then sat open 2–3 months. Neither commit is
reachable from any open PR, so `gh pr list`, `pr-preflight --search`, and branch
sweeps are all blind to them — only the timeline `referenced` event exposed
them. Anyone working these from the bead text alone reimplements from scratch.
The ask is a decision per commit (revive with attribution, or record why it was
abandoned), not implementation. Worth checking whether the shape is common
enough to fold the recon into standing triage.

**B. Read-only command misclassification (3529, 4438) → new bead mybd-b25fy, p2.**
`bd memories` — a pure reader, and on the hot path for every agent session in
this repo per AGENTS.md — is missing from `readOnlyCommands`, so it opens the
store for writing and emits the no-op warning gh-3529 reported in April. `stats`
was added; `memories` was missed. A pure reader going unclassified for three
months means the map is hand-maintained with no test behind it, so the fix is
one line plus an audit plus a test. Independent of the Dolt Server v2 work that
governs the gh-4438 umbrella.

**C. Premise refuted or underspecified — needs the reporter (4776, 4506, 3496).**
Three stubs where the code does not behave as the issue asserts, but where
closing requires a question we cannot ask from this lane.

**D. Small, genuinely-open CLI gaps (2908, 4397, 4503).** Ordinary work; each
bead now carries acceptance criteria. 2908 adds top-level UX surface and should
get an owner nod before anyone builds it.

**E. Packaging pipeline, outside the Go tree (4908).** Root cause is now
established (the repo template is not the publish source); the fix lives in
whatever submits to `winget-pkgs`.

## Confidence and caveats

- **Everything here is a source read at `upstream/main`.** This lane has no
  shell to run `bd` in, so no repro was executed. Where a claim depends on
  runtime behaviour rather than source — chiefly that the `memories`
  misclassification is the *sole* remaining cause of gh-3529's log noise — it is
  inference, and the per-bead note says so.
- **One merge claim, verified:** `d3e35b8be` (#5242) is on `upstream/main`. The
  two commits in group A were checked the same way and are **not** ancestors of
  main — `compare` returned `diverged` with nonzero `ahead_by` for both. That
  check is what kept them from being written up as fixes.
- **Could not re-verify:** the live `winget-pkgs` manifest for 4908.
  `GET repos/microsoft/winget-pkgs/contents/manifests/s/SteveYegge/beads`
  returned 404 and code search was unusable, so "the published manifest lacks
  the alias" rests entirely on the 2026-07-27 verification. The 404 may itself
  be meaningful — establish where the package actually publishes before working
  it.
- **Two prior-note corrections** worth carrying: `install.sh` is at
  `scripts/install.sh`, not the root (4503); `create.go:427` is now `:448`
  (4397). The 07-27 pass was six days stale and both would have sent someone to
  the wrong line.
- **Not re-read this run:** the gh-4068 issue body (so the storage-rewrite
  gating claim is unconfirmed), the gh-4438 Dolt-Server-v2 deferral rationale,
  gh-pr-4242's scope, and the single comment on gh-4397 — which might reveal the
  reporter wanted `--id` + `--parent` *supported* rather than documented, making
  it a design question instead of a message fix.
- **One collision, unresolved:** mybd-h5pky vs. the in-progress mybd-w7yc lane.
  Left open deliberately rather than dispositioned around.
- Two working-tree greps (in `bd-main/`) were used to *locate* file paths; every
  resulting claim was then re-read at `upstream/main` before being written down.

_solo-sweep run 14 — claude-opus-5-high on behalf of maphew_
