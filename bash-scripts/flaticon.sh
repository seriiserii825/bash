#!/bin/bash

# Find icon by argument after calling script
# Example: ./fontawesome.sh setting
# Open browser with search result for "setting" icon

chrome_path=$(which google-chrome-stable)
if [ -z "$chrome_path" ]; then
  echo "Google Chrome is not installed."
  exit 1
fi

read -p "Enter icon name: " icon_name
if [ -z "$icon_name" ]; then
  echo "Please provide an icon name."
  exit 1
fi

icon_name=$(echo "$icon_name" | tr '[:upper:]' '[:lower:]')

# Switch to workspace 1 and focus it
i3-msg workspace 1

# Open browser with search result for the icon
$chrome_path "https://www.flaticon.com/search?word=$icon_name" &

# Wait for the browser to fully load the window
sleep 2

# Focus the browser window using wmctrl
wmctrl -x -a "google-chrome.Google-chrome"
