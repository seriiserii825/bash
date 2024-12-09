#!/bin/bash

# Define colors (optional)
tgreen='\e[32m'
treset='\e[0m'

echo "${tgreen}Starting nbsp.sh${treset}"

# Get clipboard content with newlines preserved
clipboard=$(xclip -selection clipboard -o)

# File paths
file_from=~/Downloads/file.pug
file_to=~/Downloads/file.html

# Ensure the source file exists
if [ ! -f "$file_from" ]; then
  touch $file_from
fi

# Write clipboard content to file while preserving newlines
printf "%s\n" "$clipboard" > "$file_from"

# Convert Pug to HTML
pug "$file_from" -o ~/Downloads

# Copy output HTML to clipboard
if [ -f "$file_to" ]; then
  xclip -selection clipboard -i "$file_to"
  notify-send "Pug to HTML conversion complete"
else
  notify-send "Conversion failed: HTML file not found"
fi
