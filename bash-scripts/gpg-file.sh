#!/bin/bash
user=$(whoami)

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
