#!/usr/bin/env bash
# ACF field path picker: flattens an exported ACF JSON file (array of field
# groups, each with a "fields" array, fields nesting via "sub_fields") into
# every field's dot-notation path built from its actual "name" value — not the
# JSON schema keys — lets you fuzzy-search all of them at once via fzf, then
# prints the selected path(s) and copies them to the clipboard.
# Usage: bash-scripts/parse-json.sh [file.json]
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Required: $1"; exit 1; }; }
need jq
need fzf

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/libs/fzf-multiselect.sh"

copy_to_clipboard() {
  if command -v xclip >/dev/null 2>&1; then printf '%s' "$1" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then printf '%s' "$1" | xsel -b -i
  else echo "Install xclip or xsel" >&2; return 1
  fi
}

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "parse-json.sh" "$1"
  return 0
}

select_file() {
  local files
  files="$(find . -type f -name '*.json')"
  { echo "🚪  Exit"; [ -n "$files" ] && printf '%s\n' "$files"; } \
    | fzf --select-1 --exit-0 \
          --prompt='Select JSON file: ' \
          --height=90% --layout=reverse --border \
          --preview='[ -f {} ] && head -n 120 {}' --preview-window=up:40%
}

# Root is either an array of field groups (standard ACF export — use group [0])
# or a bare object with a "fields" array. Each field's path segment is its own
# "name" value (falling back to "label" for nameless fields like tabs) — never
# the generic schema key — so distinct fields sharing the same JSON shape
# (key/label/name/type/...) each show up once under their real name, and
# recursion follows "sub_fields" to build the full dotted path.
JQ_PROGRAM='
def acf_name(f):
  (f.name // "") as $n
  | if ($n | length) > 0 then $n else (f.label // "field") end;

def walk(fields; path):
  fields[] as $f
  | (acf_name($f)) as $seg
  | (path + [$seg]) as $newpath
  | ( ($newpath | join(".")) + " │ " + ($f.label // "") + " (" + ($f.type // "?") + ")" ),
    ( ($f.sub_fields // []) as $sub
      | if ($sub | length) > 0 then walk($sub; $newpath) else empty end
    );

(if type == "array" then .[0].fields else .fields end) as $root_fields
| walk($root_fields // []; [])
'

CLI_FILE="${1:-}"

# ── OUTER LOOP: file selection (⬅️ Back returns here to pick another file) ────
while true; do
  if [ -n "$CLI_FILE" ]; then
    FILE="$CLI_FILE"
  else
    FILE="$(select_file)"
  fi

  [ -z "${FILE:-}" ] && { echo "Exit."; exit 0; }
  [[ "$FILE" == "🚪"* ]] && { echo "Exit."; exit 0; }
  [ ! -f "$FILE" ] && { echo "Not a file: $FILE"; exit 1; }
  jq empty "$FILE" 2>/dev/null || { echo "❌ Invalid JSON: $FILE"; exit 1; }

  CLEAN_FILE="${FILE#./}"

  ALL_PATHS="$(jq -r "$JQ_PROGRAM" "$FILE")"
  [ -n "$ALL_PATHS" ] || { echo "No fields found in $FILE"; exit 1; }

  ITEMS=$'⬅️  Back (choose another file)\n🚪  Exit\n'"$ALL_PATHS"

  DO_EXIT=false
  DO_BACK=false

  # ── INNER LOOP: pick field path(s), repeat until Back/Exit/empty Enter ─────
  while true; do
    SELECTED=$(printf '%s\n' "$ITEMS" \
      | fzf_multiselect --height=90% --reverse \
            --prompt="Select field path(s) > " \
            --header="$FILE  |  Enter with nothing selected to exit")

    [ -n "$SELECTED" ] || { echo "Exit."; DO_EXIT=true; break; }

    PATHS=()
    while IFS= read -r line; do
      case "$line" in
        "⬅️"*) DO_BACK=true ;;
        "🚪"*) DO_EXIT=true ;;
        *) [ -n "$line" ] && PATHS+=("${line%% │ *}") ;;
      esac
    done <<< "$SELECTED"

    if [ "${#PATHS[@]}" -gt 0 ]; then
      JOINED=$(IFS=,; echo "${PATHS[*]}")
      RESULT="$CLEAN_FILE $JOINED"
      echo "$RESULT"
      copy_to_clipboard "$RESULT" && echo "📋 Copied to clipboard" >&2
      notify "$RESULT"
    fi

    { [ "$DO_EXIT" = true ] || [ "$DO_BACK" = true ]; } && break
  done

  [ "$DO_EXIT" = true ] && break
  CLI_FILE=""
done
