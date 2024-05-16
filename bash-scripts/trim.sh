#!/bin/bash

file_name=music.txt

echo "Enter text:"
read text

echo "$text" > $file_name

sed -i -e 's/ /-/g' $file_name
sed -i -e 's/,//g' $file_name
sed -i -e 's/://g' $file_name
sed -i -e 's/\.//g' $file_name

cat $file_name | xclip -selection clipboard

