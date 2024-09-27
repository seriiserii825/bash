#!/bin/bash
while /home/serii/Documents/bash/bash-scripts/clipnotify;
do
  sleep 2
  output_file=~/Downloads/new_file.txt
  touch $output_file
  xsel --clipboard --output > "$output_file"
  file_content=$(cat $output_file)
  notify-send "$(echo -e "$file_content")" 
  # loop thorw file and add <ul and li tags
  new_value="<ul>\n"
  while IFS= read -r line
  do
    new_value+="<li>$line</li>\n"
  done < "$output_file"
  new_value+="</ul>"
  #remove empty lines
  new_value=$(echo -e "$new_value" | sed '/^\s*$/d')
  echo -n $new_value | xclip -selection clipboard
  notify-send "$(echo -e "$new_value")" 

done
