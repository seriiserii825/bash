#!/usr/bin/env bash
# Marks repos from clipboard as ignored in multi-git-status

ORIG_DIR="$PWD"

if command -v xclip &>/dev/null; then
  CLIPBOARD=$(xclip -selection clipboard -o 2>/dev/null)
elif command -v xsel &>/dev/null; then
  CLIPBOARD=$(xsel --clipboard --output 2>/dev/null)
elif command -v wl-paste &>/dev/null; then
  CLIPBOARD=$(wl-paste 2>/dev/null)
else
  echo "No clipboard tool found (install xclip, xsel, or wl-paste)"
  exit 1
fi

if [[ -z "$CLIPBOARD" ]]; then
  echo "Clipboard is empty"
  exit 1
fi

COUNT=0

while IFS= read -r line; do
  # strip mgitstatus trailing status, e.g. "./.cache/yay/foo: Untracked files" -> "./.cache/yay/foo"
  REPO=$(echo "$line" | sed 's/:[^:]*$//' | xargs)
  [[ -z "$REPO" ]] && continue

  if [[ ! -d "$REPO" ]]; then
    echo "ERROR: not a valid path: $REPO"
    continue
  fi

  if [[ ! -d "$REPO/.git" ]]; then
    echo "SKIP (not a git repo): $REPO"
    continue
  fi

  cd "$REPO" || continue
  git config --local mgitstatus.ignore true
  echo "IGNORED: $REPO"
  cd "$ORIG_DIR" || exit 1
  (( COUNT++ ))

done <<< "$CLIPBOARD"

if [[ $COUNT -eq 0 ]]; then
  echo "ERROR: no valid repos found in clipboard"
  exit 1
fi

cd "$ORIG_DIR" || exit 1
