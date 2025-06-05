#!/bin/bash

# Find a file excluding node_modules, let user pick one with fzf
file_path=$(find . -type f ! -path "*/node_modules/*" | fzf --height 40% --reverse --preview 'head -n 100 {}' --preview-window=up:30%:wrap)

# Exit if no file selected
[[ -z "$file_path" ]] && echo "No file selected." && exit 1

# Extract filename and path
filename=$(basename "$file_path")
dir=$(dirname "$file_path")

echo "Selected file: $file_path"
read -p "New file name: " newfilename

# Show planned rename
newpath="$dir/$newfilename"
echo "Will rename:"
echo "$file_path"
echo "to"
echo "$newpath"

read -p "Do you want to rename the file? (y/n): " answer
if [[ "$answer" == "y" ]]; then
  mv -i "$file_path" "$newpath" && echo "File renamed successfully." || echo "Rename failed."
else
  echo "No files were renamed."
fi
