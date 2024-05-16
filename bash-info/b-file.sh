#!/bin/bash
file_find=$(find -name "front-page.php");
file_path=$(fzf)
file_name=$(basename $file_path)
file_without_extension="${file_name%.*}"
file_extention=${file_name##*.}
word_before_dash="${file_name%%-*}"
capital_name="${file_name^}"

#buffer to file
acf_path=$(touch ~/Downloads/acf.txt)
echo "$(xclip -o -selection clipboard)" > $acf_path

#file to buffer
xclip -sel clip < $acf_path

# read file
while read -r line; do
  echo "line: $line"
done < "$acf_path"

# get path of current file
current_path=$(pwd);
IFS='/' read -r -a array <<< "$current_path"

for index in "${!array[@]}"
do
  element=${array[index]}
  echo "element: $element"
  if [ "$index" -ne 0 ]; then
    full_url="$full_url/${element}";
  fi
done

echo "full_url: $full_url"
