#!/bin/bash
while /home/serii/Documents/bash/bash-scripts/clipnotify;
do
  sleep 2
  echo $clipboard
  clipboard=$(xclip -o -selection clipboard)
  new_value="<strong>$clipboard</strong>"
  #new value to clipboard
  echo -n $new_value | xclip -selection clipboard
  notify-send "$(echo -e "$new_value")" 
done
