source "$(dirname "$0")/encrypt.sh"

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
