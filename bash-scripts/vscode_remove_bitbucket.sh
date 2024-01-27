#!/bin/bash

site_path=~/Downloads/site.txt
output_path=~/Downloads/output.txt
touch $site_path

echo "$(xclip -o -selection clipboard)" > $site_path

bat $site_path

while read -r line; do
  git clone "git@bitbucket.org:sites-bludelego/$line.git"
  cd $line
  rm -rf .vscode
  git add .
  git commit -m "removed vscode"
  git push
  echo ".vscode" >> .gitignore
  git add .
  git commit -m "added vscode to .gitignore"
  git push
  git restore .
  git clean -f   
  git clean -df
  git status
  cd ..
  rm -rf $line
  echo "================================================= removed $line"
done < "$site_path"

rm $site_path
