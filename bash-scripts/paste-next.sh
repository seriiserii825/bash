#!/bin/bash
# Pastes the next item from greenclip clipboard history and types it via xdotool

INDEX_FILE="/tmp/paste_stack_index"
INDEX=$(cat "$INDEX_FILE" 2>/dev/null || echo "0")

# Получаем историю из greenclip
TEXT=$(greenclip print | sed -n "$((INDEX + 1))p")

if [ -z "$TEXT" ]; then
    echo "0" > "$INDEX_FILE"
    notify-send "Paste Stack" "Reset!"
    exit
fi

echo -n "$TEXT" | xclip -selection clipboard
xdotool key --clearmodifiers ctrl+v

echo "$((INDEX + 1))" > "$INDEX_FILE"
notify-send "Paste Stack" "[$((INDEX+1))]: ${TEXT:0:40}"
