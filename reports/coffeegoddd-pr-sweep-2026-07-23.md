# Maintainer sweep: coffeegoddd's open PRs — 2026-07-23

Owner request: review all of coffeegoddd's open PRs on gastownhall/beads, maintainer-fix
the obvious things on his branches, and leave him only the items that need his judgment.
Sweep bead: mybd-lw0b. Review fan-out: workflow `wf_d25f440f-b37` (6 reviewers + 4
adversarial verifiers, ~634k tokens) plus a Codex (gpt-5.6-sol, high) cross-vendor pass
on the schema-migration PR per the store-open pairing rule.

Base health at sweep time: upstream main green (Main b7e25f091, Regression 1125ef3b4).

## Outcomes

| PR | Verdict | Action taken |
|----|---------|--------------|
| 5003 proxied compact/gc/ping/clean-databases | merge-fix | Maintainer commit `21eacaef0` pushed; comment with 4 author-judgment items; **squash-merged 2026-07-24 by pr-babysit patrol** after green checks + preflight |
| 5002 bd sql multi-statement + --database | easy-win / merge | Approved + **squash-merged** as `b9b437894` after green sharded CI; Copilot threads resolved |
| 4942 Bump Go 1.26.5 | merged externally | Merged by a parallel maphew session at 01:54Z **with red nix** — go-modules FOD hash changed without default.nix update, main nix red ~2h until dependabot #4701's auto-computed vendorHash healed it |
| 4388 ci: drop -short + bundled metrics/RunE | retire | **Closed** with credit note |
| 4372 metrics → GA4 via eventkit | retire | **Closed** with credit note |
| 4286 six target-typed dependency tables | retire (re-cut wanted) | **Closed** with full re-cut requirements |

## Maintainer fixes pushed (PR 5003, commit 21eacaef0)

- `runCompactDoltProxiedServer`: added `CheckReadonly("compact")` on the non-dry-run
  path — proxied `bd compact --dolt` could run Dolt GC in readonly mode (embedded path
  and the PR's other proxied handlers all guard).
- Same function: Dolt GC failure now returns `HandleErrorRespectJSON` instead of raw
  stderr + `SilentExit`, so `--json` callers get a structured error.
- `runCompactProxiedServer`: `--json` emits `remote_refs_pruned`/`tags_anchoring` as
  arrays matching embedded `compact_dolt.go`, not counts under the same keys.

Validated locally: `go build`, `go vet`, `gofmt`, `go test -run TestCompact ./cmd/bd/`
(CGO_ENABLED=1, `-tags gms_pure_go`), all clean.

## Why the three old PRs were closed

- **4388 / 4372**: their real content (RunE refactor + usage metrics) landed on main
  2026-06-23 via #4419 as cherry-pick `d7d7a3460` with coffeegoddd's authorship
  preserved, then hardened (consent notice `00d317dde`, DO_NOT_TRACK #4938, config
  precedence/unset/0600 fixes) — resolving every CHANGES_REQUESTED finding on 4388.
  The leftover CI intent (drop `-short`) contradicts main's adopted
  `Short()`-allowlist design. Both branches were 600-700 commits behind with
  100+ conflicted paths. Verified before closing: commits exist on upstream/main with
  stated authorship.
- **4286**: architecture explicitly wanted (steveyegge audit decision bd-6dnrw.14,
  julianknutsen upgrade-program exclusion), but branch unlandable: migration IDs
  0050/ignored-0009 taken by shipped migrations, 722 commits behind, 64 conflict hunks
  in 32 files. Close comment records six re-cut requirements from the dual-vendor
  review: (1) store-open verification brick (verify runs every MigrateUp, counts
  diverge after first post-migration write; cursors advance before verify), (2)
  INSERT IGNORE backfill collapses duplicate legacy rows then count-verify aborts,
  (3) no mixed-version dual-write/fence → silent divergence across clones, (4) natural
  PKs don't stop add/add conflicts (per-clone NOW()/actor/metadata non-key values),
  (5) cross-target logical-edge uniqueness lost (remove deletes first match only;
  rename-collision test deleted), (6) down migration is data-destructive.
  Two earlier human review comments (HasCycle wisp traversal, doctor deep.go legacy
  names) were **refuted** by the adversarial verify pass — the branch had fixed them —
  and were withdrawn in the close comment.

## Left for coffeegoddd (tracked in mybd-5bz2)

PR 5003 judgment items: uow init/migrate transient-retry gap (flake pressure from the
new parallel DOLT_GC tests), proxied-vs-embedded `bd gc` exit-code divergence,
clean-databases circuit-breaker omission for multi-tenant servers, JSON parity ledger.
PR 5002 non-blocking note: `SwitchDatabase` session-scoped USE outlives the UOW on
pooled connections — safe for one-shot CLI, latent hazard if reused long-lived.

## Session-overlap incident → babysitter pattern

The #4942 red-nix merge collision (a parallel session of the same user merging a
PR another session was mid-review on) exposed that `bd --claim` cannot mutually
exclude same-user sessions. Outcome: babysitter pattern instituted —
`scripts/pr-handoff` + `scripts/pr-babysit` (systemd user timer, zero-token
mechanical patrol that merges green PRs after blocking preflight, one flake
rerun, `merge-blocked` relabel for agent judgment). Sessions produce; only the
patrol merges. Documented in AGENTS.md "PR Merge Tails" + `bd remember
pr-babysit-pattern`. First live customer: #5003, merged by the patrol.

## Cross-vendor observation

The Codex pass on 4286 independently found items 4-6 above, which the Claude reviewers
missed; the Claude verify pass refuted two stale human review comments Codex did not
question. Pairing vendors on schema/store-open changes continues to pay for itself.
