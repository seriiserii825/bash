#!/bin/bash


echo "${tgreen}1) Search word from buffer and open in Neovim${treset}"
echo "${tblue}2) Find word in all files and another word not in the same file${treset}"

read -p "Enter your choice: " choice

function findWord(){
  search_word=$(xsel -b)
  echo "Searching for word in all files and opening in Neovim"
  files=$(grep -rl --exclude-dir={__pycache__,venv} "$search_word" *)

  # Open all files in a single Neovim instance
  if [ -n "$files" ]; then
    echo "Files found containing the word '${tgreen}$search_word':${treset}"
    echo "${tblue}$files${treset}"
    read -p "Do you want to open all files in Neovim? (y/n): " open_files
    if [ $open_files == "y" ]; then
      nvim $files
    fi
  else
    echo "No files found containing the word '$search_word'."
  fi
}

function findWordWithExclude(){
  read -p "Enter the word to search: " search_word
  read -p "Enter the word is missing: " missing_word
  if [ -z "$search_word" ]; then
    echo "${tmagenta}Search word is empty${treset}"
    exit 1
  elif [ -z "$missing_word" ]; then
    echo "${tmagenta}Missing word is empty${treset}"
    exit 1
  fi
  files=$(grep -rl "$search_word" --exclude-dir=$exclude_dirs . | xargs grep -L "$missing_word")

  echo "Files found containing the word:${treset}"
  echo "${tblue}$files${treset}"

  read -p "Do you want to open all files in Neovim? (y/n): " open_files

  # Open all files in a single Neovim instance
  # check if files are not empty
  if [ -n "$files" ]; then
    if [ $open_files == "y" ]; then
      nvim $files
    fi
  else
    echo "No files found containing the word '$search_word'."
  fi
}

  if [ $choice -eq 1 ]; then
    findWord
  elif [ $choice -eq 2 ]; then
    findWordWithExclude
  else
    echo "${tmagenta}Invalid choice${treset}"
    exit 1
  fi

