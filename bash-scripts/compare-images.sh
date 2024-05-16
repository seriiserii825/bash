#!/bin/bash

echo "Choose 2 images with fzf"

sleep 1

file1_path=$( fzf )
file2_path=$( ls | grep -v $file1_path | fzf )

# feh -g 950x800+5+30 "$file1_path" & pid1=$!
# feh -g 950x800+963+30 "$file2_path" & pid2=$!

sxiv "$file1_path" & pid1=$!
sxiv "$file2_path" & pid2=$!

# call script with exit
# ./compare-images.sh && exit
