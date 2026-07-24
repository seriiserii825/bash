#!/usr/bin/env bash
# Interactive JSON path picker: browse a JSON file of any nesting depth via fzf
# (objects and arrays) and resolve the selected field to a dot-notation path,
# printed to stdout and copied to the clipboard.
# Usage: bash-scripts/parse-json.sh [file.json]
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Required: $1"; exit 1; }; }
need jq
need fzf

quit() { echo "Exit."; exit 0; }

# Numbers each incoming line as "N) text" for menu display.
number_lines() { awk '{printf "%d) %s\n", NR, $0}'; }

copy_to_clipboard() {
  if command -v xclip >/dev/null 2>&1; then printf '%s' "$1" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then printf '%s' "$1" | xsel -b -i
  else echo "Install xclip or xsel" >&2; return 1
  fi
}

# ── 1. SELECT FILE ────────────────────────────────────────────────────────────
if [[ $# -ge 1 ]]; then
  FILE="$1"
else
  FILE="$(find . -type f -name '*.json' \
    | fzf --select-1 --exit-0 \
          --prompt='Select JSON file: ' \
          --height=40% --layout=reverse --border \
          --preview='head -n 120 {}' --preview-window=up:70%)"
fi

[ -z "${FILE:-}" ] && { echo "No file selected"; exit 1; }
[ ! -f "$FILE" ] && { echo "Not a file: $FILE"; exit 1; }
jq empty "$FILE" 2>/dev/null || { echo "❌ Invalid JSON: $FILE"; exit 1; }

# ── 2. NAVIGATE ───────────────────────────────────────────────────────────────
JQ_CUR="."
PATH_CUR=""
STACK=()

while true; do
  NODE_TYPE="$(jq -r "($JQ_CUR) | type" "$FILE")"

  CHILDREN=()
  if [ "$NODE_TYPE" = "object" ]; then
    while IFS= read -r k; do CHILDREN+=("$k"); done \
      < <(jq -r "($JQ_CUR) | keys_unsorted[]" "$FILE")
  elif [ "$NODE_TYPE" = "array" ]; then
    ELEM_TYPE="$(jq -r "($JQ_CUR) | if length>0 then .[0] | type else \"empty\" end" "$FILE")"
    if [ "$ELEM_TYPE" = "object" ]; then
      # Unique child keys across all elements, preserving first-seen order.
      while IFS= read -r k; do CHILDREN+=("$k"); done \
        < <(jq -r "($JQ_CUR) | [.[] | keys_unsorted[]] | reduce .[] as \$k ([]; if index(\$k) then . else . + [\$k] end) | .[]" "$FILE")
    fi
  fi

  ITEMS=("✅  Select this path: ${PATH_CUR:-<root>}" "🚪  Exit")
  [ "${#STACK[@]}" -gt 0 ] && ITEMS+=("⬅️  Back")
  ITEMS+=("${CHILDREN[@]}")

  CHOICE=$(printf '%s\n' "${ITEMS[@]}" \
    | number_lines \
    | fzf --height=70% --reverse --no-info \
          --header="📄 ${PATH_CUR:-<root>}" \
          --preview="jq '($JQ_CUR)' '$FILE' | head -c 2000" \
          --preview-window=right,50%) || quit
  CHOICE="${CHOICE#*) }"

  case "$CHOICE" in
    "✅"*)
      break
      ;;
    "🚪"*)
      quit
      ;;
    "⬅️"*)
      IFS=$'\t' read -r JQ_CUR PATH_CUR <<< "${STACK[-1]}"
      unset 'STACK[-1]'
      ;;
    *)
      STACK+=("$JQ_CUR"$'\t'"$PATH_CUR")
      if [ "$NODE_TYPE" = "array" ]; then
        JQ_CUR="($JQ_CUR) | map(select(has(\"$CHOICE\"))) | .[0].\"$CHOICE\""
      else
        JQ_CUR="($JQ_CUR).\"$CHOICE\""
      fi
      PATH_CUR="${PATH_CUR:+$PATH_CUR.}$CHOICE"
      ;;
  esac
done

[ -n "${PATH_CUR:-}" ] || quit

# ── 3. OUTPUT ──────────────────────────────────────────────────────────────
echo "$PATH_CUR"
copy_to_clipboard "$PATH_CUR" && echo "📋 Copied to clipboard" >&2
