#!/usr/bin/bash
# YouTube/VK/Zen/Twitch helper: download as mp3/mp4 or open in mpv

source /home/serii/dotfiles/zsh_modules/zsh_colors

directory="$HOME/Downloads/youtube"
file_path="$HOME/Downloads/youtube/yt.txt"

function ensureDirAndFile(){
  if [ ! -d "$directory" ]; then
    mkdir "$directory"
    echo "Directory created at $directory"
  fi

  if [ ! -f "$file_path" ]; then
    touch "$file_path"
    echo "File created at $file_path"
  fi
}

function convertToMp3(){
  cd "$directory"
  bat "$file_path"
  while read -r line; do
    new_line=$(echo "$line" | sed 's/&list.*//g')
    yt-dlp -x --audio-quality 0 --audio-format mp3 --embed-thumbnail --embed-metadata \
      --cookies-from-browser firefox \
      -o "%(title)s.%(ext)s" "$new_line"
  done < yt.txt
  cp "$directory"/*.mp3 "$HOME/Downloads"
}

function clipboardToFile(){
  xclip -selection clipboard -o > "$file_path"
  echo >> "$file_path"
}

function clearFile(){
  > "$file_path"
}

function viewFile(){
  bat "$file_path"
}

function removeMp3Files(){
  rm "$directory"/*.mp3
}

function resetMp3State(){
  viewFile
  clearFile
  removeMp3Files
  viewFile
}

function downloadMp3(){
  ensureDirAndFile
  resetMp3State
  clipboardToFile
  convertToMp3
  rename 's/ /_/g' ~/Downloads/*.mp3
  id3v2 -D ~/Downloads/*.mp3
  notify-send "yt_mp3" "Download complete" --icon=audio-x-generic
}

function downloadMp4(){
  local youtube_url
  youtube_url=$(xclip -o -selection clipboard)

  if [[ $youtube_url != *youtube* && $youtube_url != *zen* && $youtube_url != *vkvideo* && $youtube_url != *vk.com/video* ]]; then
    echo "${tmagenta}Error: Invalid YouTube/VK/Zen URL.${treset}"
    return 1
  fi

  local quality height
  echo "${tgreen}1) 1080p${treset}"
  echo "${tgreen}2) 2K (1440p)${treset}"
  echo "${tgreen}3) 4K (2160p)${treset}"
  read -rp "Select quality: " quality
  case $quality in
    1) height=1080 ;;
    2) height=1440 ;;
    3) height=2160 ;;
    *)
      echo "${tmagenta}Invalid quality.${treset}"
      return 1
      ;;
  esac

  yt-dlp -o '%(title)s.%(ext)s' \
    --format "bestvideo[height<=$height]+bestaudio[ext=m4a]/bestvideo[height<=$height]+bestaudio/best[height<=$height]" \
    --merge-output-format mp4 --cookies-from-browser firefox "$youtube_url"

  notify-send "yt_mp4" "Download complete" --icon=video-x-generic
}

function openInMpv(){
  local youtube_url
  youtube_url=$(xclip -o -selection clipboard)

  if [[ $youtube_url == *youtube* ]]; then
    echo "YouTube URL is valid."
    mpv --msg-level=ffmpeg=no,cplayer=warn "$youtube_url" &
  elif [[ $youtube_url == *twitch* ]]; then
    mpv --msg-level=ffmpeg=no,cplayer=warn "$youtube_url" &
  elif [[ $youtube_url == *vkvideo* ]]; then
    mpv --msg-level=ffmpeg=no,cplayer=warn "$youtube_url" &
  else
    echo "${tmagenta}Error: Invalid YouTube/Twitch/VK URL.${treset}"
  fi
}

while true; do
  echo ""
  echo "${tblue}--- yt ---${treset}"
  echo "${tgreen}1) Download from clipboard as MP3${treset}"
  echo "${tgreen}2) Download from clipboard as MP4 (YouTube/VK/Zen)${treset}"
  echo "${tgreen}3) Open clipboard URL in mpv (YouTube/Twitch/VK)${treset}"
  echo "4) Exit"

  read -rp "Select an option: " option
  case $option in
    1)
      downloadMp3
      ;;
    2)
      downloadMp4
      ;;
    3)
      openInMpv
      ;;
    4)
      exit 0
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
