#!/bin/bash -x

echo -n "Word to find: "
read -r WORD

# Initialize ignore flags
ignore_file=""
ignore_dir=""

# File ignoring
echo -n "Do you want to ignore a specific file? (y/n): "
read -r ASK_IGNORE_FILE
if [[ "$ASK_IGNORE_FILE" == "y" ]]; then
    file_path=$(fzf)
    if [[ -n "$file_path" ]]; then
        ignore_file="--ignore-file=is:$(basename "$file_path")"
    fi
fi

# Directory ignoring
echo -n "Do you want to ignore a directory? (y/n): "
read -r ASK_IGNORE_DIR
if [[ "$ASK_IGNORE_DIR" == "y" ]]; then
    dir_path=$(fzf)
    # get directory path from dir_path that it's a file path
    if [[ -f "$dir_path" ]]; then
        dir_path=$(dirname "$dir_path")
    fi
    
    if [[ -n "$dir_path" ]]; then
        ignore_dir="--ignore-dir=$(basename "$dir_path")"
    fi
fi

# Build command
cmd="ack \"$WORD\""
if [[ -n "$ignore_file" ]]; then
    cmd+=" $ignore_file"
fi
if [[ -n "$ignore_dir" ]]; then
    cmd+=" $ignore_dir"
fi

# Execute
echo "Running: $cmd"
eval "$cmd"
