#!/bin/bash

youtube_url=$(xclip -o -selection clipboard)

# Check if the URL is valid
if [[ $youtube_url == *youtube* ]]; then
    echo "YouTube URL is valid."
    video_id="${BASH_REMATCH[1]}"
    echo "${tgreen}Video ID: $video_id${treset}"
    # mpv $youtube_url &
    mpv $youtube_url &
    # yt playurl $video_id
elif [[ $youtube_url == *twitch* ]]; then
    mpv $youtube_url &
elif [[ $youtube_url == *vkvideo* ]]; then
    mpv $youtube_url &
else
    echo "${tmagenta}Error: Invalid YouTube URL.${treset}"
fi
