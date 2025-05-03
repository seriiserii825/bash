source "$(dirname "$0")/sync-repos.sh"
source "$(dirname "$0")/git-push-all.sh"
source "$(dirname "$0")/git-pull-all.sh"
function gitSync(){
  syncRepos
  menu_items=(
    "Push"
    "Pull"
    "Commits"
  )
  # choose with fzf
  selected_item=$(printf '%s\n' "${menu_items[@]}" | fzf --height 40% --reverse --inline-info --prompt "Select an option: ")
  if [[ "$selected_item" == "Push" ]]; then
    echo "${tmagenta}Pushing...${treset}"
    pushAll
  elif [[ "$selected_item" == "Pull" ]]; then
    echo "${tmagenta}Pulling...${treset}"
    pullAll
  elif [[ "$selected_item" == "Commits" ]]; then
    echo "${tmagenta}Commits...${treset}"
  else
    echo "${tmagenta}Invalid option selected. Exiting...${treset}"
  fi
}
