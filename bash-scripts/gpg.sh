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

read -p "Do you want to encrypt or decrypt the file or project, by default project? (f/p): " option
if [ "$option" == "f" ]; then
  file_with_fzf=$(find . -type f | fzf)
  if [ -z "$file_with_fzf" ]; then
    echo "${tmagenta}Error: file not found.${treset}"
    exit 1
  fi

  if [ -z "$(find . -name "*.gpg")" ]; then
    gpg -e -r $user $file_with_fzf
    rm $file_with_fzf
    echo "${tgreen}File $file_with_fzf.gpg created${treset}"
  else
    file_without_gpg=$(echo $file_with_fzf | sed 's/.gpg//')
    gpg -d $file_with_fzf > $file_without_gpg
    rm $file_with_fzf
    echo "${tgreen}File $file_with_fzf decrypted${treset}"
  fi
else
  toggleProject
fi


