#!/usr/bin/env bash

TARGET="wp-config.php"
DEFINE="define('WP_HTTP_BLOCK_EXTERNAL', true);"
DIR="$(pwd)"
found=0

while [[ "$DIR" != "/" ]]; do
  FILE="$DIR/$TARGET"

  if [[ -f "$FILE" ]]; then
    found=1
    echo "Found: $FILE"

    if grep -qF "// $DEFINE" "$FILE"; then
      sed -i "s|// ${DEFINE}|${DEFINE}|" "$FILE"
      echo "Uncommented: $DEFINE"

    elif grep -qF "$DEFINE" "$FILE"; then
      sed -i "s|${DEFINE}|// ${DEFINE}|" "$FILE"
      echo "Commented: $DEFINE"

    else
      printf "\n%s\n" "$DEFINE" >> "$FILE"
      echo "Added at end: $DEFINE"
    fi

    exit 0
  fi

  DIR="$(dirname "$DIR")"
done

if [[ $found -eq 0 ]]; then
  echo "wp-config.php not found in parent directories"
fi
