#!/bin/bash

file_path=~/Downloads/links.txt
result_path=~/Downloads/slugs.txt
touch "$file_path"
touch $result_path

# Read the clipboard content and save it to a file
clipboard=$(xclip -o -selection clipboard)
echo "$clipboard" >> "$file_path"
bat "$file_path"
while IFS= read -r line
do
  slug=$(echo "$line" | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z)
  echo "$slug : $line" >> $result_path
done < "$file_path"
xclip -selection clipboard < "$result_path"
bat "$result_path"

# Cleanup
rm "$file_path"
rm "$result_path"
