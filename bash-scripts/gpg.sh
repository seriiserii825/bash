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
  read -p "Encrypt or decrypt file(e/d):"

  if [ $REPLY == "e" ]; then
    gpgrc=".gpgrc"
    echo "${tyellow}Note: only files from .gpgrc will be used${treset}"
    file_with_fzf=$(sed 's/\.gpg$//' "$gpgrc" | fzf)
    gpg -e -r $user $file_with_fzf
    echo "${tgreen}File $file_with_fzf.gpg created${treset}"
  elif [ $REPLY == "d" ]; then
    file_with_fzf=$(find . -maxdepth 1 -name "*.gpg" -type f | fzf)
      file_without_gpg=$(echo $file_with_fzf | sed 's/.gpg//')
      gpg -d $file_with_fzf > $file_without_gpg
      echo "${tgreen}File $file_with_fzf decrypted${treset}"
  else
    echo "${tmagenta}Error: option not found.${treset}"
    exit 1
  fi
}

function moreFiles(){
  read -p "Encrypt or decrypt file(e/d):"
  if [ $REPLY == "e" ]; then
    read -p "Choose extension file: " extension
    for file in $(find .  -maxdepth 1 -name "*.$extension"); do
      gpg -e -r $user $file
      echo "${tgreen}File $file.gpg created${treset}"
    done
  elif [ $REPLY == "d" ]; then
    for file in $(find . -maxdepth 1 -name "*.gpg" -maxdepth 1); do
      file_without_gpg=$(echo $file | sed 's/.gpg//')
      gpg -d $file > $file_without_gpg
      echo "${tgreen}File $file decrypted${treset}"
    done
  else
    echo "${tmagenta}Error: option not found.${treset}"
    exit 1
  fi
}

function envFile(){
  local action=$1
  local env_file=".env"
  local env_gpg=".env.gpg"

  if [ "$action" == "--encrypt" ]; then
    if [ ! -f "$env_file" ]; then
      echo "${tmagenta}Error: $env_file not found.${treset}"
      exit 1
    fi
    gpg -e -r $user $env_file
    echo "${tgreen}File $env_gpg created${treset}"
  elif [ "$action" == "--decrypt" ]; then
    if [ ! -f "$env_gpg" ]; then
      echo "${tmagenta}Error: $env_gpg not found.${treset}"
      exit 1
    fi
    gpg -d $env_gpg > $env_file
    echo "${tgreen}File $env_file decrypted${treset}"
  else
    echo "${tmagenta}Error: use --encrypt or --decrypt with --env.${treset}"
    exit 1
  fi
}

function menu(){
  ls -la
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

if [ "$1" == "--env" ]; then
  envFile "$2"
else
  menu
fi
