#! /bin/bash

# get svg files only with fzf
file_path=$( find . -type f -name "*.svg" | fzf )

read -p "Enter w/o(width,optimize): " choose

if [ "$choose" == "w" ]; then
    read -p "Enter width: " width
    file=$( basename "$file_path" .svg )
    new_file=$( echo "$file"-"$width".svg )

    rsvg-convert -w "$width" -f svg "$file".svg -o "$file"-"$width".svg
    svgo "$file"-"$width".svg

    cat "$file"-"$width".svg | xclip -selection clipboard
    echo "${tgreen}your file is ready: $file-$width.svg${treset}"
    bat "$file-$width.svg"
    echo "${tblue}Copied to clipboard!${treset}"
    exit
  else
    # svgo file -o file_output
    # change output file with posfix optimize
    file_name=$( basename "$file_path" .svg )
    new_file=$( echo "$file_name"-optimize.svg )
    svgo "$file_path" -o "$new_file"
    bat "$new_file"
fi
