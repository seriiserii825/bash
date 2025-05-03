pushAll(){
  script_dir=$1
  source "$script_dir/git-push.sh"
  file_path="$HOME/Downloads/git-repos.txt"

  # loop through all lines in file
  while IFS= read -r line; do
    # skip empty lines
    [[ -z "$line" ]] && continue

    # check if line is a directory and a Git repo
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
      echo "Uncommitted changes in $line:"
      gitPush $script_dir
    else
      echo "No uncommitted changes in $line."
    fi
  done < "$file_path"
}
