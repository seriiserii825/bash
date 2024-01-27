#!/bin/bash
cd ~/Downloads
md_path=~/Downloads/index.md
touch $md_path

echo "$(xclip -o -selection clipboard)" > $md_path
bat $md_path
pandoc --columns=1000 -f markdown $md_path | xclip -selection clipboard


