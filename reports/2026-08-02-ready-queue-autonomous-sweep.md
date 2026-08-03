# Ready-queue autonomous sweep — 2026-08-02

**Brief:** work the `bd ready` queue autonomously until dry or genuinely blocked;
use workflows; check every candidate for existing branch/PR coverage before
claiming; worktree + branch + tests + PR per task; do not decide product
questions; do not touch history.

**Outcome:** the queue is not dry and cannot be — 100 items ready at session
start, and it is a mirrored-issue backlog, not a work list. What was actually
dry is the *autonomously actionable* subset: of six candidate code fixes taken
to full recon, **one** turned out to be implementable without a maintainer
ruling. That one shipped. The other five are now documented on their beads with
the specific question that blocks each, which is the reusable output — the next
session does not have to re-derive any of it.

Nothing was merged. Nothing was closed upstream. No history was rewritten (the
one stale branch was reconciled by **merge**, not rebase).

---

## 1. What shipped

### gastownhall/beads#5316 — pin `MaxAllowedPacket` in the server DSN

Item 4 of #5273 (the PR 4167 showcase salvage list). Both MySQL DSN builders
construct `mysql.Config` as a composite literal rather than through
`mysql.NewConfig()`, so `MaxAllowedPacket` stays zero, `FormatDSN` emits
`maxAllowedPacket=0`, and go-sql-driver runs `SELECT @@max_allowed_packet`
while establishing **every** connection — an extra round trip per connection,
paid on every pool expansion.

Verified from source rather than inferred, and TDD RED confirmed: reverting only
the struct field fails both new tests with `got 0` and prints the offending DSN.

Files: `internal/storage/doltutil/dsn.go`, `internal/storage/dbproxy/util/dsn.go`,
plus both test files. Clean on `gofmt`, `go vet`, `golangci-lint` with the repo
gate's exact flags, and on both the native and `GOOS=windows CGO_ENABLED=0`
target tuples.

**The interesting part is what the cross-vendor review caught — twice, and both
times correctly.** This is the clearest case yet for that gate being a gate and
not a suggestion.

| Pass | Finding | Verdict after reconciliation |
|---|---|---|
| 1 | Pinning the driver's own 64 MiB default *shrinks* the client ceiling from ~1 GiB | **Correct.** go-mysql-server declares `max_allowed_packet` with `Default: 1073741824` and type `NewSystemUintType(..., 1024, 1073741824)`. A 64 MiB pin would make the client reject large imports/base64 content locally with `ErrPktTooLarge`. Fixed by pinning 1 GiB. |
| 2 | The server does not actually enforce that sysvar for ordinary queries | **Correct.** In go-mysql-server it is read in exactly one non-test place — `sql/expression/function/load_file.go`, for `LOAD_FILE` — and nowhere in the query-packet path. Vitess's `MaxPacketSize` is the unrelated 16 MiB protocol chunking constant. |

Finding 2 is why this PR is **not** queued for auto-merge. Under the old probing
behaviour the driver set its ceiling from the server's *configured* value, so an
operator who lowered `max_allowed_packet` got a client-side rejection; after this
change they do not. But since the server appears never to enforce it for query
packets, that client-side cap was arguably the *only* thing honouring the
setting — and whether Beads intends to keep honouring it is a policy question,
not mine. Both options (accept as-is / probe-once-and-cache) are written into the
PR body and into bead `mybd-43k7j`, labelled `human-decision`. The trade-off is
in the code comment either way, so it is not silent.

Two commits kept deliberately rather than squashed locally, so the reasoning —
including the 64 MiB mistake — stays on the record.

### gastownhall/beads#5092 — unstuck, by merge

`CONFLICTING` / `DIRTY`, 255 commits behind, `gh pr update-branch` could not
resolve it. Now `MERGEABLE` at `3f0c5d72b`.

One conflicted file, `cmd/bd/uow_factory.go`, where this PR's hardened dolt
resolve/probe helpers and an upstream refactor of the same function landed on
top of each other. Both sides kept. **The line that mattered:**
`newManagedProxiedServerUOWProvider` takes upstream's new topology-struct
signature and body but *our* `resolveAndProbeDolt`, not upstream's
`exec.LookPath`. A merge that let `LookPath` come back would have compiled,
passed tests, and silently defeated the entire point of the PR.

