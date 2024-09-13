#!/bin/bash

file_path=~/Downloads/gitstatus.txt
touch $file_path
find ~ -maxdepth 5 -name ".git" -type d -exec bash -c "echo '{}' && pwd" \; > $file_path
sed -i '/.cache/d' $file_path
sed -i '/yay/d' $file_path
sed -i '/Downloads/d' $file_path

function gitPush(){
  modified_files_path=~/Downloads/modified_files.txt
  mod=0
  line=$1
  # Check for modified files
  if [ $(git status | grep modified -c) -ne 0 > /dev/null ]
  then
    echo -en "\033[0;31m"
    echo $line
    echo "Modified files"
    echo -en "\033[0m"
  fi

  # Check for untracked files
  if [ $(git status | grep Untracked -c) -ne 0 > /dev/null ]
  then
    echo -en "\033[0;31m"
    echo $line
    echo "Untracked files"
    echo -en "\033[0m"
  fi

  # Check for unpushed changes
  if [ $(git status | grep 'Your branch is ahead' -c) -ne 0 > /dev/null ]
  then
    echo -en "\033[0;31m"
    echo $line
    echo "Unpushed commit"
    echo -en "\033[0m"
  fi
}

function gitPull(){
  changed=0
  git remote update && git status -uno | grep -q 'Your branch is behind' && changed=1
  if [ $changed = 1 ]; then
    echo "${tmagenta}Neet to pull${treset}"
    git status | grep -q 'nothing to commit, working tree clean' && git pull || git add . && git commit -m "auto commit" && git pull
    echo "${tblue}Updated successfully${treset}";
  else
    echo "${tgreen}Up-to-date${treset}"
  fi
}


read -p "${tblue}Do you want to push or pull? (push/pull) ${treset}" action

while IFS= read -r line
do
  cd $line
  cd ..
  if [ $action = "push" ]; then
    gitPush "$line"
  elif [ $action = "pull" ]; then
    gitPull
  else
    echo "${tmagenta}Invalid action${treset}"
  fi
done < $file_path

rm $file_path



