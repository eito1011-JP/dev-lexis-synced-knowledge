#!/usr/bin/env bash
set -euo pipefail

SUMMARY_FILE="${1:-SUMMARY.md}"

if [[ ! -f "$SUMMARY_FILE" ]]; then
  echo "ERROR: $SUMMARY_FILE not found"
  exit 1
fi

BASE_DIR="$(cd "$(dirname "$SUMMARY_FILE")" && pwd)"

errors=()

while IFS= read -r line; do
  path=$(echo "$line" | sed -n 's/.*](\([^)]*\)).*/\1/p')
  [[ -z "$path" || "$path" != */ ]] && continue
  [[ "$path" =~ ^https?:// ]] && continue
  dir="${BASE_DIR}/${path%/}"
  if [[ ! -d "$dir" ]]; then
    errors+=("${path%/}/ (directory not found)")
  else
    md_count=$(find "$dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    subdir_count=$(find "$dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$md_count" -eq 0 && "$subdir_count" -eq 0 ]]; then
      errors+=("${path%/}/ (no .md files or subdirectories in category)")
    fi
  fi
done < "$SUMMARY_FILE"

if [[ ${#errors[@]} -gt 0 ]]; then
  echo "ERROR: Ghost categories detected in $SUMMARY_FILE"
  echo ""
  for err in "${errors[@]}"; do
    echo "  - $err"
  done
  echo ""
  echo "Each category in SUMMARY.md must have a corresponding directory"
  echo "with at least one tracked file. Git cannot track empty directories."
  echo ""
  echo "To fix: add at least one .md document to each category, or remove"
  echo "the empty category from SUMMARY.md."
  exit 1
fi

echo "All categories in $SUMMARY_FILE have valid directories."