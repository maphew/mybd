# Beads PR Backlog And Dolt Sync Analysis

Date: 2026-05-16  
Scope: `gastownhall/beads` GitHub issues/PRs, local `bd-main`, `docs/PROJECT_CHARTER.md`, `proposals/plugin-system.md`  
Prepared for: maphew

## Executive Summary

The PR backlog is not one problem. It is three queues sharing one GitHub view:

- a release-safety queue around Dolt, JSONL import/export, hooks, storage commits, and server/embedded mode;
- an architecture queue around storage/server refactors and plugin boundaries;
- a community throughput queue containing old PRs, dependency bumps, docs, integrations, and feature requests.

Treating all 138 open PRs as one review pile is what makes the situation feel impossible. The path is to split the pile into lanes, land the narrow release-critical fixes, deliberately convert obsolete or architecture-blocked PRs into tracking issues, and preserve contributor credit when absorbing useful tests or repros.

My strongest conclusion: the charter is on the right track, but it is not yet operational enough for agents. It says what belongs in Beads; it does not yet tell an agent how to triage 130 open PRs in a way that protects contributors and reduces risk.

## Current Snapshot

GitHub state observed on 2026-05-16:

- Open PRs: 138.
- Open issues: 189.
- PRs with storage/Dolt/sync/import/export/remote/server/schema/migration/daemon/JSONL/backup/hook terms in the title: about 67.
- Open issues matching the same storage/sync cluster: about 91.
- PRs opened on 2026-05-16 alone: 23.
- Open PRs created before 2026-05-01: 22.
- Draft PRs: 6.
- Dependabot PRs: 11.
- Docs/community/skill PRs: about 10.
- `bd-main` local checkout was behind `upstream/main`; I fetched upstream and used temporary worktrees for analysis.

That means roughly half the PR backlog is touching the riskiest surface in the project. This validates @coffeegoddd's concern: the merge queue cannot be treated as a normal feature-review queue until storage/server churn settles.

## The 3340 / 3626 / 3598 / 3599 Cluster

Issue #3340 reports a real class of deadlock: an internal `git commit` runs while a parent `bd` process still owns the embedded Dolt lock, the Beads pre-commit hook runs, the hook shells out to `bd export`, and the child `bd export` tries to open the same embedded store.

PR #3626 fixes this by adding `--no-verify` to `commitBeadsConfig` and adds an embedded regression test for `bd dolt remote add/remove`.

There is also an earlier duplicate, #3599, for #3598. It applies the same one-line fix and adds useful hostile-hook unit tests, including commit-msg hook and idempotence coverage. #3626 is fresh, mergeable, and CI-clean. #3599 is older and currently has unknown mergeability, but its tests contain value.

Local repro notes:

- A normal local build failed because this machine lacks ICU headers for the default Dolt dependency path.
- A `gms_pure_go` build succeeded.
- In the pure-Go/Linux build, the manual `bd dolt remote add` recipe did not hang on current `upstream/main` or #3626.
- That non-repro is not decisive. Linux normally has GNU `timeout`, and the hook wrapper uses it to avoid hard hangs. The reported hard path is stock macOS without `timeout`, and #3626's test is cgo/embedded-only.
- Current `upstream/main` still has `git commit -m` without `--no-verify` in `cmd/bd/sync_remote.go`, so the code-level hazard still exists.

Recommended action:

Land one combined fix, not two competing PRs. The cleanest maintainer outcome is a fix-merge that uses #3626 as the landing vehicle or a local maintainer branch, adds the useful #3599 unit-test coverage, and credits both contributors. Then close the duplicate PR and both issues with a comment explaining what was preserved.

## The 3354 / 3356 / 3937 / 3940 Line

This line is about policy, not just bugs.

#3354 reported massive `tmp_pack_*` growth in the embedded Dolt git remote cache. #3356 identified one cause: `bd init` was registering a plain Git source `origin` as a Dolt remote even when the remote had no `refs/dolt/data`. PR #3357 fixed that by only wiring the remote when Dolt data was known to exist or the user explicitly configured it.

That safety fix was correct. It prevented Beads from treating arbitrary Git origins as existing Dolt databases.

The regression is convenience: users remembered `bd init` plus Git origin making sync work. #3937 restates the desired policy more cleanly:

- do not treat a plain Git origin as existing Dolt history during bootstrap/pull;
- do let an explicit `bd dolt push` adopt Git origin as the target when no Dolt remote is configured.

PR #3940 implements that narrower push-time adoption. This preserves the #3356/#3354 protection while restoring the common workflow at the point where the user has expressed intent to publish.

Status of #3940:

- mergeable and CI-clean at the time observed;
- review nits were addressed in `fe1adad13`;
- good tests around lazy adoption, `-C` targeting, no-origin local init, and doctor guidance;
- broader than #3626, so it deserves a scenario matrix before release.

Recommended action:

Keep #3940 as a release candidate only if maintainers run and record the scenario matrix:

- init with no Git origin stays local;
- init with plain Git origin does not register remote unless policy explicitly says it should;
- push with no Dolt remote but Git origin adopts and publishes `refs/dolt/data`;
- bootstrap/pull only auto-use origin when `refs/dolt/data` exists;
- server/shared-server mode does not regress;
- no `issues.jsonl` import/export path is treated as canonical sync.

## Current Release Pressure

Several current PRs and issues point to the same near-term release theme: reduce write amplification, avoid data clobbering, and make orchestration-scale commands survivable.

High-priority release candidates or blockers:

