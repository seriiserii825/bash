pushAll(){
  script_dir=$1
  source "$script_dir/git-push.sh"
  file_path="$HOME/Downloads/git-repos.txt"
  current_dir=$(pwd)

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

    if [[ -n $(git status --porcelain) ]]; then
      echo "Uncommitted changes in $line:"
      gitPush $script_dir
    fi
  done
  cd "$current_dir" || exit 1
}
