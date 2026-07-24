# PR #4366 fix-merge: fail loud on unloadable metadata.json — 2026-07-06

**Outcome:** gastownhall/beads#4366 (Wldc4rd) merged as `b556c8edd`, 54/54 checks green.
Tracking bead: mybd-7a1f (closed).

## The bug (reproduced on main tip e3e2db1e8)

`.beads/metadata.json` present but unloadable (torn read / corrupt JSON) silently
degraded store selection to the embedded default:

- `bd list --json` → exit 0, `[]` — false-empty; orchestrators read "no work".
- The fallback **created a phantom empty default-name database** on disk beside
  the real one — the same `beads`-vs-`mybd` drift this repo carries
  `scripts/check-beads-config --fix` to repair. This bug class is plausibly how
  that drift originates.
- Writes misrouted: `bd update` on an existing issue reported "no issue found".

Four call sites collapsed *absent* (legit fresh-repo default) into *unloadable*:
`loadServerModeFromBeadsDir`, the store-init path in `main.go`, and both store
factories. Torn-read trigger: `configfile.Save` and `writePortFile` used plain
`os.WriteFile`.

## Why the PR looked broken (it wasn't)

All 6 red checks were **attempt-2 re-runs of the June 10 CI**, pinned to the
original merge commit (June-10 base):

- Routed-store test failures (`store is read-only`) reproduce at that base
  **without** the patch — a since-fixed main bug of that era.
- Upgrade-smoke resolves its release matrix at **runtime**: the re-run pitted
  late-June v1.1.0-family releases against a June-10 candidate binary — a
  disguised downgrade. (Now in `bd remember`: `stale-pr-ci-reruns-test-pinned-merge`.)

## Maintainer actions (contributor branch, attribution intact)

1. Merged current main into `Wldc4rd:mechanic/fail-loud-store-selection` (clean).
2. **Fixed a real blocker** flagged independently by both reviewers (Claude
   `reviewer` agent + `codex-agent reviewer`): the fatal also fired in the
   no-DB pre-run contexts, bricking the repair path — `bd doctor`, `bd init`,
   `bd version` all exited 1 on corrupt metadata, while the error text says
   "fix or restore metadata.json and retry". Fixup `64cdff392` scopes the hard
   error to store-selecting paths (store init + factories); pre-run contexts
   warn-and-continue.
3. Added an e2e regression test (diagnostics run / data fails loud naming the
   file / `bd init` repairs / data intact afterward) and a nocgo factory-error
   test; cleaned a dead comment.
4. Validated locally: PR unit tests, routed integration suites, `configfile`,
   `doltserver`, vet, builds CGO 0/1. Approved workflow runs, merged on green.

## Side finding: WSL global gitconfig pollution

`~/.gitconfig` on this machine has been `CI Bot <ci@beads.test>` since
2026-04-07 (old beads test escape; predates this session). bd-main now has
repo-local identity set to matt wilkie; the global file is left for the owner.
Recorded in `bd remember`: `wsl-global-gitconfig-ci-bot-pollution`.

---
_claude-fable-5-high on behalf of matt wilkie_
