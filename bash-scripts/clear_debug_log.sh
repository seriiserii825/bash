#!/usr/bin/env bash

TARGET="debug.log"
DIR="$(pwd)"

found=0

while [[ "$DIR" != "/" ]]; do
  FILE="$DIR/$TARGET"

  if [[ -f "$FILE" ]]; then
    found=1
    SIZE=$(du -h "$FILE" | cut -f1)

    echo "Found: $FILE"
    echo "Current size: $SIZE"

    read -rp "Clear this file? (y/N): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      : > "$FILE"
      echo "✔ File cleared (not removed)"
    else
      echo "✖ Skipped"
    fi
  fi

  DIR="$(dirname "$DIR")"
done

if [[ $found -eq 0 ]]; then
  echo "No debug.log found in parent directories"
fi
