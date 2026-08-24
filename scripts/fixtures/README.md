# Hook payload fixtures

`codex-pretooluse-shell.json` is a scrubbed capture from Codex CLI 0.149.1 on
2026-08-24, made at the coordination project root by starting
`codex --no-alt-screen -s read-only -a never`, trusting the temporary capture
hook in `/hooks`, then requesting `echo hello-hook-capture`. The temporary hook
command was
`bash -c 'cat > /tmp/codex-pretooluse-payload.json; env | sort > /tmp/codex-hook-env.txt; exit 0'`.
Volatile IDs and paths have stable placeholders; the key names, types, and Bash
command seam are retained.
`claude-pretooluse-bash.json` is
the minimal Claude Code Bash PreToolUse shape supported by the shared adapter.

Guard tests replace only `tool_input.command` and `cwd` as needed. Do not use
these fixtures to infer payload shapes for other tools.
