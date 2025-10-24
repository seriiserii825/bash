#!/bin/bash

# Ask user for FontAwesome icon name (interactive)
read -rp "🔍 Enter icon name to search on FontAwesome: " icon_name

# Exit if empty
if [ -z "$icon_name" ]; then
  echo "⚠️  Icon name cannot be empty."
  exit 1
fi

# Normalize to lowercase
icon_name=$(echo "$icon_name" | tr '[:upper:]' '[:lower:]')

# Check for Chrome
chrome_path=$(command -v google-chrome-stable || command -v google-chrome)
if [ -z "$chrome_path" ]; then
  echo "❌ Google Chrome is not installed."
  exit 1
fi

# Switch to workspace 1 (i3)
i3-msg workspace 1 >/dev/null

# Open search URL
$chrome_path "https://fontawesome.com/search?q=$icon_name&o=r&ic=free" &

# Wait for window to appear
sleep 2

# Focus the Chrome window
wmctrl -x -a "google-chrome.Google-chrome"
