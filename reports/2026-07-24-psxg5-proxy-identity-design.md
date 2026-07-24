# Design v2: harden managed dbproxy identity and listener-safety (mybd-psxg.5)

Target: gastownhall/beads managed proxied-server mode. Worktree
`.worktrees/beads/psxg5-proxy-identity` (branch `feat/psxg5-proxy-identity` @ upstream/main 2e20a183f).
v1 assessed by codex gpt-5.6-sol (reports/2026-07-24-psxg5-design-review-codex-sol.md); v2 adopts its findings.

## Defects (all confirmed at 2e20a183f)

- D1 blind adoption: `endpoint.go:305` + `probePort:317` — pidfile read + raw TCP dial = adopt;
  managed-local never compares identity (`intendedUpstreamID` returns "" — `endpoint.go:35`),
  even though the proxy publishes `UpstreamID` = DoltServer.ID root hash (`proxy/server.go:158`,
  `server/doltserver.go:101`).
- D2 blind kill: `endpoint.go:162-174` (spawn-path cleanup) and `shutdown.go:58-72` — production:
  `bd dolt stop` → `cmd/bd/dolt.go:613`. Pidfile schema `{pid,port,upstream_id}` has nothing to
  verify against (`pidfile/pidfile.go:13`).
- D3 port race: `PickFreePort` bind-close (`endpoint.go:70`); windows at `endpoint.go:177`→
  `server.go:136` (proxy) and `proxied_server.go:352`→`doltserver.go:236` (dolt YAML).
- D4 listener policy: custom YAML host never restricted (`proxied_server.go:270-285`); also
  unenforced for marker hand-edits, marker parse-fallback, and pre-marker default-path files
  (`proxied_server.go:302`, `:337`). Generated config is loopback (`:454-477`).
- D5 (review finding) orphan Dolt: `proxy-child.lock` is held by the proxy supervisor, not the
  Dolt child (`doltserver.go:221,247,266`). Proxy SIGKILL → lock freed, Dolt survives; cleanup
  reads `proxy-child.pid` only when the lock is HELD (`endpoint.go:162`), so the orphan is
  skipped and a second Dolt can launch on the same root.
- D6 (review finding) start/stop race: parent releases `proxy.lock` before `cmd.Start`
  (`endpoint.go:273`); `bd dolt stop` can observe a free lock and report success before the
  delayed child appears (`shutdown.go:61`).

## Locked decisions (review recommendations adopted)

1. **Identity = workspace-scoped control handshake, not PID+birth alone.**
   - Proxy opens a second loopback control listener (`127.0.0.1:0`, plain TCP, line protocol).
   - Secret: 32-byte random hex written `0600` to `<rootDir>/proxy.secret` before pidfile
     publication; rotated each proxy start.
   - Handshake: client sends `IDENT <secret>\n`; proxy replies one JSON line
     `{schema, role:"db-proxy", root_id, upstream_id, pid, birth, data_port}`.
   - Adoption requires: pidfile schema v2, `procid.Verify(pid, birth)` true, handshake OK,
     `root_id` == expected root hash, `data_port` == pidfile port, handshake pid/birth ==
     pidfile pid/birth. Then dial data port. Anything else → typed non-adoption status.
2. **`procid` package** (platform-split, deliberately the #4513 `BirthToken` shape; doltserver
   adoption stays out of scope, link in comments):
   - Versioned tokens: `linux-v1:<boot_id>:<starttime>` (parse `/proc/<pid>/stat` after final
     `)`), `windows-v1:<creation_filetime>` (GetProcessTimes), `darwin-v1:<sec>.<usec>`
     (sysctl kern.proc.pid).
   - `Capture(pid) (Token, error)`, `Verify(pid, Token) (bool, error)`.
   - `Open(pid, Token) (*Handle, error)` for TOCTOU-safe signaling: Linux pidfd
     (PidfdOpen/PidfdSendSignal), Windows process handle re-verified via GetProcessTimes;
     macOS verify→signal→re-verify with the residual race documented, not claimed away.
3. **Pidfile schema v2** (additive): `schema:2`, `kind:"db-proxy"|"dolt-backend"` (typed consts,
   validated by every reader), `birth`, `root_id`, `control_port` (proxy record only).
   Readers validate pid>0, port 1-65535, known kind, nonempty birth for v2. Writers:
   `proxy/server.go:158`, `doltserver.go:266`.
