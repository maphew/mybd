## Verdict

Request design revision before implementation. D1–D4 are real, but W1 does not yet establish proxy/socket identity, W2’s backend retry lacks a safe ownership model, and W3 misses several exposure paths. Implementing this version would likely cost another storage-owner review cycle.

## Verified defects

- D1 is confirmed. Managed-local computes no intended upstream identity, and adoption is only pidfile read plus raw TCP connect; PID is ignored. Existing tests even adopt a listener with nonexistent PID `12345`, proving the behavior is intentional today: [endpoint.go:35](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:35), [endpoint.go:117](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:117), [endpoint.go:305](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:305), [endpoint_mismatch_test.go:16](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint_mismatch_test.go:16).

- D2 is confirmed. Both orphan cleanup and shutdown kill the pidfile PID without identity verification: [endpoint.go:162](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:162), [shutdown.go:58](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/shutdown.go:58). Correction to the design: `proxy.Shutdown` is not merely a test helper; production `bd dolt stop` calls it at [dolt.go:613](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/dolt.go:613).

- D3 is confirmed. Proxy allocation closes the temporary listener before the child binds; backend config similarly records a released port long before Dolt starts: [endpoint.go:70](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:70), [endpoint.go:177](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:177), [server.go:136](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/server.go:136), [proxied_server.go:352](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/proxied_server.go:352), [doltserver.go:236](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:236).

- D4 is confirmed. Custom env/sidecar configs are parsed and warned about but their effective host is not constrained, while newly generated configs use `127.0.0.1`: [proxied_server.go:214](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/proxied_server.go:214), [proxied_server.go:270](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/proxied_server.go:270), [proxied_server.go:454](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/proxied_server.go:454).

## Workstream assessment

### W1 — not implementation-ready

The birth-token direction is good, but it fixes stale PID detection, not D1 as claimed.

1. PID+birth does not bind that process to `pf.Port`. A pidfile containing a live unrelated PID with its correct birth token plus a foreign listener still passes the proposed algorithm. Add a control identity exchange or OS socket-owner correlation. A separate local control channel is cleaner than modifying the transparent MySQL stream. It should report at least process role, workspace/root ID, effective launch/config ID, upstream ID, and advertised data address.

2. Managed-local already has a useful root-derived identity: `DoltServer.ID` hashes its absolute root and the proxy writes it into `UpstreamID`, but adoption deliberately does not compare it: [doltserver.go:101](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:101), [proxy/server.go:158](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/server.go:158), [endpoint.go:35](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:35). Require it for new-schema records, but do not mistake it for socket authentication. Also fingerprint effective managed-local launch configuration so a live proxy is not silently reused after env/sidecar config changes.

3. `Verify` followed by `os.FindProcess(pid).Kill()` remains a PID-reuse TOCTOU. The process can exit and the PID can be reused between the two calls. The primitive should expose stable-handle signaling where supported—Linux pidfd and a Windows process handle verified with `GetProcessTimes`. Document the residual macOS strategy rather than claiming atomic safety.

4. Linux field 22 alone is reusable across boots. Use a versioned token such as `linux-v1:<boot-id>:<startticks>`, and parse `/proc/<pid>/stat` after its final `)` because `comm` can contain spaces and parentheses.

5. `readAndDial` currently collapses every pidfile error into “not found” via a boolean result: [endpoint.go:305](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:305). Change it to typed status/errors. Malformed JSON, an invalid token, permission failure, dead process, identity mismatch, and unavailable listener require different handling.

6. Do not remove a stale pidfile from `readAndDial`. Discovery runs before proxy-lock acquisition; a stale reader could verify the old record, another process atomically publish a new record, and then the stale reader unlink the new file. Re-read and conditionally quarantine/remove only after acquiring `proxy.lock`: [endpoint.go:117](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:117), [endpoint.go:128](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:128).

7. The lock/PID model is misstated. `proxy-child.lock` is held by the proxy supervisor, while `proxy-child.pid` records the Dolt child: [doltserver.go:221](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:221), [doltserver.go:247](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:247), [doltserver.go:266](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:266), [doltserver.go:278](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:278). Therefore “verified PID is the lock holder” is impossible with this schema.

