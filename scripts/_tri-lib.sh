# shellcheck shell=bash
# _tri-lib.sh — shared helpers for tri-* scripts.
#
# Source from script: . "$(dirname "$0")/_tri-lib.sh"

TRI_UPSTREAM="${TRI_UPSTREAM:-gastownhall/beads}"
TRI_WORKTREE_BASE="${TRI_WORKTREE_BASE:-$HOME/dev/mybd-tri}"
TRI_PROJECT_ROOT="${TRI_PROJECT_ROOT:-$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null)}"
TRI_BD_MAIN="${TRI_BD_MAIN:-$TRI_PROJECT_ROOT/bd-main}"
TRI_REVIEWS_DIR="${TRI_REVIEWS_DIR:-$TRI_PROJECT_ROOT/_working_on/pr-reviews}"

TRI_POST_MAX_WORDS="${TRI_POST_MAX_WORDS:-150}"

tri_die() { echo "${0##*/}: $*" >&2; exit 1; }

# Confirmation gate for posting agent-authored TEXT to upstream GitHub.
# Mirroring, labels, and local reports run freely; text posts require a human
# at a terminal. Confirmation is read from /dev/tty specifically so that
# unattended agents (no controlling terminal) cannot pass the gate.
# TRI_ALLOW_UNATTENDED_POST=1 is the deliberate, owner-only escape hatch.
tri_confirm_post() {
  local body_file="$1" target="$2"
  if [[ "${TRI_ALLOW_UNATTENDED_POST:-}" == "1" ]]; then
    echo "TRI_ALLOW_UNATTENDED_POST=1 — skipping interactive confirmation" >&2
    return 0
  fi
  # -r/-w /dev/tty pass even with no controlling terminal; actually open it.
  if ! { : </dev/tty; } 2>/dev/null; then
    tri_die "posting text to $target requires an interactive terminal.
Agents: leave the distilled post file in place and hand off to a human.
Humans automating deliberately: TRI_ALLOW_UNATTENDED_POST=1"
  fi
  {
    echo
    echo "── Exact body that will be posted to $target ──"
    cat "$body_file"
    echo "── end body ──"
    printf 'Post this? Type "post" to confirm, anything else aborts: '
  } >/dev/tty
  local answer=""
  IFS= read -r answer </dev/tty || true
  [[ "$answer" == "post" ]] || tri_die "not confirmed — nothing posted"
}

# True (exit 0) iff the body has non-whitespace content OUTSIDE HTML comment
# blocks. Line-prefix checks are not enough: the tri-review post scaffold is a
# multi-line <!-- ... --> whose interior lines look like content.
tri_body_has_content() {
  awk '
    {
      line = $0
      while (1) {
        if (!inc) {
          s = index(line, "<!--")
          if (s) {
            if (substr(line, 1, s - 1) ~ /[^ \t]/) found = 1
            line = substr(line, s + 4); inc = 1
          } else {
            if (line ~ /[^ \t]/) found = 1
            break
          }
        } else {
          e = index(line, "-->")
          if (e) { line = substr(line, e + 3); inc = 0 } else break
        }
      }
    }
    END { exit(found ? 0 : 1) }
  ' "$1"
}

# Stdin filter: drop HTML comment spans, keeping text before/after them.
tri_strip_html_comments() {
  awk '
    {
      line = $0; out = ""
      while (1) {
        if (!inc) {
          s = index(line, "<!--")
          if (s) { out = out substr(line, 1, s - 1); line = substr(line, s + 4); inc = 1 }
          else { out = out line; break }
        } else {
          e = index(line, "-->")
          if (e) { line = substr(line, e + 3); inc = 0 } else break
        }
      }
      print out
    }
  '
}

# Count the words of a GitHub-facing body, excluding fenced code blocks and
# HTML comments (invisible on GitHub), and fail if over budget. Prints the
# count on success. An unterminated fence would silently exclude everything
# after it, so refuse it instead of undercounting.
tri_word_budget() {
  local body_file="$1" max_words="$2"
  local fences words
  fences="$(grep -cE '^[[:space:]]*(```|~~~)' "$body_file" || true)"
  if (( ${fences:-0} % 2 != 0 )); then
    tri_die "unterminated code fence in $body_file - close it before posting"
  fi
  words="$(awk '/^[[:space:]]*(```|~~~)/{in_code=!in_code; next} !in_code' "$body_file" \
    | tri_strip_html_comments | wc -w)"
  if (( words > max_words )); then
    tri_die "body is $words words, budget is $max_words: $body_file
Keep only what changes the maintainer's action: verdict plus top findings.
The full analysis stays in the local review note, not the upstream post."
  fi
  echo "$words"
}

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

# Review note path for PR number (full local analysis, never posted).
tri_review_note_path() { printf '%s/%s.md\n' "$TRI_REVIEWS_DIR" "$1"; }

# Distilled upstream post path for PR number (the ONLY file tri-submit posts).
tri_post_note_path() { printf '%s/%s.post.md\n' "$TRI_REVIEWS_DIR" "$1"; }

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
#   mybd-XXX.N[.M...]  → child/grandchild ids (dotted numeric suffix)
#   #NNNN  / NNNN      → searches bd by external_ref gh-pr-NNNN
tri_resolve_bd_id() {
  local input="$1"
  if [[ "$input" =~ ^mybd-[a-z0-9]+(\.[0-9]+)*$ ]]; then
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

# Lint a Markdown body before posting it to GitHub. This catches the two
# recurring shell-handoff mistakes that GitHub will render badly.
tri_lint_gh_body() {
  local body_file="$1"
  [[ -f "$body_file" ]] || tri_die "GitHub body file not found: $body_file"

  local failed=0
  if grep -nF '\n' "$body_file" >&2; then
    echo "GitHub body contains literal \\n sequences; write real newlines and use --body-file" >&2
    failed=1
  fi
  if grep -nE '(^|[^[:alnum:]_])GH#[0-9]+' "$body_file" >&2; then
    echo "GitHub body contains GH# refs; use #1234 or owner/repo#1234 for GitHub autolinks" >&2
    failed=1
  fi
  [[ "$failed" == 0 ]] || tri_die "GitHub body lint failed: $body_file"
}

# Normalize safe GitHub body patterns in-place. This intentionally only changes
# same-repo shorthand refs; literal \n needs a human/template fix.
tri_normalize_gh_body() {
  local body_file="$1"
  [[ -f "$body_file" ]] || tri_die "GitHub body file not found: $body_file"
  perl -0pi -e 's/(^|[^[:alnum:]_])GH#([0-9]+)/$1#$2/g' "$body_file"
}
