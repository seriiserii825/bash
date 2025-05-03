pushAll(){
  script_dir="$HOME/Documents/bash/bash-git"
  source "$script_dir/git-push.sh"

  file_path="$HOME/Downloads/git-repos.txt"

  # Loop through all lines in file
  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Check if line is a directory and a Git repo
    if [[ ! -d "$line/.git" ]]; then
      echo "Not a Git repository: $line"
      continue
    fi

    echo "==============================="
    echo "Processing repository: $line"
    echo "==============================="

    cd "$line" || continue

    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
      echo "Uncommitted changes in $line:"
      
      # Here we call gitPush and ensure it asks for a commit message
      gitPush $script_dir
    else
      echo "No uncommitted changes in $line."
    fi
  done < "$file_path"
}
