#!/bin/bash

current_folder="chrome-extensions"

repos=(
  quick-tabs-project 
  chrome-svg-copy
  chrome-fill-form
  chrome-autofill
  chrome-image
  chrome-tabs-copy
  chrome-autocopy
  chrome-wp-admin
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
