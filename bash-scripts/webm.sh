#! /bin/bash

# Check if ffmpeg is installed
if ! [ -x "$(command -v ffmpeg)" ]; then
  echo 'Error: ffmpeg is not installed.' >&2
  exit 1
fi

mkdir mp3

## if has webm files
if [ -f *.webm ]; then
    for FILE in *.webm; do
        echo -e "Processing video '\e[32m$FILE\e[0m'";
        # ffmpeg -i "${FILE}" "${FILE%.webm}.mp3"; 
        ffmpeg -i "${FILE}" -vn -ab 128k -ar 44100 -y "mp3/${FILE%.webm}.mp3";
    done;
fi

## if has wav files
if [ -f *.wav ]; then
    for FILE in *.wav; do
        echo -e "Processing video '\e[32m$FILE\e[0m'";
        # ffmpeg -i "${FILE}" "${FILE%.webm}.mp3"; 
        ffmpeg -i "${FILE}" -vn -ab 128k -ar 44100 -y "mp3/${FILE%.webm}.mp3";
    done;
fi

