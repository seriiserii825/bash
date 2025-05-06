selectProjectWithFzf(){
  today_projects=("$@")
  print -n "${tmagenta}Select a project, (y/n): ${treset}"
  read -r selected_project
  if [[ "$selected_project" == "y" ]]; then
    selected_project=$(printf '%s\n' "${today_projects[@]}" | fzf --height 40% --reverse --inline-info --prompt "Select a project: ")
    if [[ -n "$selected_project" ]]; then
      cd "$selected_project" || exit
      today_commits=$(git log --since="${today_date} 01:00:00" --oneline | sed 's/^[^ ]* //' | tac)
      #today commits to clipboard
      #from today_commits remove feat: upd: fix:
      today_commits=$(echo "$today_commits" | sed 's/feat://')
      today_commits=$(echo "$today_commits" | sed 's/upd://')
      today_commits=$(echo "$today_commits" | sed 's/fix://')
      echo "$today_commits" | xclip -i -selection clipboard
      notify-send "$today_commits"
      selectProjectWithFzf $today_projects
    else
      echo "No project selected."
    fi
  fi
}
getCommits() {
  script_dir=$1
  source "$script_dir/sync-repos.sh"
  file_path="$HOME/Documents/git-repos.txt"
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
      #show today commits       
      echo "${tblue}$line${treset}"
      today_commits=$(git log --since="${today_date} 01:00:00" --oneline | sed 's/^[^ ]* //' | tac)
      echo "$today_commits"
      echo "----------------------------------------"
    fi
  done < "$file_path"
  # show projects
  if [[ ${#today_projects[@]} -eq 0 ]]; then
    echo "No projects modified today."
  else
    selectProjectWithFzf $today_projects
  fi
  cd "$current_dir" || exit
}
