# Codex implementation brief - mybd-304op (attempt 1, DEFEATED)

**Status: not yet usable as-is. Read this header before dispatching it again.**

Authored 2026-08-24 and dispatched once to `codex-agent builder` (session
`01a03376-c4e8-7fd1-8fde-c4c88fb70e08`, gpt-5.6-terra, workspace-write). The
run produced zero commits and correctly refused to guess an adapter. The brief
was not defeated on content - it was defeated by two environment facts it did
not know about:

1. `<worktree>/.codex/` is **read-only** inside `codex exec -s workspace-write`
   (EROFS, errno 30), despite the sandbox advertising the worktree as a
   writable root. Section 3's capture procedure and section 6's wiring step
   both require writing that directory, so **a Codex agent cannot perform
   them**. The capture must happen outside the Codex sandbox.

2. Every Codex hook command must be trusted per-machine by sha256 in
   `~/.codex/config.toml` under
   `[hooks.state]."<abs hooks.json path>:<event>:<i>:<j>"`. An untrusted or
   edited command is **silently skipped** by non-interactive `codex exec` - no
   warning, exit 0. Verified directly: a freshly added PreToolUse dump hook in
   this worktree did not fire at all. So committing a `PreToolUse` entry does
   not make the gate real on any machine that has not trusted that exact hash,
   and editing the command silently un-trusts it. This is the same
   silent-false-security failure the bead exists to prevent, one layer down,
   and the brief below does not cover it.

