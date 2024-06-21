#!/bin/bash

# choose video mp4 file with fzf
video_url=$(find . -type f -name "*.mp4" | fzf)

# if video don't end with .mp4
if [[ $video_url != *.mp4 ]]; then
  echo "${tmagenta}Please select a video file${treset}"
fi


read -p "Enter quality by default is 24 (0-51): " quality

if [ -z "$quality" ]; then
    quality=24
fi

output_file=$(echo $video_url | sed "s/.mp4/_$quality.mp4/g")

if [ -f $output_file ]; then
    echo "${tmagenta}File already exists${treset}"
    read -p "Enter new file name: " output_file
fi

ffmpeg -i $video_url -vcodec libx265 -crf $quality $output_file
