# Issue sweep — theme:test-ci (solo-sweep run 9)

2026-07-31. Unattended lane. All 8 open `theme:test-ci` `tri:claim` stubs examined
(theme is under the 12-stub cap; nothing skipped). Dispositions are **proposals** —
nothing was closed, labelled, or posted upstream.

Code claims are read at `upstream/main` tip **8bb0d36be** (2026-07-30) unless noted.

## Dispositions

| Stub | P | Upstream | Proposed | Evidence |
|---|---|---|---|---|
| mybd-2n1ns | 3 | gh 3796 | **close** | Fixed by #4600, **merged** 2026-07-07, `7865493f7` (API `merged=true`). It rewrote `scripts/release_script_test.go` (+127); the JQ test now uses the `shellPath`/`writeFakeBD`/`copyReleaseScriptFixture` Bash-native path helpers. |
| mybd-5fbkt | 3 | gh 3805 | **close** | Same merged #4600 (+50 to `internal/hooks/hooks_test.go`). All five POSIX-shebang hook tests carry a `GOOS=="windows"` skip citing GH#3800 (l.151/193/242/344/374) — superset of the 4 filed. Root cause split to mybd-zqgat. |
| mybd-nfvi1 | 3 | gh 3800 | **close** | Same merged #4600. `cmd/bd/update_close_hook_test.go:25-33` skips on Windows with the issue's own diagnosis in the comment. Deeper ask (real Windows dispatch) → mybd-zqgat. |
| mybd-u8vex | 3 | gh 3798 | **close** | Same merged #4600. `newDoltServer` helper (`doltserver_test.go:63-75`) now `t.Cleanup`s `s.Stop` to release the log handle before `RemoveAll`; `TestDoltServer_Dial_BeforeStart:356` uses it. |
| mybd-cjcpt | 1 | gh 3811 | **keep-open** (narrowed, unblocked) | Filed bug *is* fixed by merged #4600: `init_embedded_test.go:1905-1936` counts `timeoutKills`, caps at 2, asserts the 3-way sum. Survivor is the *inverse* mode (mybd-o97vm): `l.1926 lockErrors < 1` still fails when the 5s gate serializes all 10 inits. **#5093 merged today** (`6d81e1c73`) → the file-collision block is gone. |
| mybd-qx3f | 2 | gh 4860 | **flesh-out** (half shipped) | #5174 **merged** 2026-07-31T01:04Z (`132fec3f4`, in main's history) adds a `BEADS_FIX_REQUIRE_DOLT=1` job for `./cmd/bd/doctor/fix/` in **both** `pr.yml:515-519` and `main.yml:552-556` — the PR-CI path now exists for doctor/fix. Not covered: the detect side `./cmd/bd/doctor`, and destructive-`--fix` application tests. |
| mybd-xz76h | 2 | gh 4937 | **keep-open** (verified live) | `internal/metrics/metrics.go:37-43` `DataDir()` uses `os.UserHomeDir()` with no override; `metrics_test.go` sets `HOME` only (l.13/41/76/87/138/155/192). On Windows `UserHomeDir()` reads `%USERPROFILE%` → tests write the real profile. Fix PR #4828 is **open, `merged=false`**. |
| mybd-7cpd | 2 | gh 4638 | **flesh-out** (2 of 4 leaves done) | Signal(0) **live** (`config_drift.go:333-339`); fix #4808 open, unmerged. HOME/USERPROFILE **resolved** by merged #4809 (`30fa306b0`) + #4945 (`3fe20e709`). NTFS exec bit only *skipped* by #4600, not fixed. Worktree walk-up unverified. |

**Counts:** 4 close · 2 flesh-out · 2 keep-open · 1 new bead (mybd-zqgat).

## Root-cause map

**A. The #4600 port (4 closes + half of cjcpt).** One merged maintainer PR,
`7865493f7`, absorbed five stale contributor PRs and is the single fix behind
mybd-2n1ns / 5fbkt / nfvi1 / u8vex and cjcpt's original ask. **Every one of those
contributor PRs is `state=closed, merged=false, merge_commit_sha=null`** — 3797,
3801, 3802, 3806. Citing any of them as "the fix" is the exact closed-but-unmerged
error the strategy report warns about; cite `7865493f7`. All four upstream issues
are still `open`, so tri-close should carry the label.

**B. #4600 fixed tests by skipping them.** Six Windows hook tests are now dark, and
the product gap under them — no shebang/PATHEXT/interpreter dispatch, so a Windows
user cannot write a working `bd` hook and a broken hook silently no-ops — is
untracked. Filed as **mybd-zqgat** (p2), with the six skip guards as its acceptance
target. The two closes above are only safe *because* that bead now exists. It also
subsumes mybd-7cpd's NTFS exec-bit leaf.

**C. HOME-only test isolation on Windows.** mybd-7cpd leaf 2 was swept by merged
#4809/#4945 across `cmd/bd`, storage and `internal/git`. `internal/metrics` was
missed and is still live (mybd-xz76h). That stub bundles two separable asks: the
one-line test-safety fix (set `USERPROFILE` too) and the product change (honour
`BEADS_DIR` in `DataDir()`, which is what #4828 proposes). The first is closeable
today without waiting on the PR.

**D. Stale "blocked by an active PR" notes.** Two beads carry reconciliation notes
warning off overlaps that have since evaporated: mybd-qx3f defers to #4388, which
is **closed and never merged**; mybd-7cpd calls #4808 "green/mergeable", still
unmerged 3 weeks on. Both notes are now corrected in-bead.

## Confidence and caveats

- **`merged_at`/`merged=true` checked individually for every fix claim.** Two PRs
  (#4828, #4808) have a populated `merge_commit_sha` while `merged=false` — that
  field is GitHub's speculative test-merge and is *not* evidence of a merge. If a
  future sweep greps only for `merge_commit_sha`, it will close both stubs wrongly.
- **mybd-cjcpt has an unresolved gap.** #5093 merged at 08:41 today, *after* my
  `upstream/main` ref (8bb0d36be, 07-30), and it modifies `cmd/bd/init_embedded_test.go`
  (+59/-3). The commit-API patch I could see for that file starts near `envWithout`
  (~l.110), not the assertions (~l.1868), so **I could not confirm whether 5093
  changed the `lockErrors < 1` line.** The "inverse mode survives" claim is true as
  of 8bb0d36be only — re-read at current main before working it.
- **Live lane collision on mybd-qx3f:** mybd-1fisj is `in_progress` P0 — *"main red:
  doctor/fix dep_keys + metadata_dolt tests hard-fail without the Dolt test container
  (missed by #5174)"*. Someone is inside that code path now; do not act on qx3f
  without checking with them.
- **Not verified:** mybd-7cpd leaf 4 — `findBeadsRepoRoot` is absent from
  `internal/git/worktree.go`, consistent with "dead after #3183", but I did not
  search the whole tree, so treat removal as unconfirmed. mybd-qx3f (b),
  per-function coverage of the destructive `--fix` functions, was not audited.
  mybd-zqgat's description of `hooks_windows.go` comes from the gh 3800 report plus
  the six skip-guard comments (which agree), **not** from reading that file.
- All source reads were `upstream/main` via `solo-recon show`. The `bd-main/`
  working tree was not read.
- Not blocked: no denied command I needed, bd and GitHub both available.
- Dep hygiene: all four Windows stubs already had `blocks` edges from their closed
  PR-mirror beads, so no consolidation bead was created for group A — the structure
  was already there.
