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
}

getExcludPullFiles(){
  exclude_file="$HOME/Documents/bash/bash-git/exclude-pull.txt"
  if [[ ! -f "$exclude_file" ]]; then
    echo "${tmagenta}Exclude file not found. Creating it...${treset}"
    exit 1
  fi

  files=("${(@f)$(< "$exclude_file")}")
  exclude_files=()
  for file in "${files[@]}"; do
    exclude_files+=("$file")
  done
  # remove empty lines
  exclude_files=("${exclude_files[@]//[$'\t\r\n']}")
  # return the array
  echo "${exclude_files[@]}"
}

syncRepos () {
  echo "Syncing repositories..."
  file_path="$HOME/Documents/git-repos.txt"
  pull_path="$HOME/Documents/git-repos-pull.txt"

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
  excluded_words=($(getExcludPullFiles))
  echo "Excluded words: ${excluded_words[@]}"
  # copy file_path to pull_path
  cp "$file_path" "$pull_path"
  sed -i '/^$/d' "$pull_path"
  # from pull_path remove lines that contain the excluded words
  for word in "${excluded_words[@]}"; do
    sed -i "/$word/d" "$pull_path"
  done
}
