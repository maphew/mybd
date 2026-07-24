# PR-A adversarial review — Claude opus reviewer agent, 2026-07-24

Diff reviewed: feat/psxg5-proxy-identity 9f45ea0e4 / afe9954ec / 7151238be vs upstream/main.
Verdict: core redesign sound (typed statuses, no pre-lock pidfile mutation, handle-only
kills, quarantine-not-delete all correct on the Linux happy path; tests unusually thorough).
Defects cluster in (a) non-Linux procid implementations, (b) "unverifiable ⇒ refuse forever"
paths that removed the old code's self-healing without an operator recovery.

Condensed findings (full text in session transcript; fixes tracked in
scratchpad psxg5-spec-A3b.md → commit on this branch):

Critical
1. procid_darwin: `err == unix.ESRCH` never true (error is %w-wrapped); plus macOS
   SysctlKinfoProc maps missing-pid to EIO/zero-len, not ESRCH → dead process becomes error;
   stale pidfile permanently wedges every bd command on darwin; IsProcessGone also wrong.
2. Fallback kill (darwin always; linux when pidfd unavailable): post-signal re-verify treats
   gone-after-fatal-signal as FAILURE → bd dolt stop reports error after successful kill,
   leaves record; orphan cleanup refuses spawn (D5 fix inert on macOS). Untested fallback.
3. shutdown.go stopAndAcquire(proxy record, verifyRoot=false): copied-workspace can kill the
   ORIGINAL workspace's proxy — only kill path missing the root check (matches codex P1).

Major
4. unverifiableProcessError never quarantines → permanent wedges: (a) legacy record after
   crash+upgrade blocks every spawn; (b) post-reboot birth-mismatch (boot_id changed) treated
   as unverifiable-LIVE though mismatch proves the recorded process exited — readAndDial
   already classifies same evidence as StaleDead; (c) copied workspace. Message text wrong
   ("live process") and names no file to move aside.
5. Any procid.Verify error → adoptionIOErr → fatal BEFORE lock probe: darwin (finding 1) and
   Windows ERROR_ACCESS_DENIED on recycled pid (DACL-protected process) wedge the workspace.
   Should map to non-adopting status → quarantineForSpawn (still fail-closed: quarantine
   requires free proxy.lock, kills nothing).
6. FAIL-OPEN: procid_linux Capture reads boot_id first; ENOENT/EACCES on that read matches
   isGone → Verify says "dead" for every LIVE process → orphan cleanup quarantines a live
   Dolt's record and boots a second dolt sql-server on the same root. Only fail-open in diff.
7. No stop path for a live pre-upgrade proxy: new bd refuses legacy records, old binary is
   overwritten; with idle-timeout 0 workspace wedged until manual kill. Needs narrow
   `bd dolt stop --force` (verify executable identity) or doctor fixer + release note.
   Rated the most likely upstream bounce reason.

Minor (selected): control reply unauthenticated (nonce+HMAC cheap; use ConstantTimeCompare
for secret check); accept-loop busy-spins on persistent accept error (EMFILE) unlike data
loop's fail-fast; post-kill wait can inherit zero deadline budget → false timeout;
spawn-marker not cleared via defer on kill-failure path; stop epoch not passed to child
(cold-start stop races 30s backend wait); ID(ctx) called twice → pidfile/handshake
upstream_id can diverge and forever block adoption; ControlFilePaths omits proxy.secret
(matches codex P2) and .stale-* files; sleep-based tests lack !windows constraint;
darwin case-insensitive path → RootID differs by invocation casing (comment);
missing edge tests: legacy backend record, birth-mismatch backend, foreign-root shutdown,
fallback-signal path, zombie child, N-process convergence.

PR-framing note: the surprising behavior change for existing users is discovery/cleanup
going from "self-healing, occasionally unsafe" to "refuses, sometimes permanently";
findings 4/5/7 route more states into the (never-kills) quarantine path instead. Call out
in PR body: bd dolt stop can't stop a pre-upgrade proxy; IsRunning now false for
running-but-unverifiable proxy.
