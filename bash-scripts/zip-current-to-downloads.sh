#!/bin/bash
# Zips the current folder and moves the archive to ~/Downloads

current_dir=$(pwd)
folder_name=$(basename "$current_dir")
downloads_dir="$HOME/Downloads"
archive_name="${folder_name}.zip"

if [[ -f "$downloads_dir/$archive_name" ]]; then
  echo "Archive already exists: $downloads_dir/$archive_name"
  read -r -p "Delete it? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm "$downloads_dir/$archive_name"
  else
    echo "Cancelled."
    exit 0
  fi
fi

cd "$(dirname "$current_dir")" || exit 1
zip -r "$archive_name" "$folder_name"
if [[ $? -ne 0 ]]; then
  echo "Failed to create archive."
  exit 1
fi

mv "$archive_name" "$downloads_dir/$archive_name"
echo "Archived and moved to $downloads_dir/$archive_name"
