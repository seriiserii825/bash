#!/usr/bin/env bash

FILE="$HOME/Documents/projects/updated-projects.txt"

clipboard=$(xclip -selection clipboard -o 2>/dev/null)

if [[ ! "$clipboard" =~ ^https?:// ]]; then
    echo "Error: clipboard does not contain a URL (got: '${clipboard:0:60}')" >&2
    exit 1
fi

origin=$(echo "$clipboard" | grep -oP '^https?://[^/?#]+')

if [[ -z "$origin" ]]; then
    echo "Error: could not extract origin from URL" >&2
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    mkdir -p "$(dirname "$FILE")"
    touch "$FILE"
    echo "Created: $FILE"
fi

if grep -qxF "$origin" "$FILE"; then
    echo "Error: '$origin' already exists in file" >&2
    exit 1
fi

echo "$origin" >> "$FILE"
echo "Appended: $origin"

bat "$FILE"
