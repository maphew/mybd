# Red-team gate: would it have caught what reviewers caught? (mybd-rto1j)

**Question.** Before building the pre-PR red-team gate (adversarial agent that
writes failing tests against new code paths, hunts regex/string-match bypasses,
checks test hermeticity, and probes fixture-state coupling), audit the recent
autonomous-lane PRs: of the findings human reviewers / CI actually raised
post-open, which would the gate have surfaced *before* the PR existed?

**Method.** The 10 newest lane PRs (5632–5651, the 2026-08-11 batch) have zero
review activity so far, so the audit window is the 12 most recent lane PRs
*with* feedback: 5202, 5204, 5222, 5229, 5232, 5241, 5243, 5245, 5248, 5251,
5265, 5277. One analysis agent per PR fetched all reviews, inline threads,
comments, and CI failures, extracted distinct substantive findings, and
classified each against the gate's four adversary behaviours (honest
classification instructed: `gate_would_catch=true` only when the described
adversary would realistically surface it). Raw per-finding JSON: workflow run
`wf_1f51d066-e6d` in the session transcript.

## Headline

**16 of 28 substantive post-open findings (57%) would have been caught
pre-PR.** Four PRs (5241, 5248, 5251, 5265) drew no substantive findings at
all.

| Gate behaviour | Findings it would have caught |
|---|---|
| failing-test (new tests against new code paths) | 10 |
| regex-bypass (crafted inputs vs string-match checks) | 5 |
| hermeticity (isolation / random order / cwd) | 1 |
| fixture-state | 0 |
| **caught total** | **16 / 28** |

## What it would have caught (highlights)

- **5202** (import --skip-invalid, changes_requested): 4 of 7 — the proxied
  route where --skip-invalid is a silent no-op (a direct test of the new
  branch fails), --dry-run mutating the filesystem, three named code paths
  with no coverage, and a hard-link bypass of the path-collision guard.
- **5245**: the `literalStampsRowLock` guard checks SQL text only, so a stale
  or zero token bound to a syntactically-matching statement passes — textbook
  bypass hunt against a newly added string/AST-match check.
- **5232**: `UPDATE/*comment*/` slips past the whitespace-anchored DML
  detector; multi-space `ON  UPDATE` breaks the clause masker.
- **5229**: `go build -o dir/ ./...` silently skips library packages (false
  green a deliberate broken-input test exposes); unguarded `source
  ./.buildflags` lets the grep-based tag check diverge from reality;
  zero-modules-discovered was a vacuous pass.
- **5222**: a 3-backtick line closes a 4-backtick fence — crafted-input bypass
  of the fence matcher.
- **5243**: both findings — the helper test that dodged the real
  startup-rebind path, and the .env-selector regression the first fix commit
  introduced. Notably the second was in fact caught by this repo's
  cross-vendor review *during* the fix; the gate would have moved that catch
  before the PR opened.
- **5277**: the `err == nil && n > 0` greeting check misses Go's
  data-plus-io.EOF single-Read case (adversarial peer test), and a ~100ms
  timing margin the hermeticity re-runs would likely flake out.

## What it would NOT have caught (12/28), and why

- **Scope-completeness in files the diff never touched** (4): 5277's three
  sibling-file instances of the same dial+slam-close bug; part of 5232. The
  adversary attacks the patch's own code paths; it has no mandate to sweep the
  tree for other instances of the pattern.
- **Platform/CI semantics** (2): `continue-on-error` still reporting FAILURE
  in the rollup; a pre-existing repo-wide invariant test breaking against the
  new job.
- **Shell portability** (2): bash-3.2/macOS `declare -A`, `mapfile`, GNU
  `xargs -r`. Hermeticity varies order/cwd, not OS.
- **Docs/changelog omissions** (2), **product-default disagreement** (1, the
  5202 polarity reversal), **stale comment prose** (1).

**Implication for expectations:** the gate should roughly halve review
iteration rounds on lane PRs, concentrated on correctness findings. The
residue is dominated by "same bug elsewhere in the tree" — a plausible future
fifth adversary behaviour (pattern-sweep the tree for the anti-pattern the
diff fixes), deliberately out of scope for v1.

## Dogfood: the gate red-teamed itself

A live single-round run (`scripts/red-team -C . --base main --rounds 1
--no-fix`) against this very branch exercised the real codex adversary
end-to-end (sandbox worktree, schema-enforced findings, bead filing on
exhaustion — it filed `mybd-o5esm`, closed after fixes). It returned five
P1s against its own implementation, four of them real fixes now on this
branch with regression tests:

- **RT-001** (regex-bypass): `MYBD_SKIP_XVENDOR=10` matched the `=1` hatch
  substring and skipped the gate. Hatches are now boundary-anchored.
- **RT-002** (failing-test): a hand-rolled `{"verdict":"pass","base":"main"}`
  stub satisfied the gate. It now requires a verdict only `scripts/red-team`
  could have written (matching head, findings array, numeric rounds).
- **RT-003** (fixture-state): two unrelated repos with the same directory
  basename and branch shared a `--no-fix` round counter. The state key now
  includes a checksum of the absolute toplevel path.
- **RT-004** (hermeticity): concurrent runs of `test-pr-review-gate` collided
  on the deterministic empty-commit sha and raced through the shared
  fixture files. Fixture commits now embed the run's own tmp path.
- **RT-005** (hermeticity): the test suites write to the main checkout's
  shared `.review-logs` — **accepted by design**: the sha-keyed shared log
  dir is the gate's contract, and the tests deliberately exercise the real
  location. Documented rather than changed.

Earlier, the first live run also caught a duplicate `--model` flag crash in
the codex invocation that the stub-based tests could not see. An adversary
finding five real defects in the adversarial gate itself, pre-PR, is the
mechanism working as intended.

The cross-vendor review (codex gpt-5.6-sol, high) of the post-fix diff then
found three more, all fixed with regression tests: hatch text anywhere in
the command disarmed the gate (now the hatch must be an env-style prefix on
the gh segment itself); a structurally complete "pass" verdict carrying open
P0/P1 findings satisfied the gate (now internally-consistent passes only);
and branches `foo/bar` and `foo_bar` collided on one round counter (the key
checksum now covers the raw branch name). Final suites: 57 + 37 checks
green.

## What was built (same branch)

`scripts/red-team` (adversary sandbox → P0–P3 findings → builder fix rounds,
max 3 → bead on exhaustion), wired into `scripts/pr-open` (runs before the
cross-vendor review, since fix rounds move HEAD) and enforced by
`scripts/pr-review-gate`, which now requires BOTH `.review-logs/<sha>.md` and
a passing `.review-logs/<sha>.redteam.json` for the exact commit+base.
Scoped escape hatches: `MYBD_SKIP_XVENDOR=1` / `MYBD_SKIP_REDTEAM=1`; full
bypass needs both. Smoke tests: `scripts/test-red-team-gate`,
`scripts/test-pr-review-gate`.
