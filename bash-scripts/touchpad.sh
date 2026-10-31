#!/usr/bin/env bash
# Touchpad: toggle on/off via xinput (X11)

source /home/serii/dotfiles/zsh_modules/zsh_colors

get_touchpad_id() {
  xinput list --id-only "$(xinput list --name-only | grep -i -m1 -E 'touchpad|trackpad')" 2>/dev/null
}

toggle() {
  local id state
  id=$(get_touchpad_id)
  if [ -z "$id" ]; then
    echo -e "${tred}Touchpad not found${treset}"
    return 1
  fi

  state=$(xinput list-props "$id" | awk -F: '/Device Enabled/{gsub(/[[:space:]]/, "", $2); print $2}')
  if [ "$state" = "1" ]; then
    xinput disable "$id" && echo -e "${tyellow}Touchpad disabled${treset}"
    command -v notify-send &>/dev/null && notify-send "Touchpad" "Disabled"
  else
    xinput enable "$id" && echo -e "${tgreen}Touchpad enabled${treset}"
    command -v notify-send &>/dev/null && notify-send "Touchpad" "Enabled"
  fi
}

toggle
