# Cold-start-readiness check for session-close — design

**Bead:** mybd-bz6i · **Date:** 2026-07-05 · **Status:** design proposal (owner review required before adoption)

## Why

On 2026-07-05 (session `mybd-y7u0` and siblings), making sure a *fresh* agent
would be oriented was not part of any close procedure. It took a human-triggered
question ("will a fresh agent know what to do?") plus manual poking (`bd ready`,
`bd prime` memories, walking the bead link graph) plus fixes (updated the
`upstream-history-rewrite-2026-06` memory in place, created the entry-point bead
`mybd-ufzk`, linked its dependency to `mybd-q1c9`). None of that was mechanized
or prompted; it happened only because a human noticed.

The gap is specifically the **cold** handoff. The existing Session Completion
protocol (AGENTS.md, and the bd SESSION CLOSE PROTOCOL) already covers the
**warm** handoff — step 7 "Hand off: provide context for next session" produces
prose that *someone reads*. A cold start is different: the next actor is an
agent that reads only `bd prime` + `bd ready` and starts pulling work. Prose in a
closed bead or a session summary is invisible to it.

## Core principle: hybrid, not mechanical

The load-bearing step on 2026-07-05 was **judgment** — recognizing that "the
late-May re-root is the one fact a cold agent must know." That is not
mechanizable. A purely mechanical "context captured?" gate would rubber-stamp:
it would pass as long as *some* memory was written, giving false confidence while
missing the fact that actually mattered.

So the design is a **hybrid**: a short judgment checklist the closing agent
self-asks (the real work), backed by a few high-signal mechanical checks that
catch the cheap, common omissions (the backstop). The mechanical part must stay
small; every low-signal check trains agents to ignore the output.

## Part A — Judgment checklist (the real work)

Three self-ask prompts, added to the close protocol. The agent answers them in
prose in the handoff, not just ticks them:

1. **What did this session learn that changes how a future agent works — and is
   it in `bd remember` (so it surfaces at `bd prime`), not only in a report?**
   Reports are not on the cold-start path; memories are.
2. **Is every deliverable/report this session produced reachable from an OPEN
   bead or a memory?** A pointer that lives only in a *closed* bead is a smell —
   a cold agent runs `bd ready`, not `bd list --status=closed`.
3. **Does any bead I touched say "after / gated-on / once X lands" in prose but
   lack a dependency edge?** Prose ordering is invisible to `bd ready`; encode
   it as a dependency or the cold agent will pick blocked work.

These map directly to the three failure modes the 2026-07-05 episode exhibited
(learning stranded in a report; entry point missing; ordering implicit).

## Part B — Mechanical backstop: `scripts/session-close-check`

A warn-not-block script, style-matched to `scripts/verify-status`
(bash + `_tri-lib.sh`, `tri_require bd jq git`). It emits warnings and exits 0 by
default so it never blocks a close; `--strict` returns non-zero for a Stop-hook
that wants a hard gate.

Three checks, each mapping to one judgment prompt:

| # | Check | Warns when | Maps to |
|---|-------|-----------|---------|
| 1 | Unreferenced reports | a new `reports/` file this session is referenced by no OPEN bead and no memory | A.2 |
| 2 | Thin new beads | a bead created this session has an empty/near-empty (<N char) description | A.1 |
| 3 | Left in_progress | a bead is still `in_progress` and was `started`/touched by this session | A.3 (and hygiene) |

Deliberately **excluded** (low signal / high noise): "did you write a memory"
(rubber-stampable), "is the handoff long enough" (unmeasurable), test/lint status
(already covered by step 2 of the existing protocol).

### The hard part: what is "this session"?

A script cannot know what *this session* did unless given a boundary. Do not
guess it — make it explicit and fail loud when absent:

- **Preferred:** a session-start stamp. Have the `bd prime` session-start hook
  (already wired in Claude Code and Codex via `.codex/hooks.json`) write
  `.beads/.session-start` containing the wall-clock time and `git rev-parse HEAD`
  at open. `session-close-check` reads it:
  - new reports: `git diff --name-only <stamp-sha>..HEAD -- reports/` plus
    untracked files under `reports/`;
  - beads created this session: `bd list --json` filtered to
    `created_at >= <stamp-time>`;
  - left in_progress: `bd list --status=in_progress --json` filtered to
    `started_at >= <stamp-time>` (optionally `assignee == current user`).
