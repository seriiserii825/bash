#!/bin/bash

video_url=$(fzf)

if [ -z "$video_url" ]; then
    echo "${tmagenta}No video selected${treset}"
    exit 1
fi

# if video don't end with .mp4
if [[ $video_url != *.mp4 ]]; then
  echo "${tmagenta}Please select a video file${treset}"
fi

output_file=$(echo $video_url | sed 's/.mp4/_optimized.mp4/g')

if [ -f $output_file ]; then
    echo "${tmagenta}File already exists${treset}"
    read -p "Enter new file name: " output_file
fi

ffmpeg -i $video_url -vcodec libx265 -crf 28 $output_file
