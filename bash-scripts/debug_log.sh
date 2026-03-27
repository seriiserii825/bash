#!/usr/bin/env bash

TARGET="debug.log"
DIR="$(pwd)"

# ── Select action ───────────────────────────────────────────
echo "Choose action:"
echo "1) Open debug.log (nvim)"
echo "2) Clear debug.log"
echo "3) Watch debug.log (bat live, colored)"
read -rp "Enter choice [1-3]: " ACTION

if [[ ! "$ACTION" =~ ^[1-3]$ ]]; then
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

    case "$ACTION" in
      1)
        nvim "$FILE"
        exit 0
        ;;
      2)
        read -rp "Clear this file? (y/N): " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
          : > "$FILE"
          echo "✔ File cleared (not removed)"
        else
          echo "✖ Skipped"
        fi
        ;;
      3)
        echo "Watching with bat (Ctrl+C to stop)..."
        tail -F "$FILE" | bat --paging=never -l log
        exit 0
        ;;
    esac
  fi

  DIR="$(dirname "$DIR")"
done

if [[ $found -eq 0 ]]; then
  echo "No debug.log found in parent directories"
fi