- **Fallback:** accept `--since <git-ref|RFC3339>`; if neither a stamp nor
  `--since` is present, emit one warning ("no session boundary; pass --since or
  enable the session-start stamp") and skip the session-scoped checks rather than
  silently passing. Honesty over a green checkmark.

A stamp also lets the check work across compaction/`/clear` within one wall-clock
session, which prose-based "this session" cannot.

### Reference prototype (illustrative, not final)

```bash
#!/usr/bin/env bash
# session-close-check - cold-start-readiness backstop (warn, don't block).
#   scripts/session-close-check [--since <ref|timestamp>] [--strict]
set -euo pipefail
. "$(dirname "$0")/_tri-lib.sh"
tri_require bd jq git

strict=0; since=""
while [[ $# -gt 0 ]]; do case "$1" in
  --strict) strict=1; shift;;
  --since)  since="$2"; shift 2;;
  *) tri_die "usage: session-close-check [--since <ref|ts>] [--strict]";;
esac; done

stamp=".beads/.session-start"
[[ -z "$since" && -f "$stamp" ]] && since="$(cut -f1 "$stamp")"   # RFC3339 time
warns=0
warn() { printf 'WARN: %s\n' "$*" >&2; warns=$((warns+1)); }

if [[ -z "$since" ]]; then
  warn "no session boundary (no --since, no $stamp); session-scoped checks skipped"
else
  # 1. new reports not referenced by an open bead or a memory
  #    (git diff since boundary + untracked) X-checked against bd + bd memories
  # 2. beads created since boundary with near-empty description
  # 3. beads in_progress started since boundary
  :   # full implementation per the table above
fi

[[ $warns -gt 0 ]] && echo "session-close-check: $warns warning(s)" >&2 || echo "session-close-check: clean"
[[ $strict -eq 1 && $warns -gt 0 ]] && exit 1 || exit 0
```

The full script is intentionally left for the implementation bead once the owner
decides placement and warn-vs-gate (below), because those decisions change the
exit-code contract and the hook wiring.

## Part C — Placement problem (new finding)

The bead proposes "extend the EXISTING Session Completion protocol (AGENTS.md
step 7)." **That section is a bd-managed block**, not free text:

```
<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->  (AGENTS.md:420)
...  Session Completion, steps 1-7 ...
<!-- END BEADS INTEGRATION -->                                       (AGENTS.md:465)
```

Editing steps 1-7 in place would be overwritten the next time the block is
regenerated. So the extension has to go somewhere durable. Three options:

1. **Upstream template PR** (`internal/templates/agents/defaults/*.md` +
   `internal/recipes/template.go`). Correct if the cold-start step should ship to
   *all* beads users. Heaviest path; couples this to the agent.profile template
   work already in flight (`mybd-44me` / PR gastownhall/beads#4585, still open;
   `mybd-d8q0`). The block here is `profile:minimal`, so any template change must
   respect the profile knob.
2. **mybd-local section outside the managed block** — a "Cold-start handoff"
   subsection in AGENTS.md *below* `END BEADS INTEGRATION`, plus one pointer line
   *inside* step 7 is not possible (managed), so instead reference it from the
   un-managed "Session Completion" prose the coordination repo owns. Lightest;
   keeps the policy local where PROJECT_CHARTER says orchestration policy belongs
   (outside beads core).
3. **A `/session-close` skill** that runs the checklist + script. Most
   discoverable for agents, invocable on demand; still needs the prose to say
   "run it."

**Recommendation:** start with **(2) + (3)** — a mybd-local "Cold-start handoff"
subsection that houses the three judgment prompts and calls
`scripts/session-close-check`, optionally surfaced as a `/session-close` skill.
Defer **(1)** until it is clear the step generalizes beyond this coordination
repo; if it does, upstream it through the profile-aware template path so it
composes with `mybd-44me`/`mybd-d8q0` rather than fighting the managed block.

## Part D — Warn vs gate, and the Stop hook

- **Warn, do not gate, by default.** The judgment step is the real check; a hard
  mechanical gate would either block on false positives (unreferenced report that
  is genuinely throwaway) or get an escape-hatch env var that becomes reflexive.
  Ship `--strict` for anyone who wants CI/hook enforcement, but the default close
  path stays warn.
- **Stop hook: optional, opt-in.** A `Stop` hook that auto-runs
  `session-close-check` is reasonable *as a reminder* (its output reaches the
  agent as feedback), but only in warn mode. Do not wire a blocking Stop hook —
  it would fire on every stop, including mid-task pauses, and train dismissal.
  Model it on the existing opt-in `.githooks/pre-commit` root-guard: tracked,
  documented, enabled by the owner with a single `git config`, not auto-on.

## Part E — Risks

- **Nag fatigue / rubber-stamping.** Mitigated by keeping mechanical checks to
  the three high-signal ones and defaulting to warn. If agents start ignoring the
  output, cut a check rather than adding more.
- **False sense of safety.** The check cannot catch "the agent failed to realize
  X matters" — the exact 2026-07-05 failure mode. The judgment checklist is the
  only defense there; the script is a backstop for the *cheap* misses, and the
  docs must say so explicitly so nobody treats a clean run as "cold-start proven."

## Part F — Decisions needed from maphew

1. Placement: confirm option (2)+(3) (mybd-local section + skill) vs upstream
   template PR now.
2. Session boundary: approve adding a `.beads/.session-start` stamp to the
   `bd prime` session-start hook (vs relying on `--since` only).
3. Stop hook: opt-in warn-only reminder — yes/no.
4. `--strict` exit contract: is there any place we want a hard gate (e.g. a CI
   job), or warn-everywhere?

## Part G — Recommended landing sequence (post-approval)

1. Implement `scripts/session-close-check` (+ `.ps1` wrapper per repo convention)
   with checks 1-3 and the `--since`/stamp boundary — warn default, `--strict`
   opt-in. (Builder-scoped; spec is Part B.)
2. Add the `.beads/.session-start` stamp to the session-start hook.
3. Add the mybd-local "Cold-start handoff" subsection (3 judgment prompts + call
   the script) outside the managed block; optionally a `/session-close` skill.
4. Leave the upstream template PR as a follow-up bead, gated on the outcome of
   `mybd-44me`/PR #4585 so it lands profile-aware.

Steps 1-3 are the minimum viable cold-start check; step 4 is optional
generalization.
