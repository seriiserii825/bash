#!/bin/bash

# Read configuration from config.json
CONFIG_FILE="config.json"
NAME=$(jq -r '.name' "$CONFIG_FILE")
HOST=$(jq -r '.host' "$CONFIG_FILE")
PROTOCOL=$(jq -r '.protocol' "$CONFIG_FILE")
PORT=$(jq -r '.port' "$CONFIG_FILE")
USERNAME=$(jq -r '.username' "$CONFIG_FILE")
PASSWORD=$(jq -r '.password' "$CONFIG_FILE")
REMOTE_PATH=$(jq -r '.remotePath' "$CONFIG_FILE")
WATCH_FILES=$(jq -r '.watcher.files' "$CONFIG_FILE")
IGNORE_PATTERNS=$(jq -r '.ignore | join("|")' "$CONFIG_FILE")

# Function to upload a file, preserving directory structure
upload_file() {
  local file_path=$1
  local relative_path=${file_path#./}  # Get the relative path from the current directory
  echo "Uploading $file_path to $REMOTE_PATH$relative_path"
  notify-send "Uploading $file_path to $REMOTE_PATH$relative_path"

  # Use lftp with mkdir -p to ensure the directory structure is created
  lftp -u "$USERNAME","$PASSWORD" -e "
    set ssl:verify-certificate no;
    mkdir -p $REMOTE_PATH$(dirname "$relative_path");  # Ensure directory exists
    put $file_path -o $REMOTE_PATH$relative_path;  # Upload the file
    bye
  " "$PROTOCOL://$HOST:$PORT"
}

# Function to delete a file from the remote server using lftp
delete_file() {
  local file_path=$1
  local relative_path=${file_path#./}  # Get the relative path from the current directory
  echo "Deleting $file_path from $REMOTE_PATH$relative_path"
  notify-send "Deleting $file_path from $REMOTE_PATH$relative_path"
  
  # Use lftp to delete the file from the server
  lftp -u "$USERNAME","$PASSWORD" -e "
    set ssl:verify-certificate no;
    rm $REMOTE_PATH$relative_path;  # Delete the file
    bye
  " "$PROTOCOL://$HOST:$PORT"
}

# Start watching files with inotify
inotifywait -m -r -e modify,create,delete --exclude "$IGNORE_PATTERNS" --format "%w%f %e" . | while read file event; do
  if [[ $event == *DELETE* ]]; then
    delete_file "$file"
  else
    echo "Detected $event on $file"
    notify-send "Detected $event on $file"
    # Sleep for 2 seconds to wait for compilation to finish
    sleep 2
    upload_file "$file"
  fi
done
