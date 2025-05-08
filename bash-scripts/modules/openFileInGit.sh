openFileInGit(){
  ## select just any file from current dir with fzf
  file=$(find . -type f | fzf --height 40% --reverse --inline-info --preview 'bat --style=numbers --color=always {}' --preview-window=up:30%:wrap)
  if [ -z "$file" ]; then
    echo "${tmagenta}No file selected${treset}"
    exit 1
  fi
  echo "File selected: $file"

  ## get remote path for git repo
  remote_path=$(git config --get remote.origin.url)
  echo "Remote path: $remote_path"

  ## open in browser selected file with git repo
  # git@github.com:seriiserii825/bash.git
  # https://github.com/seriiserii825/bash
  if [[ $remote_path == *"github"* ]]; then
    echo "remote path: $remote_path" not dir
    repo_path=$(echo $remote_path | cut -d':' -f2)
    echo "repo path: $repo_path"
    repo_path=$(echo $repo_path | cut -d'.' -f1)
    echo "repo path: $repo_path"
    # https://github.com/seriiserii825/bash/blob/main/bash-scripts/bitbucket.sh
    # https://seriiserii825/bash/blob/main/bash-git/exclude-pull.txt
    file_url="https://github.com/$repo_path/blob/$(git rev-parse --abbrev-ref HEAD)/$file"
    echo "File URL: $file_url"
    file_url=$(echo $file_url | sed 's/\.\///g')
    echo "File URL: $file_url"
    #open in browser
    xdg-open $file_url
  fi
}