8. Worse, if the proxy is SIGKILLed, its lock fd closes but Dolt may survive. Cleanup checks the backend pidfile only when the lock is held, so it skips exactly this orphan and may launch a second Dolt. Either make Dolt hold the lock or inspect every verified backend record while exclusively holding `proxy.lock`, regardless of backend-lock state.

9. Keep `kind`, but define typed constants and validate it at every reader. It catches accidental cross-wiring; it is self-asserted metadata, not security identity. Add an explicit schema/token version and validate `pid > 0`, valid port range, role, and nonempty new-schema birth.

### W2 — proxy half sound; backend half requires redesign

Proxy port `0` is the correct solution, and no production consumer needs the port before pidfile publication. But after `net.Listen`, the implementation must store the actual `ln.Addr()` port. Today it writes unchanged `p.port`, which would still be zero: [server.go:136](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/server.go:136), [server.go:158](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/server.go:158). Preserve explicit nonzero proxy-port semantics.

The backend proposal is not implementable at its claimed seam:

- The cited retry scaffold retries `dolt init`, before listener launch; it is unrelated to bind failures: [doltserver.go:178](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:178).

- `NewDoltServer` parses and caches the config once. Rewriting YAML without reparsing leaves DSN/readiness pointed at the old port: [doltserver.go:83](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:83), [doltserver.go:118](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:118).

- `DoltServer` does not know whether the config is Beads-managed. Custom and pre-marker configs are explicitly user-owned and must never be rewritten: [proxied_server.go:270](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/proxied_server.go:270), [proxied_server.go:337](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/proxied_server.go:337).

- Stderr goes to one append-only log and the actual child exit error is discarded after readiness failure. Searching that log can match stale output: [doltserver.go:247](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:247), [doltserver.go:278](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:278), [doltserver.go:283](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:283).

- Raw TCP readiness can false-green against the foreign listener that caused the collision, before the Dolt child’s exit is observed: [doltserver.go:293](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:293), [doltserver.go:393](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:393).

- Retry timing is inconsistent: the parent kills startup after roughly 15 seconds, while one backend readiness attempt allows 30 seconds: [endpoint.go:63](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:63), [endpoint.go:208](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:208), [doltserver.go:293](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver.go:293).

Define a separate managed-config allocator/retry contract, retry only automatic Beads-owned TCP ports, and hard-error on custom/pre-marker/fixed-port collisions.

### W3 — correct policy, incomplete enforcement

Validate the effective `cfg.Host()` for every managed-local configuration, not only `isCustom`. Current paths also accept:

- marker-bearing files whose listener was hand-edited;
- marker parse fallbacks with interpolation;
- pre-marker default-path files treated as unmanaged.

Those paths return without host enforcement at [proxied_server.go:302](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/proxied_server.go:302) and [proxied_server.go:337](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/proxied_server.go:337). Use one shared validator in both runtime config resolution and early init validation at [init.go:331](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/init.go:331).

Recommendations:

- Safest policy is numeric loopback literals using `net.ParseIP(...).IsLoopback()`. Accept `localhost` only if resolver trust is an explicit policy decision; string equality does not guarantee loopback binding.

- Remove `BEADS_PROXIED_SERVER_ALLOW_NONLOCAL`. Managed mode hardcodes root with an empty password because it assumes loopback; an env bypass creates unauthenticated network exposure: [uow_factory.go:124](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/uow_factory.go:124).

- Fix remediation text. `--server-*` is mutually exclusive with proxied mode. The correct surface is `--proxied-server-external-host/port/socket`, or switching entirely to non-proxied server mode: [init.go:322](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/init.go:322), [init.go:384](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/cmd/bd/init.go:384).

### W4 — good start, insufficient adversarial coverage

Add these required cases:

- Valid birth token for an unrelated live PID plus a foreign listener. The proposed wrong-birth test cannot expose W1’s process/socket gap.

- A helper holding `proxy-child.lock` and a separate unrelated process in the pidfile. A plain sleep process does not enter the dangerous kill branch.

