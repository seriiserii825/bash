lf(){
  script_dir="$HOME/Documents/bash/bash-git"
  source "$script_dir/git-push.sh"
  source "$script_dir/git-pull.sh"
  source "$script_dir/git-clone.sh"
  source "$script_dir/git-sync.sh"

  if [[ $# -eq 1 && $1 == '-h' ]]; then
    echo "Usage: lf [message]"
    echo "Push, pull, sync, or clone a git repository."
    echo
    echo "Options:"
    echo "  message   The commit message to use when pushing."
    echo
    echo "Examples:"
    echo "  lf 'Initial commit'"
    echo "  lf -h"
    return
  fi

  menu_items=(
    "Push"
    "Pull"
    "Sync"
    "Clone"
  )
  # choose with fzf
  selected_item=$(printf '%s\n' "${menu_items[@]}" | fzf --height 40% --reverse --inline-info --prompt "Select an option: ")

  if [[ "$selected_item" == "Push" ]]; then
    echo "${tmagenta}Pushing...${treset}"
    message="$*"
    if [[ -z "$message" ]]; then
      echo "No commit message provided. Exiting..."
      return
    fi
    gitPush $script_dir "$message"
  elif [[ "$selected_item" == "Pull" ]]; then
    echo "${tmagenta}Pulling...${treset}"
    gitPull $script_dir
  elif [[ "$selected_item" == "Sync" ]]; then
    echo "${tmagenta}Syncing...${treset}"
    gitSync $script_dir
  elif [[ "$selected_item" == "Clone" ]]; then
    echo "${tmagenta}Cloning...${treset}"
    gitClone
  else
    echo "${tmagenta}Invalid option selected. Exiting...${treset}"
  fi
}
