# Issue sweep: theme:import-export (13 stubs) — 2026-07-26

First theme-clustered tri:claim drain sweep (epic mybd-xmx7; strategy in
`reports/2026-07-26-triclaim-drain-strategy.md`). Freshness recon delegated
(haiku tier, ~38k tokens); dispositions synthesized in-session.

## Dispositions

| bd | gh issue | disposition | reason |
|----|----------|-------------|--------|
| mybd-k7o9f | 3948 | tri-close | fixed on main: empty-DB guard restored + regression test #4218 (verified by maphew in-thread) |
| mybd-1qu7c | 4245 | tri-close | fixed on main: #4170 added the missing serverMode gate at the auto-import call site |
| mybd-j4kyn | 3880 | tri-close | same family as 4245/3948, gated since #4170 + guard restore |
| mybd-gkutl | 4298 | left open, dep-gated | blocked by PR-mirror bead mybd-2n6g (#4346/#4730 open); tri-sync closes on merge |
| mybd-bjwpj | 4239 | consolidated → **mybd-zlqec** | auto-import overwrite family — verify on v1.1.2 |
| mybd-4e1i0 | 4128 | consolidated → **mybd-zlqec** | per-call re-import OOM — same family verification |
| mybd-plq3h | 4887 | consolidated → **mybd-vkc56** | auto-export wedge; #4557 may fix, unconfirmed |
| mybd-7ap28 | 4988 | consolidated → **mybd-vkc56** | auto-export wedge, wisp-compaction orphan track |
| mybd-rm29u | 3884 | keep, fleshed out | lossy round-trip is by design; bug = silent acceptance; work with mybd-suxn |
| mybd-g4vgq | 3885 | keep, fleshed out | --force downgrades dolt_mode; well-scoped |
| mybd-itgj | 4492 | keep, fleshed out | skip-and-quarantine policy for invalid records |
| mybd-7z1xc | 4080 | keep, fleshed out | GIT_INDEX_FILE preservation; builder-tier candidate |
| mybd-jnrff | 3787 | keep, fleshed out | determinism residue after #4063 made export opt-in |

Net: 13 → 7 closed (3 tri-close + 4 consolidation), 2 new consolidated
engineering beads, 5 survivors with acceptance criteria, 1 dep-gated.

## Root-cause map

- **Auto-import-on-every-command family** (4239, 4128, 4245, 3948, 3880 — 5 of
  13): three upstream fixes landed (#4170 call-site gate 06-17, restored
  TotalIssues>0 guard + #4218 test, 75d3d95 import.auto=false 07-24). All
  reporters on 1.0.3/1.0.4. One verification bead (mybd-zlqec) replaces five
  stubs; if v1.1.2 repro is clean, upstream close-comments go through
  human-gated tri-submit.
- **Auto-export latch-off wedges** (4887, 4988): shared failure shape — the
  export gate never self-heals once its state marker diverges (mybd-vkc56).
- **Fidelity/UX singles** (3884, 3885, 4492, 4080, 3787): real, distinct,
  now individually actionable.

## Pattern notes for the next sweep

- Freshness recon per ~13 issues ≈ one haiku agent, <10 min, ~40k tokens.
  The timeline cross-reference query (merged fix PRs) was the highest-value
  signal; keep it.
- The "reporter is on v1.0.4, subsystem rewritten since" pattern killed 5 of
  13 stubs here; expect it to dominate data-integrity/concurrency themes too.
- Upstream issues stay open (closing them is the owner's call via
  tri-submit); tri-close only retires our stub and labels upstream `triaged`.
