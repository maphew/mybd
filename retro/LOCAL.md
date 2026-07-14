# LOCAL.md — mybd adaptation of the retro playbook

This repo (maphew/mybd, **public**) is the coordination home for the
cross-project retro campaign: the shared `findings.md` lives here even when
the sessions under review belong to other projects. Redaction rules from
PLAYBOOK.md apply with extra force — the repo is public.

## Campaign inventory (as of 2026-07-14, this machine)

| Scope | Substantive sessions | Notes |
|---|---|---|
| mybd × Claude Code | 15 of 19 (≥100 KB) | seeded in `ledger.tsv` |
| fauxcasa × Claude Code | ~23 (127 MB store) | seed when campaign starts |
| agentsview, mdo, oracle-batch3 × Claude Code | ~12 | " |
| all × Amp | 269 of 386 threads ≥ 8 msgs | " |
| all × Codex (interactive `codex-tui`/`cli` only) | TBD — most of the 452 rollouts are `codex_exec` delegate runs | " |

≈ 12+ rounds of 5 for Claude Code alone. Expect stop-rule 1 or 2 to fire
well before exhaustion — that is the design, not a failure.

## Inventory / strip recipes (verified 2026-07-14)

Claude Code — seed ledger rows for a project store:

```bash
STORE=~/.claude/projects/-var-home-matt-dev-mybd   # slug = cwd with / → -
for f in "$STORE"/*.jsonl; do
  id=$(basename "$f" .jsonl)
  start=$(jq -r 'select(.timestamp != null) | .timestamp' "$f" 2>/dev/null | head -1)
  kb=$(( $(stat -c%s "$f") / 1024 ))
  printf 'mybd\tclaude-code\t%s\t%s\t%s\tpending\t\t\n' "$id" "${start:0:10}" "$kb"
done >> ledger.tsv
```

Claude Code — strip a transcript (1.5 MB → 88 KB ≈ 22 k tokens, measured):

```bash
jq -c '
  select(.type=="user" or .type=="assistant" or .type=="system") |
  if .type=="user" then
    {t:"u", ts:.timestamp,
     txt: (if (.message.content|type)=="string" then .message.content
           else ([.message.content[]? | select(.type=="text") | .text] | join("\n")) end | .[0:2500]),
     err: [.message.content | if type=="string" then empty
           else .[]? | select(.type=="tool_result" and (.is_error==true)) | ((.content|tostring)[0:300]) end]}
  elif .type=="assistant" then
    {t:"a", ts:.timestamp, m:.message.model, out:.message.usage.output_tokens,
     txt: ([.message.content[]? | select(.type=="text") | .text] | join("\n") | .[0:1500]),
     tools: [.message.content[]? | select(.type=="tool_use") | (.name + ":" + ((.input|tostring)[0:120]))]}
  else
    {t:"s", ts:.timestamp, s: ((.content // (.message|tostring) // "")[0:250])}
  end' "$SESSION.jsonl" > digests/work/"$ID".stripped.jsonl
```

Codex — classify rollouts (only `codex-tui` + `cli` are retro units):

```bash
find ~/.codex/sessions -name '*.jsonl' | while read -r f; do
  head -1 "$f" | jq -r --arg f "$f" \
    '.payload | "\(.originator)/\(if (.source|type)=="string" then .source else "subagent" end)\t\($f)"'
done | grep '^codex-tui/cli' | cut -f2
```

Amp — thread inventory: `jq '{id, msgs:(.messages|length), title}' ~/.local/share/amp/threads/T-*.json`
(strip = keep `role`, text content, `usage.model`; drop tool payloads).

## Execution wiring (this repo's rules apply)

- **Track rounds in bd.** Epic + one open "run retro round N" task at all
  times — that keeps the campaign on the `bd ready` cold-start path. Close
  round N's bead and open round N+1's at session close.
- **Digest agents (Phase 2b):** Claude `haiku`/low effort, or
  `scripts/codex-agent scout -o digests/<name>.md "<rubric + stripped file path>" </dev/null`
  for quota relief (Codex tokens bypass `budget.spent()` — log each call).
  The 5 digests may run in parallel: read-only inputs, disjoint outputs, no
  bd/dolt involvement. Everything touching bd stays serial.
- **Synthesis (Phase 3):** stays in the orchestrator session (smart tier) —
  it is judgment work over ~15 k tokens; delegating it wastes more than it saves.
- **Workflow tool:** pre-authorized here (AGENTS.md standing opt-in). A round
  fits `pipeline(batch, strip→digest)` with a barrier before synthesis.
  Default budget +200 k self-enforced.
- **Commits:** from a worktree under `.worktrees/mybd/`, ff-merge to main,
  standard Agent-Signature trailer, push (team-maintainer profile). Track
  `findings.md`, `batches/`, `ledger.tsv`, playbook/LOCAL edits. Never track
  `digests/` (see `.gitignore`) — transcript quotes stay local.
- **Session close:** `/session-close` as usual; the round's batch report is
  the deliverable and must be reachable from the open round-N+1 bead.

## Round entry point (paste into a fresh session here)

> Run one retrospective round per `retro/PLAYBOOK.md` + `retro/LOCAL.md`:
> claim the open retro bead, take the next 5 pending ledger rows, strip +
> digest (cheap tier / codex scout), synthesize into `retro/findings.md` and
> `retro/batches/round-NN.md` in-session, promote anything actionable, update
> the ledger, close per repo protocol, and open the next round's bead.
