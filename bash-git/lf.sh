lf(){
  script_dir="$HOME/Documents/bash/bash-git"
  source "$script_dir/git-push.sh"
  source "$script_dir/git-pull.sh"
  source "$script_dir/git-clone.sh"
  source "$script_dir/git-sync.sh"
  source "$script_dir/openFileInGit.sh"
  source "$script_dir/resolveConflict.sh"

  if [[ $# -eq 1 && $1 == '-h' ]]; then
    echo "Usage: lf [message]"
    echo "Push, pull, sync, or clone a git repository."
    echo
    echo "Options:"
    echo "  message   The commit message to use when pushing."
    echo
    echo "Examples:"
    echo "  lf 'Initial commit'"
    echo "  lf -h"
    return
  fi

  menu_items=(
    "Clipboard"
    "Clone"
    "LogAll"
    "OpenFileInGit"
    "Pull"
    "Push"
    "Sync"
    "ResolveConflict"
  )
  # choose with fzf
  selected_item=$(printf '%s\n' "${menu_items[@]}" | fzf --height 40% --reverse --inline-info --prompt "Select an option: ")

  if [[ "$selected_item" == "Push" ]]; then
    echo "${tmagenta}Pushing...${treset}"
    message="$*"
    if [[ -z "$message" ]]; then
      echo "No commit message provided. Exiting..."
      return
    fi
    gitPush $script_dir "$message"
  elif [[ "$selected_item" == "Pull" ]]; then
    echo "${tmagenta}Pulling...${treset}"
    gitPull $script_dir
  elif [[ "$selected_item" == "Sync" ]]; then
    echo "${tmagenta}Syncing...${treset}"
    gitSync $script_dir
  elif [[ "$selected_item" == "Clone" ]]; then
    echo "${tmagenta}Cloning...${treset}"
    gitClone
  elif [[ "$selected_item" == "LogAll" ]]; then
    $(git log --pretty="%C(Yellow)%h  %C(reset)%ad (%C(Green)%cr%C(reset))%x09 %C(Cyan)%an: %C(reset)%s" --date=short -100 --reverse > log.log)
    bat log.log
    rm log.log
  elif [[ "$selected_item" == "Clipboard" ]]; then
    log=$(git log --since="3am" --pretty=tformat:"%s" --reverse > log.log);
    sed -i 's/feat://' log.log
    sed -i 's/upd://' log.log
    sed -i 's/fix://' log.log
    text=$(cat log.log)
    cat log.log | xclip -selection clipboard
    notify-send  "Copied" "$text"
    rm log.log
    echo "${tmagenta}Copied to clipboard.${treset}"
  elif [[ "$selected_item" == "OpenFileInGit" ]]; then
    echo "${tmagenta}Opening file in git...${treset}"
    openFileInGit
  elif [[ "$selected_item" == "ResolveConflict" ]]; then
    echo "${tmagenta}Resolving conflict...${treset}"
    resolveConflict
  else
    echo "${tmagenta}Invalid option selected. Exiting...${treset}"
  fi
}
