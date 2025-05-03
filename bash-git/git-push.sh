function gitPush() {
  script_dir=$1
  source "$script_dir/encrypt.sh"

  # Check for git changes
  if [ -z "$(git status --porcelain)" ]; then
    echo "${tmagenta}No changes to commit. Exiting...${treset}"
    return 1
  fi

  git status

  # Check if user wants to view changes with lazygit
  print -n "${tgreen}Do you want to view changes with lazygit? (y/n): ${treset}"
  read view_changes
  if [[ "$view_changes" == "y" ]]; then
    # Check if lazygit is installed
    if command -v lazygit &> /dev/null; then
      echo "${tmagenta}Opening lazygit...${treset}"
      lazygit
    else
      echo "${tred}Error: lazygit is not installed${treset}"
      return 1
    fi
  fi

  # Handle commit message
  if [ $# -gt 1 ]; then
    shift  # Remove the first argument (script_dir)
    message="$*"  # Capture all remaining arguments as the message
  else
    print -n "${tgreen}Enter a commit message: ${treset}"
    read message
    if [ -z "$message" ]; then
      echo "${tred}Error: No message provided${treset}"
      return 1
    fi
  fi

  git add .
  git commit -m "$message"
  git push

  encryptFiles
}
