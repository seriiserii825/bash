#!/usr/bin/env bash
# Toggles WP_HTTP_BLOCK_EXTERNAL constant (comment/uncomment) in wp-config.php
# Run from inside a WordPress theme folder (must contain functions.php and style.css)

set -e

# Setup colors for output
tblue=$(tput setaf 4)
tgreen=$(tput setaf 2)
tmagenta=$(tput setaf 5)
treset=$(tput sgr0)

# Check that current directory is a WordPress theme
if [ ! -f "functions.php" ] || [ ! -f "style.css" ]; then
  echo "${tmagenta}⚠️ This is not a WordPress theme folder (functions.php or style.css not found).${treset}"
  exit 1
fi

# Theme folder is 3 levels below the WordPress root:
# wp-root/wp-content/themes/theme-name -> up 3 levels
WP_CONFIG="../../../wp-config.php"

if [ ! -f "$WP_CONFIG" ]; then
  echo "${tmagenta}⚠️ wp-config.php not found (looked at ${WP_CONFIG}).${treset}"
  exit 1
fi

TARGET="WP_HTTP_BLOCK_EXTERNAL"

MATCH=$(grep -n "$TARGET" "$WP_CONFIG" | head -n1)

if [ -z "$MATCH" ]; then
  echo "${tmagenta}⚠️ ${TARGET} not found in ${WP_CONFIG}${treset}"

  DEFINE_LINE="define( 'WP_HTTP_BLOCK_EXTERNAL', true );"

  read -rp "${tblue}Add it now? (y/N): ${treset}" add_answer

  if [[ "$add_answer" =~ ^[Yy]$ ]]; then
    MARKER_LINE=$(grep -n "That's all, stop editing" "$WP_CONFIG" | head -n1 | cut -d: -f1)

    if [ -n "$MARKER_LINE" ]; then
      sed -i "${MARKER_LINE}i ${DEFINE_LINE}" "$WP_CONFIG"
    else
      printf '\n%s\n' "$DEFINE_LINE" >> "$WP_CONFIG"
    fi

    echo "${tgreen}🟢 Added: ${DEFINE_LINE}${treset}"
  else
    echo "Skipped"
  fi

  exit 0
fi

LINE_NUM=$(echo "$MATCH" | cut -d: -f1)
LINE_CONTENT=$(echo "$MATCH" | cut -d: -f2-)

if echo "$LINE_CONTENT" | grep -Eq '^[[:space:]]*//'; then
  STATUS="commented"
  echo "${tmagenta}🔵 ${TARGET} is currently commented:${treset}"
else
  STATUS="active"
  echo "${tgreen}🟢 ${TARGET} is currently active:${treset}"
fi

echo "${LINE_CONTENT}"

read -rp "${tblue}Do you want to toggle it? (y/N): ${treset}" answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
  if [ "$STATUS" == "commented" ]; then
    sed -i "${LINE_NUM}s#^\([[:space:]]*\)//[[:space:]]*#\1#" "$WP_CONFIG"
    echo "${tgreen}🟢 Uncommented ${TARGET}${treset}"
  else
    sed -i "${LINE_NUM}s#^\([[:space:]]*\)#\1// #" "$WP_CONFIG"
    echo "${tmagenta}🔵 Commented ${TARGET}${treset}"
  fi
else
  echo "Skipped"
fi
