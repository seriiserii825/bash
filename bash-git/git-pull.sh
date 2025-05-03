function gitPull(){
  script_dir=$1
  source "$script_dir/encrypt.sh"
  source "$script_dir/git-push.sh"
  # check for git changes
  if [ -z "$(git status --porcelain)" ]; then
    gitPush $script_dir
    git pull
  else
    git pull
  fi
}
