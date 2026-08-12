# Wind-down conversion queue: verified issue drafts (2026-08-12)

Verified against upstream/main 4ad99760b on 2026-08-12 by the
upstream-issue-verify workflow (18 agents). The first five were filed same
day as gastownhall/beads 5689-5693. The seven below are VERIFIED STILL-VALID
but deliberately queued to pace filings (tracked in bead mybd-i921i).
Re-check freshness before filing - main moves fast.

## mybd-vctrh: Formula var validation: absent-var defaults skip enum/pattern checks; mol bond --dry-run validates before resolving extends

**Evidence:** Confirmed on upstream/main@4ad99760b. (1) internal/formula/parser.go:475-479 `ValidateProvidedVars` does `if !provided { continue }`, never running the declared default through `validateVarValue`, while cook.go:728 calls it via the resolved formula after inheritance. (2) mol_bond.go:610-637 `resolveOrDescribe` calls `parser.LoadByName(operand)` (parser.go:308, unresolved) then validates against it directly at line 633, whereas the real path `resolveAndCookFormulaWithVars` (cook.go:707-728) calls `parser.Resolve(f)` before validating. PR #5253's own body confirms both were deliberately deferred and only tracked in the internal mybd tracker, not upstream — no gh issue/PR search turned up existing coverage.

---

Two small validation gaps in the formula var-checking path, both left over from #5253 (which added `ValidateProvidedVars` for pour/wisp/mol bond) as deliberate follow-ups that were never filed here.

## 1. `ValidateProvidedVars` never checks a var's own declared default

`internal/formula/parser.go:472-489`:

```go
func ValidateProvidedVars(formula *Formula, values map[string]string) error {
	var errs []string

	for name, def := range formula.Vars {
		val, provided := values[name]
		if !provided {
			continue
		}

		errs = append(errs, validateVarValue(name, def, val, provided)...)
	}
	...
```

When a var is absent from the caller-supplied `values` map, the loop `continue`s and never calls `validateVarValue` with the var's own `def.Default`. So if a formula author writes:

```toml
[vars.policy]
enum = ["strict", "lax"]
default = "loose"   # typo, not in enum
```

`bd mol pour`/`bd mol wisp`/`bd mol bond` (which route through `ValidateProvidedVars` via `resolveAndCookFormulaWithVars`, cook.go:702-731) will silently apply the invalid default `"loose"` instead of erroring. By contrast, `bd cook --mode=runtime`'s `ValidateVars` (parser.go:441-461) does run defaulted values through `validateVarValue` (`if !provided && def.Default != nil { val = *def.Default }` at parser.go:508-510, upstream of the enum/pattern checks), so the same malformed formula produces inconsistent behavior depending on which command loads it — a silently-applied bad default via pour/wisp vs. a hard rejection via cook.

**Suggested direction:** in `ValidateProvidedVars`, when a var is absent but has a non-nil `Default`, pass that default through `validateVarValue` the same way `ValidateVars` already does, so a formula-authoring mistake surfaces consistently regardless of entry point.

## 2. `mol bond --dry-run` validates vars against the unresolved formula, before `extends` is applied

`cmd/bd/mol_bond.go:610-637` (`resolveOrDescribe`, used by `bd mol bond --dry-run` for both local and proxied-server code paths):

```go
parser := formula.NewParser()
f, err := parser.LoadByName(operand)
if err != nil {
	return nil, "", fmt.Errorf("'%s' not found as issue or formula: %w", operand, err)
}

// A dry-run must fail the same way the real bond would: ...
if err := formula.ValidateProvidedVars(f, vars); err != nil {
	return nil, "", err
}
```

`parser.LoadByName` (parser.go:308-310) just calls `loadFormula`, returning the formula as parsed from its own file — `Vars` contains only the vars declared directly on that formula, not vars merged in from any `extends` parent (merging happens only in `parser.Resolve`, parser.go:198-282, specifically the parent-vars merge loop at parser.go:247-252).

Compare the real (non-dry-run) path, `resolveAndCookFormulaWithVars` (cook.go:702-731), which the comment at line 630 explicitly says dry-run is trying to match:

```go
f, err := parser.LoadByName(formulaName)
...
resolved, err := parser.Resolve(f)   // extends applied here
...
if err := formula.ValidateProvidedVars(resolved, conditionVars); err != nil {
```

So if a formula `child.formula.toml` has `extends = ["parent"]` and `parent.formula.toml` declares `[vars.region] enum = ["us", "eu"]`, then:

- `bd mol bond A B --var region=ap` (real, non-dry-run) resolves `child` against `parent`'s merged vars and correctly rejects `region=ap`.
- `bd mol bond A B --var region=ap --dry-run` validates against the *unresolved* `child` formula, which has no `region` var of its own, so `ValidateProvidedVars` silently finds nothing to check and the dry-run reports success — a false preview for a value the real command would reject.

**Suggested direction:** in `resolveOrDescribe`, call `parser.Resolve(f)` (as `resolveAndCookFormulaWithVars` already does) before running `ValidateProvidedVars`, so the dry-run preview validates against the fully merged var set.

## Context

Both of these were identified during cross-vendor review of #5253 and deliberately deferred out of that PR's scope (see its description) rather than being filed as follow-up issues here.

## mybd-ykaa: TestCLI_CreateRejectsEmptyTitle/FlagTab leaves shared --title cobra flag dirty for later in-process tests

**Evidence:** cmd/bd/cli_fast_test.go@upstream/main(4ad99760b): TestCLI_CreateRejectsEmptyTitle FlagTab subtest (L1868-1885) calls runBDInProcessAllowError→rootCmd.Execute() with --title \t against shared package-level createCmd, no t.Cleanup/flag reset. TestCLI_CreateRejectsEmptyTitle_ProxiedServerMode (L1903-1925) explicitly works around it, commenting it's 'a pre-existing gap.' No matching gh issue/PR found.

---

## What

In `cmd/bd/cli_fast_test.go`, `TestCLI_CreateRejectsEmptyTitle`'s `FlagTab` subtest (around line 1868) runs:

```go
{"FlagTab", []string{"create", "--title", "\t", "-p", "2"}},
```

via `runBDInProcessAllowError`, which calls `rootCmd.SetArgs(args); rootCmd.Execute()` in-process against the shared package-level `createCmd` (`cmd/bd/cli_fast_test.go:1201-1250`, `runBDInProcessAllowError`). That helper resets several package globals after execution (`store`, `dbPath`, `actor`, `jsonOutput`, `sandboxMode`, `rootCtx`, `rootCancel`) but never resets the cobra flag state on `createCmd` itself. So after `FlagTab` runs, `createCmd`'s `--title` flag is left with `Value == "\t"` and `Changed == true` on the `*cobra.Command`'s `FlagSet`.