- Proxy crash after backend pidfile publication, proving an orphan Dolt is detected even though the backend lock becomes free.

- Real N-process `bd` startup against one idle/missing-config root; all callers converge on one proxy/backend and consistent pidfiles/config. Existing concurrency tests only exercise direct server lock contention: [proxy/server_test.go:571](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/server_test.go:571), [doltserver_test.go:396](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/server/doltserver_test.go:396).

- Concurrent start versus `bd dolt stop`. The parent currently releases `proxy.lock` before `cmd.Start`; stop can observe a free lock, return success, and the delayed child start afterward: [endpoint.go:273](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/endpoint.go:273), [shutdown.go:61](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/shutdown.go:61).

- Port-zero unit test proving the published port is nonzero and dialable.

- Backend collision tests for managed automatic config versus custom/pre-marker/fixed config, and a real SQL operation after startup—not merely TCP readiness.

- All listener paths: env custom, sidecar custom, pre-marker default, marker hand-edit, interpolation, omitted host, IPv4/IPv6 loopback, wildcard, nonlocal address, and live config switching.

- Malformed/truncated JSON, invalid PID/port/kind/token, capture failure, temp-file debris, Linux zombie/reaped child, upgrade, and downgrade.

Pidfile writes already use temp-file, fsync, and rename, so ordinary readers should not observe torn JSON: [pidfile.go:38](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/pidfile/pidfile.go:38), [atomicfile.go:66](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/atomicfile/atomicfile.go:66). However, the parent directory is not fsynced, crashes can leave temp debris, and corrupt/manual files still need fail-closed behavior.

## Open-question recommendations

1. Legacy grace: fail closed by default. “One upgrade cycle” is unbounded because a live legacy proxy is adopted repeatedly and never respawns. If its lock is free, remove under lock and respawn. If held, wait for idle exit or return actionable instructions. If compatibility absolutely requires insecure adoption, put it behind a loudly logged, temporary opt-in.

2. Kill refusal: error is correct. Do not provide a normal `--force` that kills an unverified PID, and do not delete the only forensic/recovery record. A dedicated operator recovery command may quarantine metadata, but force cannot make signaling safe.

3. Proxy port zero: proceed. No pre-write consumer was found. Publish `ln.Addr()`’s actual port and retain explicit nonzero-port behavior.

4. `kind`: keep it as typed, validated defense-in-depth, preferably alongside schema version. It prevents accidental cross-wiring only.

5. Handshake: PID+birth is insufficient for D1. Require a workspace-scoped control handshake or socket-owner verification if the PR claims “verified adoption.” Otherwise narrow the claim to stale-PID mitigation.

## PR strategy

The proposed two PRs are not right as written. PR-B combines a small proxy fix, a policy check, and a materially harder managed-config relaunch protocol. The branches are also not truly independent because both modify `endpoint.go`, proxy pidfile publication, and lifecycle tests.

Recommended sequence:

1. PR-A: complete identity/adoption/cleanup hardening, including handshake or socket association, typed errors, safe signaling, lock/orphan fixes, and concurrency tests.
2. PR-B: proxy port zero plus comprehensive managed-listener enforcement.
3. PR-C/RFC: backend automatic-port reallocation, config serialization/ownership, launch classification, and end-to-end contention tests.

If upstream insists on two PRs, defer backend-port retry rather than hiding it inside PR-B.

## Storage-driver boundary

Process identity, pidfiles, dbproxy locks, proxy bind-to-zero, managed-child lifecycle, and pre-launch listener policy are in scope. The charter explicitly recognizes the proxied-server surface as an allowed exception: [PROJECT_CHARTER.md:44](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/engdocs/PROJECT_CHARTER.md:44), [PROJECT_CHARTER.md:59](/var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/engdocs/PROJECT_CHARTER.md:59).

The genuine boundary conflict is the instruction to extend the Dolt-init storage-error substring retry or drive recovery through Dolt-specific append-log scraping. Keep listener collision handling as a separate, generic managed-process lifecycle retry based on typed child exit/liveness and explicit config ownership. Do not add database-state inspection, repair, or storage-format recovery.