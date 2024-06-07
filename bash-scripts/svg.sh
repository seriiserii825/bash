#! /bin/bash

file_path=$( fzf )
read -p "Enter width: " width
file=$( basename "$file_path" .svg )
new_file=$( echo "$file"-"$width".svg )

rsvg-convert -a -w "$width" -f svg "$file".svg -o "$file"-"$width".svg
svgo "$file"-"$width".svg

cat "$file"-"$width".svg | xclip -selection clipboard
echo "${tgreen}your file is ready: $file-$width.svg${treset}"
bat "$file-$width.svg"
echo "${tblue}Copied to clipboard!${treset}"
