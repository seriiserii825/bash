#!/usr/bin/env bash
# ACF field path picker: flattens an exported ACF JSON file (array of field
# groups, each with a "fields" array, fields nesting via "sub_fields") into
# every field's dot-notation path built from its actual "name" value — not the
# JSON schema keys — lets you fuzzy-search all of them at once via fzf, then
# prints the selected path and copies it to the clipboard.
# Usage: bash-scripts/parse-json.sh [file.json]
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Required: $1"; exit 1; }; }
need jq
need fzf

quit() { echo "Exit."; exit 0; }

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
          --height=90% --layout=reverse --border \
          --preview='head -n 120 {}' --preview-window=up:40%)"
fi

[ -z "${FILE:-}" ] && { echo "No file selected"; exit 1; }
[ ! -f "$FILE" ] && { echo "Not a file: $FILE"; exit 1; }
jq empty "$FILE" 2>/dev/null || { echo "❌ Invalid JSON: $FILE"; exit 1; }

# ── 2. FLATTEN ────────────────────────────────────────────────────────────────
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

ALL_PATHS="$(jq -r "$JQ_PROGRAM" "$FILE")"
[ -n "$ALL_PATHS" ] || { echo "No fields found in $FILE"; exit 1; }

# ── 3. PICK ───────────────────────────────────────────────────────────────────
SELECTED=$(printf '🚪  Exit\n%s\n' "$ALL_PATHS" \
  | fzf --height=90% --reverse --no-info \
        --prompt="Select field path > " \
        --header="$FILE") || quit

[ -n "$SELECTED" ] || quit
[[ "$SELECTED" == "🚪"* ]] && quit
PATH_CUR="${SELECTED%% │ *}"

# ── 4. OUTPUT ──────────────────────────────────────────────────────────────
echo "$PATH_CUR"
copy_to_clipboard "$PATH_CUR" && echo "📋 Copied to clipboard" >&2
