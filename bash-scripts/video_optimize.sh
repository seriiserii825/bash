#!/bin/bash

choosed_video_with_fzf=$(find . -maxdepth 1 -type f -name "*.mp4" | fzf)

if [ -z "$choosed_video_with_fzf" ]; then
    echo "No video selected."
    exit 1
fi

read -p "Enter quality (18-28), 18 best : " quality
if [[ ! "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 18 ] || [ "$quality" -gt 28 ]; then
    echo "Invalid input. Using default value: 20"
    quality=20
fi

output_dir="./optimized"
mkdir -p "$output_dir"
optimized_name="$output_dir/$(basename "${choosed_video_with_fzf%.*}_optimized_${quality}.mp4")"

ffmpeg -i "$choosed_video_with_fzf" -vcodec libx264 -crf "$quality" -preset slow -acodec aac -b:a 128k "$optimized_name"

echo "✅ Optimization complete: $optimized_name"
