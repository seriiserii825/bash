#!/bin/bash
user=$(whoami)

function toggleProject(){
  # check if exists .git
  if [ ! -d ".git" ]; then
    echo "${tmagenta}Error: .git folder not found.${treset}"
    exit 1
  fi

  # check if zip is installed
  if ! [ -x "$(command -v zip)" ]; then
    echo 'Error: zip is not installed.' >&2
    exit 1
  fi

  # check if gpg is installed
  if ! [ -x "$(command -v gpg)" ]; then
    echo 'Error: gpg is not installed.' >&2
    exit 1
  fi

  # check if unzip is installed
  if ! [ -x "$(command -v unzip)" ]; then
    echo 'Error: unzip is not installed.' >&2
    exit 1
  fi

  # check if exists dist folder or file with gpg extension
  if [ -z "$(find . -name "dist")" ] && [ -z "$(find . -name "*.gpg")" ]; then
    echo "${tmagenta}Error: dist folder or gpg file not found.${treset}"
    exit 1
  fi

  # check if exists file  with gpg extension
  if [ -z "$(find . -name "*.gpg")" ]; then
    if [ ! -z "$(find dist -name "venv" -type d)" ]; then
      rm -rf dist/venv
    fi
    zip_path="dist.zip"
    zip -r dist.zip dist
    gpg -e -r $user $zip_path
    rm $zip_path
    rm -rf dist
    echo "${tgreen}File dist.zip.gpg created${treset}"
  else
    file_path="dist.zip.gpg"
    zip_path="dist.zip"
    gpg -d $file_path > $zip_path
    unzip $zip_path
    rm $zip_path
    rm $file_path
    cd dist
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    source venv/bin/activate
    pip install -r requirements.txt
    echo "${tgreen}File dist.zip.gpg decrypted${treset}"
  fi
}

function oneFile(){
  file_with_fzf=$(find . -type f | fzf)
  if [ -z "$file_with_fzf" ]; then
    echo "${tmagenta}Error: file not found.${treset}"
    exit 1
  fi

  file_extension=$(echo $file_with_fzf | awk -F . '{print $NF}')

  if [ $file_extension == "gpg" ]; then
    file_without_gpg=$(echo $file_with_fzf | sed 's/.gpg//')
    gpg -d $file_with_fzf > $file_without_gpg
    rm $file_with_fzf
    echo "${tgreen}File $file_with_fzf decrypted${treset}"
  else
    gpg -e -r $user $file_with_fzf
    rm $file_with_fzf
    echo "${tgreen}File $file_with_fzf.gpg created${treset}"
  fi
}

function moreFiles(){
  read -p "Choose extension file: " extension
  for file in $(find . -name "*.$extension"); do
    file_extension=$(echo $file | awk -F . '{print $NF}')
    if [ $file_extension == "gpg" ]; then
      file_without_gpg=$(echo $file | sed 's/.gpg//')
      gpg -d $file > $file_without_gpg
      rm $file
      echo "${tgreen}File $file decrypted${treset}"
    else
      gpg -e -r $user $file
      rm $file
      echo "${tgreen}File $file.gpg created${treset}"
    fi
  done
}

function menu(){
  echo "${tgreen}1. One file${treset}"
  echo "${tblue}2. More files${treset}"
  echo "${tyellow}3. Project${treset}"
  echo "${tmagenta}4. Exit${treset}"

  read -p "Choose option: " option

  if [ $option == 1 ]; then
    oneFile
  elif [ $option == 2 ]; then
    moreFiles
  elif [ $option == 3 ]; then
    toggleProject
  elif [ $option == 4 ]; then
    exit 0
  else
    echo "${tmagenta}Error: option not found.${treset}"
    menu
    exit 1
  fi
}

menu