Because `createCmd` is a shared, package-level `*cobra.Command` (not reconstructed per test), that dirty flag state persists across subsequent in-process `rootCmd.Execute()` calls within the same test binary run, i.e. it can leak into any later test in the same package that invokes `create` without itself passing `--title`.

## Where this is already known

`TestCLI_CreateRejectsEmptyTitle_ProxiedServerMode` (`cmd/bd/cli_fast_test.go:1903-1925`) already has to work around exactly this, with an explicit comment:

```go
// createCmd is a shared package-level *cobra.Command, so a --title value
// set by an earlier in-process test invocation (e.g. TestCLI_CreateRejectsEmptyTitle's
// own FlagTab case) survives on the FlagSet across rootCmd.Execute() calls.
// Reset it explicitly so this test's outcome doesn't depend on suite
// ordering — a pre-existing gap, not something this test should also fall
// victim to.
titleFlag := createCmd.Flags().Lookup("title")
origTitleValue := titleFlag.Value.String()
origTitleChanged := titleFlag.Changed
t.Cleanup(func() {
	_ = titleFlag.Value.Set(origTitleValue)
	titleFlag.Changed = origTitleChanged
})
_ = titleFlag.Value.Set("")
titleFlag.Changed = false
```

That workaround only protects `TestCLI_CreateRejectsEmptyTitle_ProxiedServerMode` itself — it doesn't fix the root cause in `FlagTab`, so any *other* current or future in-process test that runs `create` without an explicit `--title` and depends on the flag being unset/empty is still exposed to suite-order-dependent flakiness whenever it runs after `FlagTab` in the same binary.

## Suggested direction

Add the same kind of reset directly at the source (`FlagTab` subtest), e.g. via `t.Cleanup` restoring `createCmd`'s `--title` flag value/`Changed` state after the subtest runs, so the dirty state never escapes the subtest that caused it. Alternatively, `runBDInProcessAllowError`/`runBDInProcess` could reset all changed flags on `rootCmd`'s tree after each in-process execution as a general safeguard, which would remove the need for the per-test workaround in `TestCLI_CreateRejectsEmptyTitle_ProxiedServerMode` too.

## mybd-7qp5: dbproxy control handshake: cleartext secret over TCP loopback + cheap slot-exhaustion DoS

**Evidence:** internal/storage/dbproxy/identity/control.go:57 (upstream/main@4ad99760b) still sends `IDENT `+secret+` `+nonce+`\n` in cleartext. proxy/control.go:42 listens on TCP 127.0.0.1:0 (not a unix socket); maxConcurrentIdentRequests=8 (line 22), identDeadline=2s (line 21) applied via SetDeadline at line 124; full slots reject new conns immediately (lines 110-118) but held slots block for up to 2s. No commits to either file since #5013 introduced this (only a later test-only commit f3eebf1f7). No matching open issue/PR found via 6 keyword searches.

---

## Summary

