pullAll(){
  if [[ ! -d "$HOME/.dotfiles" ]]; then
    mkdir -p ~/.dotfiles
  fi
  cp -f ~/Documents/bash/bash-git/git-pull.sh ~/.dotfiles/

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
      alacritty -e bash -c "
        source ~/.dotfiles/git-push.sh && \
        cd '$line' && \
        echo 'Running gitPush in: $line' && \
        gitPush || echo 'gitPush failed!' && \
        echo && read -p 'Press Enter to continue...' temp
      "
      alacritty -e bash -c "
        source ~/.dotfiles/git-pull.sh && \
        cd '$line' && \
        echo 'Running gitPull in: $line' && \
        gitPull || echo 'gitPull failed!' && \
        echo && read -p 'Press Enter to continue...' temp
      "
    else
      alacritty -e bash -c "
        source ~/.dotfiles/git-pull.sh && \
        cd '$line' && \
        echo 'Running gitPull in: $line' && \
        gitPull || echo 'gitPull failed!'
      "
      echo "No uncommitted changes in $line."
    fi
  done < "$file_path"
}
