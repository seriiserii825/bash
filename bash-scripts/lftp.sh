#!/bin/bash

# Read configuration from config.json
CONFIG_FILE=".vscode/sftp.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Configuration file not found: $CONFIG_FILE"
  exit 1
fi
NAME=$(jq -r '.name' "$CONFIG_FILE")
HOST=$(jq -r '.host' "$CONFIG_FILE")
PROTOCOL=$(jq -r '.protocol' "$CONFIG_FILE")
PORT=$(jq -r '.port' "$CONFIG_FILE")
USERNAME=$(jq -r '.username' "$CONFIG_FILE")
PASSWORD=$(jq -r '.password' "$CONFIG_FILE")
REMOTE_PATH=$(jq -r '.remotePath' "$CONFIG_FILE")
REMOTE_PATH="$REMOTE_PATH/"
WATCH_FILES=$(jq -r '.watcher.files' "$CONFIG_FILE")
IGNORE_PATTERNS=$(jq -r '.ignore | join("|")' "$CONFIG_FILE")

# Function to upload a file, preserving directory structure
upload_file() {
  local file_path=$1
  local relative_path=${file_path#./}  # Get the relative path from the current directory
  # echo "Uploading $file_path to $REMOTE_PATH$relative_path"
  notify-send "Uploading $file_path to $REMOTE_PATH$relative_path"
  lftp -u "$USERNAME","$PASSWORD" -e "set ssl:verify-certificate no; mkdir -p $REMOTE_PATH$(dirname "$relative_path"); put $file_path -o $REMOTE_PATH$relative_path; bye" "$PROTOCOL://$HOST:$PORT"
}

# Start watching files with inotify
inotifywait -m -r -e modify,create,delete --exclude "$IGNORE_PATTERNS" --format "%w%f %e" . | while read file event; do
  if [[ $event == *DELETE* ]]; then
    local relative_path=${file#./}  # Get the relative path from the current directory
    # echo "Deleting $file from $REMOTE_PATH$relative_path"
    # notify-send "Deleting $file from $REMOTE_PATH$relative_path"
    lftp -u "$USERNAME","$PASSWORD" -e "rm $REMOTE_PATH$relative_path; bye" "$PROTOCOL://$HOST:$PORT"
  else
    # echo "Detected $event on $file"
    # notify-send "Detected $event on $file"
    # Sleep for 2 seconds to wait for compilation to finish
    upload_file "$file"
  fi
done
