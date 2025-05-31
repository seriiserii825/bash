#!/bin/bash

function prettyEcho(){
  echo "------------------"
  echo "$*"
  echo "------------------"
}

current_user=$(whoami)

echo "Need to enter folder name, that will be created after cloning the repository."
echo "From folder name will be created project url like: http://folder_name.local"

read -p "Enter folder name: " folder_name
if [ -z "$folder_name" ]; then
  echo "Folder name cannot be empty."
  exit 1
fi

if [ "$current_user" == "serii" ]; then
  message="${tblue}You are serii, clone with ssh.${treset}"
  prettyEcho "$message"
  url_path="git@github.com:seriiserii825/docker-wp.git"
else
  message="${tmagenta}You are not serii, clone with https.${treset}"
  prettyEcho "$message"
  url_path="https://github.com/seriiserii825/docker-wp.git"
fi
git clone $url_path $folder_name

message="${tgreen}Now run: cd $folder_name${treset}"
prettyEcho "$message"
