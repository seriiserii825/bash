#!/bin/bash

file_path=$(fzf)
file_name=$(basename $file_path)
file_extention="${file_name##*.}"
new_file_name="center-${file_name%.*}.${file_extention}"

read -p "Choose line color, by default is red: " line_color
if [[ -z "$line_color" ]]; then
  line_color=red
fi
echo "line color is $line_color"

width=$(convert $file_path -format "%w" info:)
height=$(convert $file_path -format "%h" info:)
let w=width/2
convert $file_path  -fill $line_color  -draw "line $w,0 $w,$height"  -quality 75%  $new_file_name

