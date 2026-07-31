# Pushes all git repos with uncommitted changes listed in ~/Documents/git-repos.txt

pushAll(){
  script_dir=$1
  source "$script_dir/git-push.sh"
  file_path="$HOME/Documents/git-repos.txt"
  current_dir=$(pwd)

  repos=("${(@f)$(< "$file_path")}")

  for line in "${repos[@]}"; do
    [[ -z "$line" ]] && continue

    if [[ ! -d "$line/.git" ]]; then
      echo "Not a Git repository: $line"
      continue
    fi

    echo "Processing repository: $line"

    cd "$line" || continue

    if [[ -n $(git status --porcelain) ]]; then
      echo "Uncommitted changes in $line:"
      gitPush $script_dir
      if [[ $? -eq 2 ]]; then
        echo "${tred}Aborting pushAll: $line needs a pull first.${treset}"
        cd "$current_dir" || return 1
        return 1
      fi
    fi
  done
  cd "$current_dir" || exit 1
}
