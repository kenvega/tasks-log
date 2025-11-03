#!/usr/bin/env bash
# scripts/update_tasks_completed.sh
set -euo pipefail

METRIC_FILE=".metrics/total_tasks_completed.txt"
mkdir -p .metrics

# ----- get current total (default 0) -----
if [[ -s "$METRIC_FILE" ]]; then
  total=$(<"$METRIC_FILE")
  [[ "$total" =~ ^[0-9]+$ ]] || total=0
else
  total=0
fi

# Count only newly *added* lines that contain "[X]" in staged .md/.txt files.
# - --diff-filter=AM → include only Added/Modified (ignores Renames/Copies)
# - -U0 → zero context so only added lines start with '+'
# - pathspecs → only .md/.txt; exclude anything under .metrics/
added=$(
  git diff --cached --diff-filter=AM -U0 -- \
    "*.md" "*.MD" "*.txt" "*.TXT" ":(exclude).metrics/**" \
  | awk '
      # Skip diff metadata lines
      /^diff --git/ || /^index / || /^--- / || /^\+\+\+ / || /^@@/ { next }
      # Count only added content lines (start with +, but not +++)
      /^\+[^+]/ && index($0, "[X]") > 0 { c++ }
      END { print c+0 }
    '
)

# If nothing matched, exit quietly so other hooks can run
[[ "${added:-0}" -eq 0 ]] && exit 0

new_total=$(( total + added ))
printf '%s\n' "$new_total" > "$METRIC_FILE"
echo "Tasks completed (+[X] lines): $added | New total → $new_total"

# Stage the updated metric file
git add "$METRIC_FILE"
