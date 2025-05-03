makeSync(){
  excluded_dirs=(
    "*/autoload/*"
    "*/.tmux/*"
    "*/.cache/*"
    "*/.local/*"
    "*/snapd/*"
    "*/JetBrains/*"
    "*/IdeaProjects/*"
    "*/.oh-my-zsh/*"
    "*/advanced-custom-fields-wpcli/*"
  )

  # Start building the find command
  find_cmd="find ~ -type d -name '.git'"

  # Append exclusions, making sure to escape any special characters properly
  for dir in "${excluded_dirs[@]}"; do
    find_cmd+=" ! -path \"$dir\""
  done

  # Add redirection and sed
  find_cmd+=" 2>/dev/null | sed 's|/\.git||' > \"$file_path\""

  # Execute the command
  eval "$find_cmd"

  # Check if the file is created
  if [[ ! -f "$file_path" ]]; then
    echo "No repositories found or file creation failed."
    return 1
  fi

  # Show file lines count
  lines_count=$(wc -l < "$file_path")
  echo "Found $lines_count git repositories."

  # Ask if the user wants to see the file
  print -n "${tgreen}Do you want to see the file? (y/n):  ${treset}"
  read answer
  if [[ "$answer" == "y" ]]; then
    if [[ -f "$file_path" ]]; then
      bat "$file_path" --color=always
    else
      echo "File not found: $file_path"
    fi
  fi
}

syncRepos () {
  echo "Syncing repositories..."
  file_path="$HOME/Downloads/git-repos.txt"

  if [[ -f "$file_path" ]]; then
    print -n "${tgreen}File already exists. Do you want to delete it? (y/n):  ${treset}"
    read answer
    if [[ "$answer" == "y" ]]; then
      rm -f "$file_path"
      echo "File deleted."
      makeSync
    else
      echo "File not deleted."
    fi
  else
    makeSync
  fi
}
