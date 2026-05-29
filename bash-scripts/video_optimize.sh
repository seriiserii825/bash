#!/bin/bash

choosed_video_with_fzf=$(find . -maxdepth 1 -type f -name "*.mp4" | fzf)

if [ -z "$choosed_video_with_fzf" ]; then
    echo "No video selected."
    exit 1
fi

read -p "Enter quality (18-51), default 30 (web hero): " quality
if [[ ! "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 18 ] || [ "$quality" -gt 51 ]; then
    echo "Invalid input. Using default value: 30"
    quality=30
fi

read -p "Remove audio? (y/n): " remove_audio

base_name="$(basename "${choosed_video_with_fzf%.*}")"

if [[ "$remove_audio" =~ ^[Yy]$ ]]; then
    optimized_name="${base_name}_optimized_${quality}-no-audio.mp4"
    ffmpeg -i "$choosed_video_with_fzf" \
        -c:v libx264 -crf "$quality" -preset slow \
        -profile:v high -level 4.0 \
        -pix_fmt yuv420p \
        -movflags +faststart \
        -an \
        "$optimized_name"
else
    optimized_name="${base_name}_optimized_${quality}.mp4"
    ffmpeg -i "$choosed_video_with_fzf" \
        -c:v libx264 -crf "$quality" -preset slow \
        -profile:v high -level 4.0 \
        -pix_fmt yuv420p \
        -movflags +faststart \
        -c:a aac -b:a 96k \
        "$optimized_name"
fi

echo "✅ Optimization complete: $optimized_name"
