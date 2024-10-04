#!/bin/bash

# get all mp4 in folder and convert to mp3
for i in *.mp4; do
    ffmpeg -i "$i" -vn -acodec libmp3lame -ac 2 -ab 160k -ar 48000 "${i%.*}.mp3"
done
