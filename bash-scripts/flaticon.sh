#!/bin/bash

read -rp "🔍 Enter icon name to search on Flaticon: " icon_name

if [ -z "$icon_name" ]; then
  echo "⚠️  Icon name cannot be empty."
  exit 1
fi

# normalize
icon_name=$(echo "$icon_name" | tr '[:upper:]' '[:lower:]')

# URL-encode (handles spaces)
encoded_icon=$(printf '%s' "$icon_name" | sed 's/ /%20/g')

chrome_path=$(command -v google-chrome-stable || command -v google-chrome)
if [ -z "$chrome_path" ]; then
  echo "❌ Google Chrome is not installed."
  exit 1
fi

# open in background (important for i3)
# nohup "$chrome_path" \
#   "https://fontawesome.com/search?q=$encoded_icon&o=r&ic=free" \
#   >/dev/null 2>&1 &

nohup "$chrome_path" \
  --new-window \
  --user-data-dir=/tmp/chrome-fa-search \
  "https://www.flaticon.com/search?word=$icon_name" &
