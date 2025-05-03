function gitPull(){
  script_dir=$1
  source "$script_dir/encrypt.sh"
  source "$script_dir/git-push.sh"
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
