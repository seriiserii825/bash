#!/usr/bin/env bash

# Paths to config files
PICOM_CONF="$HOME/.config/picom/picom.conf"
PICOM_HARD="$HOME/.config/picom/picom-hard.conf"

# File to store current mode
STATE_FILE="$HOME/.config/picom/current_picom_mode"

# Default mode
if [ ! -f "$STATE_FILE" ]; then
    echo "normal" > "$STATE_FILE"
fi

CURRENT=$(cat "$STATE_FILE")

# Kill any running picom
pkill picom

if [ "$CURRENT" = "normal" ]; then
    picom --config "$PICOM_HARD" -b
    echo "hard" > "$STATE_FILE"
    notify-send "Picom" "Switched to HARD config"
else
    picom --config "$PICOM_CONF" -b
    echo "normal" > "$STATE_FILE"
    notify-send "Picom" "Switched to NORMAL config"
fi
