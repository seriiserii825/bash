function gitSync(){
  script_dir=$1
  source "$script_dir/sync-repos.sh"
  source "$script_dir/git-push-all.sh"
  source "$script_dir/git-pull-all.sh"
  source "$script_dir/sync-repos.sh"
  source "$script_dir/getCommits.sh"

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
    pushAll $script_dir
  elif [[ "$selected_item" == "Pull" ]]; then
    echo "${tmagenta}Pulling...${treset}"
    pullAll $script_dir
  elif [[ "$selected_item" == "Commits" ]]; then
    echo "${tmagenta}Commits...${treset}"
    getCommits $script_dir
  else
    echo "${tmagenta}Invalid option selected. Exiting...${treset}"
  fi
}
