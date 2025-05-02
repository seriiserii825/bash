function push(){
  # check for git changes
  if [ -z "$(git status --porcelain)" ]; then
    echo "${tmagenta}No changes to commit. Exiting...${treset}"
    return 1
  fi
  git status
  # check if want to view changes with lazygit
  read -p "${tgreen}Do you want to view changes with lazygit? (y/n): ${treset}" view_changes
  if [[ "$view_changes" == "y" ]]; then
    # check if lazygit is installed
    if command -v lazygit &> /dev/null; then
      echo "${tmagenta}Opening lazygit...${treset}"
      lazygit
    else
      echo "${tred}Error: lazygit is not installed${treset}"
      return 1
    fi
  fi
  read -p "Enter a message: " message
  if [ -z "$message" ]; then
    echo "${tred}Error: No message provided${treset}"
    return 1
  fi
  echo "message: $message"
  git add .
  git commit -m "$message"
  git push
}

function encryptFiles(){
  # check for .gpgrc file if exists
  if [ -f ".gpgrc" ]; then
    # read lines
    while IFS= read -r line; do
      # line its a filename end with gpg, get file name without gpg
      filename=$(echo "$line" | sed 's/\.gpg$//')
      echo "$filename"
      # check if file exists
      if [ -f "$filename" ]; then
        # remove gpg
        rm -f "$line"
        # encrypt file
        gpg -e -r "$USER" "$filename"
      else
        echo "${tred}Error: $filename not found${treset}"
      fi
    done < ".gpgrc"
  else
    echo "${tmagenta}No .gpgrc file found. Exiting...${treset}"
  fi
}

function gitPush(){
  encryptFiles
  push
}
