#!/bin/bash

echo "${tgreen}Starting nbsp.sh${treset}"
echo "${tblue}Copy text with non-breaking spaces in clipboard and wait for the script to change them${treset}"
echo "${tyellow}Use text with non-breaking spaces in clipboard${treset}"
echo "${tmagenta}Press Ctrl+C to stop the script${treset}"

# while /home/serii/Documents/bash/bash-scripts/clipnotify;
# do
#   sleep 2
#   echo $clipboard
#   clipboard=$(xclip -o -selection clipboard)
#   notify-send "$(echo -e "$clipboard")"
#   lower_clipboard=$(echo $clipboard | tr '[:upper:]' '[:lower:]')
#   slug_clipboard=$(echo $lower_clipboard | tr ' ' '-')
#   # remove /()[]{}<>?| from slug
#   slug_clipboard=$(echo $slug_clipboard | tr -d '/()[]{}<>?|’')
#   xclip -selection clipboard -t text/plain -i <<< "$slug_clipboard"
#   notify-send "$(echo -e "$slug_clipboard")" 
# done
#
#

function clipboardHandler() {
  clipboard=$(xclip -o -selection clipboard)
  echo "$clipboard"
  notify-send "$clipboard"
  slug_clipboard=$(echo "$clipboard" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -d '/()[]{}<>?|’')
  # remove :,'" from sug
  slug_clipboard=$(echo "$slug_clipboard" | tr -d ':,"')
  # remove '
  slug_clipboard=$(echo "$slug_clipboard" | tr -d "'")
  # remove newline at the end
  slug_clipboard=$(echo "$slug_clipboard" | tr -d '\n')
  # after paste i have newline remove it
  slug_clipboard=$(echo "$slug_clipboard" | tr -d '\r')
  xclip -selection clipboard -t text/plain -i <<< "$slug_clipboard"
  notify-send "$slug_clipboard"
}

clipboardHandler

while /home/serii/Documents/bash/bash-scripts/clipnotify; do
  sleep 2
  clipboardHandler
done
