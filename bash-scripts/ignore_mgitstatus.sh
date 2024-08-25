#!/bin/bash -x
user=$(whoami)
clipboard=$(xclip -o)
file=~/Downloads/ignore_mgitstatus.txt
touch $file
echo $clipboard > ~/Downloads/ignore_mgitstatus.txt
# for each line in file remove ./ from the beginning
sed -i 's/^\.\///g' ~/Downloads/ignore_mgitstatus.txt
# choose file from downloads with fzf
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

rm $file
