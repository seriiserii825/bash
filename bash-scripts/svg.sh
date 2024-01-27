#! /bin/bash

file_path=$( fzf )
read -p "Enter width: " width
file=$( basename "$file_path" .svg )
echo "file: $file"

rsvg-convert -a -w "$width" -f svg "$file".svg -o "$file"-"$width".svg

echo "your file is ready: $file-$width.svg"
