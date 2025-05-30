#! /bin/bash

echo "Copy old bitbucket url to clipboard"
echo "Create new repo, add group and copy url"
echo "Repository permissions -> Add users or groups -> add bitbucket-users-blueline2025"

read -p "Continue? (y/n): " answer
if [[ "$answer" != "y" ]]; then
  echo "${tmagenta}Exiting script.${treset}"
  exit 0
fi

function getOldUrl(){
  clipboard=$(xclip -o -selection clipboard)
  # check if cliboard has bitbucket word
  if [[ ! "$clipboard" =~ bitbucket ]]; then
    echo "${tmagenta}Clipboard does not contain a Bitbucket URL. Please copy the URL to your clipboard and try again.${treset}"
    exit 1
  fi
  old_url=$clipboard

  # in old url after git clone word add --mirror
  # old_url is like git clone git@bitbucket.org:sites-bludelego/lm-ecomacchine.git
  # from old_url is like git clone git@bitbucket.org:sites-bludelego/lm-ecomacchine.git i need lm-ecomacchine to extract
  repo_name=$(echo "$old_url" | awk -F'/' '{print $NF}' | sed 's/\.git$//')
  echo "${tgreen}Repository name extracted: $repo_name${treset}"
  echo "${tgreen}Cloning old repository...${treset}"
  old_url=$(echo "$old_url" | sed 's/git clone /git clone --mirror /')
  eval "$old_url"
  cd "${repo_name}.git"
  echo "${tgreen}Old repository cloned successfully.${treset}"
}


function setAndPushToNewUrl(){
  echo "Copy ssh url from new repo"
  read -p "Enter the new Bitbucket URL: " new_url

  if [[ -z "$new_url" ]]; then
    echo "${tmagenta}No new URL provided. Exiting.${treset}"
    exit 1
  fi

  # instead of git clone set git push --mirror
  new_url=$(echo "$new_url" | sed 's/git clone /git push --mirror /')
  echo "new_url: $new_url"
  eval "$new_url"
  if [[ $? -ne 0 ]]; then
    echo "${tmagenta}Failed to push to the new URL. Please check the URL and try again.${treset}"
    exit 1
  fi
  echo "${tgreen}Repository pushed to new URL successfully.${treset}"
}

getOldUrl
setAndPushToNewUrl

