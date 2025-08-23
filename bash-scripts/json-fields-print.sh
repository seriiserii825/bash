#!/usr/bin/env bash

# got json file with fzf
FILE=${1:-$(fzf --prompt="Select JSON file: " --query="$1" --height=40% --layout=reverse --border --preview='cat {}' --preview-window=up:70%)}
[ -z "$FILE" ] && { echo "No file selected"; exit 1; }
# FILE="your.json"

jq -r '
  .[] 
  | .fields[] 
  | [.label, .type] 
  | @tsv
' "$FILE"
