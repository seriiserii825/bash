#!/bin/bash
# Opens Flaticon search page for the entered icon name in a new Chrome window

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

# open in background (important for i3), using the normal Chrome profile
nohup "$chrome_path" \
  --new-window \
  "https://www.flaticon.com/search?word=$icon_name" \
  >/dev/null 2>&1 &
