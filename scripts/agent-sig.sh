#!/usr/bin/env bash
# agent-sig [runtime] [--trailer]
#
# Emit the agent signature defined in AGENTS.md "Signing":
#   comment form:  _{runtime}-{model}-{reasoning} on behalf of {user}_
#   trailer form:  Agent-Signature: {runtime}-{model}-{reasoning} on behalf of {user}
#
# Reads live session metadata only; never guesses from defaults, prompts, or
# memory. Unknown fields become unknown-model / unknown-reasoning.
#
# Runtime detection: claude (CLAUDE_CODE_SESSION_ID set), codex (CODEX_HOME or
# CODEX_THREAD_ID set), amp (AMP_CURRENT_THREAD_ID set). Other runtimes pass
# their name as $1, e.g. `agent-sig kilocode`. Runtimes whose metadata this
# script cannot read may supply AGENT_MODEL / AGENT_REASONING env vars.
set -euo pipefail

form=comment
runtime="${AGENT_RUNTIME:-}"
for a in "$@"; do
  case "$a" in
    --trailer) form=trailer ;;
    *) runtime="$a" ;;
  esac
done

if [ -z "$runtime" ]; then
  if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
    runtime=claude
  elif [ -n "${CODEX_THREAD_ID:-}" ] || [ -n "${CODEX_HOME:-}" ]; then
    runtime=codex
  elif [ -n "${AMP_CURRENT_THREAD_ID:-}" ]; then
    runtime=amp
  else
    runtime=unknown-runtime
  fi
fi

model="${AGENT_MODEL:-}"
effort="${AGENT_REASONING:-}"

