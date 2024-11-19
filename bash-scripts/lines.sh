#!/bin/bash
new_value=$(xclip -o)
echo -e "$new_value" > /home/serii/Downloads/lines.txt
bat /home/serii/Downloads/lines.txt

tac /home/serii/Downloads/lines.txt > /home/serii/Downloads/lines.txt.tmp
bat /home/serii/Downloads/lines.txt.tmp

# read each line from file and add in to clipboard
while IFS= read -r line; do
  xclip -selection clipboard -i <<< "$line"
  sleep 0.5
done < /home/serii/Downloads/lines.txt.tmp

notify-send "Lines copied to clipboard" 
exit
