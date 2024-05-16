#!/bin/bash



while /home/serii/Documents/bash/bash-scripts/clipnotify;
do
  clipboard=$(xclip -o -selection clipboard)
  notify-send "$(echo -e "$clipboard")" 
  touch ~/Downloads/special_chars.txt
  echo "$clipboard" > ~/Downloads/special_chars.txt
  grep -oP '[^\x00-\x7F]' ~/Downloads/special_chars.txt | sort | uniq -c | sort -nr
  sed -i 's/ / /g' ~/Downloads/special_chars.txt
# copy to buffer
xclip -selection clipboard ~/Downloads/special_chars.txt
done

# rm ~/Downloads/special_chars.txt
# echo "Special characters copied to clipboard."