4. **Legacy (pre-v2) pidfile: fail closed.** Never dial-adopt. If `proxy.lock` free → quarantine
   record under lock, respawn. If held → actionable error (stop the old-version proxy or wait
   for idle exit). Loud log either way. No insecure-adoption opt-in.
5. **Kill safety**: signal only through a verified `procid.Handle`. Unverifiable record → never
   kill, never delete; quarantine pidfile (rename `<name>.stale-<unixts>`) and error with pid +
   paths. No `--force` that kills unverified PIDs (operator recovery = quarantine only).
6. **Orphan handling (D5)**: while holding `proxy.lock` exclusively, always inspect
   `proxy-child.pid` regardless of `proxy-child.lock` state; verified live backend record with
   free proxy lock = orphan → handle-kill, quarantine record, proceed. Unverifiable → rule 5.
7. **`readAndDial` returns typed statuses** (adopted / no-record / stale-verified-dead /
   identity-mismatch / legacy / malformed / io-error), not a bool; no pidfile mutation before
   `proxy.lock` is held (fixes the pre-lock unlink race, `endpoint.go:117-128`).
8. **Proxy port**: default port 0, child binds `127.0.0.1:0` itself, publishes ACTUAL
   `ln.Addr()` port (v1 bug caught in review: `server.go:158` would publish 0). Explicit
   nonzero port behavior preserved. `PickFreePort` remains only for dolt-config path + tests.
9. **Listener policy (D4)**: one shared `validateManagedListenerHost(cfg)`; strict numeric
   loopback only (`net.ParseIP(host).IsLoopback()`; empty host = default loopback per dolt
   servercfg → allowed; `localhost` rejected with fix-it text naming `127.0.0.1`). Enforced on
   EVERY managed-local path (generated, env custom, sidecar custom, pre-marker, marker
   hand-edit, parse-fallback) at runtime resolution AND `cmd/bd/init.go:331`. NO bypass env
   (managed mode = root/empty-password, `uow_factory.go:124`). External topology
   (`--proxied-server-external-host/port/socket` or server mode) is the supported non-local
   path and never launches a managed child. Remediation text uses those flags (not `--server-*`,
   which is mutually exclusive with proxied mode).
10. **Backend port collision (D3-dolt) deferred to PR-C/RFC**: needs managed-config
    allocator/ownership contract (config parsed+cached once `doltserver.go:83,118`; custom and
    pre-marker configs are user-owned, never rewritten `proxied_server.go:270,337`). Retry must
    key on typed child exit/liveness, NOT stderr-log scraping (storage-boundary: no Dolt
    append-log inspection). Out of this bead's PRs; tracked as a follow-up bead + upstream
    issue.
11. **D6**: close the release-lock-before-Start window — hold `proxy.lock` across fork/exec
    (child re-acquires or inherits ordering) or re-check under lock post-start; exact mechanism
    decided in implementation with a regression test (concurrent start vs `bd dolt stop`).

## PR sequence (review-recommended)

- **PR-A** `feat/psxg5-proxy-identity`: decisions 1-7 + 11 — procid, pidfile v2, handshake,
  verified adoption, safe cleanup/orphans, typed statuses, concurrency tests.
- **PR-B** (branch off after A): decisions 8-9 — proxy port-0 + comprehensive managed-listener
  enforcement + tests.
- **PR-C/RFC**: decision 10 (follow-up bead, coordinate with coffeegoddd before design).

## Test matrix (PR-A/B, extends BEADS_TEST_PROXIED_LOCAL=1 lane + unit tests)

Identity/adoption: foreign listener with doctored pidfile (dead pid; wrong birth; RIGHT birth of
unrelated live pid — the case PID+birth alone can't catch); root_id mismatch (second workspace);
legacy pidfile fail-closed both lock states; malformed/truncated JSON; invalid pid/port/kind/
token; quarantine behavior. Kill safety: unrelated live process in pidfile while a helper holds
`proxy-child.lock` (enters the dangerous branch); orphan Dolt after proxy SIGKILL (D5); zombie
child. Concurrency: N-process cold start converges on one proxy/backend + consistent artifacts;
concurrent start vs `bd dolt stop` (D6). Port-0: published port nonzero, dialable, real SQL op.
Policy: every listener path (env/sidecar/pre-marker/marker-edit/interpolation/omitted host/
IPv4+IPv6 loopback/wildcard/nonlocal), init-time and runtime. procid unit tests: self-pid
roundtrip, child exit → Verify false, cross-platform files CI-runnable. Windows/macOS lifecycle
lane extension defined-not-implemented (consistent with psxg.1 staging).
