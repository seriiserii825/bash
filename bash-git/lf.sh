gitMenu(){
  script_dir="$HOME/Documents/bash/bash-git"
  source "$script_dir/git-push.sh"
  source "$script_dir/git-pull.sh"
  source "$script_dir/git-clone.sh"
  source "$script_dir/git-sync.sh"

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
    gitPush $script_dir
  elif [[ "$selected_item" == "Pull" ]]; then
    echo "${tmagenta}Pulling...${treset}"
    gitPull
  elif [[ "$selected_item" == "Sync" ]]; then
    echo "${tmagenta}Syncing...${treset}"
    gitSync
  elif [[ "$selected_item" == "Clone" ]]; then
    echo "${tmagenta}Cloning...${treset}"
    gitClone
  else
    echo "${tmagenta}Invalid option selected. Exiting...${treset}"
  fi
}
