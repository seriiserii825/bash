#!/bin/bash

read -p "Enter file_extension (e.g., .txt): " file_extension
# Check if the file extension is empty
if [[ -z $file_extension ]]; then
    echo "File extension cannot be empty."
    exit 1
fi

read -p "Enter search_string: " search_string
# Check if the search string is empty
if [[ -z $search_string ]]; then
    echo "Search string cannot be empty."
    exit 1
fi
read -p "Enter replace_string: " replace_string
# Check if the replace string is empty
if [[ -z $replace_string ]]; then
    echo "Replace string cannot be empty."
    exit 1
fi
read -p "Exclude folder: " exclude_folder

# check if exclude exists
if [[ -d $exclude_folder ]]; then
    echo "Excluding folder: $exclude_folder"
else
    echo "Folder $exclude_folder does not exist. No folders will be excluded."
    exclude_folder=""
fi

# just show files that will be changed
echo "Files that will be changed:"
find . -type f -name "*$file_extension" ! -path "./$exclude_folder/*" -exec grep -l "$search_string" {} \;
# ask for confirmation
read -p "Do you want to proceed with the replacement? (y/n): " confirm
if [[ $confirm != "y" ]]; then
    echo "Aborting."
    exit 1
fi
# find and replace
find . -type f -name "*$file_extension" ! -path "./$exclude_folder/*" -exec sed -i "s/$search_string/$replace_string/g" {} \;

