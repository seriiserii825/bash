#!/bin/bash

# Read configuration from config.json
CONFIG_FILE=".vscode/sftp.json"
NAME=$(jq -r '.name' "$CONFIG_FILE")
HOST=$(jq -r '.host' "$CONFIG_FILE")
PROTOCOL=$(jq -r '.protocol' "$CONFIG_FILE")
PORT=$(jq -r '.port' "$CONFIG_FILE")
USERNAME=$(jq -r '.username' "$CONFIG_FILE")
PASSWORD=$(jq -r '.password' "$CONFIG_FILE")
REMOTE_PATH=$(jq -r '.remotePath' "$CONFIG_FILE")
REMOTE_PATH="$REMOTE_PATH/"
IGNORE_PATTERNS=$(jq -r '.ignore | join("|")' "$CONFIG_FILE")


# echo "Starting $NAME"
# echo "Host: $HOST"
# echo "Protocol: $PROTOCOL"
# echo "Port: $PORT"
# echo "Username: $USERNAME"
# echo "Password: $PASSWORD"
# echo "Remote Path: $REMOTE_PATH"
# echo "Ignore Patterns: $IGNORE_PATTERNS"

# Function to upload a file using rsync with sshpass
upload_file() {
  local file_path=$1
  local relative_path=${file_path#./}  # Get the relative path from the current directory

  sshpass -p "$PASSWORD" rsync -avz --progress --rsh="sshpass -p $PASSWORD ssh -p $PORT" "$file_path" "$USERNAME@$HOST:$REMOTE_PATH$relative_path"

  echo "Uploading $file_path to $REMOTE_PATH$relative_path"
  notify-send "Uploading $file_path to $REMOTE_PATH$relative_path"
}

# Function to delete a file from the remote server using ssh and sshpass
delete_file() {
  local file_path=$1
  local relative_path=${file_path#./}  # Get the relative path from the current directory

  sshpass -p "$PASSWORD" ssh -p "$PORT" "$USERNAME@$HOST" "rm -f $REMOTE_PATH$relative_path"

  echo "Deleting $file_path from $REMOTE_PATH$relative_path"
  notify-send "Deleting $file_path from $REMOTE_PATH$relative_path"
}

# Start watching files with inotify
inotifywait -m -r -e modify,create,delete --exclude "$IGNORE_PATTERNS" --format "%w%f %e" . | while read file event; do
  if [[ $event == *DELETE* ]]; then
    delete_file "$file"
  else
    echo "Detected $event on $file"
    # notify-send "Detected $event on $file"
    # Sleep for 2 seconds to wait for compilation to finish
    # sleep 2
    upload_file "$file"
  fi
done
