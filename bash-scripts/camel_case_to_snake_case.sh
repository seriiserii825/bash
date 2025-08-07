#!/bin/sh

toSnakeCase(){
  content_from_clipboard=$(xclip -selection clipboard -o)
  snake_case=$(echo "$content_from_clipboard" | sed -E 's/([a-z])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]')
  printf "%s" "$snake_case" | xclip -selection clipboard -i
  notify-send "Converted to snake_case" "$snake_case"
}

file_path=~/Downloads/nbsp.txt
touch $file_path

while /home/serii/Documents/bash/bash-scripts/clipnotify;
do
  sleep 1
  toSnakeCase
done
