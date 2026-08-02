#!/usr/bin/env bash
# Print the remaining Amp Free daily quota as one numeric percentage.

set -euo pipefail

if ! usage_output="$(amp usage 2>&1)"; then
  printf 'quota-watch: amp usage failed: %s\n' "$usage_output" >&2
  exit 1
fi

percent="$({
  printf '%s\n' "$usage_output" |
    sed -nE 's/^Amp Free: ([0-9]+([.][0-9]+)?)% remaining.*/\1/p' |
    head -1
} || true)"

case "$percent" in
  ''|*[!0-9.]*)
    printf 'quota-watch: could not parse Amp Free percentage from amp usage output\n' >&2
    exit 1
    ;;
esac

printf '%s\n' "$percent"
