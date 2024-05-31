#!/bin/bash

inotifywait -m /home/serii/Downloads -e create -e moved_to |
  while read dir action file; do
    if [[ $file == *.jpg ]]; then
      full_path="$dir""$file"
      file_weight=$(du -h $full_path)
      echo $file_weight
      # notify-send "$(echo $file_weight)"
      jpegoptim --strip-all --all-progressive -ptm 80 $full_path >> /dev/null
      file_weight=$(du -h $full_path)
      echo $file_weight
      # notify-send "$(echo $file_weight)"
    fi
  done


