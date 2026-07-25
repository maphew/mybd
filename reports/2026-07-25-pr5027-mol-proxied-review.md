# PR 5027 review — coffeegoddd, `bd mol` in proxied-server mode (2026-07-25)

Bead: mybd-wo8r. Upstream: gastownhall/beads#5027 (`db/mol`, head `1a275d351`,
+4304/−1140, 38 files). Author is the storage-layer owner; PR routes all `bd mol`
subcommands through a new `molReader`/`molWriter` port (`cmd/bd/mol_port.go`)
shared with embedded, and dedupes drifted proxied-only reimplementations.

## Context: coffeegoddd catch-up

8 proxied-mode PRs merged 2026-07-14→24 (#4794 comment, #4797 label, #4799
search+11, #4849 TLS, #4879 18 cmds, #4997 gate check, #5002 sql batches, #5003
compact/gc/ping, #5014 purge-dropped). #5027 is the mol capstone. No review from
him yet on our #5013/#5024 (mybd-psxg.5) as of this session; zero file overlap
between #5027 and those, so merge order is free.

## CI red — root cause (verified)

Shard 11: `TestProxiedServerReady/gated_empty_case`
(`ready_proxied_integration_test.go:439`) asserts `"No closed gates found"`; the
PR deleted proxied-only `emitGatedEmpty()` in favor of the shared embedded
wording `"No molecules ready for gate-resume dispatch"`. Deterministic, not
flake; slipped because his test plan ran proxied Mol|Wisp|Pour but not Ready.
One-line assertion update applied locally in
`.worktrees/beads/pr-5027-review` (uncommitted) and **verified green against a
real dolt sql-server 2.2.0 testcontainer**. Inverted string-sweep confirmed it
is the only orphaned assertion.

## Review method

Cross-vendor pair per house pattern: Codex gpt-5.6-sol (high, `codex review
--base upstream/main`) + Claude opus reviewer agent. Finding sets again largely
disjoint (pairing memory holds): Codex found the cascade-mismatch P1 that
Claude missed; Claude found the dropped-labels blocker, burn atomicity/retry
bug, and the parity divergences Codex missed. All merge-gating findings
re-verified in-session against source before posting.

## Posted outcome (single review comment, signed)

Blockers: (1) `uowMolWriter.CreateIssue` drops `issue.Labels`
(`CreateIssueParams.Labels` never set → proxied pour/wisp-create/bond produce
label-less molecules, breaks gate labels); (2) proxied clone paths skip
`ensureSubgraphCustomTypes` (custom types like `gate` never registered;
silent); (3) port `DeleteIssue` routes to domain `Cascade: true` while embedded
`tx.DeleteIssue` is single-row → proxied squash can cascade-delete dependents
outside the molecule; (4) proxied `mol burn` commits partial deletions on error
(contradicts documented all-or-nothing contract) and double-counts on
`backoff.Retry`.

Parity-decision items: hand-rolled `resolveMolID` vs `utils.ResolvePartialID`
(loses known-prefix handling + `SearchIssueIDs` narrow projection, 60s+
pathology; suggested widening `ResolvePartialID` to a narrow interface
instead); `GetMoleculeProgress` divergences (InProgress=1 hardcode, subgraph vs
direct-children totals, large-molecule fast path defeated);
`GetMoleculeLastActivity` root-seeding divergence; `ready --gated` vs `mol
ready --gated` render drift; `wisp gc --json` two shapes. Plus minors (isWisp
negative-cache + fail-open misroute, dead nil guard, parity-guard tests need
tracking refs, hooked-exclusion release note, shard manifest conflict warning).

Verdict conveyed: architecture right, dedup direction correct everywhere
traced, storage boundary clean, best proxied tests in repo; land after
blockers. Offered to push the test fix and/or blocker fixes as follow-up
commits (absorb-and-fix per PR_MAINTAINER_GUIDELINES).

## Tails

- `.worktrees/beads/pr-5027-review` kept with the verified test fix uncommitted,
  in case we push a follow-up commit to his branch.
- mybd-wo8r stays open until coffeegoddd responds or fixes land.
- mybd-psxg.5 unchanged: still awaiting his review of #5013/#5024.
