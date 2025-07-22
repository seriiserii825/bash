#!/bin/bash

# Detect clipboard tool
if command -v xclip &>/dev/null; then
    CLIP_CMD="xclip -selection clipboard -o"
elif command -v xsel &>/dev/null; then
    CLIP_CMD="xsel --clipboard --output"
elif command -v wl-paste &>/dev/null; then
    CLIP_CMD="wl-paste"
else
    echo "No supported clipboard tool found (xclip, xsel, wl-paste)"
    exit 1
fi

# Get clipboard content
clipboard_content="$($CLIP_CMD)"

# Check if content looks like Markdown
if echo "$clipboard_content" | grep -qE '(^#|[*_]{1,2}|!\[.*\]\(.*\)|\[.*\]\(.*\))'; then
    echo "Markdown detected in clipboard"
else
    echo "No Markdown syntax detected"
    exit 1
fi

# Check for pandoc
if ! command -v pandoc &>/dev/null; then
    echo "Pandoc is not installed. Please install pandoc."
    exit 1
fi

# Convert to HTML
html_output=$(echo "$clipboard_content" | pandoc -f markdown -t html --wrap=none)

# Optionally, copy back to clipboard (uncomment one of these)
echo "$html_output" | xclip -selection clipboard
# echo "$html_output" | xsel --clipboard --input
# echo "$html_output" | wl-copy

# Output the result
echo "Generated HTML:"
echo "$html_output"
