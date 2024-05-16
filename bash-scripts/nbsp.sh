#!/bin/bash

echo "${tgreen}Starting nbsp.sh${treset}"
echo "${tblue}Copy text with non-breaking spaces in clipboard and wait for the script to change them${treset}"
echo "${tyellow}Use text with non-breaking spaces in clipboard${treset}"
echo "${tmagenta}Press Ctrl+C to stop the script${treset}"

file_path=~/Downloads/nbsp.txt
touch $file_path

while /home/serii/Documents/bash/bash-scripts/clipnotify;
do
  sleep 2
  echo $clipboard
  clipboard=$(xclip -o -selection clipboard)
  echo $clipboard > $file_path
  bat -A $file_path
  sed -i 's/ \+/ /g' $file_path
  bat -A $file_path
  xclip -selection clipboard -i $file_path
  notify-send "$(echo -e "$clipboard")" 
done
