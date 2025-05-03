function gitPush(){
  script_dir=$1
  source "$script_dir/encrypt.sh"
  # check for git changes
  if [ -z "$(git status --porcelain)" ]; then
    echo "${tmagenta}No changes to commit. Exiting...${treset}"
    return 1
  fi
  git status
  # check if want to view changes with lazygit
  print -n "${tgreen}Do you want to view changes with lazygit? (y/n): ${treset}"
  read view_changes
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
  # print prompt for message
  print -n "${tgreen}Enter a message: ${treset}"
  read message
  if [ -z "$message" ]; then
    echo "${tred}Error: No message provided${treset}"
    return 1
  fi
  echo "message: $message"
  git add .
  git commit -m "$message"
  git push
}
