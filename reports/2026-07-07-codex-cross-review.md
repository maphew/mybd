# Codex Cross-Vendor Review of Own Upstream PRs — 2026-07-07

**Bead:** mybd-ycu4 · **Fix follow-up:** mybd-lu6a
**Reviewers:** OpenAI Codex `codex review` (gpt-5.5, high reasoning, read-only) per PR · Claude (fable-5-high) adversarial verification of every finding before posting.
**Scope:** all 15 open maphew-authored PRs on gastownhall/beads in the #4576–#4600 band (#4586 merged before the run and was dropped; #4593 and #4580 joined; #4408/#4206 excluded — tracked by their own beads).

## Why cross-vendor

Same-family review of Claude-assisted PRs has correlated blind spots. AGENTS.md names independent-vendor review as the highest-value Codex use, and this run bore that out: **15 findings, 14 confirmed by independent Claude verification, 1 softened, 0 refuted** — including one P1 data-loss regression that same-family review sweeps had not flagged.

## Mechanics

- One detached git worktree per PR under `.worktrees/beads/codex-rev-<N>`, checked out from local refs `codex-rev/pr-<N>` (the fork's fetch refspec is main-only, so PR branches were fetched into local branch refs, which sibling `fetch --prune` cannot delete).
- Review base pinned as local branch `codex-base` = upstream/main `ce3c040` (post-#4586).
- `scripts/codex-agent reviewer --diff --base codex-base`, concurrency 4 (parallel Codex is sanctioned in beads source worktrees; the coordination repo stays serial).
- Codex tokens bill to the ChatGPT plan and bypass workflow budget accounting; the Claude verification workflow (9 agents) ran under the standing 200k directive.

## Results

| PR | Title (short) | Codex findings | Verification |
|----|---------------|----------------|--------------|
| [#4598](https://github.com/gastownhall/beads/pull/4598) | bootstrap: retry failed clone cleanup | **P1** cleanup can `RemoveAll` a pre-existing Dolt repo | **confirmed**, end-to-end repro traced |
| [#4592](https://github.com/gastownhall/beads/pull/4592) | doltserver: reap leaked test servers | P2 Pdeathsig kills subprocess-started servers; P2 SIGKILL without PID revalidation | both **confirmed** (scope corrected: auto-started servers unaffected) |
| [#4576](https://github.com/gastownhall/beads/pull/4576) | doltremote: canonical comparison hardening | P2 SSH userinfo stripping over-matches; P2 dotless SCP aliases unmatched | confirmed; softened (documented trade-off → P3) |
| [#4595](https://github.com/gastownhall/beads/pull/4595) | import: respect import.auto=false | P2 `bd config set import.auto false` triggers the import it disables | **confirmed** (env-var workaround exists) |
| [#4600](https://github.com/gastownhall/beads/pull/4600) | test: port Windows hardening fixes | P2 fixtures moved into source tree; P2 PATH replaced not prepended | both **confirmed** |
| [#4587](https://github.com/gastownhall/beads/pull/4587) | build: auto gms_pure_go + doctor-build | P2 second `-tags` silently replaces existing; P3 doctor-build substring check | both **confirmed** |
| [#4582](https://github.com/gastownhall/beads/pull/4582) | docs: advanced page public surface | P2 `bd sql` examples fail in embedded mode | **confirmed** |
| [#4593](https://github.com/gastownhall/beads/pull/4593) | docs: remove stale worktree guidance | P2 stages nonexistent `.gitattributes`; P2 nonexistent `bd vc conflicts`; P3 broken anchor | all **confirmed** |
| [#4585](https://github.com/gastownhall/beads/pull/4585) | prime: agent.profile knob | P3 unregistered config key emits false warning | **confirmed** |
| [#4599](https://github.com/gastownhall/beads/pull/4599) | prune: speed up reference scan | none | clean |
| [#4594](https://github.com/gastownhall/beads/pull/4594) | ci: golangci-lint pin alignment | none | clean |
| [#4589](https://github.com/gastownhall/beads/pull/4589) | ci: depguard storage boundary | none | clean |
| [#4588](https://github.com/gastownhall/beads/pull/4588) | docs: reserved log export | none | clean |
| [#4584](https://github.com/gastownhall/beads/pull/4584) | test: migration blocker assertions | none | clean |
| [#4580](https://github.com/gastownhall/beads/pull/4580) | dolt: transaction event parity | none | clean |

## The P1 in brief (#4598)

The new clone-failure cleanup `RemoveAll`s the target whenever `target/.dolt` exists — even when this clone attempt didn't create it. `dolt_database` reaches the clone unvalidated (metadata.json / `BEADS_DOLT_SERVER_DATABASE` verbatim; `ValidateDatabaseName` guards only `bd init` flags and `CREATE DATABASE`), and the pre-clone `doltExists` guard checks only immediate children. A non-basename name like `foo/bar` therefore: clones fine the first time, is missed by the guard the second time, fails `dolt clone` ("target already exists"), and the cleanup deletes the pre-existing repo with its local commits. Pre-PR the same failure was harmless. Hand-edited metadata is exactly the recovery scenario bootstrap serves, so the precondition is not exotic. Fix (mybd-lu6a): validate the name at the top of `BootstrapFromRemoteWithDB` and skip cleanup when the target pre-existed.

## Verification value

Beyond confirm/refute, verification added material the raw findings lacked: the concrete breaking test for #4592 (`TestDoctorCheckHealthReportsVersionMismatchOnRepoLocalPort`) plus a scope correction (auto-started servers are safe); the env-var workaround on #4595; the second unguarded kill window in #4592's sweep; and the re-grading of #4576's dotless-alias finding as a documented trade-off rather than a defect.

## Posted comments

One signed comment per PR with findings (9 total, 2026-07-07): [4598](https://github.com/gastownhall/beads/pull/4598#issuecomment-4904342221) · [4576](https://github.com/gastownhall/beads/pull/4576#issuecomment-4904342435) · [4592](https://github.com/gastownhall/beads/pull/4592#issuecomment-4904342686) · [4595](https://github.com/gastownhall/beads/pull/4595#issuecomment-4904342881) · [4600](https://github.com/gastownhall/beads/pull/4600#issuecomment-4904343145) · [4587](https://github.com/gastownhall/beads/pull/4587#issuecomment-4904343349) · [4582](https://github.com/gastownhall/beads/pull/4582#issuecomment-4904343577) · [4593](https://github.com/gastownhall/beads/pull/4593#issuecomment-4904343764) · [4585](https://github.com/gastownhall/beads/pull/4585#issuecomment-4904343956). The six clean PRs received no comment (recorded here and in mybd-ycu4 instead).

All comments signed `claude-fable-5-high on behalf of matt wilkie`; Codex authorship of the underlying findings is credited in each comment body.
