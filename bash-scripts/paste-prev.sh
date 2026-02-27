#!/bin/bash

INDEX_FILE="/tmp/paste_stack_index"
INDEX=$(cat "$INDEX_FILE" 2>/dev/null || echo "0")

# Уменьшаем индекс, но не меньше 0
if [ "$INDEX" -le 0 ]; then
    notify-send "Paste Stack" "Already at first item!"
    exit
fi

INDEX=$((INDEX - 1))
echo "$INDEX" > "$INDEX_FILE"

TEXT=$(greenclip print | sed -n "$((INDEX + 1))p")
echo -n "$TEXT" | xclip -selection clipboard
xdotool key --clearmodifiers ctrl+v

notify-send "Paste Stack" "[$((INDEX+1))]: ${TEXT:0:40}"
