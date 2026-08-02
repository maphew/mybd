# Issue sweep — theme:cli-ux (run 13, unattended solo-sweep)

2026-08-02. Second cli-ux pass; run 12 (same day) took 12 stubs, leaving 23.
This run took the 12 that remained at p2 — the whole p2 remainder — leaving
**11 p3 stubs unreached** (#2908, #3102, #3496, #3529, #4068, #4397, #4438,
#4503, #4506, #4776, #4908). Every claim below was re-verified against
`upstream/main` at `21ca92db6` (2026-08-02), not `bd-main/`. Nothing was
closed, labelled, or posted upstream.

**No stub in this batch was fixed upstream.** All 12 upstream issues are still
open with zero new comments. One prior bead note was found to be wrong.

## Dispositions

| bd | upstream | proposed | evidence |
|----|----------|----------|----------|
| mybd-sfiw | #4816 | flesh-out (retarget) | **Prior note was wrong.** It cited #4820 as the fix; #4820 is **verified merged** but its body says "Fixes #4817. Independent of the #4816 stack" and it touches only `epic*.go`. The real stack #4818/#4819 is **verified closed, merged=false**. Meanwhile #5191 (**verified merged** 07-31, `b92442d1a`) landed the plumbing — `res.Changed`, `alreadyClosed` at `close.go:207` — but `close.go:196-205` says it keeps "OUTPUT parity" on purpose, and `close.go:263` prints the same ✓ for both branches. Cheap now, but a maintainer call. |
| mybd-g07u | #5054 | **consolidate** → mybd-jna5a | `create.go:644` `outputJSON(created)` (object) vs `show.go:364` `outputJSON(allDetails)` (slice). Confirmed; nothing merged that normalizes envelopes. |
| mybd-txicf | #4982 | flesh-out (retarget) | **Premise partly wrong, and wrong when filed.** `bd create --mol-type` does populate the field (`create.go:216-221,377,541`) and has since `f3dcafca6`, 2025-12-28. Real gap: `pour.go` has no `mol_type` at all, and `update.go` has none either, so poured steps are permanently invisible to the `ready.go:722` / `list.go:483` filters. Retitle before engaging. |
| mybd-p5k4 | #5049 | flesh-out | Both halves confirmed: `config.go:310` hardcodes `"location": "config.yaml"` while siblings at 182/206/332 report real provenance; `main.go:763` says `Default: off` vs `internal/config/config.go:244` `SetDefault("dolt.auto-commit", "on")`. Non-breaking, lands independently. |
| mybd-q6iq | #5048 | flesh-out | `routed.go:251-260` verbatim `strings.Index(beadID, "-")` + exact-equality match. Multi-hyphen route prefixes can never match. Also returns `""` on `idx==0`. Small, no design question. |
| mybd-7sogg | #4927 | flesh-out | Two swallows compose: `internal/beads/context.go:112` boundary-rejects a cross-home dir, then `prime.go:345-356` maps *any* error to `false`. Feeds `localOnly` at `prime.go:596` → the no-remote policy text at 607-611. |
| mybd-ap5nk | #5096 | flesh-out | Gate exists but on the wrong axis: `setup/agents.go:57-64` omits the raw push only when **no remote** is configured. A repo with a remote *and* a guarded wrapper is exactly the uncovered case. `setup/codex.go:24` already points at `bd prime`, so the preferred direction is half-built. |
| mybd-si4zw | #4745 | flesh-out | No push flag / `doltPush` call / registration anywhere in `update.go`. Feature, not bug — design questions (opt-in vs default, failure semantics, `auto-commit=batch` interaction) belong in acceptance. |
| mybd-47ly | #4437 | flesh-out | N+1 confirmed at `graph.go:391,405,420-425` — and *documented in place* at `graph.go:142-143`. Maintainers know; the blocker is threading `MaxRows`. Benchmark-first staging, not a builder task. |
| mybd-g88l | #4772 | keep-open | Defect confirmed in `internal/beads/context.go:131-137` (note: the prior anchor "context.go:136" points at the wrong file). Asymmetry three lines later at 141 — `GetRepoRoot()` tolerates no-git for `cwdRepoRoot` — makes it a bug not a design choice. Fix PR #4792 **re-verified state=open, merged=false**. |
| mybd-3o7s | #4714 | keep-open | `mol_bond.go:611,647` still `utils.ResolvePartialID` against the local store. Fix PR #4720 **re-verified state=open, merged=false** (touched 07-28, author still active). |
| mybd-3wkx | #4684 | keep-open | Needs-repro stands; **prior anchor now stale** — `ephemeral_routing.go:241` was moved by #4259 and #5150 (**verified merged** 07-29). Neither touches wisp GC batching, so neither is a fix. Next step is a question to the reporter, not code. |

**Counts:** 0 close · 1 consolidate · 8 flesh-out · 3 keep-open. Zero executed.

**New bead:** **mybd-jna5a** (p2) — *bd --json/exit-code surface has no contract*.
Owns the one decision behind #5054, #5049 and #4816: envelope shape, whether a
reported field must reflect real provenance, and whether an idempotent no-op is
distinguishable from a state change. Parts are breaking; parts (#5049) are not
and can land immediately.

## Root-cause map

- **Fix written, not landed (3).** #4772→#4792, #4714→#4720 both re-verified
  open/unmerged; #4816's stack (#4818/#4819) verified closed-unmerged. Same
  finding as run 12, now 5 of 24 cli-ux stubs swept today. The lever for this
  theme is the PR queue, not the issue queue.
- **The `--json`/exit-code surface has no contract (3).** #5054 (shape), #5049
  (fake provenance), #4816 (success on a no-op). Each has a cheap local patch;
  patching independently just picks three ad-hoc answers. → mybd-jna5a.
- **A filter exists that nothing upstream of it can satisfy (2).** #5048
  (multi-hyphen prefixes unmatched by construction), #4982 (`mol_type` filters
  unreachable from `pour`). Both are "the read side shipped ahead of the write
  side".
- **Error swallowed into a confident wrong answer (2).** #4927 (`err → false` →
  agent told "no remote, do not push"), #4772 (`err →` fatal where the adjacent
  field tolerates the same absence). Both would be cheap to make tri-state.
