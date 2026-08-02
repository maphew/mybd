# Issue sweep — theme:cli-ux (run 12, unattended solo-sweep)

2026-08-02. 35 open `tri:claim` stubs carry `theme:cli-ux`. Scope cap 12, taken
as both p1s plus the ten oldest p2s (oldest upstream issue number first — that
maximises the freshness-kill yield, which is what a sweep is for). Nothing was
closed, labelled, or posted upstream; every row below is a proposal recorded via
`solo-bd note` for the owner to execute.

## Dispositions

| bd | upstream | p | proposed | evidence |
|----|----------|---|----------|----------|
| mybd-dyqws | #3585 | 2 | **close** | Fixed by #5189 (**verified merged=true**, 2026-07-31, `822fd01aa`), filed against sibling #3885 so 3585 never auto-closed. Read the code to confirm it covers 3585: `init.go:568` inherits `dolt_mode` from metadata.json unless `--server/--shared-server/--proxied-server` or `BEADS_DOLT_*` names a mode, and `--reinit-local` is not in that list — so a bare re-init now prints `Mode: server` (init.go:2046). |
| mybd-s4h6 | #4395 | 2 | **consolidate** → mybd-v1fux | `GetDependencyCountsInTx` hardcodes `AND type = 'blocks'` (dependency_queries.go ~466, ~495), so `bd list --json` `dependent_count` cannot see parent-child edges. Confirmed present. |
| mybd-alm2 | #4396 | 2 | **consolidate** → mybd-v1fux | `.dependents[]` is now opt-in behind `--include-dependents` (show.go ~47/397), so the reported empty array is expected default behaviour today. Repro plausibly stale, not verified fixed. |
| mybd-k4v5z | #3518 | 2 | flesh-out | `doltserver.go:863-878` still appends "To start manually: bd dolt start" in *both* branches — including the one whose own text says the server is externally managed. No PR exists. |
| mybd-rgje4 | #3981 | 2 | flesh-out | All three escapes still shut: `main.go:421` and `main.go:605` call warn-only `CheckBeadsDirPermissions`; `FixBeadsDirPermissions` is create-path only (fs/beads.go:70-74); no `--repair` flag; bare `bd doctor` gated off in embedded by the #3794 policy. Needs an owner call on which escape to open. |
| mybd-hclnd | #4036 | 2 | flesh-out | Structural in `integrations/beads-mcp/.../server.py`: `_context_set` (679) pops `BEADS_DB` for Dolt backends, `_context_show` (746) reads only `BEADS_DB` — so Dolt workspaces are *guaranteed* "Database: NOT SET". Reporter already narrowed this himself. Display bug, Python not Go. |
| mybd-06uhb | #4285 | 2 | flesh-out | `buildAttachCloneOpts` (mol_bond.go:449-457) still uses `extractAllVariables` with no `applyVariableDefaults` call; `pour.go` calls both. Empty timeline since 2026-06-01. |
| mybd-0uxy4 | #3288 | 2 | flesh-out (retarget) | Premise stale: `bd linear link` **does not exist** — `cmd/bd/linear.go` registers only `sync`/`status`/`teams` (211-214). Underlying silent type-based `state_map` fallback is still real. Retarget to a warn/refuse on `sync --push`, or decline as won't-do — but not as "stale". |
| mybd-ulmls | #3927 | **1** | keep-open | The only gastownhall commit on the timeline is `027b17d0e` = #4191, **verified merged** but **diagnostics-only by its own body** (debug logging + a better error hint). Discovery logic unchanged. This is the exact false positive the strategy report warns about. Still needs a repro. |
| mybd-5eon | #4635 | **1** | keep-open | Guard confirmed at `init.go:1006`; `hasExplicitBeadsDir` (846) is still only `BEADS_DIR`. Prior bead note pointed at #4795 — **re-verified: state=open, merged=false**, last touched 2026-07-24, and its title scopes it to the home directory only, not root or a non-empty dir. Action is review/land #4795, not reimplement. |
| mybd-oa793 | #4241 | 2 | keep-open | `routing_read.go:52` still hardcodes `DetectUserRole(".")`. Fix PR #4242 **verified state=open, merged=false**. Collides with in-progress lane bead mybd-w7yc — leave to that lane. |
| mybd-4efw4 | #3316 | 2 | keep-open | Wiring confirmed at `cook.go:632-663`, but `createGateIssue`'s doc comment (488-489) says gates blocking their step is *intended*. Design disagreement, not drift — needs an owner call, and a flip would silently invert every existing formula. |

