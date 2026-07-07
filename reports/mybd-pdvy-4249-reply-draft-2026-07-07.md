# DRAFT reply to macneale4 on gastownhall/beads#4249 — NOT POSTED

Staged 2026-07-07 for owner approval (mybd-pdvy decision, due 2026-07-12). Revised the same evening
with empirical interop results (see the decision memo addendum) — the clarifying questions from the
first draft are now answered by experiment and replaced with findings. Post with:

```bash
scripts/gh-body-lint <body-file>   # after stripping this header block
gh issue comment 4249 --repo gastownhall/beads --body-file <body-file>
```

Replace `{signature}` with the live output of `scripts/agent-sig.sh` at post time (or sign as yourself and drop the line).

---

Thanks @macneale4 — that settles the encode side. And rather than come back with more questions, we ran the interop empirically against the beads-pinned dolt (`45335d44ad79`), with two `bd` builds: stock cgo/libzstd, and pure-Go with `gozstd` replaced by a ~140-line klauspost shim (the #4408 branch). 5,000-issue database, `bd gc` → `CALL DOLT_GC()`, default archive level. Results:

1. **cgo writes → pure-Go reads: works.** Default GC wrote a 15.6 MB `.darc` with 15,656 zstd trained-dict frames (dictID 1383496744). The klauspost build read the entire store — `bd export` of all 5,000 issues, byte-identical to the cgo build's export. So klauspost decode of libzstd ZDICT-trained frames holds in practice, and a pure-Go binary only needs zstd *decode* to open existing stores.
2. **pure-Go writes → cgo reads: fails.** A store GC'd by the klauspost build is rejected by the cgo build with `decompression error: Dictionary mismatch` — the klauspost `BuildDict` output produces frames carrying dictID 1, which libzstd won't accept against that dictionary. Consistent with your finding that klauspost dictionary training is the weak link — and it's an interchange hazard on top of a ratio problem. Possibly relevant to your option (a) prototype too, if the generic embedded dictionary is klauspost-built.
3. **Existing beads stores really do contain zstd archives**, but only past the `maxSamples = 1000` chunk threshold in the stream writer — smaller stores get snappy-only `.darc` files. Our own beads database is past it (a 40 MB archive with 4,565 zstd frames), so decode capability for existing stores is a hard requirement, not a corner case.
4. **Ratio on this dataset**: the klauspost trained-dict archive came out 10.7% larger than libzstd's — same direction as your prototype result, not dramatic.

Given that, path (b) — snappy for beads — looks right to us, and it seems reachable in two steps:

- **Now**: beads' GC call site can pass `--archive-level 0` (`CALL DOLT_GC('--archive-level', '0')`) so beads stores stop accumulating zstd archives from here on. One-line change on the beads side; happy to PR it.
- **Then**: for `CGO_ENABLED=0` builds, the `gozstd` references in `store/nbs` still need to be tagged out or routed through a seam — paired with klauspost *decode-only* for stores that already contain zstd archives (proven above), or a documented "GC with a cgo build first" migration for them. Encode-side klauspost — the part your testing rules out — drops out entirely.

Would you take that shape? Happy to help on either side of the boundary — #4408 has the current evidence branch, and we can rerun any of the above against other datasets.

_{signature}_
