#!/usr/bin/env bash

BASE_URL="https://github.com/seriiserii825"
REPO_FILE="repos.txt"

if [[ ! -f "$REPO_FILE" ]]; then
  echo "Repository list file '$REPO_FILE' not found!"
  echo "example content:"
  echo "repo1"
  echo "repo2"
  exit 1
fi

while IFS= read -r repo; do
  # Skip empty lines
  [[ -z "$repo" ]] && continue

  # If folder doesn't exist, clone it
  if [[ ! -d "$repo" ]]; then
    echo "Cloning $repo..."
    git clone "$BASE_URL/$repo.git"
  else
    echo "Skipping $repo (already exists)"
  fi
done < "$REPO_FILE"
