#!/usr/bin/env bash
# Shared PreToolUse payload adapter for Claude Code and Codex CLI Bash hooks.
#
# Call hook_payload_extract with the complete JSON document on stdin captured in
# an argument.  On success, it sets HOOK_PAYLOAD_COMMAND and
# HOOK_PAYLOAD_CWD.  It deliberately accepts only a string command: coercing
# an array or object to JSON would change shell quoting semantics.
#
# Return values: 0 accepted Bash PreToolUse; 1 unknown Bash PreToolUse shape;
# 2 a known non-Bash tool (silently irrelevant to these shell guards).
hook_payload_extract() {
  local input="$1" event tool command cwd
  HOOK_PAYLOAD_COMMAND=""
  HOOK_PAYLOAD_CWD=""

  # Malformed JSON and non-object payloads are unknown, not non-Bash. Treating
  # a missing tool name as an unrelated tool would recreate the silent
  # fail-open this adapter exists to expose.
  jq -e 'type == "object"' <<<"$input" >/dev/null 2>&1 || return 1
  event="$(jq -r 'if (.hook_event_name | type) == "string" then .hook_event_name else empty end' <<<"$input" 2>/dev/null)"
  tool="$(jq -r 'if (.tool_name | type) == "string" then .tool_name else empty end' <<<"$input" 2>/dev/null)"

  # Older Claude-side tests and standalone callers supplied only tool_input.
  # Preserve that accepted seam when both metadata fields are absent, while
  # treating a partially populated or non-string command as schema drift.
  if [[ -z "$tool" && -z "$event" ]]; then
    command="$(jq -er '.tool_input | select(type == "object") | .command | select(type == "string")' <<<"$input" 2>/dev/null)" || return 1
    cwd="$(jq -r 'if (.cwd | type) == "string" then .cwd else empty end' <<<"$input" 2>/dev/null)"
    HOOK_PAYLOAD_COMMAND="$command"
    HOOK_PAYLOAD_CWD="$cwd"
    return 0
  fi

  # Hooks are filtered by Bash in both clients.  Do not make unrelated tools
  # noisy merely because this adapter does not understand their input schema.
  [[ -n "$tool" ]] || return 1
  if [[ "$tool" != "Bash" ]]; then
    # An unfamiliar tool carrying a shell command is schema drift, not an
    # unrelated read/edit tool. Make a vendor rename or command-shape change
    # visible. Only a tool_input object with no command key is known to be
    # irrelevant to these shell guards.
    jq -e '.tool_input | (type != "object") or has("command")' \
      <<<"$input" >/dev/null 2>&1 && return 1
    return 2
  fi
  [[ "$event" == "PreToolUse" ]] || return 1

  command="$(jq -er '.tool_input | select(type == "object") | .command | select(type == "string")' <<<"$input" 2>/dev/null)" || return 1
  cwd="$(jq -r 'if (.cwd | type) == "string" then .cwd else empty end' <<<"$input" 2>/dev/null)"
  HOOK_PAYLOAD_COMMAND="$command"
  HOOK_PAYLOAD_CWD="$cwd"
}
