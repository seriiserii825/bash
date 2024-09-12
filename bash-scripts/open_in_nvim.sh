#!/bin/bash

# Word to search for
# search word is the content of the global clipboard
search_word=$(xsel -b)
echo $search_word

# Find files containing the word, excluding __pycache__ and venv directories
files=$(grep -rl --exclude-dir={__pycache__,venv} "$search_word" *)
# echo $files

# Open all files in a single Neovim instance
if [ -n "$files" ]; then
  nvim $files
else
  echo "No files found containing the word '$search_word'."
fi
