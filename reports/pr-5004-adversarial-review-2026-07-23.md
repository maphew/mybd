# PR #5004 Adversarial Review — managed-local proxied lifecycle smoke

| Field | Value |
|---|---|
| PR | [gastownhall/beads#5004](https://github.com/gastownhall/beads/pull/5004) |
| Title | `test: managed-local proxied lifecycle smoke lane (Linux, offline)` |
| Author | maphew |
| Base / head | `main@1125ef3b` / `test/proxied-local-smoke@9bcfcbff` |
| Size | +627 / -0 across 3 files |
| Local bead | `mybd-87ef` |
| Review date | 2026-07-23 |
| Review method | Three independent review angles fanned out; two `gpt-5.6-sol` / xhigh reviews completed, one slow run was stopped; orchestrator reproduced and reconciled findings |

## Verdict

**Fix-merge. Do not merge the current head as-is.**

The lane is valuable and the central test design is sound: it genuinely selects
managed-local mode, launches the local proxy/backend topology, writes and reads
through it, checks generated configuration and live listeners, observes idle
shutdown, and verifies transparent restart with persisted data. The exact smoke
passed three consecutive local runs against Dolt 2.2.0 (66.1 seconds total), and
the hosted lane passed against pinned Dolt 2.2.2.

The current head nevertheless has three CI-integrity blockers. The new job can
silently pass while running no target test, skips direct dependencies through
its path filters, and still invokes the package-wide Docker testcontainer setup
despite claiming an offline/testcontainer-free lane. These are small fixes on a
useful contributor branch, so the maintainer-policy outcome is **Fix-merge**,
not rejection or replacement.

## Merge blockers

### P1 — CGO-off builds silently pass with zero managed-local tests

Both added Go files require `cgo`, but the workflow neither sets
`CGO_ENABLED=1` nor proves the compiled binary contains
`TestManagedLocalProxiedLifecycleSmoke`:

- [workflow build/run](https://github.com/gastownhall/beads/blob/9bcfcbff025007dfe6de06ed3e12f2214c59e58f/.github/workflows/proxied-local-smoke.yml#L66-L89)
- [helper build constraint](https://github.com/gastownhall/beads/blob/9bcfcbff025007dfe6de06ed3e12f2214c59e58f/cmd/bd/proxied_local_helpers_test.go#L1)
- [lifecycle build constraint](https://github.com/gastownhall/beads/blob/9bcfcbff025007dfe6de06ed3e12f2214c59e58f/cmd/bd/proxied_local_lifecycle_linux_test.go#L1)

Reproduction at the exact PR head:

```text
$ CGO_ENABLED=0 go test -tags gms_pure_go -count=1 \
    -run '^TestManagedLocalProxiedLifecycleSmoke$' -v ./cmd/bd
testing: warning: no tests to run
PASS
ok github.com/steveyegge/beads/cmd/bd 0.075s [no tests to run]
```

GitHub's current Ubuntu image defaults CGO on, so the observed PR run did
execute the test. The workflow is still fail-open: a runner/toolchain/env change
turns the dedicated gate into a green no-op.

**Fix:** set `CGO_ENABLED: "1"` explicitly for compilation and execution, then
fail unless `-test.list '^TestManagedLocalProxiedLifecycleSmoke$'` returns the
expected test before running it.

### P1 — Path filters omit direct managed-local dependencies

The workflow filters cover the new files, selected proxied command files,
`dbproxy`, and `uow`, but omit direct lifecycle inputs including:

- `cmd/bd/init.go` — parses, validates, and dispatches
  `--proxied-server-idle-timeout`;
- `cmd/bd/init_proxied_server.go` — builds and persists the proxied client info;
- `cmd/bd/proxied_integration_helpers_test.go` — provides every subprocess
  init/create/show helper used by the new test;
- `cmd/bd/test_dolt_server_cgo_test.go` — controls package-wide pre-test setup;
- `cmd/bd/store_factory*.go`, `internal/configfile/**`, and
  `internal/doltserver/**` — select and configure the managed path;
- `go.mod` / `go.sum` — can change the embedded/client and pinned external-Dolt
  compatibility surface.

See the current [push and pull-request filters](https://github.com/gastownhall/beads/blob/9bcfcbff025007dfe6de06ed3e12f2214c59e58f/.github/workflows/proxied-local-smoke.yml#L17-L37).
A change that drops idle-timeout persistence, changes client-info decoding, or
misroutes managed init can therefore merge without exercising the only
managed-local lane.

The workflow also has no `merge_group` trigger, so it cannot become a reliable
merge-queue gate in its present form.

**Fix:** preferably run this roughly 20-second runtime test on every PR/push
after its binary is built. If cost requires filtering, include the complete
direct dependency set above and add `merge_group`.

### P1 — The “no testcontainer” lane still enters shared Docker setup

`cmd/bd` registers a CGO package hook that starts the shared Dolt testcontainer.
It bypasses that setup for `BEADS_TEST_EMBEDDED_DOLT=1` and
`BEADS_TEST_PROXIED_SERVER=1`, but not for the new
`BEADS_TEST_PROXIED_LOCAL=1` mode:

- [package hook registration and bypasses](https://github.com/gastownhall/beads/blob/1125ef3b46b8436bb5132318f56f62c593fcc403/cmd/bd/test_dolt_server_cgo_test.go#L15-L39)
- [offline workflow environment](https://github.com/gastownhall/beads/blob/9bcfcbff025007dfe6de06ed3e12f2214c59e58f/.github/workflows/proxied-local-smoke.yml#L71-L88)

This is observable, not theoretical:

- the exact local smoke invocation started and stopped
  `dolthub/dolt-sql-server:2.2.0` before the managed-local test;
- the hosted CI log avoided startup only because that image was not cached:
  `WARN: Docker image ... not cached locally ..., skipping Dolt tests`.

Docker is reached through its Unix socket, so the daemon is outside the
test process's network namespace. A cached image makes this allegedly
testcontainer-free lane environment-dependent and allows unrelated Docker
setup to delay or fail before the target test.

**Fix:** exempt `BEADS_TEST_PROXIED_LOCAL=1` in
`startTestDoltServer`, and set `BEADS_TEST_SKIP=dolt` in the workflow as a
defense-in-depth assertion of intent.

## Important test-strengthening fixes

### P2 — Dynamic listener checks do not bind the pidfile ports to the pidfile processes

`assertLoopbackOnlyListeners` requires at least one listener and rejects
non-loopback addresses, but it never receives the expected `proxyPF.Port` or
`backendPF.Port`. A PID with an unrelated loopback listener passes even when the
advertised serving port belongs to another process.

See [the calls](https://github.com/gastownhall/beads/blob/9bcfcbff025007dfe6de06ed3e12f2214c59e58f/cmd/bd/proxied_local_lifecycle_linux_test.go#L94-L102)
and [the assertion](https://github.com/gastownhall/beads/blob/9bcfcbff025007dfe6de06ed3e12f2214c59e58f/cmd/bd/proxied_local_lifecycle_linux_test.go#L175-L190).

**Fix:** require the enumerated socket set to contain the expected
`127.0.0.1:<pidfile port>` for each process, in addition to rejecting every
non-loopback listener.

### P2 — The requested idle timeout is not asserted

The test requests five seconds, but `bdManagedLocalInit` only checks that the
client-info `External` block is absent. It never asserts
`info.IdleTimeout == 5*time.Second`. The shutdown wait permits 90 seconds, so a
regression that drops the flag and falls back to the 30-second production
default still passes.

See [client-info validation](https://github.com/gastownhall/beads/blob/9bcfcbff025007dfe6de06ed3e12f2214c59e58f/cmd/bd/proxied_local_helpers_test.go#L52-L72)
and [timeout setup/wait](https://github.com/gastownhall/beads/blob/9bcfcbff025007dfe6de06ed3e12f2214c59e58f/cmd/bd/proxied_local_lifecycle_linux_test.go#L44-L56).

**Fix:** assert the persisted timeout immediately after init. If the held
connection is intended to prove active-connection gating end to end, hold and
query it across more than one full configured idle interval before release.

## Non-blocking hardening

- Use context-bounded subprocess helpers. The outer 60-second poll deadline
  does not bound `bdProxiedRun`, which uses an unbounded `exec.Command.Run`;
  a wedged child reaches the 15-minute global timeout and can strand detached
  proxy/backend processes.
- Remove the `proxyPF2.Pid != proxyPF.Pid` assertion or compare process birth
  identities. Linux may legitimately reuse a numeric PID; number inequality is
  not an identity contract.
- Add table tests for the roughly 100-line procfs parser, especially IPv6,
  mapped addresses, malformed rows, and absent `/proc/net/tcp6`.
- Upload `server.log`, generated config, pidfiles, and socket snapshots on
  workflow failure. The current `t.TempDir` cleanup discards the most useful
  diagnostics for an intermittent lifecycle failure.
- Consider concurrency cancellation for superseded PR runs.

## Existing product risks are not blockers for this test-only PR

The review also traced pre-existing PID reuse, stale pidfile, backend
port-readiness, and shutdown races in the managed proxy implementation. PR
#5004 does not introduce them, and its body explicitly leaves identity
hardening to [#4513](https://github.com/gastownhall/beads/issues/4513) and
[#4637](https://github.com/gastownhall/beads/issues/4637). They should remain
separate product work rather than expanding this test-only PR into a lifecycle
redesign.

The smoke can, however, cheaply improve future coverage by checking exact
pidfile-port ownership and the restarted backend identity. Those assertions
strengthen this lane without pretending to solve the underlying identity
protocol.

## What held up under adversarial review

- `External == nil`, proxied subprocess environment selection, and direct SQL
  through the advertised proxy jointly rule out an embedded/external false
  positive.
- Closing both the checked-out `sql.Conn` and its entire `sql.DB` pool is the
  correct way to release every proxy TCP session before idle shutdown.
- Cleanup is registered before init launches the detached topology.
- The graceful path checks both pidfile removal and death of the recorded proxy
  and backend processes.
- Static generated-config validation, live socket enumeration, CLI CRUD,
  direct SQL, idle shutdown, restart, and persisted reread provide complementary
  signal.
- The `/proc/net/tcp{,6}` inode join and address decoding are sound for the
  current Linux/amd64 lane.
- `git diff --check` is clean; formatting and lint CI passed.

## Validation and PR state observed

- Base `main` health: green under blocking preflight.
- Preflight: branch maintainable and mergeable, but review required and checks
  pending at review start.
- Hosted managed-local lane: passed in 21.8 seconds on Dolt 2.2.2.
- Local exact smoke: three consecutive passes on Dolt 2.2.0, 66.1 seconds
  total; package setup unexpectedly started the shared Docker Dolt container.
- CGO-off falsification: green zero-test reproduction confirmed.
- PR discussion/review threads: none at review time.
- Working tree at exact head `9bcfcbff025007dfe6de06ed3e12f2214c59e58f`
  remained clean.

## Recommended maintainer action

Apply the three blocker fixes directly on `test/proxied-local-smoke`, strengthen
the exact-port and timeout assertions in the same pass, rerun the hosted lane,
and obtain a substantive review from someone other than the author. The PR is
then a strong merge candidate.

Do not open a replacement PR: the contributor branch is writable, the design
and most of the implementation are worth preserving, and every blocker is
localized.

---

_codex-gpt-5.6-sol-high on behalf of maphew_
