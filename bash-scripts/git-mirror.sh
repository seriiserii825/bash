#!/bin/bash

clipboard=$(xclip -o -selection clipboard)

read -p "Want to clone, push or remote? (c/p/r): " action

if [[ "$action" == "c" ]]; then
  # in clipboard instead git clone, git clone --mirror
  url=$(echo "$clipboard" | sed 's/git clone/git clone --mirror/')
  # run command
  eval "$url"
elif [[ "$action" == "p" ]]; then
  # git remote set-url origin https://github.com/your-username/your-repo.git
  # git push --mirror
  #from clipboard get url without git clone
  url=$(echo "$clipboard" | sed 's/git clone //')
  new_url="git remote set-url origin $url"
  eval "$new_url"
  git push --mirror
  echo "Repository pushed successfully."
elif [[ "$action" == "r" ]]; then
  url=$(echo "$clipboard" | sed 's/git clone //')
  new_url="git remote set-url origin $url"
  eval "$new_url"
else
  echo "Invalid action. Please enter 'c' to clone or 'p' to push."
fi
