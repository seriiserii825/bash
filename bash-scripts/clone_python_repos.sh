#!/bin/bash

current_folder="python"

repos=(
  py-wp
  py-bitbucket
  py-private
  py-vue
  py-scss
  py-sync-settings
  python-scripts
  py-arch
  py-lf
  py-commit
  py-clipboard
  py-dotfiles
)

if [[ "$(basename "$PWD")" != "$current_folder" ]]; then
  echo "Error: must be run from the '$current_folder' directory"
  exit 1
fi

for repo in "${repos[@]}"; do
  if [[ -d "$repo" ]]; then
    echo "Already exists: $repo"
  else
    url="git@github.com:seriiserii825/${repo}.git"
    echo "Cloning $url"
    git clone "$url"
  fi
done
