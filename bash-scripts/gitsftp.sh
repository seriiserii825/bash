#!/bin/bash

if [ "$1" == "--help" ]; then
  echo "Usage: gitsftp.sh [all]"
  echo "y: upload all git modified files"
  echo "empty: upload only main.css and main.js files"
  exit 0
fi

if [ ! -f front-page.php ]; then
  echo "${tmagenta}Please run this script in the root of the project.${treset}"
  exit 1
fi

all=$1
sftp_config_file_json=".AutoRemoteSync.json"
if [ -f $sftp_config_file_json ]; then
  echo "File $sftp_config_file_json exists."
  host=$(jq -r '.remote.host' $sftp_config_file_json)
  user=$(jq -r '.remote.user' $sftp_config_file_json)
  remote_path=$(jq -r '.remote.path' $sftp_config_file_json)
  modified_files=$(git ls-files --others --modified --exclude-standard)
  if [ "$all" == "y" ]; then
    for file in $modified_files; do
      echo "${tblue}file: $file${treset}"
      full_path=$remote_path/$file
      echo "${tgreen}full_path: $full_path${treset}"
      rsync -avz -e ssh $file $user@$host:$full_path
    done
  else
    for file in $modified_files; do
      # if file contains main.css
      if [[ $file == *"main.css"* ]]; then
        echo "${tblue}file: $file${treset}"
        full_path=$remote_path/$file
        echo "${tgreen}full_path: $full_path${treset}"
        rsync -avz -e ssh $file $user@$host:$full_path
      elif [[ $file == *"main.js"* ]]; then
        echo "${tblue}file: $file${treset}"
        full_path=$remote_path/$file
        echo "${tgreen}full_path: $full_path${treset}"
        rsync -avz -e ssh $file $user@$host:$full_path
      fi
    done
  fi
else
  touch $sftp_config_file_json
  read -p "Enter remote host: " host
  read -p "Enter user: " user
  read -p "Enter remote path: " remote_path
  if [ -z "$host" ] || [ -z "$user" ] || [ -z "$remote_path" ]; then
    echo "Please enter all values."
    exit 1
  fi
  cat <<TEST >> "$sftp_config_file_json"
{
  "type": "rsync",
  "remote": {
    "host": "$host",
    "user": "$user",
    "path": "$remote_path"
  },
  "verbose": true
}
TEST
fi
