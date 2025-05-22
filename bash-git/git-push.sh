function gitPush() {
  script_dir=$1

  source "$script_dir/encrypt.sh"

  # Check for git changes
  if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit."
    return 1
  fi

  git status

  # Ask user if they want to view changes with lazygit
  read -p "Do you want to view changes with lazygit? (y/n): " view_changes
  if [[ "$view_changes" == "y" ]]; then
    if command -v lazygit &> /dev/null; then
      echo "${tmagenta}Opening lazygit...${treset}"
      lazygit
    else
      echo "${tred}Error: lazygit is not installed${treset}"
      return 1
    fi
  fi

  # Menu function to select message type
  function menu() {
    echo -e "\t${tgreen}1. Feature${treset}"
    echo -e "\t${tgreen}2. Update${treset}"
    echo -e "\t${tgreen}3. Bugfix${treset}"
    
    read -p "Select type of message (1/2/3): " selection

    if [[ "$selection" =~ ^[1-3]$ ]]; then
      echo "$selection"
    else
      echo "${tred}Error: Invalid selection. Please enter 1, 2, or 3.${treset}"
      menu
    fi
  }

  type_of_message=$(menu)

  case "$type_of_message" in
    1) message_type="feat:" ;;
    2) message_type="upd:" ;;
    3) message_type="fix:" ;;
    *) message_type="feat:" ;;
  esac

  # Commit message handling
  if [ $# -gt 1 ]; then
    message="${@:2}"
  else
    read -p "${tgreen}Enter a commit message: ${treset}" message
    if [ -z "$message" ]; then
      echo "${tred}Error: No message provided${treset}"
      return 1
    fi
  fi

  encryptFiles
  full_message="$message_type $message"
  git add .
  git commit -m "$full_message"
  git push
}
