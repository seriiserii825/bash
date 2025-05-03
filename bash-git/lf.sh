#!/usr/bin/bash 

cp -f ~/Documents/bash/bash-git/encrypt.sh ~/.dotfiles/
source "$(dirname "$0")/git-push.sh"
source "$(dirname "$0")/git-pull.sh"
source "$(dirname "$0")/git-clone.sh"
source "$(dirname "$0")/git-sync.sh"

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
  gitPush 
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
