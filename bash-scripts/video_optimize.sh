#!/bin/bash

choosed_video_with_fzf=$(find . -maxdepth 1 -type f -name "*.mp4" | fzf)

if [ -z "$choosed_video_with_fzf" ]; then
    echo "No video selected."
    exit 1
fi

read -p "Enter quality (18-28), 28 best : " quality
if [[ ! "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 18 ] || [ "$quality" -gt 28 ]; then
    echo "Invalid input. Using default value: 20"
    quality=20
fi

read -p "Remove audio? (y/n): " remove_audio

base_name="$(basename "${choosed_video_with_fzf%.*}")"

if [[ "$remove_audio" =~ ^[Yy]$ ]]; then
    optimized_name="${base_name}_optimized_${quality}-no-audio.mp4"
    ffmpeg -i "$choosed_video_with_fzf" -c:v libx264 -crf "$quality" -preset slow -an "$optimized_name"
else
    optimized_name="${base_name}_optimized_${quality}.mp4"
    ffmpeg -i "$choosed_video_with_fzf" -c:v libx264 -crf "$quality" -preset slow -c:a aac -b:a 96k "$optimized_name"
fi

echo "✅ Optimization complete: $optimized_name"
