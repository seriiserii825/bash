#!/bin/bash

# Get the current state of the active window
# floating: 0=false (tiled), 1=true (floating)
# fullscreen: 0=false, 1=fullscreen (type 0/1), 2=maximize (type 1)
read -r floating fullscreen <<< $(hyprctl activewindow -j | jq -r '"\(.floating) \(.fullscreen)"')

if [[ $fullscreen -eq 0 ]] && [[ $floating == "false" ]]; then
    # Case 1: Window is tiled and not fullscreen -> Make it float
    hyprctl dispatch togglefloating
elif [[ $fullscreen -eq 0 ]] && [[ $floating == "true" ]]; then
    # Case 2: Window is floating -> Make it fullscreen (type 0 or 1)
    hyprctl dispatch fullscreen 1
else
    # Case 3: Window is fullscreen/maximized -> Revert to original tiled state
    # This first exits fullscreen, then un-floats to tile
    hyprctl dispatch fullscreen 0
    hyprctl dispatch togglefloating
fi
