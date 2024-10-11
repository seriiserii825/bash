#!/bin/bash

choosed_video_with_fzf=$(find . -maxdepth 1 -type f -name "*.mp4" | fzf)

read -p "Enter quality (18-28), 18 best : " quality
if [ -z "$quality" ]; then
    quality=20
fi

# optimized_name="${i%.*}_optimized_${quality}.mp4"
optimized_name="${choosed_video_with_fzf%.*}_optimized_${quality}.mp4"
ffmpeg -i "$choosed_video_with_fzf" -vcodec libx264 -crf $quality -preset slow -acodec aac -b:a 128k $optimized_name
