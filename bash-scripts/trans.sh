#!/bin/bash

# title: copy_without_linebreaks
# author: Glutanimate (github.com/glutanimate)
# modifier: Siddharth (github.com/SidMan2001)
# license: MIT license

# Parses currently selected text and removes 
# newlines
current_lang="en"
read -p "Enter current language(en, it, ru, ro, de)" current_lang


while ./clipnotify;
do
  SelectedText="$(xsel)"
  CopiedText="$(xsel -b)"
  # echo "SelectedText: $SelectedText"
  echo "CopiedText: $CopiedText"
  sleep 0.5
  clipboard=$(xclip -o -selection clipboard)
  echo "current_lang: $current_lang"
  trans -b  ":$current_lang" "$clipboard"  | tr -d '\n' | xsel -b -i 
  sleep 1
  clipboard=$(xclip -o -selection clipboard)
  notify-send "$(echo -e "$clipboard")"
done
