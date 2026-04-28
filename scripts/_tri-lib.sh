# shellcheck shell=bash
# _tri-lib.sh — shared helpers for tri-* scripts.
#
# Source from script: . "$(dirname "$0")/_tri-lib.sh"

TRI_UPSTREAM="${TRI_UPSTREAM:-gastownhall/beads}"
TRI_WORKTREE_BASE="${TRI_WORKTREE_BASE:-$HOME/dev/mybd-tri}"
TRI_PROJECT_ROOT="${TRI_PROJECT_ROOT:-$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null)}"
TRI_BD_MAIN="${TRI_BD_MAIN:-$TRI_PROJECT_ROOT/bd-main}"
TRI_REVIEWS_DIR="${TRI_REVIEWS_DIR:-$TRI_PROJECT_ROOT/_working_on/pr-reviews}"

tri_die() { echo "${0##*/}: $*" >&2; exit 1; }

tri_require() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null || tri_die "$cmd not on PATH"
  done
}

# Returns the bd issue's external_ref (e.g., gh-pr-3482), or empty string.
tri_external_ref() {
  local bd_id="$1"
  bd show "$bd_id" --json 2>/dev/null | jq -r '.[0].external_ref // empty'
}

# Parses a gh-(pr|iss)-NNNN ref into "kind num" (e.g., "pr 3482"). Returns 1 if not matched.
tri_parse_ref() {
  local ref="$1"
  if [[ "$ref" =~ ^gh-(pr|iss)-([0-9]+)$ ]]; then
    echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
}

# Worktree path for PR number.
tri_worktree_path() { printf '%s/%s\n' "$TRI_WORKTREE_BASE" "$1"; }

# Review note path for PR number.
tri_review_note_path() { printf '%s/%s.md\n' "$TRI_REVIEWS_DIR" "$1"; }

# Branch name convention.
tri_branch_name() { printf 'pr-%s-review\n' "$1"; }

# Append a timestamped + machine-tagged note to a bd issue.
tri_log_note() {
  local bd_id="$1" msg="$2"
  local stamp host
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  host="$(hostname -s 2>/dev/null || echo unknown)"
  bd update "$bd_id" --append-notes="[$stamp $host] $msg" >/dev/null
}

# Resolve a bd-id (or short pr num) to a bd-id. Accepts:
#   mybd-XXX           → as-is (validated by bd show)
#   #NNNN  / NNNN      → searches bd by external_ref gh-pr-NNNN
tri_resolve_bd_id() {
  local input="$1"
  if [[ "$input" =~ ^mybd-[a-z0-9]+$ ]]; then
    echo "$input"
    return 0
  fi
  local num="${input#\#}"
  if [[ "$num" =~ ^[0-9]+$ ]]; then
    local id
    id="$(bd list --limit 0 --json 2>/dev/null \
      | jq -r --arg ref "gh-pr-$num" '.[] | select(.external_ref == $ref) | .id' \
      | head -n1)"
    [[ -n "$id" ]] || tri_die "no bd issue with external_ref=gh-pr-$num"
    echo "$id"
    return 0
  fi
  tri_die "unrecognized id: $input (expected mybd-XXX or PR number)"
}

# Print a formatted line of "key: value" diagnostics, padded.
tri_kv() { printf '  %-22s %s\n' "$1:" "$2"; }