- **Design-heavy scale work (2).** #4437, #4684. Neither is a builder task;
  both want a query-count benchmark or reporter data first.
- **Feature requests (2).** #4745, #5096 — real, but need a design call.

## Confidence and caveats

- **High confidence** on all 12 code-path claims: each was read from
  `upstream/main:<path>` at `21ca92db6`, not the working tree, and quoted by
  line. Line numbers will drift — upstream moved several hundred files in the
  six days since the 2026-07-27 verify pass, which is how two prior anchors
  (#4772, #4684) went stale.
- **High confidence** on all six merge-state claims (#4820, #4818, #4819,
  #5191, #5236, #5150 merged/unmerged as stated) — each read from
  `pulls/<n>.merged` directly, not inferred from a timeline reference.
- **The #4714 timeline is a live example of the failure mode this lane guards
  against.** It carries five `referenced` commits whose messages read
  "…(closes #4714)". All five are on the unmerged PR branch. A timeline-only
  sweep reads that as fixed.
- **Not verified:** #4684's actual timeout — unreproducible without HQ-scale
  data, so "generic `deleteBatch` N+1" remains a hypothesis I did not test.
  #5096's claim that no *other* renderer path substitutes a guarded command:
  I read `setup/agents.go` and `setup/codex.go`, not all 10 renderers in
  `cmd/bd/setup/`.
- **Not checked:** whether #4792 and #4720 still apply cleanly. Both carry
  CHANGES_REQUESTED from earlier triage; I verified merge state only, not
  review state or mergeability this run.
- Collision guard run: none of the 12 is referenced by an `in_progress` bead.
- Nothing blocked me — no denied command I needed, bd and GitHub both fine.
  Two `solo-bd note` calls were rejected for containing literal `--flag`
  tokens and were reworded; the notes are complete.
