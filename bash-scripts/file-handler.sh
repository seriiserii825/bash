#!/bin/bash

[ ! -d "$1" ] && {
  printf "error: argument is not a valid directory to monitory.\n"
  exit 1
}

while :; fname="$1/$(inotifywait -q -e modify -e create --format '%f' "$1")"; do
  if [[ $fname == *.jpg ]]; then
    width=$(identify -format "%w" "$fname")> /dev/null
    height=$(identify -format "%h" "$fname")> /dev/null
    echo "filesize: $width x $height"
    du -sh "$fname"

    mogrify -resize x900 "$fname" > /dev/null
    jpegoptim --strip-all --all-progressive -ptm 80 "$fname" > /dev/null

    width=$(identify -format "%w" "$fname")> /dev/null
    height=$(identify -format "%h" "$fname")> /dev/null

    echo "filesize: $width x $height"
    du -sh "$fname"
  fi
done
