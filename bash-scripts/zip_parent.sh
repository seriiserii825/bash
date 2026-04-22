#!/bin/bash

current_dir=$(pwd)
folder_name=$(basename "$current_dir")
archive_name="${folder_name}.zip"
downloads_dir="$HOME/Downloads"

echo "Archive: $archive_name → $downloads_dir"
read -r -p "Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

cd "$(dirname "$current_dir")" && zip -r "$downloads_dir/$archive_name" "$folder_name"

if [[ $? -ne 0 ]]; then
    echo "Failed to create archive."
    exit 1
fi

echo "Archived and moved to $downloads_dir/$archive_name"
