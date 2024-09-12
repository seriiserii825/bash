#!/bin/bash

search_word=$(xsel -b)

echo "1) Search word from buffer and open in Neovim"
echo "2) Find word in all files and another word not in the same file"

read -p "Enter your choice: " choice

exclude_dirs="{__pycache__,venv}"

if [ $choice -eq 1 ]; then
  echo "Searching for word in all files and opening in Neovim"
  files=$(grep -rl --exclude-dir=$exclude_dirs "$search_word" *)
  echo "Files: $files"

  # Open all files in a single Neovim instance
  if [ -n "$files" ]; then
    # nvim $files
    echo $files
  else
    echo "No files found containing the word '$search_word'."
  fi
elif [ $choice -eq 2 ]; then
#  grep -rl 'EC.presence_of_element_located' --exclude-dir=$exclude_dirs . | xargs grep -L 'from selenium.webdriver.support import expected_conditions as EC'
 files=$(grep -rl 'EC.presence_of_element_located' --exclude-dir=$exclude_dirs . | xargs grep -L 'from selenium.webdriver.support import expected_conditions as EC')

  # Open all files in a single Neovim instance
  if [ -n "$files" ]; then
    nvim $files
  else
    echo "No files found containing the word '$search_word'."
  fi
else
  echo "Invalid choice"
  exit 1
fi

