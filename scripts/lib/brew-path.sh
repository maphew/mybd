#!/usr/bin/env bash
# Shared PATH repair for agent shells (bead mybd-zvups).
#
# Bluefin's /etc/profile.d/brew.sh (image 44.20260901+) adds linuxbrew to
# PATH only when the shell is interactive ($- contains i). Claude Code shell
# snapshots, `codex exec`, hooks and ssh BatchMode shells are not, so gh,
# dolt and codex silently vanished and scripts/pr-review-gate stood down at
# its `command -v codex` check. Sourcing this file appends the brew bin dirs
# (system bins keep precedence, matching brew.sh) so every script that needs
# those tools sees the same PATH an interactive shell would.
#
# MYBD_BREW_PREFIX overrides the prefix. It can only ADD a directory, never
# remove one, so it is not a gate bypass: a bogus prefix on a host whose
# PATH already has codex changes nothing, and on a host without codex it
# leaves the gate's loud-fail path in charge.
mybd_ensure_brew_path() {
  local prefix="${MYBD_BREW_PREFIX:-/home/linuxbrew/.linuxbrew}" d
  for d in "$prefix/bin" "$prefix/sbin"; do
    [[ -d "$d" ]] || continue
    case ":$PATH:" in
      *":$d:"*) ;;
      *) PATH="$PATH:$d" ;;
    esac
  done
  export PATH
}
mybd_ensure_brew_path