case "$runtime" in
  claude)
    # Model is recorded per assistant message in the session transcript JSONL;
    # there is no model env var. The model id carries the family prefix
    # (claude-fable-5, claude-opus-4-7); strip it since runtime is already
    # "claude". CLAUDE_EFFORT tracks /effort; under Fable's `auto` it may
    # report a resolved level rather than the literal "auto" - sign as-is.
    if [ -z "$model" ] && [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
      # Locate the transcript by its globally-unique session id. Claude Code
      # stores it under a project dir derived from the launch cwd; rebuilding
      # that path from $(pwd) breaks when agent-sig runs from a worktree or a
      # subdirectory, so glob across every project dir and take the newest.
      f=$(ls -t "$HOME"/.claude/projects/*/"$CLAUDE_CODE_SESSION_ID".jsonl 2>/dev/null | head -1 || true)
      if [ -n "$f" ] && [ -r "$f" ]; then
        # Last real assistant-message model. Skip "<synthetic>" (interrupt and
        # placeholder messages); it can be the final entry right after a user
        # interrupt and would otherwise win.
        model=$(jq -r 'select(.message.model and .message.model != "<synthetic>") | .message.model' "$f" 2>/dev/null | tail -1 || true)
        model=${model#claude-}
      fi
    fi
    effort="${effort:-${CLAUDE_EFFORT:-}}"
    ;;
  codex)
    # Prefer the live thread id when available. On Windows, Codex stores cwd in
    # extended form (\\?\A:\path) while Git Bash reports /a/path, so cwd-only
    # matching misses active sessions.
    db="${CODEX_HOME:-$HOME/.codex}/state_5.sqlite"
    if [ -z "$model" ] && [ -f "$db" ]; then
      row=""
      if [ -n "${CODEX_THREAD_ID:-}" ]; then
        thread_id_sql=${CODEX_THREAD_ID//\'/\'\'}
        row=$(sqlite3 -separator '|' "$db" \
          "select coalesce(model,''), coalesce(reasoning_effort,'') from threads where id='$thread_id_sql' limit 1;" 2>/dev/null || true)
      fi
      if [ -z "$row" ]; then
        cwd_sql=$(pwd)
        cwd_sql=${cwd_sql//\'/\'\'}
        row=$(sqlite3 -separator '|' "$db" \
          "select coalesce(model,''), coalesce(reasoning_effort,'') from threads where cwd='$cwd_sql' order by updated_at desc limit 1;" 2>/dev/null || true)
      fi
      model="${row%%|*}"
      [ "$row" != "$model" ] && effort="${effort:-${row#*|}}"
    fi
    ;;
  amp)
    # Amp writes per-thread transcripts to ~/.local/share/amp/threads/ and
    # per-turn agent_state lines (reasoningEffort, agentMode) to the CLI log.
    # The active thread id is exported as AMP_CURRENT_THREAD_ID; until the
    # in-progress thread is flushed to disk, fall back to the newest thread
    # file. Drop only the claude- model-family prefix (sign opus-4-6, not
    # claude-opus-4-6); runtime is already "amp".
    tid="${AMP_CURRENT_THREAD_ID:-}"
    threads="$HOME/.local/share/amp/threads"
    src=""
    [ -n "$tid" ] && [ -f "$threads/$tid.json" ] && src="$threads/$tid.json"
    [ -z "$src" ] && src=$(ls -t "$threads"/*.json 2>/dev/null | head -1 || true)
    if [ -z "$model" ] && [ -n "$src" ] && [ -r "$src" ]; then
      model=$(jq -r '[.messages[]?.usage?.model // empty] | last // empty' "$src" 2>/dev/null || true)
      model=${model#claude-}
    fi
    if [ -z "$effort" ]; then
      # Amp's effort knob is agentMode (smart/low/rush); builds before
      # ~2026-08 called it reasoningEffort. Prefer the per-message value in
      # the thread transcript, then the CLI log's per-turn agent_state line,
      # then the session-level default.
      if [ -n "$src" ] && [ -r "$src" ]; then
        effort=$(jq -r '([.messages[]?.agentMode // empty] | last) // .agentMode // empty' "$src" 2>/dev/null || true)
      fi
      if [ -z "$effort" ] && [ -n "$tid" ] && [ -r "$HOME/.cache/amp/logs/cli.log" ]; then
        line=$(grep -F "\"threadId\":\"$tid\"" "$HOME/.cache/amp/logs/cli.log" 2>/dev/null \
          | grep -E '"(reasoningEffort|agentMode)"' | tail -1 || true)
        [ -n "$line" ] && effort=$(printf '%s' "$line" \
          | jq -r '.reasoningEffort // .agentMode // empty' 2>/dev/null || true)
      fi
      if [ -z "$effort" ]; then
        effort=$(jq -r '.agentMode // (.lastReasoningEffortByMode[.agentMode // "smart"]) // empty' \
          "$HOME/.local/share/amp/session.json" 2>/dev/null || true)
      fi
    fi
    ;;
esac

user=$(git config user.name 2>/dev/null || true)

# Surface unresolved fields loudly so a placeholder signature can't ride out
# silently onto a commit or comment. The common Windows cause is invoking this
# via the PowerShell tool, whose subprocess environment lacks CLAUDE_EFFORT (and
# bash spawned from it inherits that gap); run it via the Bash tool / Git Bash,
# or pass AGENT_MODEL / AGENT_REASONING explicitly.
if [ -z "${model:-}" ] || [ -z "${effort:-}" ]; then
  {
    printf 'agent-sig: warning: unresolved'
    [ -z "${model:-}" ] && printf ' model'
    [ -z "${effort:-}" ] && printf ' reasoning'
    printf ' - signature uses placeholder(s).\n'
    printf 'agent-sig: run via the Bash tool / Git Bash (not the PowerShell tool, whose env lacks CLAUDE_EFFORT), or set AGENT_MODEL / AGENT_REASONING.\n'
  } >&2
fi

sig="${runtime}-${model:-unknown-model}-${effort:-unknown-reasoning} on behalf of ${user:-$(whoami)}"

if [ "$form" = trailer ]; then
  printf 'Agent-Signature: %s\n' "$sig"
else
  printf '_%s_\n' "$sig"
fi
