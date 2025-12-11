#!/bin/bash

# set text from clipboard in to a variable with xclip
CLIPBOARD_TEXT=$(xclip -o -selection clipboard)
echo "Clipboard text: $CLIPBOARD_TEXT"

if [ -z "$CLIPBOARD_TEXT" ]; then
    echo "Clipboard is empty."
    exit 1
fi

# transform text to an array of strings for each line
IFS=$'\n' read -d '' -r -a REPO_PATHS <<< "$CLIPBOARD_TEXT"

for line in "${REPO_PATHS[@]}"; do
# ./.cache/yay/google-chrome: Untracked files
# from this path replace first . with $HOME and remove at the end : and everything after it
    REPO_PATH="${line%%:*}"               # Remove everything after the first colon
    REPO_PATH="${REPO_PATH/#./$HOME}"     # Replace leading . with $HOME
    # Check if the directory exists
    if [ -d "$REPO_PATH" ]; then
        cd "$REPO_PATH" || { echo "Failed to change directory to $REPO_PATH"; continue; }

        # Check if it's a git repository
        if [ -d ".git" ]; then
            echo "Repository: $REPO_PATH"
            git config --local mgitstatus.ignore true
            echo "-----------------------------------"
        else
            echo "$REPO_PATH is not a git repository."
        fi
    else
        echo "Directory $REPO_PATH does not exist."
    fi
done
