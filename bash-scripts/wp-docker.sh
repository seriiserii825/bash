#!/bin/bash

current_user=$(whoami)

echo "Need to enter folder name, that will be created after cloning the repository."
echo "From folder name will be created project url like: http://folder_name.local"

read -p "Enter folder name: " folder_name
if [ -z "$folder_name" ]; then
  echo "Folder name cannot be empty."
  exit 1
fi

if [ "$current_user" == "serii" ]; then
  echo "${tmagenta}You are serii, clone with ssh.${treset}"
  url_path="git@github.com:seriiserii825/docker-wp.git"
else
  echo "${tmagenta}You are not serii, clone with https.${treset}"
  url_path="https://github.com/seriiserii825/docker-wp.git"
fi
git clone $url_path $folder_name
cd $folder_name
