#!/bin/bash -x
user=$(whoami)
# choose file from downloads with fzf
file=$(ls ~/Downloads | fzf)
# loop throw file
while IFS= read -r line
do
  if [ -n "$line" ]; then
    line="/home/${user}/${line}"
    if [ -d $line ]; then
      cd $line
      git config --local mgitstatus.ignore true
      cd ~/Downloads
    else
      echo "Directory $line does not exist"
      exit
    fi
  fi
done < $file

