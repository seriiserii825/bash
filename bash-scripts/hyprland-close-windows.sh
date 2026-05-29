#!/usr/bin/env bash
# Closes all Hyprland windows on other workspaces, keeping the current workspace intact

# Get ID of the current workspace
current_ws=$(hyprctl activeworkspace -j | jq -r '.id')

# Close (gracefully) every window that is NOT on the current workspace
hyprctl -j clients | \
  jq -r --argjson cw "$current_ws" \
    '.[] | select(.workspace.id != $cw and .workspace.id != -99) | "dispatch closewindow address:\(.address)"' | \
  xargs -I {} hyprctl {}
