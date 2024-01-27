#!/bin/bash

youtube_url=$(xclip -o -selection clipboard)

# Check if the URL is valid
if [[ $youtube_url == *youtube* ]]; then
    echo "YouTube URL is valid."
    video_id="${BASH_REMATCH[1]}"
    echo "${tgreen}Video ID: $video_id${treset}"
    # mpv $youtube_url &
    smplayer $youtube_url &
    # yt playurl $video_id
else
    echo "${tmagenta}Error: Invalid YouTube URL.${treset}"
fi
