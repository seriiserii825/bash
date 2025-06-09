#!/bin/bash

function from_bitbucket_radu_to_bludelego(){
  # in clipboard instead git clone, git clone --mirror
  read -p "Enter repo_name: " repo_name
  local url="git clone --mirror git@bitbucket.org:blueline2025/$repo_name.git"
  eval "$url"
  cd "$repo_name.git"
  echo "Create new repo in blueline-wordpress-sites"
  create_url="https://bitbucket.org/blueline-wordpress-sites/workspace/create/repository"
  echo "$create_url"
  xdg-open "$create_url" &>/dev/null

  read -p "Press 'y' when you have created the new repo in blueline-wordpress-sites: " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Aborting..."
    exit 1
  fi

  echo "Add group blueline-wordpress-sites to your Bitbucket account if you don't have it yet."
  group_url="https://bitbucket.org/blueline-wordpress-sites/${repo_name}/admin/permissions"
  echo "$group_url"
  xdg-open "$group_url" &>/dev/null

  local push_url="git push --mirror git@bitbucket.org:blueline-wordpress-sites/$repo_name.git"
  eval "$push_url"

  remote_url="git@bitbucket.org:blueline-wordpress-sites/$repo_name.git"
  new_url="git remote set-url origin $remote_url"
  eval "$new_url"

  cd ..

  echo "Repository $repo_name has been cloned and pushed to blueline-wordpress-sites."
  echo "Go and delete old repo in blueline2025."
}

from_bitbucket_radu_to_bludelego
