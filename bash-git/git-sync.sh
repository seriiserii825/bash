function gitSync(){
  script_dir=$1
  source "$script_dir/sync-repos.sh"
  source "$script_dir/pushAll.sh"
  source "$script_dir/pullAll.sh"
  source "$script_dir/sync-repos.sh"
  source "$script_dir/getCommits.sh"

  syncRepos

  menu_items=(
    "Push"
    "Pull"
    "Commits"
    "View Push file"
    "View Pull file"
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
  elif [[ "$selected_item" == "View Push file" ]]; then
    bat "$HOME/Documents/git-repos.txt" --color=always
  elif [[ "$selected_item" == "View Pull file" ]]; then
    bat "$HOME/Documents/git-repos-pull.txt" --color=always
  else
    echo "${tmagenta}Invalid option selected. Exiting...${treset}"
  fi
}
