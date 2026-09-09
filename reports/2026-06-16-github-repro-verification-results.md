# GitHub Repro Verification Results

Work item: `mybd-pxzp`

## Confirmed

### issue #4241

- URL: https://github.com/gastownhall/beads/issues/4241
- Result: confirmed
- Tested binary: `bd version 1.0.5 (Homebrew)`
- Environment: Linux, temporary HOME, two scratch Git repos under `/tmp`
- Action: applied `has-repro`
- Comment: https://github.com/gastownhall/beads/issues/4241#issuecomment-4723744880

Observed: `bd -C "$target" list --parent "$root" --all --limit 1` emitted the role warning when run from a separate caller repo with no `beads.role`, while the equivalent command run from inside the target repo did not warn.

## Not Reproduced

### issue #4399

- URL: https://github.com/gastownhall/beads/issues/4399
- Result: not reproduced
- Tested binary: `bd version 1.0.5 (Homebrew)`
- Environment: Linux, temporary HOME, scratch Git repo under `/tmp`
- Action: no label applied

Observed: `bd update "$id" --status in_progress --json | python3 -c 'import json,sys; json.load(sys.stdin)'` exited `0`; the raw `bd update --json` output was a single parseable JSON array.

### issue #3787

- URL: https://github.com/gastownhall/beads/issues/3787
- Result: not reproduced
- Tested binary reported by verifier: `bd version 1.0.3 (6a6421740)`
- Environment: Linux, temporary HOME, scratch Git repo under `/tmp`
- Action: no label applied

Observed by independent verifier: default `.beads/issues.jsonl` export did not include `_type:memory` lines in the scratch repo; after creating an issue, `bd remember`, `bd memories`, and `bd prime` did not change the export hash or produce a diff. Ten forced memory-inclusive exports produced identical hashes and stable memory order.

## Build Note

Building `bd-main` with default CGO failed on this host because ICU headers are missing (`unicode/uregex.h`). A pure-Go build with `CGO_ENABLED=0 -tags 'embeddeddolt gms_pure_go'` succeeded and reported `bd version 1.0.5 (dev)`, but cannot open embedded stores. Local CLI repros above therefore used the installed current Homebrew binary.
