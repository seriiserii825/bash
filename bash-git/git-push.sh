source "$(dirname "$0")/encrypt.sh"

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

function gitPush(){
  encryptFiles
  push
}
