#!/bin/bash

echo "Choose an image with fzf"
sleep 1

# Use fzf to select an image from current directory (or modify path)
image_file_path=$(find . -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | fzf)

# Exit if nothing selected
if [[ -z "$image_file_path" ]]; then
    echo "No image selected."
    exit 1
fi

echo "You selected: $image_file_path"

# Open image on black background
feh --image-bg black "$image_file_path" &

# Open image on white background
feh --image-bg white "$image_file_path" &
