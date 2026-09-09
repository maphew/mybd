# Issue sweep: theme:data-integrity + theme:concurrency (18 stubs) — 2026-07-26

Second theme-clustered tri:claim drain sweep (epic mybd-xmx7). Freshness recon
delegated (haiku, ~40k tokens); **one recon claim was wrong and got caught by
in-session verification** — always verify "fix merged" claims before closing
(gh 3808 was CLOSED-unmerged, not merged).

## Dispositions

| bd | gh issue | disposition | reason |
|----|----------|-------------|--------|
| mybd-37wi | 4662 | dep-gated | blocked-by mybd-hcdds (fix PR #4798, changes-requested) |
| mybd-kl59 | 4673 | dep-gated | blocked-by mybd-rkfy (fix PR #4674, draft) |
| mybd-zgxf | 4657 | hold | #4675 merged (partial); full fence = PRs 4682/4697 under review (mybd-aayb leg) |
| mybd-zwurw | 3575 | hold | same claim-CAS family; same-user idempotence design caveat noted |
| mybd-soior | 3415 | relabel tri:defer | UX fixes merged (#3481); residue is an architecture redesign, no demand signal |
| mybd-f0wgx | 3807 | keep (corrected) | #3808 closed UNMERGED — cascade parity gap still real |
| mybd-je476 | 3878 | keep, noted | #3869 flock fix merged; design ask remains; consolidation candidate with backup stubs 75kql/udkv2 |
| mybd-o4wzj | 3926 | keep, noted | #4217 merged; managed-city migration guard still missing |
| mybd-5vvos | 4135 | keep, noted | 6-mode consolidated report; needs per-mode v1.1.2 verification split |
| mybd-tgqsj | 3905 | keep (p0) | no fix; silent status-UPDATE no-op |
| mybd-1hao | 4521 | keep (p0, human) | journal corruption + stale locks; awaiting integration hardening |
| mybd-xwgrd | 4093 | keep | events.old_value TEXT overflow ~64KB; schema change needed |
| mybd-j6mrb | 3964 | keep | --append-notes drops rapid writes; 4 independent repros |
| mybd-inbv | 5005 | keep (fresh) | dep ID normalization; wrong-edge delete on dep remove |
| mybd-0proh | 4750 | keep | child_counters not a true high-water for archived children |
| mybd-ad63 | 4371 | keep | partial label mutation, exit 0 |
| mybd-3rhd1 | 3360 | keep | ghost wisps: log-before-commit ordering |
| mybd-rkn87 | 4331 | keep | server-mode import race clobbers field edits; no direct fix |

Net: 18 → 0 closed, 2 dep-gated, 1 deferred, 4 hold/verify lanes opened, 11
confirmed-live engineering stubs (2 of them p0).

## Contrast with sweep 1

Import-export was freshness-heavy (7/13 retired); this theme is
**live-work-heavy** (0/18 retired) — data-integrity issues age without getting
accidentally fixed. The sweep's value here was linkage, not closure: the
claim-CAS family now routes through the julianknutsen PR reviews (4682/4697),
two wisp stubs are dep-gated on their open fix PRs, and the false "fixed by
#3808" was caught before it closed a real p1 gap.

## Carry-forwards

- Backup-subsystem mini-cluster (3878 + stubs mybd-75kql, mybd-udkv2) is a
  natural consolidation for the sync-remote sweep.
- mybd-5vvos (4135) and mybd-zlqec share the "verify on v1.1.2" shape — one
  repro-harness session could do both.
