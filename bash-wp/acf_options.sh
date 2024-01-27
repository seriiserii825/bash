#!/bin/bash

source ~/Documents/bash-scripts/extract-text-from-image.sh

acf_path=~/Downloads/acf.txt
output_path=~/Downloads/output.txt
touch $acf_path
touch $output_path

echo "$(xclip -o -selection clipboard)" > $acf_path

bat $acf_path
>$output_path

while read -r line; do
  new_line="\$$line=get_field('$line', 'option');"
  echo $new_line >> $output_path
done < "$acf_path"

bat $output_path
xclip -selection clipboard $output_path

rm $acf_path
rm $output_path
