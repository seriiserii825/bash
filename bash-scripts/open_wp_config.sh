#!/usr/bin/env bash

TARGET="wp-config.php"
DIR="$(pwd)"

found=0

while [[ "$DIR" != "/" ]]; do
  FILE="$DIR/$TARGET"

  if [[ -f "$FILE" ]]; then
    found=1
    SIZE=$(du -h "$FILE" | cut -f1)

    echo "Found: $FILE"

    read -rp "Copy file path to clipboard? (y/N): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      nvim "$FILE"
      # echo "$FILE"
      # echo -n "\"$FILE\":" | xclip -selection clipboard
      # echo "✔ File path copied to clipboard"
    else
      echo "✖ Skipped"
    fi
  fi

  DIR="$(dirname "$DIR")"
done

if [[ $found -eq 0 ]]; then
  echo "No debug.log found in parent directories"
fi
