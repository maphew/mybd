# PR-mirror stub routing — 2026-07-27

**Bead:** mybd-49q9c (under drain epic mybd-xmx7) · **Scope:** all 43 open `theme:pr-mirror` `tri:claim` stubs

## Outcome

All 43 stubs closed. Zero review work was discarded: every live PR is owned by
exactly one lane. Ready-queue shrinks by 43; net new open beads: 3.

| Class | Count | Disposition |
|-------|------:|-------------|
| Dead | 1 | #5035 merged upstream — stub mybd-82yzc closed |
| Duplicate of existing lane | 30 | closed, reason names the owning lane |
| Live, unowned | 12 | closed into 3 new author-clustered sweep beads |

## Method

One batched GraphQL pull refreshed live state (state/author/reviewDecision/
updatedAt) for all 43 PRs, then every PR number was grepped against a full bead
dump (510 open + 500 recently closed) and `reports/`. No per-PR agents needed —
the cross-reference was mechanical, and bd stays serial in this repo.

## Duplicates → owning lanes

- **Merge-when-green / merge-blocked tails (pr-babysit owns):** 4933→mybd-i6oj,
  4984→mybd-xpk1, 5024→mybd-xf2k, 4751→mybd-06h1a, 5073→mybd-gfpf,
  5074→mybd-1eag, 5076→mybd-pfts, 4535→mybd-o21it
- **Close-after-grace (patrol close-when-quiet):** 3797/3801/3802/3806→mybd-qy7m,
  3876→mybd-ihdg (+scope-out mybd-bxlu), 4376→mybd-k6zxf, 3612→mybd-g04fm
- **Fix-merge / fold deadlines:** 4858→mybd-fyno, 4804→mybd-6y9i0,
  4504→mybd-6mmbf+mybd-9wr2, 4581→mybd-h8bb
- **2026-07-26 reviewer-dispatch-sweep lanes:** 5052/5066/5067/5077→mybd-9j143,
  5065→mybd-endu4, 5085/5086/5087→mybd-457m0
- **Other:** 4844→mybd-2yun (deep re-review), 3563→mybd-8chd.3 (salvage
  cluster), 5064→mybd-uiiu+mybd-y938 (own PR)

## New sweep beads (the actual routing product)

- **mybd-n9gl2** — vishnujayvel trio 4828/4831/4833: changes-requested
  2026-07-24, author silent; deadline 2026-07-31, sequenced with mybd-fyno.
- **mybd-o9kgk** — changes-requested silent-author follow-ups: 4730
  (jakelindsay87), 4739+4839 (steveyegge); deadline 2026-08-02.
- **mybd-75vui** — dormant single-PR-author sweep: 4175, 4288+4348, 4346, 4383,
  4413 — the "dormant sweep residue" band mybd-aayb identified; one re-review
  session, real dispositions.

## Side observations

- Stub external_ref format drifted: two stubs carried `gh:owner/repo#N` instead
  of `gh-pr-NNNN`; `scripts/tri-close` refuses those (closed manually, labeled
  upstream by hand). Worth a tri-pull normalization check if it recurs.
- Owner's own PRs (5024, 5064) had been mirrored into the triage stub lane;
  tri-pull might reasonably skip PRs authored by the maintainer.
- Filed separately: mybd ready overstatement by 115 `tri:defer` stubs (bead
  created this session under mybd-xmx7).

_claude-code-fable-5-medium on behalf of maphew_
