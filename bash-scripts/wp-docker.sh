#!/bin/bash

read -p "Enter folder name: " folder_name
if [ -z "$folder_name" ]; then
  echo "Folder name cannot be empty."
  exit 1
fi
url_path="git@github.com:seriiserii825/docker-wp.git"
git clone $url_path $folder_name
