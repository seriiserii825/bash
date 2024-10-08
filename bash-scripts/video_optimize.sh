#!/bin/bash

# get all mp4 in folder and convert to mp3
for i in *.mp4; do
    # ffmpeg -i "$i" -vn -acodec libmp3lame -ac 2 -ab 160k -ar 48000 "${i%.*}.mp3"
    optimized_name="${i%.*}_optimized.mp4"
    ffmpeg -i "$i" -vcodec libx264 -crf 28 -preset slow -acodec aac -b:a 128k $optimized_name
done
