#!/bin/bash

youtube_url=$(xclip -o -selection clipboard)

# Check if the URL is valid
if [[ $youtube_url == *youtube* ]]; then
  yt-dlp -o '%(title)s.%(ext)s' --format "bestvideo+bestaudio[ext=m4a]/bestvideo+bestaudio/best" --merge-output-format mp4 $youtube_url
  # else if zen
elif [[ $youtube_url == *zen* ]]; then
  yt-dlp -o '%(title)s.%(ext)s' --format "bestvideo+bestaudio[ext=m4a]/bestvideo+bestaudio/best" --merge-output-format mp4 $youtube_url
else
  echo "${tmagenta}Error: Invalid YouTube URL.${treset}"
fi