Independent review returned SAFE-TO-COMMIT on strong evidence: the diff between
the merged tree and `upstream/main` is the same 14 files with the same per-file
line counts as the diff between the merge base and the PR head — i.e. the merged
tree is exactly `upstream/main` plus this PR's patch, nothing dropped, nothing
invented.

One reviewer should-fix applied: the `resolveAndProbeDolt` error label was
hardcoded `"newProxiedServerUOWProvider"`, but upstream's server-mode path
(`bd serve` → `newSQLServerUOWProvider`) now routes through this function too, so
a `bd serve` failure would have been mislabelled.

Also **not** queued for auto-merge, for a reason worth flagging: the merge
*widens the hardened probe's blast radius* to `bd serve`, which now forks a
10s-bounded `dolt version` probe where upstream only did `exec.LookPath`. That is
consistent with the PR's intent, but it is new surface introduced by the merge
that no upstream reviewer has seen. Said so in a PR comment. `make test`
enqueued on the verify lane.

---

## 2. Merge-lane hygiene — six lanes cleared

The patrol parks lanes for agent judgment and then waits. Four had been waiting
since 2026-08-01; two were parked on PRs that had already resolved.

**Closed as stale — the PR resolved while the bead sat parked.** This is the
"session-close miss" pattern the `agent-batch-current` memory already warns
about; it recurred twice more.

- `mybd-n8an7` — #5245 **merged**.
- `mybd-5eacq` — #5240 **merged** (and its macOS PR leg immediately proved its
  worth, see below).
- `mybd-msll` — #5251 **merged**.
- `mybd-0fnrw` — #5197 **closed** unmerged; dependabot confirmed the goldmark
  bump is superseded, so the lane had no subject.

**Re-armed after judgment.** All were congestion from the 2026-08-01 afternoon
merge burst (the systemic fix is `mybd-j1wcr`), not defects. Each got
`update-branch`, cleared `pr_babysit_freshen`/`freshun`/`rerun_head`, and a
re-claim so it does not read as unowned:

