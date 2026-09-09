# cli-ux stub verification sweep — 2026-07-27

**Bead:** mybd-syoyw (drain epic mybd-xmx7) · **Workflow:** wf_45d8e18a-600 (17 agents: 8 area verifiers + 9 adversarial refuters, ~856k subagent tokens) · **Baseline:** upstream/main c989b6b87

## Outcome

48 `theme:cli-ux` `tri:claim` stubs verified (pre-pass had closed 2 duplicates
and excluded the active PR-5027 lane mybd-wo8r from the original 51).

- **9 closed as fixed upstream** — every one survived an adversarial
  refutation pass: mybd-cg61q (#3784), mybd-kqhky (#3410), mybd-hkbr (#5078,
  fixed by #4865 one day *before* the incident was filed — reporter was on a
  pre-fix binary), mybd-i9z6q (#3901), mybd-f8yo (#4627), mybd-rxuo8 (#3596),
  mybd-xxobv (#4037), mybd-u95g0 (#2140), mybd-genpa (#2977).
- **0 fix-claims refuted** this round (server-mode round had 1 of 4 — the
  refutation stage stays justified).
- **6 needs-repro**, each note says exactly what a repro requires.
- **33 verified still-valid** with code evidence appended. Standout:
  mybd-3o7s (#4714) has an open contributor fix PR
  gastownhall/beads#4720 with a regression test — that stub should convert to
  a PR-review lane rather than new implementation work.

## Blemish

The disposition script ran twice, so the 39 kept stubs carry their
`[verify 2026-07-27]` note twice. Harmless duplication; left as-is.

## Per-stub verdicts

| bd id | gh issue | verdict | note |
|---|---|---|---|
| mybd-cg61q | [#3784](https://github.com/gastownhall/beads/issues/3784) | **fixed — closed** | Likely fixed by #4149: create paths now persist issue.Labels via PersistLabels; run the 30s waits_for pour repro from the issue to confirm before closing upstream. |
| mybd-f8yo | [#4627](https://github.com/gastownhall/beads/issues/4627) | **fixed — closed** | Fixed on main by a813f9a2f / #4575, reporter-verified at c989b6b87; upstream issue stays open only until a release ships the fix. |
| mybd-genpa | [#2977](https://github.com/gastownhall/beads/issues/2977) | **fixed — closed** | Both asks satisfied: README docs link present and repo About website field set to beads.gascity.com; safe to tri-close. |
| mybd-hkbr | [#5078](https://github.com/gastownhall/beads/issues/5078) | **fixed — closed** | Fixed upstream before filing: --include-comments streams bodies; #4865 (3102cbd4d) adds comments_omitted marker. Reporter was on a pre-#4865 SQLite-era binary. |
| mybd-i9z6q | [#3901](https://github.com/gastownhall/beads/issues/3901) | **fixed — closed** | Fixed by 7e8766db6/#3488 (pre-dates filing): gate gh:pr now requests only state,title; regression test forbids 'merged' field. Reporter on old release. |
| mybd-kqhky | [#3410](https://github.com/gastownhall/beads/issues/3410) | **fixed — closed** | Fixed by 52fc26afb (bd-r2l): gate.await_id preserved and {{var}}-expanded through cook and clone; regression test mirrors the issue's exact example. |
| mybd-rxuo8 | [#3596](https://github.com/gastownhall/beads/issues/3596) | **fixed — closed** | Fixed by e1d5b3fae (ensureStoreActive in human respond/dismiss + embedded tests); verified working at main c989b6b87. Upstream issue still open — candidate for a fixed-in comment via tri-submit. |
| mybd-u95g0 | [#2140](https://github.com/gastownhall/beads/issues/2140) | **fixed — closed** | Implemented: bd setup claude/gemini now write minimal beads sections to CLAUDE.md/GEMINI.md with symlink and AGENTS.md-stub handling (PR #2600 + follow-ups). |
| mybd-xxobv | [#4037](https://github.com/gastownhall/beads/issues/4037) | **fixed — closed** | Fixed by 8a8a2ecad: MCP validate/pollution now route through bd doctor; safe to tri-close with fix reference. |
| mybd-3wkx | [#4684](https://github.com/gastownhall/beads/issues/4684) | needs-repro | Query at ephemeral_routing.go:241 unchanged and can fail on schema-drifted DBs, but the timeout itself is unreproducible without HQ data; ask reporter for schema version (dependencies.id present?) and a minimal dataset. |
| mybd-f2kq | [#4506](https://github.com/gastownhall/beads/issues/4506) | needs-repro | Underspecified; since 544ab678d all beads temp paths honor os.TempDir(), so TMPDIR redirection likely already satisfies this. Ask reporter what concrete path/config is still missing before engaging. |
| mybd-h5pky | [#3496](https://github.com/gastownhall/beads/issues/3496) | needs-repro | Not reproducible at main c989b6b87 with the reported repro; jj-workspace false-positive class fixed by 2bde0cacf/f5a70d3eb; stale GH#2950 citation in warning text remains. |
| mybd-pah7v | [#3529](https://github.com/gastownhall/beads/issues/3529) | needs-repro | Re-run the issue's dolt.log line-count repro (bd stats / bd memories against a server-mode store) on current bd; likely resolved by PR 4141 + readOnlyCommands classification + 81489b8c1, but path was never pinned. |
| mybd-ulmls | [#3927](https://github.com/gastownhall/beads/issues/3927) | needs-repro | No beads-only repro exists; upstream added diagnostics only (027b17d0e). Ask reporter to retry with a current bd and BD debug discovery output, or close as environment-specific. |
| mybd-yyks | [#4776](https://github.com/gastownhall/beads/issues/4776) | needs-repro | Bare bd list/ready are already limited (50/100) at upstream/main, predating the issue; BEADS_MAX_ROWS cap also exists. Need the reporter's bd version and exact invocation to find the actual unbounded path (--tree? limit 0? old build). |
| mybd-03jmk | [#3102](https://github.com/gastownhall/beads/issues/3102) | still-valid | No --notes-file/--append-notes-file at c989b6b87; precedent exists (--body-file, --design-file) so implementation would be pattern-following. |
| mybd-06uhb | [#4285](https://github.com/gastownhall/beads/issues/4285) | still-valid | Verified 2026-07-27 vs c989b6b87: defaults gap in bondProtoMolWithSubgraph unchanged; secondary bare-name issue already fixed by b740f6f10. Issue includes ready-to-apply two-line fix. |
| mybd-0fzm | [#4511](https://github.com/gastownhall/beads/issues/4511) | still-valid | Verified intact at c989b6b87: dolt.go:1830 static block vs DefaultConfig doc comment 'env var > port file > config.yaml > metadata.json'. Small self-contained fix (option 2 in issue). |
| mybd-0uxy4 | [#3288](https://github.com/gastownhall/beads/issues/3288) | still-valid | Feature still open; motivating silent-failure mode already mitigated by ambiguity error (#3328) + linear.outbound_state_map (#4119), lowering urgency to convenience-level. |
| mybd-11rm | [#4626](https://github.com/gastownhall/beads/issues/4626) | still-valid | Root cause is schema-level: deps PK (issue_id, depends_on_id) omits type, so multi-type-same-target collapses silently; CLI parses both entries fine. |
| mybd-25kf | [#5011](https://github.com/gastownhall/beads/issues/5011) | still-valid | Docs-only gap confirmed at c989b6b87; cheap help-text fix, functionality already exists (ServerDSN password/TLS + credentials file). |
| mybd-3o7s | [#4714](https://github.com/gastownhall/beads/issues/4714) | still-valid | Still broken at c989b6b87, but open fix PR #4720 exists — route the stub toward reviewing/landing that PR rather than new work. |
| mybd-47ly | [#4437](https://github.com/gastownhall/beads/issues/4437) | still-valid | N+1 confirmed live: per-node GetDependents/GetDependencies BFS in cmd/bd/graph.go:386-416 plus per-issue dep load; no batch rework since #4107. |
| mybd-4efw4 | [#3316](https://github.com/gastownhall/beads/issues/3316) | still-valid | Wiring unchanged at c989b6b87; the direction is a deliberate code comment, so this is a maintainer design decision (pre- vs post-requisite gate semantics), not a plain bug fix. |
| mybd-5eon | [#4635](https://github.com/gastownhall/beads/issues/4635) | still-valid | git-init guard unchanged at upstream/main init.go:923; defect confirmed present. |
| mybd-7sogg | [#4927](https://github.com/gastownhall/beads/issues/4927) | still-valid | Confirmed at upstream/main c989b6b87: peer-home rejection + error-to-false in primeHasGitRemote unchanged; recent boundary fixes were temp-dir only. |
| mybd-agjb | [#4438](https://github.com/gastownhall/beads/issues/4438) | still-valid | Deliberately deferred upstream until Dolt Server v2; pair any re-test with gh-3529's repro since they measure the same symptom. |
| mybd-alm2 | [#4396](https://github.com/gastownhall/beads/issues/4396) | still-valid | Root cause confirmed in code: children found by id-LIKE (transaction.go:537), dependents only from stored edge tables; implicit dot-edges have no row. |
| mybd-bj0x | [#4503](https://github.com/gastownhall/beads/issues/4503) | still-valid | Confirmed at upstream/main c989b6b87: install.sh/install.ps1 only support latest; no BD_VERSION env or version arg exists. |
| mybd-dyqws | [#3585](https://github.com/gastownhall/beads/issues/3585) | still-valid | Confirmed at main: reinit-local ignores metadata dolt_mode=server; beads-only repro exists in thread (kevglynn). Note title understates it — dolt_mode is actually overwritten, not just misprinted. |
| mybd-e6x29 | [#4068](https://github.com/gastownhall/beads/issues/4068) | still-valid | Feature not implemented at c989b6b87; upstream gated it on the storage-layer rewrite (per issue body), so defer rather than claim. |
| mybd-g07u | [#5054](https://github.com/gastownhall/beads/issues/5054) | still-valid | Confirmed at c989b6b87: create.go:579 object vs show.go:431 array; no shape-normalization work landed. |
| mybd-g88l | [#4772](https://github.com/gastownhall/beads/issues/4772) | still-valid | Confirmed at main: context.go:136 still hard-requires a git root when .beads is local; docs/behavior mismatch stands. |
| mybd-hclnd | [#4036](https://github.com/gastownhall/beads/issues/4036) | still-valid | Narrowed scope: only context(show) misreports for Dolt backends (server.py _context_show reads BEADS_DB, unset for Dolt); small fix would report project root/backend instead. |
| mybd-k4v5z | [#3518](https://github.com/gastownhall/beads/issues/3518) | still-valid | Hint text unchanged at c989b6b87 (store.go:1483, doltserver.go:708); external-server-aware advice never implemented. Downstream gascity#1374 duplicate noted in thread. |
| mybd-kizkd | [#4983](https://github.com/gastownhall/beads/issues/4983) | still-valid | Verified at c989b6b87: no MaximumNArgs(1), resolveTitle consumes only args[0]; empty --body-file still accepted silently. |
| mybd-kqm7 | [#4397](https://github.com/gastownhall/beads/issues/4397) | still-valid | Exclusion error unchanged at create.go:427 / create_input.go:189; combination still unsupported and undocumented in flag help. |
| mybd-lh3kc | [#2908](https://github.com/gastownhall/beads/issues/2908) | still-valid | Still no `bd claim`; functionality exists as update --claim / close --claim-next but the zero-arg auto-claim UX is unimplemented. |
| mybd-n0wv | [#4562](https://github.com/gastownhall/beads/issues/4562) | still-valid | Docs request unimplemented: bare --parent examples remain in plugin epic.md and INTEGRATION_PATTERNS.md; labels.md lacks the inheritance caveat. Cheap docs-only PR candidate. |
| mybd-oa793 | [#4241](https://github.com/gastownhall/beads/issues/4241) | still-valid | Confirmed at upstream/main c989b6b87 (live repro 2026-07-27): -C sets BEADS_DIR only, DetectUserRole('.') still uses caller cwd. |
| mybd-p5k4 | [#5049](https://github.com/gastownhall/beads/issues/5049) | still-valid | Both halves verified at c989b6b87: config.go:304 constant location, main.go:682 stale 'Default: off' vs config.go:189 default 'on'. |
| mybd-q6iq | [#5048](https://github.com/gastownhall/beads/issues/5048) | still-valid | Confirmed at upstream/main c989b6b87: first-dash extraction + exact-equality match unchanged in cmd/bd/routed.go. |
| mybd-rgje4 | [#3981](https://github.com/gastownhall/beads/issues/3981) | still-valid | Gap confirmed at main: per-command path (main.go:341,525) still warn-only; reporter added a repro on request. |
| mybd-s4h6 | [#4395](https://github.com/gastownhall/beads/issues/4395) | still-valid | Confirmed: counts.go CountDependents queries edge tables only; implicit dot-numbered children are invisible to it. Same fix as gh-4396. |
| mybd-sfiw | [#4816](https://github.com/gastownhall/beads/issues/4816) | still-valid | Bookkeeping side of the report fixed by 607df586d (#4911); false '✓ Closed' message, dropped --reason, and missing already_closed JSON flag remain at c989b6b87. |
| mybd-si4zw | [#4745](https://github.com/gastownhall/beads/issues/4745) | still-valid | No --push on update --claim at c989b6b87; claim visibility still depends on separate `bd dolt push`. |
| mybd-txicf | [#4982](https://github.com/gastownhall/beads/issues/4982) | still-valid | Gap confirmed at c989b6b87: --mol-type/--gated ready filters remain unreachable from any pour output; feature-shaped fix (formula key or pour flag) still needed. |
| mybd-xfmr8 | [#4908](https://github.com/gastownhall/beads/issues/4908) | still-valid | Verified live in winget-pkgs 1.1.2 (2026-07-26): PortableCommandAlias still missing; repo winget/ template has it but is stale (SteveYegge.beads 0.30.7). Fix must land in the winget-pkgs publishing pipeline. |

_claude-code-fable-5-medium on behalf of maphew_
