#!/usr/bin/env bash

TARGET="debug.log"
DIR="$(pwd)"

# ── Select action ───────────────────────────────────────────
echo "Choose action:"
echo "1) Open debug.log"
echo "2) Clear debug.log"
read -rp "Enter choice [1-2]: " ACTION

if [[ "$ACTION" != "1" && "$ACTION" != "2" ]]; then
  echo "Invalid choice"
  exit 1
fi

found=0

while [[ "$DIR" != "/" ]]; do
  FILE="$DIR/$TARGET"

  if [[ -f "$FILE" ]]; then
    found=1
    SIZE=$(du -h "$FILE" | cut -f1)

    echo
    echo "Found: $FILE"
    echo "Current size: $SIZE"

    if [[ "$ACTION" == "1" ]]; then
      # ── Open file in nvim ──────────────────────────────────
      nvim "$FILE"
      exit 0
    fi

    if [[ "$ACTION" == "2" ]]; then
      read -rp "Clear this file? (y/N): " answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        : > "$FILE"
        echo "✔ File cleared (not removed)"
      else
        echo "✖ Skipped"
      fi
    fi
  fi

  DIR="$(dirname "$DIR")"
done

if [[ $found -eq 0 ]]; then
  echo "No debug.log found in parent directories"
fi
