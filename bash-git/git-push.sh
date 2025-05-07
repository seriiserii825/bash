function gitPush() {
  script_dir=$1

  source "$script_dir/encrypt.sh"

  # Check for git changes
  if [ -z "$(git status --porcelain)" ]; then
    return 1
  fi

  git status

  # Check if user wants to view changes with lazygit
  print -n "Do you want to view changes with lazygit? (y/n):"
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

  # check type of message
  type_of_message=(
    '1. Feature'
    '2. Upate'
    '3. Bugfix'
  )

  for i in "${type_of_message[@]}"; do
    echo -e "\t${tgreen}$i${treset}"
  done

  print -n "Select type of message: "
  read type_of_message
  message_type=""
  case $type_of_message in
    1)
      message_type="feat:"
      ;;
    2)
      message_type="upd:"
      ;;
    3)
      message_type="fix:"
      ;;
    *)
      message_type="feat:"
      ;;
  esac

  echo "$message_type"

  # Handle commit message
  if [ $# -gt 1 ]; then
    message="${@:2}"  # Get all arguments starting from the second one
  else
    print -n "${tgreen}Enter a commit message: ${treset}"
    read message
    if [ -z "$message" ]; then
      echo "${tred}Error: No message provided${treset}"
      return 1
    fi
  fi
  encryptFiles
  message="$message_type $message"
  git add .
  git commit -m "$message"
  git push
}
