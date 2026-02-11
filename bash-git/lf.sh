lf(){
  script_dir="$HOME/Documents/bash/bash-git"
  source "$script_dir/git-push.sh"
  source "$script_dir/git-pull.sh"
  source "$script_dir/git-clone.sh"
  source "$script_dir/git-sync.sh"
  source "$script_dir/openFileInGit.sh"
  source "$script_dir/resolveConflict.sh"

  # Define color variables
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

  echo "${tmagenta}Welcome to the Git CLI!${treset}"
  echo "${tgreen}1) Push${treset}"
  echo "${tgreen}2) Pull${treset}"
  echo "${tgreen}3) Sync${treset}"
  echo "${tgreen}4) Clone${treset}"
  echo "${tblue}5) LogAll${treset}"
  echo "${tblue}6) Clipboard${treset}"
  echo "${tyellow}7) OpenFileInGit${treset}"
  echo "${tblue}8) ResolveConflict${treset}"
  echo "${tmagenta}9) Exit${treset}"

  print "Please select an option (1-9): "
  read -r selected_item

  echo "selected_item: $selected_item"
  # if nothing was selected by default is 1
  if [[ -z "$selected_item" ]]; then
    selected_item=1
  fi

  if [[ "$selected_item" == "1" ]]; then
    echo "${tmagenta}Pushing...${treset}"
    message="$*"
    if [[ -z "$message" ]]; then
      echo "No commit message provided. Exiting..."
      return
    fi
    gitPush $script_dir "$message"
  elif [[ "$selected_item" == "2" ]]; then
    echo "${tmagenta}Pulling...${treset}"
    gitPull $script_dir
  elif [[ "$selected_item" == "3" ]]; then
    echo "${tmagenta}Syncing...${treset}"
    gitSync $script_dir
  elif [[ "$selected_item" == "4" ]]; then
    echo "${tmagenta}Cloning...${treset}"
    gitClone
  elif [[ "$selected_item" == "5" ]]; then
    $(git log --pretty="%C(Yellow)%h  %C(reset)%ad (%C(Green)%cr%C(reset))%x09 %C(Cyan)%an: %C(reset)%s" --date=short -100 --reverse > log.log)
    bat log.log
    rm log.log
  elif [[ "$selected_item" == "6" ]]; then
    log=$(git log --since="3am" --pretty=tformat:"%s" --reverse > log.log);
    sed -i 's/feat://' log.log
    sed -i 's/upd://' log.log
    sed -i 's/fix://' log.log
    text=$(cat log.log)
    cat log.log | xclip -selection clipboard
    notify-send  "Copied" "$text"
    rm log.log
    echo "${tmagenta}Copied to clipboard.${treset}"
  elif [[ "$selected_item" == "7" ]]; then
    echo "${tmagenta}Opening file in git...${treset}"
    openFileInGit
  elif [[ "$selected_item" == "8" ]]; then
    echo "${tmagenta}Resolving conflict...${treset}"
    resolveConflict
  elif [[ "$selected_item" == "9" ]]; then
    echo "${tmagenta}Exiting...${treset}"
    # exit 0
  else
    echo "${tmagenta}Invalid option selected. Exiting...${treset}"
  fi
}
