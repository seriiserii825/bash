#!/bin/bash

read -p "Enter a word: " word
grep --color=always -Rn . -e $word
read -p "Enter new word: " new_word
read -p "Enter file_type, by comma: " file_type
file_types=()
IFS=',' read -r -a file_types <<< "$file_type"
for file_type in "${file_types[@]}"
do
    echo "file_type: $file_type"
    # find . -name "*.$file_type"  -exec sed -i "s/$word/$new_word/g" {} \;
    find . -type d \( -name node_modules -o -name .git \) -prune -o -name "*.$file_type" -exec sed -i "s/$word/$new_word/g" {} \;
done
