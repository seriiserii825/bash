#!/bin/bash

# Temporary file to store text
TMPFILE=$(mktemp)

# Launch Neovim inside the st terminal
st -e nvim "$TMPFILE"

# Copy the contents of the file to the clipboard
cat "$TMPFILE" | xclip -selection clipboard

# Notify the user
notify-send "Neovim" "Text copied to clipboard!"

# Remove the temporary file
rm "$TMPFILE"
