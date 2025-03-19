#!/bin/bash

echo -n "Word to find: "
read -r WORD

# Initialize ignore flags
ignore_file=""
ignore_dir=""

# # File ignoring
# echo -n "Do you want to ignore a specific file? (y/n): "
# read -r ASK_IGNORE_FILE
# if [[ "$ASK_IGNORE_FILE" == "y" ]]; then
#     file_path=$(fzf)
#     if [[ -n "$file_path" ]]; then
#         ignore_file="--ignore-file=is:$(basename "$file_path")"
#     fi
# fi

# Directory ignoring (modified to find directories with fzf)
echo -n "Do you want to ignore a directory? (y/n): "
read -r ASK_IGNORE_DIR
if [[ "$ASK_IGNORE_DIR" == "y" ]]; then
    echo "Select directory to ignore:"
    dir_path=$(find . -type d 2>/dev/null | fzf --height 40% --reverse)
    if [[ -n "$dir_path" ]]; then
        ignore_dir="--ignore-dir=$(basename "$dir_path")"
    fi
fi

# Build command
cmd="ack \"$WORD\""
[[ -n "$ignore_file" ]] && cmd+=" $ignore_file"
[[ -n "$ignore_dir" ]] && cmd+=" $ignore_dir"

# Execute
echo -e "\nRunning: $cmd"
eval "$cmd"