Before reusing this brief: add fact (2) to it as a first-class requirement
(the work must include a way to report "registered but NOT trusted on this
machine"), and remove the capture step - hand the fixture over already
captured.

Also learned: Codex rejects `rm -f` outright ("rm -f style commands are not
permitted"), which conflicts with this repo's non-interactive-shell
convention. Avoid deletion in Codex briefs for this repo.

See bead mybd-304op for the revised plan, and `bd memories codex` for both
findings.

---

# Implementation brief: wire the PreToolUse guards into Codex (bead mybd-304op)

You are implementing one tracked bug fix in a repository you have not seen.
Everything you need is in this document. Do not ask questions. Do not stop to
request approval. Work only inside the fences stated below.

---

## 0. TL;DR of the job

Two guard scripts (`scripts/pr-review-gate`, `scripts/destructive-guard`) are
registered as `PreToolUse` hooks **only** for Claude Code, in
`.claude/settings.json`. The Codex hook config `.codex/hooks.json` has no
`PreToolUse` entry at all, so neither guard has ever run under Codex. Codex CLI
0.149.0 on this host does support `PreToolUse`.

You will: capture a **real** Codex PreToolUse payload, commit it as a test
fixture, split "extract the command from the payload" out of "match the command"
in both guards so both payload shapes work, make an **unrecognized** payload
shape loud on stderr instead of silently allowing, register both guards on
`PreToolUse` in `.codex/hooks.json`, fix that file's cwd-relative `SessionStart`
path, extend two test scripts, and prove end-to-end that a real Codex session
gets `gh pr create` blocked when review evidence is missing. Then commit on the
branch. Do not merge, push, or open a PR.

---

## 1. Orientation

- **Repo root (main checkout):** `/var/home/matt/dev/mybd`
  This is "mybd", a single-owner *coordination repository*: agent conventions
  (`AGENTS.md`), guardrail/hook scripts (`scripts/`), reports, and an issue
  tracker. It is not a product codebase. Everything you care about is bash +
  JSON.
- **YOUR WORKTREE (work here, and only here):**
  `/var/home/matt/dev/mybd/.worktrees/mybd/codex-pretooluse`
  **Branch:** `feat/codex-pretooluse-gate` (already created and checked out,
  clean, at the same commit as `main`).
  Start every command with an absolute path or `cd` into that worktree first.
- **NEVER write in `/var/home/matt/dev/mybd` itself.** Another agent session is
  live in that checkout right now. You may *read* files there; you may not edit,
  commit, checkout, stash, or `git worktree add/remove` there. (`git stash` is
  shared repo-wide across worktrees — do not use bare `git stash` at all.)
- **Issue tracker:** the repo uses "beads" (`bd`). Bead state lives in a local
  Dolt database, not in git. **Do not run any `bd` command that mutates state**
  (`bd update`, `bd close`, `bd create`, `bd dolt push`, `bd remember`, …). The
  orchestrator owns bead state. Read-only `bd show mybd-304op` is fine if you
  want the original text, but this brief already contains it.
- **Do not `git push`, do not `gh pr create`, do not merge to `main`.** Commit on
  `feat/codex-pretooluse-gate` and stop. The orchestrator lands it.

### Fences (violating any of these fails the task)

1. **Do not touch `.claude/settings.json`.** A parallel branch
   (`fix/hook-cwd-paths`, bead mybd-edh52) owns that file and is fixing its
   cwd-relative hook paths in this same window. Editing it guarantees a merge
   conflict. Your changes to the Claude side are limited to the *guard scripts*,
   which must keep working unchanged for Claude payloads.
2. **Do not extract or restructure the command-MATCHING logic** in
   `destructive-guard` (the `rm -rf .bare` / worktree-list / memory-clobber
   pattern block) or in `pr-review-gate` (the `gh pr create` policy block). A
   separate bead (mybd-gk61u) owns that refactor and depends on this one. This
   bead owns exactly one seam: **payload in → command string out**. Above the
   seam you may rewrite freely; below it, leave the code alone.
3. **Escape hatches must keep working through the new entry point.**
   `MYBD_ALLOW_BARE_DELETE`, `MYBD_ALLOW_WORKTREE_RM`,
   `MYBD_ALLOW_MEMORY_CLOBBER`, `MYBD_SKIP_XVENDOR`, `MYBD_SKIP_REDTEAM` are
   matched as **text inside the command string** (an inline `VAR=1` prefix), not
   read from the environment. If your extraction step mangles or re-quotes the
   command, the hatches break silently. You must add a test that proves a hatch
   still works when the command arrives in the *Codex* payload shape.
4. Commit on the branch. No merge, no push, no PR.

---

## 2. THE HAZARD — read this twice

Both guards **fail open**. `scripts/destructive-guard` lines 30-33:

```bash
command -v jq >/dev/null 2>&1 || exit 0
input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null)"
[[ -n "$cmd" ]] || exit 0
```

If `cmd` comes out empty — wrong field name, wrong nesting, `command` is an
array instead of a string, malformed JSON (the `2>/dev/null` swallows jq's
error) — then **every pattern misses and the guard exits 0, which means ALLOW,
with nothing on stderr and nothing in any log.**

Therefore: if Codex's PreToolUse payload does not have `.tool_input.command` as
a non-empty **string**, registering the hook produces a gate that looks
installed, logs nothing and blocks nothing. That is **strictly worse than the
current honest absence**, because the coverage table in the tracker would then
claim Codex is covered.

**Hard requirement:** capture a REAL Codex PreToolUse payload from a REAL Codex
session on this host, on disk, before you write one line of adapter code. Do not
infer the schema from documentation, from release notes, from the Claude Code
shape, from this brief, or from your own knowledge of Codex. Section 3 gives you
the capture procedure and it is not optional.

A specific trap to have in mind (do not assume it, verify it): Codex's shell
tool may pass its command as an **argv array** (e.g.
`["bash","-lc","rm -rf .bare"]`) rather than a single string. `jq -r` on an
array yields pretty-printed JSON text, which is non-empty — so the guard would
appear to work while matching against JSON punctuation, and quoting-sensitive
logic (the `code`/`flags` normalization at `destructive-guard:44-45`) would
behave differently than intended. Only the captured payload tells you.

Known-good priors you may use to *design* the capture, never to skip it: this
host's `codex --version` is `codex-cli 0.149.0`; its embedded JSON schema
`pre-tool-use.command.input` requires the keys `cwd`, `hook_event_name`
(const `"PreToolUse"`), `model`, `permission_mode`, `session_id`, `tool_input`,
`tool_name`, `tool_use_id`, `transcript_path`, `turn_id`. Note `tool_input` is
schema-typed as `true` (arbitrary) — **its inner shape is tool-specific and is
exactly the thing you must observe.** Also unknown until observed: what Codex
calls its shell tool in `tool_name` (it is probably NOT `"Bash"`), which
determines the `matcher` you must write.

---

## 3. Capture the real payload (step 1, blocking)

Codex reads project hooks from `<project>/.codex/hooks.json` and requires each
hook entry to be **trusted** (`~/.codex/config.toml` has a `[hooks.state]` table
keyed by `"<abs path to hooks.json>:<event>:<entry idx>:<hook idx>"` with a
`trusted_hash`). Your worktree's `.codex/hooks.json` is a different path from the
root one, so it starts untrusted. Non-interactive runs get past that with
`--dangerously-bypass-hook-trust` (a real `codex exec` flag on 0.149.0). Do not
edit `~/.codex/config.toml`.

`<worktree>/.codex/config.toml` already contains:

```toml
[features]
hooks = true
```

Procedure:

```bash
WT=/var/home/matt/dev/mybd/.worktrees/mybd/codex-pretooluse
cd "$WT"

# 1. Back up the real hooks config before mutating it temporarily.
cp -f .codex/hooks.json /tmp/hooks.json.orig

# 2. Add a TEMPORARY PreToolUse dump hook. Dump stdin AND the hook's
#    environment (you need the env for section 6). Use a matcher that cannot
#    filter anything out yet -- you do not know the tool name.
python3 - <<'PY'
import json
p = ".codex/hooks.json"
d = json.load(open(p))
d["hooks"]["PreToolUse"] = [{
  "matcher": ".*",
  "hooks": [{
    "type": "command",
    "command": "bash -c 'cat > /tmp/codex-pretooluse-payload.json; env | sort > /tmp/codex-hook-env.txt; exit 0'"
  }]
}]
json.dump(d, open(p, "w"), indent=2)
PY

# 3. Fire it with a throwaway Codex run that MUST shell out.
rm -f /tmp/codex-pretooluse-payload.json /tmp/codex-hook-env.txt
codex exec --dangerously-bypass-hook-trust -s read-only \
  "Run exactly this shell command and then stop: echo hello-hook-capture" \
  </dev/null

# 4. Look at what you actually got.
cat /tmp/codex-pretooluse-payload.json | jq .
grep -nE 'CODEX|PROJECT|CLAUDE' /tmp/codex-hook-env.txt
```

Verify the capture actually worked before continuing:

- `/tmp/codex-pretooluse-payload.json` exists and is non-empty.
- `jq -e '.hook_event_name == "PreToolUse"' /tmp/codex-pretooluse-payload.json`
  exits 0.
- `jq -r '.tool_name' …` prints a real tool name — record it verbatim.
- `jq -c '.tool_input' …` prints the real inner shape — record it verbatim.
- `jq -r '.tool_input.command // "MISSING"' …` — this single line tells you
  whether the existing guards fail open under Codex. Write the answer down; it
  goes in your final report.

If the file is missing or empty, the hook did not fire. Debug it before doing
anything else: confirm `codex exec` actually ran a shell command (re-run with a
prompt that forces one), confirm `[features] hooks = true` is present in
`<worktree>/.codex/config.toml`, confirm you edited the hooks.json **in the
worktree**, and re-run with `--dangerously-bypass-hook-trust` present. Do not
proceed on a guess. If after honest effort you cannot capture a payload, **stop
and report that** — a report of "could not capture" is a correct outcome; a
guessed adapter is not.

Also capture a **second** payload for a non-shell tool (e.g. a file edit) if you
can get one cheaply — it tells you whether your `matcher` needs to be narrow. Not
blocking if you cannot.

**Restore the config before you go further:**

```bash
cp -f /tmp/hooks.json.orig "$WT/.codex/hooks.json"
git -C "$WT" diff --stat .codex/hooks.json   # must be empty at this point
```

**The temporary dump hook MUST NOT be committed.** Before your final commit, run
`git -C "$WT" diff main -- .codex/hooks.json` and confirm no `cat >` / `env |
sort` / `/tmp/codex-` string survives anywhere in the tree:

```bash
grep -rn 'codex-pretooluse-payload\|codex-hook-env' "$WT" --exclude-dir=.git
```

The only acceptable hits are inside the committed **fixture file** and test code
that reads it.

---

## 4. Commit the payload as a fixture (step 2)

Create `scripts/fixtures/` (new directory) and store the captured payloads:

- `scripts/fixtures/codex-pretooluse-shell.json` — the real captured payload,
  **verbatim from the capture**, except: replace host-specific/volatile values
  (`session_id`, `turn_id`, `tool_use_id`, `transcript_path`, and any absolute
  path outside the repo) with stable placeholder values, and set the command to
  something obviously synthetic. Do **not** restructure the object: key names,
  nesting and value *types* must be exactly what Codex emitted.
- `scripts/fixtures/claude-pretooluse-bash.json` — the Claude shape, for
  symmetry, matching what the tests already synthesize:
  `{"hook_event_name":"PreToolUse","tool_name":"Bash","cwd":"…","tool_input":{"command":"…"}}`

Add a short `scripts/fixtures/README.md` (5-15 lines) recording: which codex
version produced the payload (`codex-cli 0.149.0`), the date, the exact command
used to capture it, which fields were scrubbed, and the one-sentence reason the
fixture exists (payload-shape drift silently disarms the guards). A future agent
must be able to re-capture from that note alone.

---

## 5. Split extraction from matching in BOTH guards (step 3)

### 5.1 Where the seam is today

`scripts/destructive-guard` (119 lines). Payload region is lines **30-33**;
everything from line 35 down is normalization, helpers, and matching:

```
28	set -uo pipefail
29	
30	command -v jq >/dev/null 2>&1 || exit 0
31	input="$(cat)"
32	cmd="$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null)"
33	[[ -n "$cmd" ]] || exit 0
```

`$input` is referenced exactly once (line 32). Nothing else in the file reads
`.tool_name`, `.cwd`, `.session_id`, or any other payload field. Immediately
below, lines 44-45 derive two views of the already-extracted string (this is
normalization, **not** payload parsing — do not move it):

```
44	code="$(sed -E "s/'(-[^']*)'/\1/g; s/\"(-[^\"]*)\"/\1/g; s/'[^']*'/''/g; s/\"[^\"]*\"/\"\"/g" <<<"$cmd" | tr '\n' ' ')"
45	flags="$(tr -d "'\\\"" <<<"$cmd" | tr '\n' ' ')"
```

Helpers `block()` 47-53, `excused()` 59, `has_rm_r()` 63-66. First matching line
is 69:

```
69	if ! excused MYBD_ALLOW_BARE_DELETE && has_rm_r "$code" \
70	   && grep -Eq '(^|[/ =])\.bare(/|[; &|]|$)' <<<"$flags"; then
```

Matching region: 69-116. **Leave 44-116 alone.**

`scripts/pr-review-gate` (293 lines). Payload region is lines **43-48**:

```
43	input="$(cat)"
44	command -v jq >/dev/null 2>&1 || exit 0
45	
46	cmd="$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null)"
47	hook_cwd="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)"
48	[[ -n "$cmd" ]] || exit 0
```

Two payload fields: `.tool_input.command` and `.cwd`. `.tool_name` is not read
here either. Normalization at 55-56, first matching line at 61:

```
61	grep -qE '(^|[;&|(]|&&|\|\||[[:space:]])gh[[:space:]]+pr[[:space:]]+(create|new)([[:space:]]|$)' <<<"$cmd_code" || exit 0
```

`hook_cwd` is never emptiness-checked directly; it flows to line 89
`effective_dir="$hook_cwd"` and is rescued at line 93 by
`[[ -n "$effective_dir" ]] || effective_dir="$PWD"`. Preserve that behaviour.
Note this file's other `jq` calls (lines 214, 215, 222-226, 230) parse
**verdict files on disk**, not the hook payload — do not touch them.

Note the ordering difference between the two files: `destructive-guard` checks
for `jq` *before* draining stdin; `pr-review-gate` drains stdin first. Keep each
script's existing "no jq → exit 0" behaviour.

### 5.2 What to build

Create one shared extractor and have both guards source it. Suggested:
`scripts/lib/hook-payload.sh`, providing a function that reads the payload JSON
(already slurped into a variable) and sets/echoes:

- the command string
- the hook cwd (may be empty)
- a shape label: `claude`, `codex`, or `unknown`

Requirements:

1. **Accept the Claude shape** exactly as today: `.tool_input.command` as a
   string.
2. **Accept the Codex shape** exactly as captured in section 3. If Codex passes
   argv as an array, join it back into the command line the shell would run —
   and if the array is a wrapper form like `["bash","-lc","<script>"]`, the
   thing the guards must match is the **`<script>` payload**, not the wrapper.
   Decide this from the captured fixture, and write a comment in the code
   quoting the observed shape so the next reader does not have to re-derive it.
   Preserve the command text byte-for-byte where you can: the escape hatches and
   the quote-aware normalization below the seam both depend on the original
   quoting.
3. **Unknown shape must be LOUD.** If the payload parses but no known shape
   yields a non-empty command, write a clearly-worded warning to **stderr**
   naming the script, the observed `hook_event_name`/`tool_name`, and the top
   level keys of `tool_input`, e.g.:

   ```
   destructive-guard: WARNING - unrecognized PreToolUse payload shape
     (tool_name=<x>, tool_input keys=<...>); guard could not extract a command
     and is ALLOWING this call. Re-capture the payload and update
     scripts/lib/hook-payload.sh (see scripts/fixtures/README.md).
   ```

   **Exit code stays 0** for an unrecognized shape (do not turn a schema drift
   into a hard block on every tool call — that would wedge sessions). The
   requirement is *visible*, not *blocking*. Distinguish the three dispositions
   in code and comments: (a) known shape, no command present / not a shell tool
   → silent exit 0; (b) known shape, command extracted → proceed to matching;
   (c) unknown shape → warn on stderr, exit 0.
4. Keep "jq missing → exit 0, silent" as-is in both scripts.
5. Keep both scripts runnable standalone with a payload on stdin (that is how
   the tests drive them, and how the hooks drive them).

Sourcing must be path-safe: both scripts already resolve their own directory
(`pr-review-gate:36` uses `BASH_SOURCE[0]`); use the same idiom in
`destructive-guard` rather than a relative `source scripts/lib/…`, because these
scripts are invoked from arbitrary cwds.

---

## 6. Wire `.codex/hooks.json` (steps 4 and 5)

### 6.1 Current content (verbatim, in your worktree)

```json
{
  "hooks": {
    "PostCompact": [
      {
        "hooks": [
          {
            "command": "bd codex-hook PostCompact",
            "statusMessage": "Scheduling Beads context refresh",
            "type": "command"
          }
        ],
        "matcher": "manual|auto"
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "command": "bd codex-hook PreCompact",
            "statusMessage": "Checking Beads context",
            "type": "command"
          }
        ],
        "matcher": "manual|auto"
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/session-start-stamp"
          }
        ]
      },
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "bd codex-hook SessionStart"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": null,
        "hooks": [
          {
            "type": "command",
            "command": "bd codex-hook UserPromptSubmit"
          }
        ]
      }
    ]
  }
}
```

### 6.2 The new PreToolUse entry

Add a `PreToolUse` array mirroring the Claude registration (`pr-review-gate`
first, then `destructive-guard`, both as separate hooks in one entry), with:

- `"matcher"` set to whatever actually matches Codex's shell tool. **Take the
  tool name from your captured payload** (`jq -r '.tool_name'`). Do not write
  `"Bash"` unless the capture says `Bash`. If you observed more than one shell
  tool name, use a regex alternation and say why in the commit message.
- Commands invoked by **absolute-safe** path, not `bash scripts/…` — see 6.3.

Skeleton (fill in the matcher and the path form you verified):

```json
"PreToolUse": [
  {
    "matcher": "<verified tool name regex>",
    "hooks": [
      { "type": "command", "command": "<resolved> scripts/pr-review-gate" },
      { "type": "command", "command": "<resolved> scripts/destructive-guard" }
    ]
  }
]
```

Keep the file's existing formatting style (2-space indent) and make sure it still
parses: `jq empty .codex/hooks.json`.

### 6.3 The path fix (applies to the new entries AND to SessionStart)

`"bash scripts/session-start-stamp"` is **cwd-relative**. Hooks run in the
session's current working directory, and sessions in this repo routinely work in
nested checkouts that have no `scripts/` of their own (`/var/home/matt/dev/mybd/bd-main`,
`/var/home/matt/dev/mybd/.worktrees/…`). From there the hook dies with "No such
file or directory" and — because the failure is non-blocking — the call proceeds
ungated. That is the exact bug mybd-edh52 is fixing on the Claude side; fix the
Codex side here.

**Verify the project-root variable; do not assume `CLAUDE_PROJECT_DIR`.** You
already dumped the hook environment to `/tmp/codex-hook-env.txt` in section 3:

```bash
grep -nE 'PROJECT|ROOT|CODEX|WORKSPACE|CLAUDE' /tmp/codex-hook-env.txt
```

Then confirm the variable actually **expands inside a hooks.json command** (the
hook runner does `${VAR}` substitution on command strings; whether it does so for
a given variable is a fact, not a guess). Test it the same way you captured the
payload: temporarily set a hook command to
`bash -c 'echo "VAR=[${THE_VAR}]" > /tmp/codex-hook-var.txt'`, fire a throwaway
`codex exec … --dangerously-bypass-hook-trust`, and read the file. Remove the
probe afterwards.

- If a project-root variable exists and expands: use
  `bash "${THAT_VAR}/scripts/pr-review-gate"` (and the same for the other two
  commands).
- If **no** such variable exists, do not hardcode `/var/home/matt/dev/mybd`.
  Use a self-resolving form that walks up from the cwd to the directory that
  owns the scripts, e.g.:

  ```
  bash -c 'd="$PWD"; while [ "$d" != / ] && [ ! -x "$d/scripts/destructive-guard" ]; do d="$(dirname "$d")"; done; [ -x "$d/scripts/destructive-guard" ] && exec bash "$d/scripts/destructive-guard"; exit 0'
  ```

  This works from `bd-main` and from `.worktrees/*` because both live under the
  repo root. Whichever form you pick, it must start with `bash ` or `bash -c`
  (a test asserts this — see 7.3).

Apply the same fix to the existing `SessionStart` `session-start-stamp` command.
Leave the four `bd codex-hook …` commands untouched.

### 6.4 Self-gating warning

Once you commit this, Codex sessions **in that worktree** are themselves gated by
these guards. If one of your own later commands gets blocked, that is the gate
working. Use the documented inline escape hatch
(`MYBD_ALLOW_WORKTREE_RM=1 …` etc., as a prefix on the command line) rather than
removing or weakening the hook. Never disable the hook to unblock yourself.

---

## 7. Extend the tests (step 6)

### 7.1 `scripts/test-guardrails`

Runs directly as a bash script; exits 0 on all-pass, 1 on any failure.
Reporting helpers at lines 24-25:

```bash
pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; fails=$((fails + 1)); }
```

Payload synthesis today, lines 86-89:

```bash
run_guard() {  # $1 = command string; echoes rc
  jq -n --arg c "$1" '{tool_input:{command:$c}}' | "$guard" >/dev/null 2>&1
  echo $?
}
```

Table-driven cases: `blocked` associative array at lines 91-112 with the loop at
113-120 asserting rc==2; `allowed` array at 122-132 with the loop at 133-140
asserting rc==0. Adding a case to either array is enough — the loops pick it up.

**Add:** a second runner, e.g. `run_guard_codex`, that builds the **Codex** shape
(derive it from `scripts/fixtures/codex-pretooluse-shell.json` — read the fixture
and substitute the command, so the test breaks if the fixture and the extractor
disagree), then run the **same** `blocked` and `allowed` tables through it. Every
existing block/allow expectation must hold under both shapes.

Also add explicitly:

- Escape-hatch parity: `MYBD_ALLOW_BARE_DELETE=1 rm -rf .bare` (and one more
  hatch) must return rc 0 through the **Codex** shape, and the un-hatched form
  must return rc 2 through the Codex shape.
- Unknown-shape loudness: feed a payload with a plausible-but-wrong shape (e.g.
  `{"hook_event_name":"PreToolUse","tool_name":"whatever","tool_input":{"cmdline":"rm -rf .bare"}}`)
  and assert **both** that the exit code is 0 **and** that stderr is non-empty
  and contains a recognizable marker (`WARNING`). Capture stderr with
  `2>"$tmp/err"` rather than `2>&1`, since the runners currently discard it.
- A regression guard on the fixture itself: assert the committed Codex fixture
  still yields a non-empty extracted command through the shared extractor.

### 7.2 `scripts/test-pr-review-gate`

Bash script, exits 0 on all-pass. Detects `codex` on PATH at line 20 and skips
deny-cases if absent. Payload synthesis at lines 49-54:

```bash
run() { # run <cmd> <cwd> -> exit code
  jq -nc --arg c "$1" --arg d "$2" \
    '{hook_event_name:"PreToolUse",tool_name:"Bash",cwd:$d,tool_input:{command:$c}}' \
    | "$GATE" >/dev/null 2>&1
  echo $?
}
```

Assertion helper at 56-62:

```bash
check() { # check <label> <expected> <actual>
  if [[ "$2" == "$3" ]]; then
    printf '  ok    %s\n' "$1"; pass=$((pass+1))
  else
    printf '  FAIL  %s (want exit %s, got %s)\n' "$1" "$2" "$3"; fail=$((fail+1))
  fi
}
```

Fixture planting at 68-71:

```bash
plant_redteam() {
  printf '{"head":"%s","base":"%s","verdict":"%s","rounds":1,"open_p0p1":0,"findings":[]}\n' \
    "$1" "$2" "${3:-pass}" > "$REVIEW_DIR/$1.redteam.json"
}
```

Existing shapes of checks to copy: pass-throughs at 76-82
(`check "gh pr view" 0 "$(run 'gh pr view 123 --repo gastownhall/beads' "$tmp")"`),
deny cases at 86-92 (`check "unreviewed, --repo named" 2 "$(run 'gh pr create --repo gastownhall/beads --title x' "$tmp")"`),
allow-with-fixture at 109-120.

**Add:** a `run_codex` twin of `run` producing the captured Codex shape (again
derived from the committed fixture), and re-run the representative pass-through,
deny, and allow cases through it. Include at least one `MYBD_SKIP_XVENDOR=1` /
`MYBD_SKIP_REDTEAM=1` hatch case through the Codex shape. Also assert the
unknown-shape warning path here, same as 7.1.

Keep the existing `hook_cwd` semantics under test: one Codex-shape deny case run
from a directory other than the repo root, matching the existing
`"-R upstream from elsewhere"` case at line 90.

### 7.3 `scripts/test-agent-hooks` — you WILL need to update this

This script asserts on the hook configs themselves and will fail if you ignore
it. Relevant existing behaviour:

- It requires `.codex/hooks.json` to parse as JSON and to fire
  `bd codex-hook <Event>` for `SessionStart`, `PreCompact`, `PostCompact`,
  `UserPromptSubmit`, and to fire `session-start-stamp` on `SessionStart` (it
  matches the command with a regex containing `session-start-stamp`, so a
  path-prefixed form still matches).
- Group 2 asserts, for **both** `.codex/hooks.json` and `.claude/settings.json`:
  no `C:\` drive-letter paths, no `bash.exe`, no `PROGRA~1`, and that **every**
  command string mentioning `scripts/` or `session-start-stamp` starts with
  `bash ` or `bash -c`. Your new commands must satisfy that.

Add coverage there for the new invariant: `.codex/hooks.json` registers a
`PreToolUse` entry that fires both `pr-review-gate` and `destructive-guard`, and
no hook command in the file is cwd-relative (i.e. no command matching
`bash scripts/` with nothing resolving the root). The existing
`event_has_command <event> <regex>` helper (lines 45-52) is the tool for the
first half.

---

## 8. Prove it end-to-end (step 7)

A passing unit test is not the acceptance criterion. Run a **real** Codex session
in the worktree and show `gh pr create` being blocked with no review evidence.

```bash
WT=/var/home/matt/dev/mybd/.worktrees/mybd/codex-pretooluse
cd "$WT"
codex exec --dangerously-bypass-hook-trust -s workspace-write \
  "Run exactly this and report the exact stderr you get: gh pr create --repo gastownhall/beads --title probe --body probe" \
  </dev/null 2>&1 | tee /tmp/codex-gate-proof.txt
```

Expected: the command does **not** create a PR; the guard's block message
(`pr-review-gate: BLOCKED …`-style text, exit 2) appears. Save the transcript at
`/tmp/codex-gate-proof.txt` and quote the decisive lines in your final report.
Do the same for a destructive shape, read-only sandbox is fine:

```bash
codex exec --dangerously-bypass-hook-trust -s workspace-write \
  "Run exactly this and report the exact stderr: rm -rf .bare" </dev/null 2>&1 \
  | tee /tmp/codex-destructive-proof.txt
```

Expected: blocked by `destructive-guard`, and **`.bare` still exists**. Confirm:
`ls -d /var/home/matt/dev/mybd/.bare` still succeeds afterwards. If for any
reason the block does not happen, that is the headline finding — report it
rather than papering over it.

Note: Codex's `PreToolUse` contract on 0.149.0 supports a JSON
`hookSpecificOutput.permissionDecision: "deny"` with a non-empty
`permissionDecisionReason`, in addition to the exit-2-plus-stderr convention the
scripts already use. **Do not switch the guards to the JSON form** unless the
end-to-end proof shows exit-2 is not honoured under Codex. If exit 2 does not
block, that is a real finding: implement the minimal JSON output needed, keep
exit 2 working for Claude, and say so prominently in your report.

---

## 9. Verification commands and expected output

Run all of these from the worktree. Report actual output; do not summarize a
failure as a pass.

```bash
WT=/var/home/matt/dev/mybd/.worktrees/mybd/codex-pretooluse
cd "$WT"

jq empty .codex/hooks.json            # no output, exit 0
jq empty .claude/settings.json        # no output, exit 0  (file must be UNCHANGED)
git diff --stat main -- .claude/settings.json   # MUST be empty

bash -n scripts/destructive-guard     # no output
bash -n scripts/pr-review-gate        # no output
bash -n scripts/lib/hook-payload.sh   # no output (if you created it)

scripts/test-guardrails               # ends "test-guardrails: all checks passed", exit 0
scripts/test-pr-review-gate           # ends "<N> passed, 0 failed", exit 0
scripts/test-agent-hooks              # all PASS lines, exit 0

# Claude-shape regression, by hand:
jq -n '{tool_input:{command:"rm -rf .bare"}}' | bash scripts/destructive-guard; echo "rc=$?"
#   expect: block message on stderr, rc=2
jq -n '{tool_input:{command:"MYBD_ALLOW_BARE_DELETE=1 rm -rf .bare"}}' | bash scripts/destructive-guard; echo "rc=$?"
#   expect: no output, rc=0

# Codex-shape, by hand, from the committed fixture:
jq '.tool_input' scripts/fixtures/codex-pretooluse-shell.json   # eyeball the real shape
#   then the equivalent block/allow pair through that shape: rc=2 / rc=0

# Unknown-shape loudness:
jq -n '{hook_event_name:"PreToolUse",tool_name:"x",tool_input:{cmdline:"rm -rf .bare"}}' \
  | bash scripts/destructive-guard; echo "rc=$?"
#   expect: WARNING text on stderr, rc=0

# Temp capture hook is gone:
grep -rn 'codex-pretooluse-payload\|codex-hook-env\|/tmp/codex-hook-var' . --exclude-dir=.git
#   expect: hits only in scripts/fixtures/README.md prose, if anywhere

git status --short   # only your intended files
```

Also run `shellcheck` on the changed scripts if it is on PATH; if it is not,
say so rather than claiming it passed.

---

## 10. Acceptance criteria (checklist from the bead)

- [ ] A captured **real** Codex PreToolUse payload is committed as a test fixture.
- [ ] Both guards extract the command from **Claude-shaped AND Codex-shaped**
      payloads.
- [ ] An **unrecognized** payload shape produces a visible warning (stderr)
      instead of silently allowing.
- [ ] `.codex/hooks.json` registers **both** guards on `PreToolUse`.
- [ ] `.codex/hooks.json`'s `SessionStart` hook no longer uses a cwd-relative
      path, and the project-root variable used was **verified**, not assumed.
- [ ] `scripts/test-guardrails` and `scripts/test-pr-review-gate` assert against
      **both** payload shapes.
- [ ] The `MYBD_ALLOW_*` / `MYBD_SKIP_*` escape hatches still work through the
      new entry point, proven by a test.
- [ ] A Codex session demonstrably has `gh pr create` blocked without review
      evidence (transcript saved).
- [ ] `.claude/settings.json` untouched; `destructive-guard` / `pr-review-gate`
      matching logic unrestructured.
- [ ] Committed on `feat/codex-pretooluse-gate`. Not merged, not pushed, no PR.

---

## 11. Commit

Commit only in the worktree, only on `feat/codex-pretooluse-gate`.

Message: one-line summary naming the bead, then a body answering **why** (Codex
sessions ran ungated; the guards fail open, so wiring without verifying the
payload shape would have been worse than the gap), what the captured payload
actually looked like, and the fence you respected (`.claude/settings.json`
untouched; matcher refactor left to mybd-gk61u). Reference the bead as
`mybd-304op` in plain text.

**Signing is mandatory.** The commit needs an `Agent-Signature` trailer,
generated — never hand-written from memory — with:

```bash
AGENT_MODEL=<your model> AGENT_REASONING=<your effort> \
  /var/home/matt/dev/mybd/scripts/agent-sig.sh codex --trailer
```

Run it from **bash** (never PowerShell). It prints a line of the form
`Agent-Signature: codex-<model>-<reasoning> on behalf of matt wilkie`. Paste that
line verbatim as the last line of the commit message. **Do not guess `<model>` or
`<reasoning>`.** If you cannot determine them from reliable runtime metadata,
leave the `unknown-model` / `unknown-reasoning` placeholders the script produces
rather than inventing values.

```bash
cd /var/home/matt/dev/mybd/.worktrees/mybd/codex-pretooluse
git add -A
git commit -F /tmp/commit-msg.txt
git log --oneline -1
```

Then **stop**. No `git push`, no `gh pr create`, no merge into `main`, no
`git worktree remove`, no `bd` state changes.

---

## 12. Report back

Your final message is capped around 30KB, so summarize; leave detail on disk.

In the final message, include:

1. **The captured payload shape**, quoted: the value of `.tool_name`, and
   `jq -c '.tool_input'` (scrubbed). One sentence: did
   `.tool_input.command` exist as a non-empty string, i.e. were the old guards
   failing open under Codex or accidentally working?
2. **The project-root env var question**: which variable you found and verified,
   or that none exists and which fallback form you used.
3. Files changed, with absolute paths, one line each.
4. Verification results: for each command in section 9, pass/fail and the last
   line of its output. Report failures honestly.
5. The end-to-end proof: the decisive lines from `/tmp/codex-gate-proof.txt` and
   `/tmp/codex-destructive-proof.txt`, plus whether exit-2 blocking is honoured
   by Codex or whether the JSON `permissionDecision` form was needed.
6. The commit sha and the exact `Agent-Signature` line used.
7. Anything you deliberately did NOT do because of a fence, and any follow-up
   work you think should become a new bead (describe it — **do not create it**).

Leave on disk (do not delete): `/tmp/codex-pretooluse-payload.json`,
`/tmp/codex-hook-env.txt`, `/tmp/codex-gate-proof.txt`,
`/tmp/codex-destructive-proof.txt`, and the commit message file. Delete the
temporary hook edits — those must never reach the commit.
