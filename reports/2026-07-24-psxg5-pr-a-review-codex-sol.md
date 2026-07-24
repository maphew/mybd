# PR-A adversarial review — codex gpt-5.6-sol/high (codex review --base upstream/main), 2026-07-24

The patch can terminate a proxy belonging to another copied workspace and has broken process-exit handling on macOS. It also misreports successful fallback kills and leaves the new control credential behind during migration cleanup.

Full review comments:

- [P1] Verify the proxy root before terminating it — /var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/shutdown.go:38-40
  When a workspace directory or its control files are copied while the source proxy is still running, the copied workspace has a free lock but a valid PID/birth token for the source process. Passing `false` here skips the only workspace binding, so `Shutdown` can kill the proxy belonging to the original workspace; the backend path correctly enables this check. Verify `RootID` for proxy records as well.

- [P1] Recognize wrapped ESRCH on Darwin — /var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/procid/procid_darwin.go:31-36
  On macOS, `Capture` wraps the `SysctlKinfoProc` error with `%w`, so direct equality with `unix.ESRCH` never succeeds. After a recorded process exits, `Verify` therefore returns an error instead of `(false, nil)`, causing stale-record discovery and shutdown exit confirmation to fail; the new exited-child test also fails on the macOS test matrix. Use `errors.Is` here.

- [P2] Accept target exit after fallback signaling — /var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/procid/procid_darwin.go:67-72
  On macOS, and on Linux when pidfds are unavailable, a process can exit normally between `syscall.Kill` and this post-signal verification—especially after `SIGKILL`. That produces `match == false` and reports a failed kill even though the requested process was successfully terminated, causing shutdown to return early and leave its pidfile behind. The fallback needs to distinguish the expected gone-process outcome from an actual signaling failure.

- [P2] Purge the newly added proxy secret — /var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/shutdown.go:75-83
  When migrating away from proxied-server mode, this list drives both the dry-run output and `PurgeControlFiles`, but it omits the newly created `proxy.secret`. Consequently migration reports that control files were removed while leaving the authentication credential behind indefinitely. Include `identity.SecretFileName` in this enumeration.
The patch can terminate a proxy belonging to another copied workspace and has broken process-exit handling on macOS. It also misreports successful fallback kills and leaves the new control credential behind during migration cleanup.

Full review comments:

- [P1] Verify the proxy root before terminating it — /var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/shutdown.go:38-40
  When a workspace directory or its control files are copied while the source proxy is still running, the copied workspace has a free lock but a valid PID/birth token for the source process. Passing `false` here skips the only workspace binding, so `Shutdown` can kill the proxy belonging to the original workspace; the backend path correctly enables this check. Verify `RootID` for proxy records as well.

- [P1] Recognize wrapped ESRCH on Darwin — /var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/procid/procid_darwin.go:31-36
  On macOS, `Capture` wraps the `SysctlKinfoProc` error with `%w`, so direct equality with `unix.ESRCH` never succeeds. After a recorded process exits, `Verify` therefore returns an error instead of `(false, nil)`, causing stale-record discovery and shutdown exit confirmation to fail; the new exited-child test also fails on the macOS test matrix. Use `errors.Is` here.

- [P2] Accept target exit after fallback signaling — /var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/procid/procid_darwin.go:67-72
  On macOS, and on Linux when pidfds are unavailable, a process can exit normally between `syscall.Kill` and this post-signal verification—especially after `SIGKILL`. That produces `match == false` and reports a failed kill even though the requested process was successfully terminated, causing shutdown to return early and leave its pidfile behind. The fallback needs to distinguish the expected gone-process outcome from an actual signaling failure.

- [P2] Purge the newly added proxy secret — /var/home/matt/dev/mybd/.worktrees/beads/psxg5-proxy-identity/internal/storage/dbproxy/proxy/shutdown.go:75-83
  When migrating away from proxied-server mode, this list drives both the dry-run output and `PurgeControlFiles`, but it omits the newly created `proxy.secret`. Consequently migration reports that control files were removed while leaving the authentication credential behind indefinitely. Include `identity.SecretFileName` in this enumeration.
