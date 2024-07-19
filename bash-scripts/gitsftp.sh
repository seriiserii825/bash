#!/bin/bash

sftp_config_file_json=".AutoRemoteSync.json"
if [ -f $sftp_config_file_json ]; then
  echo "File $sftp_config_file_json exists."
  host=$(jq -r '.remote.host' $sftp_config_file_json)
  user=$(jq -r '.remote.user' $sftp_config_file_json)
  remote_path=$(jq -r '.remote.path' $sftp_config_file_json)
  modified_files=$(git ls-files --modified)
  for file in $modified_files; do
    echo "file: $file"
    full_path=$remote_path/$file
    echo "full_path: $full_path"
    rsync -avz -e ssh $file $user@$host:$full_path
  done
else
  echo "File $sftp_config_file_json does not exist."
  echo "Please create a file $sftp_config_file_json with the following content:"
  echo "{
  \"host\": \"your_host\",
  \"user\": \"your_user\",
  \"remote_path\": \"your_remote_path\"
}"
  exit 1
fi
