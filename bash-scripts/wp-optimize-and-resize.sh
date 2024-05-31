#!/bin/bash

echo "${tgreen}Starting file_copy${treset}"

# url='http://lc-giorizga.local/wp-content/uploads/2023/01/Villa-Gallo-47-min.jpg'
get_path_from_url() {
  local url=$1
  # Remove the protocol (http:// or https://)
  url_without_protocol=$(echo "$url" | sed -e 's|^[^/]*//||')
  # Remove everything up to the first slash
  full_path=$(echo "$url_without_protocol" | sed -e 's|^[^/]*/||')
  # Add a leading slash
  echo "/$full_path"
}


while /home/serii/Documents/bash/bash-scripts/clipnotify;
do
  sleep 2

  clipboard=$(xclip -o -selection clipboard)
  notify-send "$(echo -e "$clipboard")" 

  url=$clipboard
  fname=$(get_path_from_url "$url")
  # fname without first slash
  fname=${fname:1}
  notify-send "$(echo -e "$fname")" 

  if [[ $fname == *.jpg ]]; then
    width=$(identify -format "%w" "$fname")> /dev/null
    height=$(identify -format "%h" "$fname")> /dev/null
    echo "filesize: $width x $height"
    du -sh "$fname"

    file_weight=$(du -sh "$fname")

    notify-send "$(echo -e "filesize: $width x $height")" 
    notify-send "$(echo -e "$file_weight")" 

    mogrify -resize x900 "$fname" > /dev/null
    jpegoptim --strip-all --all-progressive -ptm 80 "$fname" > /dev/null

    width=$(identify -format "%w" "$fname")> /dev/null
    height=$(identify -format "%h" "$fname")> /dev/null

    echo "filesize: $width x $height"
    file_weight=$(du -sh "$fname")

    notify-send "$(echo -e "filesize: $width x $height")" 
    notify-send "$(echo -e "$file_weight")" 
  fi
done
