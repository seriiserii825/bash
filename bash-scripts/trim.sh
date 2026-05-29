#!/bin/bash
# Converts text to music-friendly filename (spaces→dashes, removes commas/dots/colons)

file_name=music.txt

echo "Enter text:"
read text

echo "$text" > $file_name

sed -i -e 's/ /-/g' $file_name
sed -i -e 's/,//g' $file_name
sed -i -e 's/://g' $file_name
sed -i -e 's/\.//g' $file_name

cat $file_name | xclip -selection clipboard

