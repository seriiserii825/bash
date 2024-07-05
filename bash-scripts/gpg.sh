#!/bin/bash

# check if exists file  with gpg extension
if [ -z "$(find . -name "*.gpg")" ]; then
  if [ ! -z "$(find dist -name "venv" -type d)" ]; then
    rm -rf dist/venv
  fi
  zip_path="dist.zip"
  zip -r dist.zip dist
  gpg -e -r serii $zip_path
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
  echo "${tgreen}File dist.zip.gpg decrypted${treset}"
fi
