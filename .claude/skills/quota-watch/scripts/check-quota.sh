#!/bin/bash
# Extracts Amp Free quota as: remaining total percent
# Output is one line, machine-friendly, minimal tokens.
# Example: 3.74 20 18
amp usage 2>/dev/null | grep -oP 'Amp Free: \$\K[\d.]+/\$[\d.]+' | head -1 | awk -F'/\\$' '{
  r=$1; t=$2
  pct=int(r/t*100+0.5)
  printf "%.2f %.2f %d\n", r, t, pct
}'
