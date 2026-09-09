# Issue sweep: theme:migration-schema (12 stubs) — 2026-07-26

Third theme-clustered tri:claim drain sweep (epic mybd-xmx7). Context was warm
from the same-day #4504 deep review (mybd-9wr2).

## Dispositions

| bd | gh issue | disposition | reason |
|----|----------|-------------|--------|
| mybd-idini | 4176 | tri-close | fixed by #4878 (merged 07-23, cites 4176 explicitly: 0047 wisps hardening) — verified merged in-session |
| mybd-jlsr9 | 4274 | consolidated → mybd-ztve | same store-open auto-migrate commit site as gh 5061; one fix covers both symptoms |
| mybd-ztve | 5061 | keep (absorbs 4274) | must fix both no-op commit noise and in-flight write sweeping |
| mybd-efzs | 4800 | keep — anchor bead | live engineering bead for the frozen-migration "nothing to commit" class; #4504 repairs confirmed no-op here (today's review); fix direction = cursor-row repair |
| mybd-veofl | 4137 | keep, verify-first | same class as efzs, migration-28 path; #4531 may have changed behavior |
| mybd-ghh34 | 3886 | keep | bootstrap commit-init path of the same class; noted on efzs |
| mybd-j881 | 4468 | keep (p0), verify-first | #4878 + wisp hardening may fix; add to v1.1.2 verification batch |
| mybd-3aev4 | 4297 | keep, verify-first | dependencies.id fallout repairs landed; verify query gone; overlaps mybd-a4c2 |
| mybd-ypqx | 5033 | keep (active) | reporter testing today; #4878 didn't fully cover fresh-clone wisp_dependencies |
| mybd-ltbf2 | 4138 | keep | is_blocked backfill for pre-existing blocked wisps still missing |
| mybd-133z1 | 3495 | keep | 92d dormant; reinit-local wipes custom types — real, untouched |
| mybd-lvss | 4356 | untouched | maphew engaged upstream today (repro request) — owner-active lane |

Net: 12 → 2 closed (1 tri-close verified, 1 consolidation), 3 marked
verify-first for a v1.1.2 verification batch, anchor-bead structure set around
mybd-efzs for the "nothing to commit" class.

## Emerging pattern: the v1.1.2 verification batch

Three sweeps in, a recurring disposition is "probably fixed by the v1.1.x
rework — verify before closing": mybd-zlqec (auto-import family), mybd-5vvos
(6 embedded failure modes), mybd-j881 (wisp column recompute), mybd-veofl
(migration 28), mybd-3aev4 (depends_on_id query). One session with a repro
harness against v1.1.2 could retire all five lanes. Candidate follow-up bead
when the count justifies it.
