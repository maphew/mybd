# Server-mode stub verification sweep — 2026-07-27

**Bead:** mybd-4uz8z (drain epic mybd-xmx7) · **Workflow:** wf_5da36c55-00c (12 agents: 8 subtheme verifiers + 4 adversarial refuters, ~714k subagent tokens) · **Baseline:** upstream/main c989b6b87

## Outcome

All 34 `theme:server-mode` `tri:claim` stubs verified against current beads
main. Every stub now carries a `[verify 2026-07-27]` note citing file:line or
commit evidence.

- **3 closed as fixed upstream** (each survived an adversarial refutation
  pass): mybd-n4yeb (#3370), mybd-a4c2 (#4483), mybd-lxvz7 (#3534).
- **1 fix-claim refuted, kept open:** mybd-flugm (#3449) — the #3346 clone-via-
  server fix covers external/shared-server mode only, not the reporter's
  bd-owned auto-started server, where the stale in-memory DB list persists.
- **4 need a repro** before implementation makes sense: mybd-tgdx (the proposed
  git+ssh reject-guard would break a *supported* remote scheme — the fix idea
  as triaged is misdirected), mybd-29k94, mybd-m6q8, mybd-3xzok.
- **26 verified still-valid** with concrete code evidence, ready for
  theme-clustered implementation sweeps.

## Coordination with mybd-psxg

The campaign links rr4x/a4c2/qrm9 as `related`; a4c2 is now closed (fixed
pre-report). Stubs remain the work items; no duplicates were found between the
stub set and campaign children. Implementation batches should honor the psxg
charter: proxied-server behavior changes (5wj1, eolg, 9ev6c) route through the
campaign lane.

## Budget note

~714k subagent tokens vs the 200k soft target: the refutation stage was not
optional (it killed one of four fix-claims — a 25% false-positive rate among
"likely fixed" verdicts justifies the stage), and code-evidence verification of
34 stubs across a large Go codebase is inherently read-heavy. Logged per the
2026-07-25 retro rule: overrun-to-complete, not skip-to-stay-under.

## Per-stub verdicts

| bd id | gh issue | verdict | note |
|---|---|---|---|
| mybd-a4c2 | [#4483](https://github.com/gastownhall/beads/issues/4483) | **fixed — closed** | Primary defect (bare depends_on_id queries) removed by d15c7572f pre-dating the report; upgrade resolves it. Residual asks (conn-leak-on-error defense, GMS DateFormat.Eval hang from richardhorvath11's comment) unverified — worth a pointer comment before closing upstream. |
| mybd-flugm | [#3449](https://github.com/gastownhall/beads/issues/3449) | fix-claim refuted — kept | Likely fixed by #3346 (80255b69c, clone via SQL server in server mode, v1.0.3) + 31d512325 (wisp tables); reporter was on 1.0.2. Suggest asking reporter to retry on >=1.0.3 before upstream close. |
| mybd-lxvz7 | [#3534](https://github.com/gastownhall/beads/issues/3534) | **fixed — closed** | Failing code path removed by #4236 (SQL-only remote management); suggest confirming on a >=1.1.0 build then tri-close as fixed. |
| mybd-n4yeb | [#3370](https://github.com/gastownhall/beads/issues/3370) | **fixed — closed** | Fixed by 0dce51a64 (PR #3381): bounded 30s timeout + pushWithContext guard + failure throttle; auto-push also opt-in-only since 456a66071 (#3446). |
| mybd-29k94 | [#3407](https://github.com/gastownhall/beads/issues/3407) | needs-repro | Code at main creates the DB during init (init.go:1132 CreateIfMissing + store.go:1914 CREATE DATABASE); needs repro on current build against an external shared server to show the skipping path. |
| mybd-3xzok | [#2559](https://github.com/gastownhall/beads/issues/2559) | needs-repro | Awaiting reporter repro (codex comment already posted); remaining symptom is Dolt journal corruption on unclean shutdown, likely upstream-Dolt territory, no bd-side fix landed. |
| mybd-m6q8 | [#4357](https://github.com/gastownhall/beads/issues/4357) | needs-repro | Base GH#2946 fix predates report; current code should persist server mode — needs repro (embedded .beads + shared server + --reinit-local) to find the fallback path, watch for the mid-run 'No dolt database found' warning. |
| mybd-tgdx | [#4421](https://github.com/gastownhall/beads/issues/4421) | needs-repro | No URL validation confirmed at bootstrap.go:315, but git+ssh is a supported beads remote scheme — proposed reject-guard is misdirected; CPU-storm claim needs repro against a git remote lacking refs/dolt/data. |
| mybd-0oeni | [#3392](https://github.com/gastownhall/beads/issues/3392) | still-valid | Server-mode lock/pid/port race machinery unchanged; upstream direction is proxied-server mode, not a fix here. |
| mybd-2w2kx | [#3897](https://github.com/gastownhall/beads/issues/3897) | still-valid | Still valid: helpers.go:538-550 unchanged (DB row wins, no metadata.json precedence); fork PR 3883 closed unmerged. |
| mybd-3gbr7 | [#4102](https://github.com/gastownhall/beads/issues/4102) | still-valid | Still valid on 1.1.0/main; proxied-server (dbproxy) work in flight (#5012/#5013, e878a31a5) is the likely eventual fix — link and watch. |
| mybd-4tna8 | [#4934](https://github.com/gastownhall/beads/issues/4934) | still-valid | Confirmed at main: config-only working set -> commitWorkingSet returns nil, CLI prints Committed. (dolt.go:622); no CLI path clears dirty internal config keys. |
| mybd-5wj1 | [#5043](https://github.com/gastownhall/beads/issues/5043) | still-valid | Verified at upstream/main c989b6b87: uow still has no remote-migrate gate; PR 5046 (workspacegate) is unrelated. Defect intact. |
| mybd-6qizf | [#3687](https://github.com/gastownhall/beads/issues/3687) | still-valid | Partially addressed: shared dir resolved and status got SQL probing (90098ccb7), but stop is still pidfile-only. |
| mybd-7huiy | [#4223](https://github.com/gastownhall/beads/issues/4223) | still-valid | Core defect present at main (circuit.go:92/335: shared os.TempDir dir, 0600 files); readState now fails open on read error but no per-user scoping landed. |
| mybd-7wr9w | [#4134](https://github.com/gastownhall/beads/issues/4134) | still-valid | Narrowed: embedded path fixed by #4024; proxied/server resolveProxiedCustomTypes still DB-wins — needs maintainer call on DB-vs-union precedence. |
| mybd-9ev6c | [#5084](https://github.com/gastownhall/beads/issues/5084) | still-valid | Verified at upstream/main c989b6b87: unconditional INSERT IGNORE seed remains; practically gated behind PR 5086 landing (accounts fail earlier without it). |
| mybd-bw78b | [#3545](https://github.com/gastownhall/beads/issues/3545) | still-valid | Verified 2026-07-27: IsDoltServerMode still ignores host config; only new dolt.mode config.yaml fallback added (workaround, not fix). |
| mybd-eg67t | [#4931](https://github.com/gastownhall/beads/issues/4931) | still-valid | Verified at upstream/main: probe loop still aborts on any non-whitelisted error (metadata.go:452,462); access-denied not in isExpectedProbeError. Skip-on-denied or probe-only-configured-db are candidate fixes. |
| mybd-eolg | [#5079](https://github.com/gastownhall/beads/issues/5079) | still-valid | Verified at upstream/main c989b6b87: bare CREATE DATABASE still on every proxied open; fix PR 5086 open, unmerged. |
| mybd-gyflp | [#3445](https://github.com/gastownhall/beads/issues/3445) | still-valid | Verified 2026-07-27 at c989b6b87: no dedup and no missing-table tolerance in GetDependentsWithMetadataInTx (dependencies.go:1122-1147); show.go:341 still discards the error. Fix pattern already exists in blocked.go. |
| mybd-ho2z | [#4995](https://github.com/gastownhall/beads/issues/4995) | still-valid | Confirmed at upstream/main: per-op DOLT_COMMIT hardcoded in dolt store write paths; batch/off policy only wired for embedded mode. |
| mybd-iznc | [#5037](https://github.com/gastownhall/beads/issues/5037) | still-valid | Verified at upstream/main c989b6b87: sync plan still returned before existing-db check; clone path has no exists handling. Breaks the documented v1.0->v1.1 non-migrator upgrade path. |
| mybd-j9v5 | [#4368](https://github.com/gastownhall/beads/issues/4368) | still-valid | Verified 2026-07-27 at c989b6b87: lock-then-check unchanged (lock.go:78, store.go:1992); no-op verification reads still inside locked region; 5s acquire budget still hardcoded. |
| mybd-m6te | [#4644](https://github.com/gastownhall/beads/issues/4644) | still-valid | Verified at upstream/main: EnsureGitignoreForBeadsDir (gitignore.go:181) still bare-writes; sole caller bootstrap.go:773 has no commit/notice. Real but minor. |
| mybd-nbf9q | [#4273](https://github.com/gastownhall/beads/issues/4273) | still-valid | Still valid at c989b6b87: dirty-tables guard unchanged, no global-config warning, no server-mode reinit recreate; #4566 only added remediation text to the error. |
| mybd-phs71 | [#3494](https://github.com/gastownhall/beads/issues/3494) | still-valid | Still valid: config get is DB-scope-only, ReadConfigPrefix ignores the yaml value it reads (helpers.go:541-546), config set issue_prefix still rejected (config.go:994); no external repair API added. |
| mybd-plcix | [#3383](https://github.com/gastownhall/beads/issues/3383) | still-valid | Exact quoted error still emitted at doltserver.go:696; no persistence setup or hook degrade landed. |
| mybd-qrm9 | [#4634](https://github.com/gastownhall/beads/issues/4634) | still-valid | Spawn moved from ~L841 to doltserver.go:1119 but is byte-equivalent in behavior: procAttrDetached() only, no fd sanitization; author offered a PR. |
| mybd-rqqa2 | [#4052](https://github.com/gastownhall/beads/issues/4052) | still-valid | Still present at c989b6b87: dial-fail -> auto-start -> divergent backend write, exit 0; only stderr warning. No fix commits reference 4052. |
| mybd-rr4x | [#4637](https://github.com/gastownhall/beads/issues/4637) | still-valid | Still present at c989b6b87: no identity check on the direct-connect path; #5013's identity work is dbproxy-only. verifyProjectIdentity is a partial, skip-prone mitigation. |
| mybd-xh716 | [#4132](https://github.com/gastownhall/beads/issues/4132) | still-valid | Connect+close probes unchanged at doltserver.go:1516 and circuit.go:203; still reproduced on bd 1.1.0. |
| mybd-yc4vo | [#4282](https://github.com/gastownhall/beads/issues/4282) | still-valid | No reaping in legacy server mode; idle-timeout only in new proxied dbproxy mode (opt-in via migrate). |
| mybd-ye9ha | [#3895](https://github.com/gastownhall/beads/issues/3895) | still-valid | TLS-env half fixed by #3679; server.json central-config half still unaddressed (PR #3883 closed unmerged). |

_claude-code-fable-5-medium on behalf of maphew_
