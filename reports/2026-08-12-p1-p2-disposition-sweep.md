# P1/P2 ready-queue disposition sweep (wind-down)

**Date:** 2026-08-12
**Trigger:** owner directive - "both [P1 items] should be either handed off or
closed out. if I carry them personally it'd cause a permanent fork and I don't
want to manage that. the p2 items should be scanned similarly."
**Scope:** both P1 ready items and all 14 P2 ready items (16 beads scanned).
**Outcome:** 11 beads closed, 3 upstream issues filed, 1 upstream comment, 1
index update, 4 items deliberately kept.

## Why

Under the wind-down campaign (mybd-ykt9f) every non-personal item must be
landed, handed off, or closed. The P1 pair (CGO epic + fork-carry decision)
had been implicitly waiting on the owner accepting a permanent fork of
gastownhall/beads; the owner explicitly declined that on 2026-08-12, which
resolved both items and set the standard for the P2 scan.

## Handed off upstream, then closed

| Bead | Upstream artifact | Note |
|------|-------------------|------|
| mybd-t7mk (+.6, .7) | #4249 wrap-up comment | CGO epic. Encode side settled by macneale4; write path fixed by #4986 (snappy GC); the only live question is read-side zstd decode - maintainer's call. Staged `mybd-hli9-*` branches on maphew/beads declared unowned reference material. |
| mybd-pdvy | (same comment) | The 4249-vs-fork decision: **no fork-carry**, decided by owner. |
| mybd-cof8 | gastownhall/beads#5731 | vendorHash drift: proposed the safe option (b) read-only CI check; option (a) trigger-widening documented as a pull_request_target trust-boundary break, not offered. |
| mybd-jart4 | gastownhall/beads#5732 | Proxied-server mol bond routing parity, filed blocked-on-#4720 (precedent: #5703 blocked on #5092). This was the "1 gated" item from the conversion campaign - queue now fully drained. |
| mybd-rgs2i | gastownhall/beads#5733 | Nested-worktree test unreliability, both observations (2026-07-31 ambient leak, 2026-08-12 order-dependent repro at 7771c99c3), honestly framed as not-yet-root-caused. Root-cause work stays in mybd-i921i. |

Index gastownhall/beads#5711 got an addendum listing #5731-#5733 and the
#4249 wrap-up; its "one item gated on #4720" paragraph was updated.

## Already handed off - closed with pointer

- **mybd-qcy1m** - #5699 (filed in the 2026-08-12 conversion batch) covers the
  pre-0059-cursor gap exactly; marcodelpin reply-watch folds into mybd-koabx.
- **mybd-xb9h** - reduced to "keep PR 5064 healthy + watch #4380", which
  mybd-koabx and the index-babysit lane already do.
- **mybd-auyb** - supervised /triage run is maintainer-era; obsolete since the
  2026-08-10 step-down.

## Owner decisions recorded

- **mybd-0nzhq approved and closed**: reports navigation = two-layer model
  (curated README reading room + deterministic report-room reader) per
  reports/2026-08-10-reports-navigation-decision.md. Child mybd-0nzhq.1 stays
  open solely for its Windows smoke run.

## Deliberately kept (personal, survive wind-down)

mybd-lq8i retro campaign (+.1, .5, .6), mybd-22w9 (codex effort benchmark),
mybd-gwxj (Windows hooks verification), mybd-ukt3 ('entire' CLI hook
rewriting). All are about the owner's cross-project agent tooling, not beads.

## Loose ends

- index-babysit still watches PR 4720 to comment on mybd-jart4; the bead is
  now closed so that comment will land on a closed bead - harmless, and the
  real gate is visible upstream on #5732. Remove lane (b) at next babysit
  template touch if convenient.
- Ready queue after sweep: mybd-koabx (P0 fleet) + the kept personal items +
  mybd-m67s/cfex/d0u3f/74jar/dcyim (P3, unscanned - out of scope this pass).

## Addendum 2026-08-13: P3 sweep (completes the ready queue)

Same standard applied to the five P3 items:

- **mybd-m67s closed (obsolete)** - the claude.ai MCP connectors' Supabase
  origin (ydeagqbwysgyknwrphur.supabase.co) has had no DNS resolution across
  checks on 06-10, 07-05, and 08-13: the project is gone, not flaky.
  Re-enable steps and the config backup path stay in the bead.
- **mybd-cfex, mybd-dcyim kept** - codex-agent bug + hardening; personal
  tooling, canonical copy in dotfiles. Same category as the kept 22w9/ukt3.
- **mybd-74jar kept** - AGENTS.md trim; personal repo hygiene with a real
  pre-check (verify Amp reads the global conventions file first).
- **mybd-d0u3f kept, unchanged** - already correctly dispositioned on 08-12
  as PR-5202-fleet-tied: the probe pattern exists only on 5202's branch, so
  filing against main would be wrong; resolve in 5202's review cycle or file
  upstream only if 5202 merges without the seam.

The ready queue is now fully dispositioned: koabx (P0 fleet shepherding) plus
deliberately-kept personal items only.

_claude-fable-5-high on behalf of matt wilkie_
