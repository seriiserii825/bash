#!/bin/bash

sftp_config_file_json=".AutoRemoteSync.json"
if [ -f $sftp_config_file_json ]; then
  echo "File $sftp_config_file_json exists."
  host=$(jq -r '.remote.host' $sftp_config_file_json)
  user=$(jq -r '.remote.user' $sftp_config_file_json)
  remote_path=$(jq -r '.remote.path' $sftp_config_file_json)
  modified_files=$(git ls-files --modified)
  for file in $modified_files; do
    echo "${tblue}file: $file${treset}"
    full_path=$remote_path/$file
    echo "${tgreen}full_path: $full_path${treset}"
    rsync -avz -e ssh $file $user@$host:$full_path
  done
else
  echo "${tmagenta}File $sftp_config_file_json does not exist.${treset}"
  echo "${tyellow}Please create a file $sftp_config_file_json with the following content:${treset}"
  exit 1
fi
