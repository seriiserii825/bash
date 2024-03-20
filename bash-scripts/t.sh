#!/bin/bash

# title: copy_without_linebreaks
# author: Glutanimate (github.com/glutanimate)
# modifier: Siddharth (github.com/SidMan2001)
# license: MIT license

# Parses currently selected text and removes 
# newlines
current_lang="en"
read -p "Enter current language("${tgreen}en${treset}", "${tblue}it${treset}", "${tmagenta}ru${treset}", "${tyellow}ro${treset}", "${tblue}en${treset}")" current_lang


while /home/serii/Documents/bash/bash-scripts/clipnotify;
do
  # SelectedText="$(xsel)"
  # CopiedText="$(xsel -b)"
  # echo "SelectedText: $SelectedText"
  # echo "CopiedText: $CopiedText"
  sleep 2
  clipboard=$(xclip -o -selection clipboard)
  echo "clipboard: $clipboard"
  echo "current_lang: $current_lang"
  trans -b  ":$current_lang" "$clipboard"  | tr -d '\n' | xsel -b -i && 
  clipboard=$(xclip -o -selection clipboard)  &&
  notify-send "$(echo -e "$clipboard")" 
done