The dbproxy managed-proxy identity handshake (introduced in #5013) has two related weaknesses in `internal/storage/dbproxy/identity/control.go` and `internal/storage/dbproxy/proxy/control.go`:

1. The client sends the shared secret in cleartext to an as-yet-unauthenticated peer.
2. The control listener is TCP loopback, reachable by any local user on the machine, and its small fixed concurrency limit makes it cheap to exhaust.

## 1. Cleartext secret in the IDENT request

`identity.Identify` (client side) writes the request as:

```go
// internal/storage/dbproxy/identity/control.go:57
if _, err := io.WriteString(conn, "IDENT "+secret+" "+nonce+"\n"); err != nil {
```

The secret is sent as plain text before the peer has proven anything. The *reply* is properly authenticated (`SignIdentReply`/`VerifyIdentReply` HMAC the reply payload with the nonce), so only one direction of the handshake is a real challenge-response. Anyone who can observe or intercept the loopback connection (e.g. another local process, or a proxy that lies about its identity but captures the request) learns the secret outright, rather than only being able to verify a MAC.

A safer client request would send `HMAC(secret, nonce_client)` and let the request itself act as a genuine challenge-response, symmetric with how the reply is already authenticated — the raw secret would then never cross the wire in either direction.

## 2. Local-user DoS via slot exhaustion on the TCP loopback listener

`proxy.startControl` binds a plain TCP loopback listener:

```go
// internal/storage/dbproxy/proxy/control.go:42
ln, err := net.Listen("tcp", "127.0.0.1:0")
```

This is reachable by *any* local user on the machine (loopback TCP has no per-uid access control, unlike a `0600` unix socket). Concurrency is capped by a small fixed pool:

```go
// internal/storage/dbproxy/proxy/control.go:19-25
const (
	maxIdentRequestBytes       = 256
	identDeadline              = 2 * time.Second
	maxConcurrentIdentRequests = 8
	...
)
```

and each accepted connection holds a slot for up to `identDeadline` (2s) before it's read or times out:

```go
// internal/storage/dbproxy/proxy/control.go:122-130
func (s *controlServer) handle(conn net.Conn) {
	defer func() { _ = conn.Close() }()
	if err := conn.SetDeadline(time.Now().Add(identDeadline)); err != nil {
		return
	}
	line, err := bufio.NewReader(io.LimitReader(conn, maxIdentRequestBytes+1)).ReadString('\n')
	...
```

When all 8 slots are occupied, new connections are dropped immediately rather than queued:

```go
// internal/storage/dbproxy/proxy/control.go:110-118
select {
case s.slots <- struct{}{}:
	go func() {
		defer func() { <-s.slots }()
		s.handle(conn)
	}()
default:
	_ = conn.Close()
}
```

**Failure scenario:** a local process (any uid, since it's a loopback TCP port) repeatedly opens 8+ connections to the control port and either sends nothing or sends slowly, holding each slot for up to 2s before the deadline fires. Legitimate `identity.Identify` callers (e.g. during proxy adoption) get their connections rejected outright while slots are full. Depending on the caller's retry/timeout budget, this can manifest as `adoptionIdentityMismatch` or the 15s `openDeadline` failure path, i.e. a cheap, sustained local DoS against proxy adoption using only a handful of TCP connects per 2-second window — no elevated privileges required.

## Suggested direction

- For (1): have the client send `HMAC(secret, nonce_client)` instead of the raw secret, mirroring the existing reply-side authentication in `SignIdentReply`/`VerifyIdentReply`.
- For (2): consider a unix domain socket (mode `0600`) or named pipe instead of TCP loopback, optionally with a `SO_PEERCRED`/peer-uid check, so only the owning user's processes can reach the control listener at all. If TCP loopback must be kept, a sub-second pre-slot read deadline (distinct from the current 2s `identDeadline`) would shrink the DoS window considerably even without eliminating it.

Both issues are present as of `upstream/main` @ `4ad99760b`; the relevant files haven't changed materially since #5013 introduced them (only a later test-only commit touched `control.go`, f3eebf1f7).

## mybd-lfos: Proxied-server port-collision recovery: no re-pick/re-render/relaunch path, and readiness discards the child's real exit error

**Evidence:** cmd/bd/proxied_server.go:119-163 resolveOrCreateProxiedServerConfig bakes proxy.PickFreePort() into YAML once, returns existing/custom paths unmodified (no rewrite path). internal/storage/dbproxy/proxy/endpoint.go:171-176 PickFreePort's own doc comment: 'that race requires the managed-config ownership/retry contract deferred to the PR-C RFC' (written in maphew's PR #5024, matching this bead's split-out). internal/storage/dbproxy/server/doltserver.go:85,110 NewDoltServer parses+caches config once; :254 stderr->logFile only; :311 '_ = s.eg.Wait()' discards child exit error after readiness failure; :40 startReadyTimeout=30s vs endpoint.go:73 openDeadline=15s. No gh issue/PR found covering this RFC.

---

## What

When the beads-managed proxied Dolt server hits a port collision at startup, there is no recovery path — the port is committed to YAML before the child ever binds, and the failure surfaced to the caller is a generic "exited before listener became ready" instead of the real bind error.

## Where (upstream/main @ 4ad99760b)

1. **Port is baked into config before the child ever runs**, with no re-pick/re-render/relaunch on failure. `resolveOrCreateProxiedServerConfig` (cmd/bd/proxied_server.go:119) allocates the port via `proxy.PickFreePort()` (line 148), renders it into YAML (`renderProxiedServerConfig`, line 322), and writes it once. If the config file already exists — whether beads-managed (line 142, `case err == nil: return path, nil`) or user-owned/custom (line 125, `if isCustom { ... return path, nil }`) — it is returned as-is with no re-validation that the port is still free, and no code path rewrites it.

2. **The allocator itself documents the gap.** `proxy.PickFreePort()` (internal/storage/dbproxy/proxy/endpoint.go:171) binds `127.0.0.1:0`, reads back the kernel-assigned port, then closes the listener before the caller uses it — a classic bind-close-rebind race window. Its doc comment at line 175 says explicitly: *"The remaining production caller allocates the Dolt config port; that race requires the managed-config ownership/retry contract deferred to the PR-C RFC."* That comment was added in PR #5024 (race-free proxy port allocation) — the RFC it defers to was never filed.

3. **Config is parsed and cached once, not re-derived on retry.** `NewDoltServer` (internal/storage/dbproxy/server/doltserver.go:63) parses the YAML at line 85 (`servercfg.YamlConfigFromFile`) and stores it in `s.config` (line 110); every later use of the port (Dial, pidfile.Write) reads this cached value. There is no seam for "pick a different port and retry" without constructing a whole new `DoltServer` against a rewritten config file — which conflicts with point 1 for custom/pre-existing configs.

4. **On a bind failure, the real error is thrown away.** `Start()` spawns the child with `cmd.Stderr = s.logFile` (line 254, append-only log — not surfaced to the caller). If the child exits early (e.g. `EADDRINUSE`), `waitReady` (line 319) only observes that `s.egCtx.Err() != nil` and returns the generic `"dolt sql-server exited before listener became ready"`. Immediately after, `Start()` calls `_ = s.eg.Wait()` (line 311) — the goroutine wrapping `cmd.Wait()` — and discards its return value, so the actual `*exec.ExitError` / bind error from the dolt process is never propagated to the caller or included in the returned error.

5. **Readiness itself is a raw TCP dial, not an identity check.** `waitReady` calls `s.Dial(ctx)` which does a plain `net.Dialer.DialContext("tcp", host:port)`. If some other process is listening on that exact port at readiness-check time (the very collision this recovery would need to handle), the dial can succeed against that foreign listener, reporting "ready" when in fact the intended dolt server never bound.

6. **Retry/timeout constants disagree between the parent and child sides of the same operation.** The parent-side readiness poll in `proxy` uses `openDeadline = 15 * time.Second` (endpoint.go:73), while the child-side dolt-server readiness wait uses `startReadyTimeout = 30 * time.Second` (server/doltserver.go:40) — two different budgets governing what is conceptually the same "is the backend up yet" wait.

## Concrete failure scenario

Two `bd` processes (or two projects on one machine) race `PickFreePort()` in the window between `Close()`-ing the probe listener and the dolt `sql-server` child actually binding that port. One child wins the bind; the other's `sql-server` exits immediately with a bind error. The caller sees only `"server: DoltServer.Start: dolt sql-server exited before listener became ready"` — no indication it was a port collision, no automatic re-pick, and no way to retry without manually deleting the rendered config (which is exactly the operation forbidden for a config that might be user-customized).

## Suggested direction (not prescriptive)

- A launch-classification split: configs beads created and owns (safe to re-pick + rewrite + relaunch on collision) vs. custom/user-supplied configs (hard error naming the conflicting port, never silently rewritten).
- Typed detection of the child's actual exit condition (parse/tag a bind-failure exit distinctly from other early exits) instead of discarding `s.eg.Wait()`'s result.
- A readiness check that verifies server identity, not just "something answered on this port" (e.g. probe a value only this server instance would return, akin to what PR #5630's MySQL-greeting-drain groundwork already touches).
- Reconciling `openDeadline` (endpoint.go) and `startReadyTimeout` (server/doltserver.go) to a single source of truth, or documenting why they differ.

Coordinating with whoever picks this up: it was intentionally deferred out of #5024 as future RFC work, so the port-allocator/readiness code paths above are the right starting point.

## mybd-43lf: Pre-0059-cursor databases with dolt#11131 encoding drift have no upgrade path and no diagnosis - panic surfaces raw, not as an actionable error

**Evidence:** Verified live on upstream/main@4ad99760b (fetched today): dolt pin (go.mod: dolthub/dolt/go v0.40.5-0.20260715172757-a6690826d767) is past dolt#11126 (2.1.0, write-path fix). internal/storage/schema/aux_row_id_backfill.go on main has NO drift handling (353 lines; no isSchemaEncodingDriftErr, no aux_row_rekey_drifted) - the fix (commit 9a3aa99f1/564049bb8) lives only on unmerged branches (our fork's origin/fix/aux-rekey-encoding-drift = open PR gastownhall/beads#5064, and upstream/hotfix/v1.1.1). gh issue view 4380 (OPEN) documents: (a) #5064 fixes only the v53 aux re-key path; (b) marcodelpin's 2026-08-12 validation run showed pre-0059-cursor drifted DBs still panic identically with or without #5064, inside migration 0059's INSERT..SELECT body (internal/storage/schema/migrations/0059_recompute_null_gate_is_blocked.up.sql, lines 73/78) before the guarded pass is ever reached; (c) "bd doctor answers 'not yet supported in embedded mode'" - doctor cannot even run on affected DBs; (d) maphew and marcodelpin explicitly agreed in-thread (last comment, same day) to file this exact follow-up ("detect and refuse clearly... file the pre-0059-cursor path as its own issue") but no such issue exists yet - searched multiple keyword sets (dolt#11131, schema-encoding-drift, recover-rows, clear-refusal encoding, 0059 cursor, doctor recovery/corruption) across gh issue/pr list, only #4380/#5064 (narrower scope) and unrelated results returned.

---

## Problem

Databases carrying dolthub/dolt#11131-class storage drift (TEXT/LONGTEXT columns written under a pre-2.1 Dolt, now undecodable) have **no working upgrade path** if their schema cursor predates migration 0059, and no diagnostic tells the operator what's wrong.

This is a known follow-up gap from #4380 / #5064, not a duplicate of either:

- #5064 (open PR, `fix/aux-rekey-encoding-drift`) makes the v53 aux row re-key (`internal/storage/schema/aux_row_id_backfill.go`) skip-and-warn on a drifted table instead of aborting. That guard only helps once a database's migration cursor is *already past* migration 0059.
- For a cursor still below 0059 (v1.1.0-era databases - exactly the ones still stuck on this bug), migration 0059's own `INSERT ... SELECT` bodies (`internal/storage/schema/migrations/0059_recompute_null_gate_is_blocked.up.sql`, lines 73 and 78) read the drifted table *before* the v53 guard is ever reached, and the process panics identically with or without #5064:

  ```
  schema.execMigrationBody
    -> rowexec.(*insertIter) over kvexec.(*mergeJoinKvIter)
    -> prolly/tree.GetField -> val.AdaptiveValue.convertToTextStorage -> hash.New
  panic: invalid hash length: 19
  ```

  (validation run posted in gastownhall/beads#4380, 2026-08-12, by @marcodelpin against a real drifted fixture: stock `main`@0498b22a7 and `fix/aux-rekey-encoding-drift`@9a3aa99f1 both exit 2 with this panic.)

Two compounding issues make this worse than a normal migration bug:

1. **The panic reaches every `bd` start, not only `bd migrate`.** Auto-migrate on open dies the same way, so even `bd sql` on an affected database panics before any command can run.
2. **`bd doctor` cannot diagnose it.** Per the same thread, `bd doctor` currently answers "not yet supported in embedded mode" - the mode these reports came from - so there is no diagnostic transcript an operator or agent can produce, only the raw panic.

Unlike the v53 aux re-key (a reconstructible pass - skip a row, warn, retry later), migration 0059 is a semantic recompute (`is_blocked`). Skip-and-continue is not safe there: silently skipping a drifted row mid-`INSERT...SELECT` would leave `is_blocked` wrong for an unknown subset of rows inside a half-applied migration - a correctness regression with a green exit code.

## Suggested direction

The thread (gastownhall/beads#4380, closing comments) converged on: **detect the drift panic at the migration-body boundary and refuse clearly**, rather than skip-and-continue, since 0059-class migrations can't safely recover the way the v53 re-key can:

- Classify the `invalid hash length` panic (both the `: 19` on-read and `: 1` on-insert/merge forms - see migration 0057's comment for why both matter) at whatever call boundary wraps migration-body execution, not just inside the v53 re-key.
- On a match, exit with an actionable message identifying the affected table(s) and pointing at this class of issue, instead of a raw Go panic from Dolt internals.
- Surface known recovery routes rather than leaving the operator to search issue comments: Dolt's own `schema-encoding-drift recover-rows` tool (dolthub/dolt#11133, unreleased - branch `zachmu/schema-repair-tool` only, verified end-to-end by @marcodelpin in #4380), and the stock-Dolt history-rebuild recipe (@albority, #4380: bisect `SELECT ... AS OF 'HEAD~N'` per drifted row to find its last readable version, `dolt checkout <commit> -- <table>` to restore the table root without re-serializing, then replay current rows on top) - both already worked for real users with zero data loss but exist only as issue-comment prose today.
- Separately, `bd doctor` in embedded mode currently can't even attempt this diagnosis ("not yet supported in embedded mode") - closing that gap would let the refusal path (or an eventual doctor check) actually reach affected users, most of whom are on embedded single-user setups per the reports in #4380.

Not prescribing an auto-`--fix`: the affected rows are typically physically unrepairable via SQL (`UPDATE`/`DELETE` of a drifted row panics the same way), so recovery is inherently an operator-supervised, out-of-band step regardless of how it's surfaced.</issue_body_md>


## mybd-o4u1w: bd -C to a non-git .beads project silently uses the caller's repo root instead of the -C target's

**Evidence:** upstream/main@4ad99760b internal/beads/context.go:118-135 buildRepoContext(): isExternal starts as redirectInfo.IsRedirected(false); isExternalBeadsDir(beadsDir) at line 157 errors when beadsDir has no enclosing git repo (getGitCommonDirForPath runs `git -C beadsDir rev-parse --git-common-dir`, fails); on err!=nil isExternal is left false (line 122-125 `if err==nil{isExternal=external}`), so code falls into the else branch and calls git.GetMainRepoRoot() (line 134), which shells out without -C and resolves the actual process CWD (caller), not beadsDir. cmd/bd/main.go:793 resolveChangeDirBeadsDir only requires FindBeadsDirFrom!="" (a .beads dir), no git check; applyChangeDirSelection (line 813) sets BEADS_DIR env only, no os.Chdir. Confirmed PR 4340/4792 (searched via gh) fix a different case (CWD itself non-git, GetMainRepoRoot errors) and don't touch this silent-wrong-branch path; PR 4340's own regression test chdirs directly into the non-git scope, never exercising CWD-in-repo-A + BEADS_DIR-pointing-to-non-git-dir-B.

---

## Summary

When `bd -C <target>` points at a `.beads` project that is *not* inside any git repository, `RepoContext.RepoRoot` silently resolves to the **caller's** git repo root instead of the target directory (or an explicit fallback/error). This is silent, not a crash — the wrong repo root is used for every git-repo-scoped decision (role detection, config lookups, path-relative operations) downstream of `GetRepoContext()`.

## Where

`internal/beads/context.go`, `buildRepoContext()` (as of `upstream/main` `4ad99760b`):

```go
// internal/beads/context.go:118-135
var repoRoot string
isExternal := redirectInfo.IsRedirected
if !isExternal {
    if external, err := isExternalBeadsDir(beadsDir); err == nil {
        isExternal = external
    }
}

if isExternal {
    // Beads dir is in a different repo - use that repo's root
    repoRoot = repoRootForBeadsDir(beadsDir)
} else {
    // Normal case - find repo root via git
    var err error
    repoRoot, err = git.GetMainRepoRoot()
    if err != nil {
        return nil, fmt.Errorf("cannot determine repository root: %w", err)
    }
}
```

`isExternalBeadsDir` (line 157) determines external-ness with:

```go
func isExternalBeadsDir(beadsDir string) (bool, error) {
    cwdCommonDir, err := git.GetGitCommonDir()   // caller's git common dir
    if err != nil { return false, err }
    beadsCommonDir, err := getGitCommonDirForPath(beadsDir) // `git -C beadsDir rev-parse --git-common-dir`
    if err != nil { return false, err }             // <-- errors when beadsDir has no enclosing git repo
    return cwdCommonDir != beadsCommonDir, nil
}
```

When `beadsDir` (the `-C` target's `.beads`) has no enclosing git repo, `getGitCommonDirForPath` errors, so `isExternalBeadsDir` returns `(false, err)`. Back in `buildRepoContext`, the `err == nil` guard means `isExternal` is left at its prior value (`redirectInfo.IsRedirected`, false here since no redirect file exists). Execution falls into the `else` branch and calls `git.GetMainRepoRoot()`.

Critically, `GetMainRepoRoot()` (`internal/git/gitdir.go:212`, via `initGitContext()` at line 30) shells out to `git rev-parse --git-dir --git-common-dir --show-toplevel` **without `-C`**, so it resolves against the process's actual working directory — the caller's location — not the `-C` target. And `-C` itself never `os.Chdir`s: `applyChangeDirSelection()` (`cmd/bd/main.go:813-826`) only sets the `BEADS_DIR` env var. `resolveChangeDirBeadsDir()` (`cmd/bd/main.go:793`) only requires `beads.FindBeadsDirFrom(absPath) != ""` — a discoverable `.beads`, not a git repo — so this path is reachable for any non-git beads project.

## Repro scenario

1. `caller-repo/` is a git repository (any repo).
2. `target-scope/` has a valid `.beads/` directory but is **not** itself a git repository and has no `.beads/redirect` file (e.g. a plain data/HQ scope backed by dolt-server).
3. From inside `caller-repo/`, run `bd -C target-scope <any command that reads RepoContext>` (e.g. `bd -C target-scope context`).

Expected: `RepoRoot` reflects `target-scope` (or the operation degrades gracefully / errors clearly that no git root exists for the target).

Actual: `RepoRoot` silently becomes `caller-repo`'s root, because `isExternalBeadsDir` returned an error (not `true`) and the normal-case branch resolved git context from the real CWD.

## Suggested direction

`repoRootForBeadsDir(beadsDir)` (context.go:199) already exists and does exactly the right thing for this case — it tries `getRepoRootFromPath(beadsDir)` and falls back to `filepath.Dir(beadsDir)` when `beadsDir` has no git root of its own. It's already used on the `isExternal == true` path. The gap is only that `isExternalBeadsDir` erroring (because the *target* has no git repo, as opposed to some other failure) never routes into that branch — it's swallowed by the `err == nil` guard and silently treated as "not external."

One direction: when `getGitCommonDirForPath(beadsDir)` fails specifically because `beadsDir` isn't in a git repo, treat that as external (route to `repoRootForBeadsDir(beadsDir)`) rather than as "same repo as caller." The existing fallback machinery does not need to change — only which branch reaches it.

Note for scope: two related fixes already touch this function (PR #4792, and closed PR #4340) but both address a *different* failure mode — CWD itself being non-git, where `git.GetMainRepoRoot()` errors outright and the command fails loudly. Neither exercises (nor fixes) the case here, where the caller **is** in a git repo and the wrong repo root is returned silently rather than an error being raised. PR #4340's own regression test `chdir`s directly into the non-git scope and never sets up a caller-repo/target-scope split, so it doesn't cover this path.


## mybd-zz04j: Stale comment in workspace_gate_test.go still documents the pre-#5204 rootCtx leak as current production behavior

**Evidence:** cmd/bd/workspace_gate_test.go:158-166 on upstream/main (4ad99760b) still says PersistentPostRunE cancels rootCancel() 'WITHOUT resetting the var to nil'. But main.go:1712-1730 (from merged PR #5204) shows PersistentPostRunE's deferred hook now calls setRootContext(nil,nil), clearing both globals. git log on the test file shows no commits since #5093 (which added the comment); #5204 didn't touch it. No open issue/PR found covering this specific stale-comment cleanup.

---

## What

The comment block above `oldRootCtx := rootCtx` in `TestChokepointSharedExcludesMigrateExclusive` (`cmd/bd/workspace_gate_test.go:158-166`, current `main` at `4ad99760b`) reads:

```go
	// rootCtx is a package global that production sets via
	// setupGracefulShutdown() in PersistentPreRunE and cancels via
	// rootCancel() in PersistentPostRunE WITHOUT resetting the var to nil —
	// harmless in production (the process exits), but any earlier in-process
	// test that exercises the full command path (Execute()) leaves rootCtx
	// pointing at an already-canceled context for whatever test runs next in
	// the same binary. acquireMigrateGates now threads rootCtx through to
	// acquireExclusiveWorkspaceGates, so this test is sensitive to that
	// leak: pin it to nil (the documented "no process signal context yet"
	// case this test exercises) regardless of what ran before it.
```

This describes a real bug that existed when the comment was written (alongside PR #5093), but PR #5204 (merged) fixed it: `PersistentPostRunE` in `cmd/bd/main.go` (currently around line 1725) now registers a deferred hook — first, so it runs last — that calls `rootCancel()` and then `setRootContext(nil, nil)`, clearing both `rootCtx` and `rootCancel` back to nil rather than leaving `rootCtx` pointing at a canceled context. `root_context_lifecycle_test.go` (added in the same PR) pins this contract directly.

`workspace_gate_test.go` itself was not touched by #5204, so its comment is now factually wrong about current behavior: the leak it describes as "harmless in production" but dangerous for in-process test reuse no longer exists — teardown clears the global precisely to prevent that.

## Why it matters

This test (`TestChokepointSharedExcludesMigrateExclusive`) is one of the more likely places a future contributor lands when debugging something context-shaped in `cmd/bd`. The comment currently asserts, as present tense, that a leak exists which was fixed months earlier — a reader who trusts it may spend time defending against a problem that no longer exists, or miss that the real invariant is now enforced by teardown rather than by this test's manual pin.

The `rootCtx = nil` pin itself is still worth keeping — it's what this test needs regardless of teardown behavior (it exercises the "no process signal context yet" path) — but the comment explaining *why* is stale.

## Suggested direction

Update the comment to describe the current (post-#5204) lifecycle instead of the pre-fix one, e.g. something along these lines (exact wording at maintainer discretion):

```go
	// rootCtx is a package global that production sets via
	// setupGracefulShutdown() in PersistentPreRunE and tears down in
	// PersistentPostRunE. The teardown clears the var precisely so an
	// earlier in-process command cannot hand this test a canceled context
	// (see root_context_lifecycle_test.go). Pin it to nil anyway: this
	// test's subject is the "no process signal context yet" case, and it
	// should assert that regardless of how teardown is implemented.
```

No behavior change needed — comment-only.

---

# Batch 2: proxied-campaign (mybd-psxg) handoff drafts

Added 2026-08-12, same session as the psxg finish-locally-vs-handoff decision
(verdict: hand off). Verified against upstream/main 4ad99760b by a 4-agent
workflow. These four upgrade psxg.3 / nsg1 / 5zvr from the unverified-medium
queue and add the psxg.4-part-2 follow-up as a new item. Re-check freshness
before filing — in particular, PR 5092's merge state gates the psxg.4-part-2
draft's framing.

## mybd-psxg.3: docs/cli-docs.pin stuck at v1.1.0 (2 releases stale); doctor gitignore template still writes .beads/proxieddb/

**Evidence:** Confirmed at upstream/main@4ad99760b, 2026-08-12. The live help text is FIXED on main (cmd/bd/init.go:2329-2333 says `.beads/dolt`; fix landed between v1.1.2 and v1.2.0), so the original bead claim is half-resolved. Two residual gaps: (1) committed generated docs still say proxieddb — docs/CLI_REFERENCE.md:3438,3448,3449 and docs/cli-reference/init.md:66,76,77 — because docs/cli-docs.pin pins doc generation to tag v1.1.0 and was never bumped across v1.1.1→v1.2.1 despite its own header saying "Bump this tag as part of each release" (git log shows only the introducing commit d2f87d50d). (2) cmd/bd/doctor/gitignore.go:101 `ProjectGitignorePatterns` — written into user projects' root .gitignore by `bd init` and `bd doctor --fix` (wired via cmd/bd/init.go:1112, cmd/bd/doctor_fix.go:279, cmd/bd/init_stealth.go:181,268) — still lists `.beads/proxieddb/` with no `.beads/dolt/` entry. Mitigating: the nested `.beads/.gitignore` template (gitignore.go:12, bare `dolt/`) independently covers the data dir, so severity is defense-in-depth, not active leak. **Overlap:** open issue gastownhall/beads#5103 (hamchowderr, 2026-07-28) covers the help-text half, which is now fixed on main; it mentions neither the stale docs pin nor the doctor gitignore template. File this as a NARROW new issue cross-referencing #5103 as prior art; optionally leave a courtesy comment on #5103 noting the help-text half is fixed as of v1.2.0.

---

`bd init --help` was fixed between v1.1.2 and v1.2.0 to document the proxied-server data root as `.beads/dolt` (the actual implementation root) — resolving the live-help half of #5103. Two smaller pieces of the same rename are still stale on main:

### 1. Committed generated CLI docs still say `proxieddb` because `docs/cli-docs.pin` is two releases stale

`docs/CLI_REFERENCE.md` (lines 3438, 3448, 3449) and `docs/cli-reference/init.md` (lines 66, 76, 77) still describe `--proxied-server`, `--proxied-server-log-path`, and `--proxied-server-root-path` as rooted at `.beads/proxieddb`.

The generator isn't broken — `docs/cli-docs.pin` pins doc generation to release tag `v1.1.0`, whose `cmd/bd/init.go` genuinely said proxieddb. The pin file's own header says "Bump this tag as part of each release, then run ./scripts/generate-cli-docs.sh", but `git log --oneline -- docs/cli-docs.pin` shows only the commit that introduced the pinning scheme (d2f87d50d); it was never bumped through v1.1.1, v1.1.2, v1.2.0, or v1.2.1. The committed reference docs are two minor releases behind the pin file's own stated policy.

**Fix shape:** bump `docs/cli-docs.pin` to the current release tag and re-run `scripts/generate-cli-docs.sh` (regenerates docs/CLI_REFERENCE.md, docs/cli-reference/*, docs/docs.json). Consider wiring the script's existing `--check` mode into the release checklist or CI so a missed bump fails visibly instead of silently shipping stale docs.

### 2. Doctor's root-.gitignore template still writes the obsolete `.beads/proxieddb/` pattern

`cmd/bd/doctor/gitignore.go:97-104` `ProjectGitignorePatterns` — the patterns `bd init` and `bd doctor --fix` write into a user project's **root** `.gitignore` — still lists `.beads/proxieddb/` (line 101) and has no `.beads/dolt/` entry. This is live code, not generated docs: wired through `cmd/bd/init.go:1112`, `cmd/bd/doctor_fix.go:279`, `cmd/bd/init_stealth.go:181,268`.

Practical severity is low because the nested `.beads/.gitignore` template (`GitignoreTemplate`, gitignore.go:12, bare `dolt/` pattern) independently covers the data dir. But the root-gitignore layer exists precisely as defense-in-depth against committing Dolt database files, and today it defends a directory name that no longer exists. Suggest replacing with `.beads/dolt/` (optionally keeping `.beads/proxieddb/` for repos that predate the rename). The repo's own top-level `.gitignore:140` has the same stale pattern, cosmetically.

Related: #5103 reported the help-text half of this rename drift; that half is fixed on main as of v1.2.0 — this issue covers the two remaining pieces #5103 doesn't mention.

## mybd-psxg.4 (part 2): dolt CLI executable contract, part 2 — identity threading, capability registry, doctor check, packaging (stacks on #5092)

**Evidence:** Confirmed at upstream/main@4ad99760b, 2026-08-12. internal/doltversion does not exist on main yet (PR 5092 unmerged: OPEN, mergeable, ~104 checks green, steveyegge MERGE-AFTER-FIXES 08-10 with all 3 should-fixes addressed by 08-12 pushes, awaiting re-review). Bare `exec.LookPath("dolt")` persists at internal/doltserver/doltserver.go:1261 (shared-server), cmd/bd/compact.go:804, internal/remotecache/cache.go:88, internal/storage/dolt/bootstrap.go:63. Only ONE version-gated capability exists in the tree (SupportsArchiveLevelConfig, internal/doltserver/gc_config.go:11-68, shared-server-only, YAML-key surface only). Pidfile v2 struct (internal/storage/dbproxy/pidfile/pidfile.go:14-23) has zero dolt-binary identity fields. No doctor check inspects the dolt CLI executable (all 7 existing dolt doctor checks operate on a connected DB or git config). #5627 (open, ours, no comments) is a concrete regression the part-2 capability registry would fix — renderProxiedServerConfig (cmd/bd/proxied_server.go:322) unconditionally emits auto_gc_behavior.archive_level after 68afa3d51 deleted the managed-mode gate, re-reaching the #4986 yaml.UnmarshalStrict failure on old dolt. Dup search across 8 query shapes: nothing owns part-2 scope; PR 5092 has no closingIssuesReferences. Full design: reports/2026-07-25-psxg4-dolt-cli-contract-design.md (v2, codex-sol adversarially reviewed, 1 FATAL + 6 MAJOR adopted) — the issue body below carries the substance inline since that report is not upstream-visible. **Filing gate: wait until 5092 merges (or file with explicit "blocked on #5092" framing if the queue pace demands).**

---

PR #5092 delivers part 1 of a supported-dolt-executable contract for proxied mode: the `internal/doltversion` leaf package (hardened probe, resolution order `BEADS_DOLT_BIN` env → PATH, warn-only RecommendedMin) wired at the managed-proxied UOW provider and `bd init --proxied-server` preflight. Its PR body explicitly defers the rest. This issue tracks that remainder so it doesn't evaporate; nothing on main or in open PRs owns it today.

### A. Thread one resolved identity through every spawn site

`doltserver.Start` (shared-server path, internal/doltserver/doltserver.go:1261) and other sites (cmd/bd/compact.go:804, internal/remotecache/cache.go:88, internal/storage/dolt/bootstrap.go:63) still do bare `exec.LookPath("dolt")`, so different code paths can silently select different binaries. The `--dolt-bin` plumbing to the proxy child already exists (cmd/bd/db_proxy_child.go) as a threading target.

### B. Clone-local gitignored sidecar override

A dolt-bin override in the existing gitignored per-clone config family (configfile.go / doctor gitignore template), sitting between the env var and PATH in resolution order. Part 1 left only a hook point. (Design note: an earlier draft put the override in committed metadata.json; that was rejected in adversarial review as repo-data-selects-an-executable, matching the credential-command env-only precedent — the sidecar must stay clone-local and gitignored.)

### C. Pidfile dolt-identity fields + candidate/launched/live triple

The pidfile v2 struct has no record of which dolt binary a running managed server was launched with. Add launched-binary path + OS file identity + parsed version; gate managed-mode pidfile publication on a bounded post-ready `SELECT dolt_version()` probe; have `bd dolt status`/doctor report candidate vs launched vs live identity and flag disagreement (external topology: report-only, never gate).

### D. Per-surface capability registry — with #5627 as the first consumer

Today exactly one version-gated capability exists (`SupportsArchiveLevelConfig`, shared-server mode, YAML-key surface only). The YAML config key, SQL `DOLT_GC` arg, `DOLT_STATS_GC`, and CLI flag are distinct surfaces that only coincidentally share version cutoffs. Concrete forcing function: #5627 — managed-proxied config rendering now emits `auto_gc_behavior.archive_level` unconditionally, which pre-archive_level dolt rejects under `yaml.UnmarshalStrict` (the #4986 symptom, re-reachable since 68afa3d51). Its proposed fix ("only emit the key when the probed dolt supports it") should be this registry's first acceptance criterion.

### E. Doctor "Dolt CLI" check

No doctor check inspects the executable itself — the existing seven dolt-related checks all operate on an already-open DB or git config. A new check should report resolved path, source (env/sidecar/PATH), parsed version vs live `dolt_version()`, and OS file identity; checksum only on request. Coordination note: doctor subcommand additions have historically gone through a single-vetted-subcommand owner gate (#3794/#3758 pattern) — flagging rather than assuming.

### F. Packaging and support-matrix docs

Per-OS install channels (Linux tarball/install.sh, macOS brew incl. services caveat, Windows MSI/Chocolatey), an explicit OS/arch/libc support table with tested/expected/unsupported states, a repo-wide DOLT_VERSION pin plus one latest-canary CI lane.

**Explicitly out of scope:** hard version-floor enforcement. That needs the cross-version compatibility matrix evidence first (separate issue; preliminary single-run evidence already points at ≥ 2.0.0 as the real storage boundary). The only hard gate part 1 ships is refusing a binary that fails the bounded probe outright.

Suggested sequencing (from the reviewed design): PR-2 = A+B+C+D (incl. the #5627 fix), PR-3 = E, PR-4 = F.

## mybd-5zvr: docs claim dolt 2.2.0+ but nothing verifies or enforces it — single-run matrix evidence puts the real floor at 2.0.0

**Evidence:** Confirmed at upstream/main@4ad99760b, 2026-08-12. docs/getting-started/sync-setup.md:15,21 assert "Dolt 2.2.0+ / must be 2.2.0+"; no code compares the dolt CLI version against any floor (doctor's "Dolt Version" check, cmd/bd/doctor/server.go:285-368, detects/reports the connected server's version only); CI pins exactly 2.2.0 everywhere (internal/testutil/testdoltcommon.go:14, scripts/pull_dolt_image_test.go:14) so boundary versions are never exercised. Harness exists in the mybd coordination repo: scripts/dolt-compat-matrix (bash, 8 probes, downloads official linux-amd64 tarballs, isolated DOLT_ROOT_PATH per run); first-run results in reports/2026-07-25-dolt-compat-matrix-first-run.md. Dup search across ~12 query shapes: nothing upstream owns an evidence-backed dolt floor; adjacent-not-duplicate: #5627 (config-writing bug re old dolt), #2764 (general CI-gap catch-all, possible see-also). **Note: the issue body must carry the results table inline — the source report is not upstream-visible.**

---

docs/getting-started/sync-setup.md tells users Dolt "must be 2.2.0+", but that number is asserted, not verified or enforced: nothing in the codebase compares the dolt CLI's version to a floor (the doctor "Dolt Version" check only reports what the connected server is), and CI only ever tests exactly 2.2.0, so the boundary between works-and-breaks has never been probed by CI.

A single-run compatibility matrix (2026-07-25, linux-amd64, official release tarballs, 8 probes: version-parse, proxied init+write, reopen, GC via CLI flag / SQL arg / stats-GC, cross-read of storage written by the current embedded dolt module, file:// sync round trip) against dolt CLI 1.52.1 / 1.85.0 / 2.0.0 / 2.2.2 found:

| dolt CLI | serve proxied (init/write/reopen) | cross-read module-written storage |
|---|---|---|
| 1.52.1 | FAIL (server never listens) | FAIL ("table has unknown fields") |
| 1.85.0 | PASS | FAIL ("table has unknown fields") |
| 2.0.0 | PASS | PASS |
| 2.2.2 | PASS | PASS |

(GC probes passed uniformly where applicable; the stats-GC probe failed identically on every version including 2.2.2 — a harness artifact from running it through offline `dolt sql`, not a version signal.)

The decisive boundary is cross-read of module-written storage: **dolt ≥ 2.0.0 is required**. 1.85.0 is notable because dolt's own release notes describe it as the oldest 1.x line that understands 2.x storage, yet it still fails at the schema level. Any embedded↔proxied migration or mixed embedded/CLI workflow hard-requires ≥ 2.0.0. Separately, 1.52.1 can't serve proxied mode at all (root cause not yet dug out).

**Suggested resolution:** treat 2.0.0 as the evidence-backed enforceable floor and keep 2.2.x as the documented/CI-tested recommendation — either way the docs number becomes a cited fact or a deliberately conservative choice that says so, instead of a number nobody checked. Happy to contribute the matrix harness (a self-contained bash script) if wanted.

**Honest caveats:** single run, linux-amd64 only; no write-compat or schema-migration-on-old-db probes yet; stats-GC probe needs rework; 1.52.1's serve failure unexplained; not wired into CI. A CI-grade matrix is the follow-on work.

## mybd-nsg1: ci: no Windows lane executes the dbproxy proxied-lifecycle tests (procid / process_executable Windows code has zero CI execution)

**Evidence:** Confirmed at upstream/main@4ad99760b, 2026-08-12, with one correction to the original bead claim: internal/procid/procid_windows_test.go now EXISTS (added by merged PR 5013, commit 21669eca6; TestVerifyAfterTerminateWhileHandleHeld regression-tests the review-caught handle-held defect) — but `git grep procid .github/workflows/` returns zero hits, so it never executes in CI on any runner. proxied-local-smoke.yml is the only workflow scoped to internal/storage/dbproxy/** and is hard ubuntu-latest; its own header admits "Linux first; the test lane defines Windows/macOS parity but does not implement those OS-specific observation helpers yet". The three existing windows-latest jobs (pr.yml test-windows-liveness, worktree-remove-windows; main.yml test-windows) cover unrelated paths and none run `go test` on internal/procid or internal/storage/dbproxy. Both review-caught Windows defects from PR 5013 ARE fixed on main (unverified_process_windows.go:97 handleExited uses GetExitCodeProcess; procid_windows.go:126 likewise) — this is purely a coverage gap, not a live bug. process_executable_windows.go, unverified_process_windows.go, endpoint_windows.go still have zero _windows_test.go. Dup search (7 query shapes): none; closest is closed PR 5075 (GOOS=windows lint/compile pass only).

---

PR #5013 added Windows-specific handling to the managed proxied-server lifecycle (internal/storage/dbproxy/proxy, internal/procid), fixing two Windows-only defects that were caught only by pre-merge review: Verify() falsely reporting a terminated-but-handle-pinned process as running, and a missing GetExitCodeProcess check. Both fixes are on main, and internal/procid/procid_windows_test.go now contains a regression test for the first (TestVerifyAfterTerminateWhileHandleHeld).

The gap: none of that Windows code ever executes in CI.

- `git grep procid .github/workflows/` → zero matches: the regression test runs on no runner, no OS. From a CI standpoint it is dead test code.
- `.github/workflows/proxied-local-smoke.yml` is the only workflow path-scoped to `internal/storage/dbproxy/**`, and it is `runs-on: ubuntu-latest`; its own header comment says the Windows/macOS observation helpers are defined-but-unimplemented.
- The windows-latest jobs that do exist (pr.yml `test-windows-liveness` — one config-drift liveness test in cmd/bd; `worktree-remove-windows` — NTFS worktree removal; main.yml `test-windows` — build + smoke only) never run `go test` against internal/procid or internal/storage/dbproxy.
- `process_executable_windows.go`, `unverified_process_windows.go`, and `endpoint_windows.go` have no `_windows_test.go` at all.

Ask: at minimum, add a windows-latest job running `go test ./internal/procid/... ./internal/storage/dbproxy/...` so the existing Windows regression test and any future Windows dbproxy tests execute pre-merge — rather than relying on ad hoc review to catch platform-specific handle-lifecycle bugs, as happened for #5013. The fuller version is the Windows/macOS parity lane proxied-local-smoke.yml's header already promises.


---

# Addendum (2026-08-12, later session): all 11 drafts filed

Owner dropped the pacing requirement ("everyone is using agents"). All 11
drafts above were filed same day against upstream main still at 4ad99760b
(zero drift since verification, so no re-verification delta):

| bead | issue |
|---|---|
| mybd-vctrh | gastownhall/beads#5695 |
| mybd-ykaa | gastownhall/beads#5696 |
| mybd-7qp5 | gastownhall/beads#5697 |
| mybd-lfos | gastownhall/beads#5698 |
| mybd-43lf | gastownhall/beads#5699 |
| mybd-o4u1w | gastownhall/beads#5700 |
| mybd-zz04j | gastownhall/beads#5701 |
| mybd-psxg.3 | gastownhall/beads#5702 (+ courtesy comment on #5103) |
| mybd-psxg.4 pt2 | gastownhall/beads#5703 (blocked-on-#5092 framing) |
| mybd-5zvr | gastownhall/beads#5704 |
| mybd-nsg1 | gastownhall/beads#5705 |

Source beads closed with issue refs; mybd-psxg epic closed (handoff
complete). Next: master handoff index issue (drafted, pending owner review),
then the 9 unverified mediums.
