#!/bin/bash

read -p "Replace file? (y/n): " replace_file
if [ $replace_file == "y" ]; then
  file=$(find . -type f | fzf)
  file_name_without_extension=$(basename $file | cut -d. -f1)
  files_with_file_extenstion_inside=$(find . -type f -exec grep -l $file_name_without_extension {} \;)

  result_files=()
  for file_with_file_extenstion in $files_with_file_extenstion_inside
  do
    read -p "file_with_file_extenstion: $file_with_file_extenstion, bat? (y/n):"
    if [ $bat == "y" ]; then
      bat $file_with_file_extenstion
    fi
    read -p "Add this file to replace list? (y/n): " add_file
    if [ $add_file == "y" ]; then
      result_files+=($file_with_file_extenstion)
    fi
  done
  read -p "Enter new word: " new_word
  for result_file in "${result_files[@]}"
  do
    sed -i "s/$file_name_without_extension/$new_word/g" $result_file
  done
  exit
else
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
fi

# read -p "Enter a word: " word
# grep --color=always -Rn . -e $word
# read -p "Enter new word: " new_word
# read -p "Enter file_type, by comma: " file_type
# file_types=()
# IFS=',' read -r -a file_types <<< "$file_type"
# for file_type in "${file_types[@]}"
# do
#     echo "file_type: $file_type"
#     # find . -name "*.$file_type"  -exec sed -i "s/$word/$new_word/g" {} \;
#     find . -type d \( -name node_modules -o -name .git \) -prune -o -name "*.$file_type" -exec sed -i "s/$word/$new_word/g" {} \;
# done