- `mybd-cebxh` (#5202), `mybd-pp5hv` (#5229), `mybd-dtdm` (#4959) — all green,
  parked on stale-green or preflight-transient during the churn window.
- `mybd-jxlgz` (#5277) — the one worth explaining. Its only red was
  `Test (macos-latest)`, and it was **not a defect**: `cmd/bd` hit go test's 10m
  budget (`FAIL ... 600.478s`, `panic: test timed out after 10m0s`, **zero
  `--- FAIL` lines**). That leg only began running on PRs when #5240 merged at
  2026-08-01T22:11Z, and the fix for its duration — #5311, which stops `cmd/bd`
  subprocess helpers relinking the binary during the test step — merged
  2026-08-03T04:46Z, ~14h *after* this PR's checks ran. The red was earned
  against a base that predated its own remedy.

**Left blocked, deliberately: `mybd-ciuod` (#5219, AlexBelous).** Marked
`human-decision`. Its failure is a genuine contract collision, not flake:

```
--- FAIL: TestProxiedServerWispGC/cascade_sweeps_dependent_step_wisps
wisp_proxied_integration_test.go:301: expected dependent child wgc-wisp-uz8
  cascaded even though it's not itself old
```

The PR is titled "apply the `--age` test to cascade children"; the test asserts
the exact opposite as the intended contract. Sibling subtests all pass, so the
suite is healthy. One of the two is wrong and deciding which is a wisp-gc
semantics question. The existing `APPROVED` review predates this red and appears
not to have accounted for it. Nothing posted upstream.

---

## 3. The five that were blocked, and by what

Full detail is on each bead — this is the index. Every one was checked for
existing coverage keyed on the **file**, not the topic, per the AGENTS.md rule;
none had any, in open PRs or unpushed local branches.

| Bead | Issue | Blocked by |
|---|---|---|
| `mybd-u5hng` | #5300 | The issue's own headline ask is "define one explicit runtime contract" and it names two candidates while picking neither. Drift is real and worse than reported: `--check` is not repo-aware **at all** (`runChecks` never computes a repo root), so beads-specific `gms_pure_go` tags and the nix/version/AGENTS checks run in *any* repo. Root cause visible in history — #4425 made the *checklist* project-aware and left `--check` behind. |
| `mybd-sfiw` | #4816 | The reporter closed his body with an explicit **"Open question for maintainers"** about the exit code, and it has never been answered — zero comments since 2026-07-15. Worse, the false output is now *deliberate*: #5191 added the `res.Changed` plumbing but kept output parity on purpose, and says so in the code. His own fix PRs #4818/#4819 were closed **by him**, unreviewed. |
| `mybd-alm2` + `mybd-s4h6` | #4396, #4395 | **Not one root cause — three mechanisms.** Dotted children created without `--parent` get no `dependencies` row at all, and the codebase compensates with a dotted-ID fallback at three read sites (deliberate, documented in `buildDescendantsCTE`); the dependents path has none. Separately, `list`/`ready` counts are blocks-only *by pinned contract* while `show`'s is all-edge-types. And `bd show --json` returns an array, so `jq '.dependent_count'` is always null regardless of data. The two candidate fixes are both semantic (materialize edges + backfill migration, vs. a fourth copy of the fallback). |
| `mybd-ad63` | #4371 | **Needs repro; the reported path no longer exists.** At the reporter's v1.0.4 the code was structurally non-atomic and ordered add-before-remove (N+M independent store calls, each its own transaction) — a perfect match for the symptom. Today it is one transaction with remove before add. A residual hypothesis exists (`ApplyLabelPatch` only DELETEs labels present in the snapshot) but it is reading, not reproduction. |
| `mybd-v0ll5` | #5273 | 11 of 12 items need the owner. Classification recorded on the bead so it is not re-derived. |

**One correction the owner should make to #5273's text.** Item 8's rationale is
wrong for the remote case it targets: it claims `maybeAutoBackup` "still runs on
every command and pays a `GetCurrentCommit` round trip", but
`isBackupAutoEnabled()` returns false in server mode *before any store call*
(`cmd/bd/backup_auto.go:33`, added after the 2026-07 shared-dolt CPU-pin
incident). It should be re-graded from a perf item to a consistency item, and
note that it would also alter embedded-mode backup cadence.

---

## 4. What I noticed that isn't on any list

- **The `bd`-inside-`bd-main` cwd trap bit again**, exactly as the
  `agent-batch-current` memory predicts, and in the specific shape that makes it
  dangerous: a compound command that began `cd bd-main && gh ...` left the shell
  there, so the following `bd update` calls in the *same* invocation silently did
  nothing and returned success. The label was still on the bead afterwards, which
  is the only reason I caught it. Chaining `gh` and `bd` in one command is the
  hazard, not `cd` alone.
- **`bd close` exits 5 on success.** Twice, `bd close` printed its closing output
  and set `status=closed`, but returned exit code 5. Anything treating that as
  failure — a script, a hook, a lane — would mis-handle a close that in fact
  worked. Possibly related to `mybd-sfiw`'s territory but distinct from all three
  symptoms in #4816; noted here rather than filed, because I did not isolate it.
- **`bd show --json` returns an array**, so every `jq -r '.status'` against it
  fails with `Cannot index array with string`. Recon independently found the same
  shape is half of what #4395 reports. It is a real ergonomic trap for agents.
- **Both DSN configs also leave `CheckConnLiveness` false** where
  `mysql.NewConfig()` sets it true — same composite-literal root cause as the bug
  fixed in #5316, and visible in the emitted DSN as `checkConnLiveness=false`.
  Out of scope there; flagged in that PR's body as its own follow-up.

## 5. State at close

- **Upstream main:** green across the last four `main.yml` runs.
- **Lanes:** installed units match tracked templates; verify queue drained plus
  one new job (`mybd-reg9t`, `make test` at `3f0c5d72b`).
- **PRs opened:** #5316. **PRs unstuck:** #5092. **Neither handed to the merge
  patrol** — each carries an explicit maintainer question, recorded in the PR and
  on its bead.
- **Beads closed:** 4 (`n8an7`, `5eacq`, `msll`, `0fnrw`). **Re-armed:** 4.
  **Newly labelled `human-decision`:** 5. **Created:** 1 (`mybd-43k7j`).

_claude-opus-5-high on behalf of maphew_
