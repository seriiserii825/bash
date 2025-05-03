source "$HOME/.dotfiles/encrypt.sh"

function pull(){
  # check for git changes
  if [ -z "$(git status --porcelain)" ]; then
    git pull
  else
    push
    git pull
  fi
}

function gitPull(){
  pull
  decryptFiles
}
