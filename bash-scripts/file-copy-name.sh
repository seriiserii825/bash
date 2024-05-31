#!/bin/bash

echo "${tgreen}Starting file_copy${treset}"

while /home/serii/Documents/bash/bash-scripts/clipnotify;
do
  sleep 2
  clipboard=$(xclip -o -selection clipboard)
  notify-send "$(echo -e "$clipboard")" 
  file_name_from_path=$(basename $clipboard)
  sleep 1
  echo $file_name_from_path | xclip -selection clipboard
  notify-send "$(echo -e "$file_name_from_path")" 
done