- #3948: auto-import/JSONL clobber and operational DoS reports in released versions.
- #3955 and #3960: non-destructive hardening for auto-import fallback.
- #3944 and #3995: overlapping server-mode/embedded-mode auto-import gates. These need one coherent decision, not both blindly merged.
- #3989, #3990, #3991: Julian's commit hygiene stack around initial create relations, label creation, and migration dirty-data sweeping.
- #3993: `dolt.auto-commit=batch` does not actually batch hot storage writes. This should become a release-blocking tracking issue if the release claims batching as an orchestration feature.
- #3943: `bd create --graph` performance and `--ephemeral` / `--no-history` pass-through. This appears directly relevant to orchestration-layer performance, but latest observed status was unstable due embedded test failures in one run.
- #3920: memory profiling flag and env support. This is small, CI-clean, and useful for future investigation.

Likely not early-release candidates without more work:

- #3908 `--max-rows`: useful defensive operator control, but currently conflicting and had doc freshness failure in its observed CI.
- #3906 lite SELECT: useful foundation, but current observed CI still had embedded test failures/in-progress jobs.
- broad daemon/storage-driver/PG capability PRs opened on 2026-05-16: these belong in the architecture lane, not the urgent release lane.

## Plugin Architecture Interaction

The plugin proposal is strong as a design spine. The two-tier model and trust layer are coherent:

- providers out-of-process over MCP for trackers and external services;
- automations in-process as sandboxed WASM for hooks/formatters/lints;
- no plugin execution without explicit grants;
- content-addressed lockfile;
- storage data plane stays in-tree;
- Cobra command tree frozen after construction.

But it should not become a reason to stall narrow safety fixes. Use it to defer or reroute integration and extension PRs, not to block bug fixes in current core behavior.

Practical policy:

- integration PRs that add or widen tracker behavior can become tracking issues unless they are small, tested, and solve a current regression;
- hook-system PRs should be judged against the automation/WASM direction;
- storage PRs should stay in core, because the proposal explicitly keeps storage out of plugins;
- CLI feature PRs that mainly support orchestration should be classified as orchestration-boundary work unless they expose a general Beads primitive.

## Project Charter Assessment

`docs/PROJECT_CHARTER.md` is directionally right:

- Beads owns issue tracking primitives.
- Orchestration policy belongs outside core.
- Storage-engine details should not leak through core.
- Metadata is the first answer for workflow-specific data.
- Maintainers should preserve contributor value instead of rejecting reflexively.

The missing piece is an operational PR intake rubric. Agents and maintainers need a short decision tree they can apply quickly:

- Release blocker: data loss, deadlock, regression, crash, severe performance, security, packaging/install breakage.
- Narrow landable: small change, clear repro, failing-on-main regression test, clean CI, fits charter.
- Fix-merge: valuable but needs small maintainer repair.
- Absorb as issue: useful repro or test but PR shape is obsolete, broad, or soon superseded by storage/server/plugin work.
- Plugin/integration candidate: not core, keep the use case, route to plugin architecture.
- Retire: already fixed, duplicate, stale with no reproducible problem, or superseded.

This should live near `PR_MAINTAINER_GUIDELINES.md`, and `AGENTS.md` should explicitly point agents at it for PR triage. The charter alone will not change agent behavior unless the operating instructions invoke it.

## Backlog Reduction Path

Use a three-lane queue for the next two weeks.

### Lane 1: Release Stabilization

Only accept PRs that address release-critical regressions, data safety, deadlocks, install/build failures, or Julian's explicitly requested orchestration support.

Candidate set:

- combine/land #3626 + useful #3599 tests;
- resolve the #3948/#3944/#3995/#3960 auto-import cluster into one coherent patch set;
- review/land #3989, then #3990 if #3989 lands, and #3991 if it passes dirty-data review;
- review #3943 after embedded CI is green or failures are explained;
- land #3920 if no hidden concern appears;
- decide whether #3940 makes the release based on the sync policy matrix.

### Lane 2: Architecture Hold

Label and pause broad storage/server/daemon/plugin-shaping PRs. Ask for tracking issues and repro evidence, not more code, until @coffeegoddd's storage/server work and Harry's plugin architecture have landed enough shape to review against.

This is not contributor rejection. It is scope control.

### Lane 3: Backlog Harvest

For older PRs, read for value and preserve one of:

- a minimal repro;
- a regression test;
- a use case;
- a small patch that can be cherry-picked;
- a design note for the plugin/storage architecture.

Then close or convert. The goal is not to save every PR; it is to avoid losing signal while reducing the count.

## How Maphew Can Help

The highest-leverage role is not "write more code." It is queue shaping:

- Be the person who turns vague PR piles into named clusters.
- Ask for copy/paste repros from `upstream/main`.
- Require a regression test that fails on main and passes on the fix for release-critical bugs.
- Mark PRs as "release lane", "architecture hold", or "harvest/retire".
- Post closure comments that explain what was preserved and why the PR is not landing as-is.
- Keep the charter as the boundary document, but add a PR intake rubric so agents can actually apply it.

This converts frustration into maintainership work that only a human core-team member can do well.

## Proposed Immediate Moves

1. Declare a temporary release stabilization lane through the next release.
2. Pick an owner for the auto-import cluster and prevent parallel overlapping fixes from landing independently.
3. Combine #3626 and #3599 value into one landed fix, then close duplicates.
4. Ask Julian for the exact minimum CLI surface needed for the early-week release; evaluate only that set first.
5. Add a short PR intake rubric next to `PR_MAINTAINER_GUIDELINES.md`.
6. Add an `AGENTS.md` pointer so agents use `PROJECT_CHARTER.md` and the PR intake rubric during triage.

_codex-gpt-5- on behalf of maphew_
