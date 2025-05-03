pullAll(){
  current_dir=$(pwd)
  script_dir=$1
  source "$script_dir/git-push.sh"
  source "$script_dir/git-pull.sh"
  file_path="$HOME/Downloads/git-repos.txt"

  repos=("${(@f)$(< "$file_path")}")

  for line in "${repos[@]}"; do
    [[ -z "$line" ]] && continue

    if [[ ! -d "$line/.git" ]]; then
      echo "Not a Git repository: $line"
      continue
    fi

    echo "==============================="
    echo "Processing repository: $line"
    echo "==============================="

    cd "$line" || continue

    # check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
      gitPush $script_dir
      gitPull $script_dir
    else
      gitPull $script_dir
    fi
  done
  cd "$current_dir" || exit 1
}
