# Dependabot PR sweep — 2026-07-25

Sweep bead: mybd-i0pd. Scope: all 10 open dependabot PRs on gastownhall/beads
(#5015–#5023 opened 2026-07-24, plus #4702 stuck since 2026-07-10).

## Findings

- **Main was red**, blocking every merge via preflight: Nightly Full Tests
  failed at `4951412f` on `TestInitCancel_E2E` ("timeout waiting for prompt",
  5s kill under full-suite load). The test dates from 2026-02-10 and the
  nightly was green the previous 7 nights — load-induced flake, not the
  HasPersistedRemote commit. Reran the failed job (run 30141630769).
- **The gomod singleton shape is structurally broken here.** Every gomod bump
  rewrites `go.sum` → invalidates nix `vendorHash` → `update-vendor-hash.yml`
  pushes a bot commit → dependabot then refuses plain rebases → each merge
  forces `@dependabot recreate` + full CI on all remaining singles. GITHUB_TOKEN
  bot pushes also don't retrigger CI, so heads show "no checks" (#5017/#5018/
  #5020/#5021 were all in this state). #4702 burned two weeks and a day of
  patrol cycles this way (see mybd-9rgr notes), ending merge-blocked after a
  manual conflict-resolution merge skipped the vendorHash workflow (that
  incident is also mybd-cof8's subject).
- A locally-built combined PR was considered and rejected: no nix on this
  machine to compute vendorHash, and the workflow only fires for
  dependabot-authored PRs.

## Dispositions

| PR | What | Action |
|----|------|--------|
| #5015 setup-go 7.0.0 | actions bump | pr-handoff → mybd-21t0 (1 shard flaky-red: TestProxiedServerConfigSetMany; patrol reruns) |
| #5016 checkout 7.0.1 | actions bump | pr-handoff → mybd-kiaz (same flaky shard) |
| #5019 setup-python 7.0.0 | actions bump | green; pr-handoff → mybd-ihj9 |
| #5022 ruff 0.16.0 | uv dev dep | green; pr-handoff → mybd-340o |
| #5023 types-requests | uv dev dep | green; pr-handoff → mybd-haks |
| #5017 testcontainers-go 0.43 | gomod | superseded by grouping (below) |
| #5018 goldmark 1.8.4 | gomod | superseded by grouping |
| #5020 go-sqlmock 1.5.2 | gomod | superseded by grouping |
| #5021 anthropic-sdk-go 1.61 | gomod | superseded by grouping |
| #4702 testcontainers dolt 0.43 | gomod, stuck | superseded by grouping; disposition comment posted; mybd-9rgr blocked on mybd-8usj |

## The fix: dependabot `groups` (PR #5038)

gastownhall/beads#5038 (branch `maphew:chore/dependabot-groups`) adds `groups`
to `.github/dependabot.yml`: gomod minor+patch as one grouped PR (majors stay
solo so a breaking bump can't block the group), actions grouped wholesale, uv
grouped wholesale. One grouped gomod PR = one bot-computed vendorHash = one CI
cycle, and dependabot auto-closes the superseded singles when it regroups
(config changes trigger an immediate dependabot run). Handed off → mybd-8usj.

## Tails (all with patrol / future agents, not this session)

- mybd-8usj — #5038 merge (patrol; waits for base green).
- mybd-ysu1 (blocked on mybd-8usj) — after regrouping: close/reopen the grouped
  gomod PR to get CI onto the bot-commit head SHA, hand off to patrol, watch
  the anthropic-sdk-go 1.45→1.61 jump (used in `cmd/bd/find_duplicates.go`,
  `internal/compact/haiku.go`), then close mybd-9rgr + itself.
- Five singleton handoff beads above.

Nightly rerun and #5038 CI were in progress at session close.

## Addendum: bring-home session (same day)

Owner asked for an independent review of #5038 and to see the sweep through.

**Dual review of #5038** (claude reviewer: approve-as-is; codex gpt-5.6-sol:
fix-first). Codex caught two real gaps, both incorporated (commit 2a732e082):

- testcontainers-go + modules/dolt must bump in lockstep and break in 0.x
  "minors", so they got their own `testcontainers` group, excluded from
  `go-deps` — coupled together, never blocking routine bumps.
- The five open gomod singles exactly saturated `open-pull-requests-limit: 5`,
  and dependabot opens no new version PR at the limit — the grouped PR could
  be wedged out. Raised to 10. PR body's auto-supersession promise softened to
  a verified migration plan (mybd-ysu1).

**The nightly "flake" wasn't one.** The rerun failed identically: the 5s
prompt deadline in `TestInitCancel_E2E` races embedded-dolt store creation,
which crept 4.71s → 4.92s → 5.02s across three nightlies. Margin exhaustion.
Fix: 60s hang-guard deadline.

**#5039's own CI then exposed a second latent red**: the wy-jpd3.7 replica-guard
test `TestProtocol_GrantingReplicaRoundTripsJSONL` asserts non-reclamation via
`strings.Contains` on *combined* output, but `warnReplica`'s stderr audit line
echoes the issue id — a correctly-declined reclaim fails the test
deterministically, on every PR's Contract corpus job from its first outing.
Fix: parse reclaimed ids from the JSON payload (stdout is the machine truth);
fails-before/passes-after verified locally.

Both fixes travel as gastownhall/beads#5039 (`test: fix red main`), the
policy-sanctioned only-mergeable PR while main is red. Chain: #5039 green →
in-session merge → workflow_dispatch nightly full-test → base green → patrol
merges #5038 + remaining singles (#5016, #5023 already landed mid-session) →
dependabot regroups. Bead chain: mybd-kney → mybd-8usj → mybd-ysu1.

## Finale (2026-07-25 ~23:30Z)

Timeline after #5039 merged (squash 96522c1e9) and the dispatched nightly went
green: upstream broke main again mid-flight with the #5030 temp-boundary work
(macOS `/var/folders` + Linux proxied shards); deliberately stayed out — a
parallel maphew session (#5046/#5050/#5051) and upstream (#5044/#5047) owned
that lane; posted the two-mode diagnostic on #5044. Main greened at af076b628.

Patrol then merged #5038 and #5022 (one patrol quirk each: a transient
"merge state UNKNOWN" block cleared by pre-warming mergeability via
`gh pr view`, and a failed bead auto-close done manually). Dependabot reacted
to the config within a minute:

| Grouped PR | Contents | Path |
|---|---|---|
| #5055 testcontainers | root + modules/dolt 0.43 (was #5017 + stuck #4702) | vendorHash bot commit → close/reopen CI cycle → patrol (mybd-o7bv) |
| #5056 go-deps | go-sqlmock, anthropic-sdk-go 1.61, goldmark + bonus x/sys, x/term | same → patrol (mybd-8uij) |
| #5057 actions | setup-go 7, setup-python 7 (was #5015/#5019) | patrol (mybd-41xs) |

Dependabot auto-closed #4702 (ending its two-week loop) and the actions
singles; the pre-config gomod singles (#5017/#5018/#5020/#5021) needed manual
closes with supersession comments — exactly the codex review's prediction.
Confirmed mechanics recorded in bd memory `beads-nix-vendorhash-gosum`:
close/reopen does fire pull_request workflows on the bot-commit head.

Final ledger: 10 original PRs → 3 merged as singles (#5016, #5022, #5023),
7 superseded into 3 grouped PRs riding fresh CI under patrol ownership.
Plus landed on main: #5038 (groups config) and #5039 (two fix-for-main test
bugs). Open watch item: anthropic-sdk-go 1.45→1.61 compile risk rides #5056
CI; patrol escalates via merge-blocked if red.

_claude-fable-5-high on behalf of matt wilkie_

## Sweep closed (2026-07-26 ~04:3xZ)

All tails resolved; **zero open dependabot PRs**. Last-mile events: #5057
self-replaced by dependabot as #5059 (merged); #5055 went CONFLICTING after
#5056 merged first (both rewrite go.sum/default.nix — the one same-batch
collision grouping can't prevent, since testcontainers is deliberately
isolated), resolved with the standard `@dependabot recreate` → fresh
vendorHash bot commit → close/reopen → patrol merge. The go-deps group's
anthropic-sdk-go 1.45→1.61 jump compiled clean. Transient reds on the
recreated branch (pre-hash nix artifact + a Docker Hub pull timeout in
Differential Regression) cleared on the fresh head.

Merged on main this sweep: #5016, #5022, #5023 (singles), #5038 (groups
config), #5039 (two fix-for-main test fixes), #5055, #5056, #5059 (grouped).
Retired without merge: #4702, #5015, #5017, #5018, #5019, #5020, #5021, #5057
(all superseded). Patrol closed every handoff bead itself except mybd-8usj
(one failed auto-close, done manually).
