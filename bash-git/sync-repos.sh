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

  # Append exclusions
  for dir in "${excluded_dirs[@]}"; do
    find_cmd+=" ! -path $dir"
  done

  # Add redirection and sed
  find_cmd+=" 2>/dev/null | sed 's|/\.git||' > $file_path"

  # Execute the command
  eval "$find_cmd"

  # Show file lines count
  lines_count=$(wc -l < "$file_path")
  echo "Found $lines_count git repositories."

  # ask if want to see the file
  read -p "Do you want to see the file? (y/n): " answer
  if [[ "$answer" == "y" ]]; then
    if [[ -f "$file_path" ]]; then
      # bat "$file_path" --paging=always --color=always | less -R
      bat "$file_path" --color=always
    else
      echo "File not found: $file_path"
    fi
  fi

  # Ask if want to see command
  # read -p "Do you want to see the command? (y/n): " answer
  # if [[ "$answer" == "y" ]]; then
  #   echo "Command:"
  #   echo "$find_cmd"
  # fi
}

syncRepos () {
  file_path="$HOME/Downloads/git-repos.txt"

  if [[ -f "$file_path" ]]; then
    echo "File already exists. Do you want to delete it? (y/n): "
    read answer
    if [[ "$answer" == "y" ]]; then
      rm -f "$file_path"
      echo "File deleted."
      makeSync
    else
      echo "File not deleted."
    fi
  fi
}