**Counts:** 1 close · 2 consolidate · 5 flesh-out · 4 keep-open. Zero executed.

## Root-cause map

- **Fix exists but is not landed (2).** #4635→#4795, #4241→#4242 — both PRs
  verified open/unmerged this run. Both stubs *look* addressed from the
  timeline and are not. The throughput lever here is the PR queue, not the
  issue queue.
- **Referenced-but-not-fixed (1).** #3927 has a merged PR that only added
  diagnostics. Merge state alone is not evidence of a fix.
- **Type-filter policy disagrees across three code paths (2).** `bd list --json`
  filters `type='blocks'`, the Dolt `CountDependents` filters nothing, and
  `.dependents[]` is now opt-in. New bead **mybd-v1fux** owns picking one answer
  and making the three agree; #4395 and #4396 fold into it.
- **CLI reports state the store does not hold (2, one now fixed).** #3585
  (`Mode: embedded` over a server store) and #4036 (`Database: NOT SET` after a
  successful set). #3585 landed; #4036 is the same shape one layer out, in the
  Python MCP server, and nobody has touched it.
- **Advice that assumes bd owns the resource (1).** #3518 tells you to start an
  embedded server when the unreachable one is external — in the very branch that
  already knows it is external.
- **Self-heal gated by deliberate policy (1).** #3981 is not a missing fix; the
  fix function exists and every route to it is closed on purpose (#3794). It
  needs a decision, not an implementation.
- **`pour`/`bond` divergence (1).** #4285: the two paths share
  `resolveAndCookFormulaWithVars` but not the variable-default handling. Worth a
  parity test, since they have now drifted once.
- **Design disagreement filed as a bug (1).** #3316.

New bead filed: **mybd-v1fux** (p2) — dependency counts / `.dependents` exclude
parent-child edges.

## Not reached (23 stubs)

All p2/p3, newer upstream numbers: mybd-3o7s, mybd-3wkx, mybd-47ly, mybd-7sogg,
mybd-ap5nk, mybd-g07u, mybd-g88l, mybd-p5k4, mybd-q6iq, mybd-sfiw, mybd-si4zw,
mybd-txicf, mybd-03jmk, mybd-agjb, mybd-bj0x, mybd-e6x29, mybd-f2kq,
mybd-h5pky, mybd-kqm7, mybd-lh3kc, mybd-pah7v, mybd-xfmr8, mybd-yyks. Two
clusters in there look pre-groupable for the next run: `agjb`+`pah7v` (DOLT_COMMIT
no-op warnings) and `g07u`+`p5k4` (`--json`/config-state shape).

## Confidence and caveats

- **All merge-state claims were verified by direct `pulls/<n>` lookup**, not
  inferred from the timeline: #5189 merged=true; #4191 merged=true (but
  diagnostics-only); #4795 merged=false; #4242 merged=false. #5203 (cited only
  as corroboration under #3981) came from recon and I did **not** verify it; no
  disposition rests on it.
- **No code was executed.** I have no shell beyond `solo-recon`, so every
  "defect confirmed present" is static reading of `upstream/main`, not an
  observed run. The one **close** proposal (#3585) is the one that most deserves
  a live repro before the owner acts on it — kevglynn's beads-only repro is in
  the issue thread and takes a minute.
- **#4396's disposition is the softest.** The code changed shape since filing
  (opt-in `.dependents`), and the 2026-06-16 repro comment does not say whether
  the child was created via `--parent` or as a bare dotted ID — which decides
  whether an edge exists at all. That is why it is consolidate-and-re-run rather
  than close.
- **Possible live lane on #3518.** Its timeline shows commits dated *today* on
  the `maphew/beads` fork, unmerged, message `fix(config,dolt): infer server
  mode from a configured non-localhost host (GH#3545, GH#3518)`. Adjacent rather
  than identical (mode inference, not error text), but check before assigning.
- **#4241 was left alone deliberately** — bead mybd-w7yc is in_progress for
  PR #4242 in another lane.
- Not blocked on anything; no denied command I needed, no rate limiting. Only
  friction was `solo-bd` rejecting a note containing the word "human-vetted" as
  a reserved-label mention; reworded.
