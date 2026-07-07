# DRAFT reply to macneale4 on gastownhall/beads#4249 — NOT POSTED

Staged 2026-07-07 for owner approval (mybd-pdvy decision, due 2026-07-12). Post with:

```bash
scripts/gh-body-lint <body-file>   # after stripping this header block
gh issue comment 4249 --repo gastownhall/beads --body-file <body-file>
```

Replace `{signature}` with the live output of `scripts/agent-sig.sh` at post time (or sign as yourself and drop the line).

---

Thanks @macneale4 — that settles the encode side. If klauspost-trained dictionaries buy nothing over snappy, the seam as proposed here (klauspost as a drop-in zstd *encode* backend) isn't worth pursuing, and we're glad to drop that approach. (The decode-interop half of the original question — reading existing libzstd trained-dict archives — is still open; question 2 below.)

**Disabling zstd and using snappy alone for beads works for us.** The goal on the beads side was never compression ratio — it's building embedded Dolt at `CGO_ENABLED=0` (the `gozstd` import is the last cgo dependency in a full `bd` binary). For the beads workload we agree database size is rarely the constraint. And your path (b) is simpler than what this issue asked for: no zstd encode backend at all. (Path (a), klauspost with an embedded generic dictionary, would also serve the cgo goal since klauspost is pure Go — we have no preference on compression; whichever is simpler for you wins.)

Three clarifying questions to make sure path (b) actually reaches `CGO_ENABLED=0`:

1. **Build-time vs runtime.** Disabling zstd at runtime doesn't by itself remove the direct `gozstd` API references in `store/nbs`, which fail under `CGO_ENABLED=0` unless tagged out or replaced. Would path (b) include tagging out (or removing) those references — i.e. a snappy-only `store/nbs` under a build tag or config, with no zstd backend linked?
2. **Existing stores.** Stores that have been GC'd by a cgo build may already contain zstd trained-dict archives — beads users do run `CALL DOLT_GC()` (it's the current workaround for #4258). Would a snappy-only binary need a zstd *decode* path for those (klauspost documents decoder support for standard trained dictionaries, so decode-only via klauspost looks feasible — we'd verify against a real archive fixture), or would GC rewrite them to snappy?
3. **Where the switch lives.** Would this be a Dolt archive-config default that the driver sets for beads, or something beads configures per-database?

Happy to help on either side of the boundary — PR #4408 has the current evidence branch (static binary, both embedded suites passing at CGO=0) if any of it is useful as a starting point, and we can benchmark or test a snappy-only build against real beads databases.

_{signature}_
