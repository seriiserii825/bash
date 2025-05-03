getCommits() {
  script_dir=$1
  source "$script_dir/sync-repos.sh"
  file_path="$HOME/Downloads/git-repos.txt"
  today_projects=()
  current_dir=$(pwd)
  today_commits=()
  
  # get today's date in YYYY-MM-DD format
  today_date=$(date +%F)

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ ! -d "$line/.git" ]] && continue

    cd "$line" || continue

    # check if there are any commits since today at 01:00
    if git log --since="${today_date} 01:00:00" --oneline | grep -q .; then
      today_projects+=("$line")
    fi
  done < "$file_path"

  # show projects
  if [[ ${#today_projects[@]} -eq 0 ]]; then
    echo "No projects modified today."
  else
    echo "Projects modified today:"
    # select project with fzf
    selected_project=$(printf '%s\n' "${today_projects[@]}" | fzf --height 40% --reverse --inline-info --prompt "Select a project: ")
    if [[ -n "$selected_project" ]]; then
      cd "$selected_project" || exit
      today_commits=$(git log --since="${today_date} 01:00:00" --oneline | sed 's/^[^ ]* //' | tac)
      #today commits to clipboard
      echo "$today_commits" | xclip -i -selection clipboard
      notify-send "$today_commits" 
      cd "$current_dir" || exit
    else
      echo "No project selected."
    fi
  fi
  cd "$current_dir" || exit
}
