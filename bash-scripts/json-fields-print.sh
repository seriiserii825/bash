#!/usr/bin/env bash
set -euo pipefail

# Если передали путь — используем его, иначе выбираем *.json через fzf
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

echo "== File: $FILE =="

echo "== Debug: top-level field indexes, labels, types =="
jq -r '
  .[] 
  | (.fields // []) 
  | to_entries[] 
  | [("idx=" + ( .key|tostring )), .value.label, .value.type] 
  | @tsv
' "$FILE" | column -t -s $'\t'

echo
echo "== Output: label<TAB>type (top-level only) =="
jq -r '
  .[] 
  | (.fields // [])[] 
  | [.label, .type] 
  | @tsv
' "$FILE" | sed 's/\r$//' | column -t -s $'\t'
