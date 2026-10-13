#!/usr/bin/bash
# YouTube/VK/Zen/Twitch/Rutube helper: download as mp3/mp4 or open in mpv

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

# split into tracks by YouTube chapters: ~/Downloads/<title>/01 - <chapter>.mp3
# tags are kept (no id3v2 -D) so each track has its title/cover
function downloadMp3Chapters(){
  local youtube_url chapters info title
  youtube_url=$(getClipboardUrl | sed 's/&list.*//g')

  if [[ $youtube_url != *youtube* ]]; then
    echo "${tmagenta}Error: Invalid YouTube URL.${treset}"
    return 1
  fi

  # line 1: chapters json, line 2: sanitized title (same as the tracks folder name)
  info=$(yt-dlp --skip-download --no-playlist --cookies-from-browser firefox \
    --print '%(chapters)j' --print filename -o "%(title)s" "$youtube_url")
  chapters=$(sed -n 1p <<< "$info")
  title=$(sed -n 2p <<< "$info")

  if [[ -z $chapters || $chapters == NA || $chapters == null || $chapters == "[]" ]]; then
    echo "${tmagenta}Error: Video has no chapters.${treset}"
    return 1
  fi

  ensureDirAndFile
  # the full mp3 goes to $directory, tracks to ~/Downloads/<title>/
  yt-dlp -x --audio-quality 0 --audio-format mp3 --embed-thumbnail --embed-metadata \
    --split-chapters --no-playlist --cookies-from-browser firefox \
    -P "$directory" \
    -o "%(title)s.%(ext)s" \
    -o "chapter:$HOME/Downloads/%(title)s/%(section_number)02d - %(section_title)s.%(ext)s" \
    "$youtube_url"

  # tracks inherit the video title tag — set each one to its chapter name and number
  local track tmp name
  for track in "$HOME/Downloads/$title"/*.mp3; do
    name=$(basename "$track" .mp3)
    tmp="${track%.mp3}.tmp.mp3"
    ffmpeg -nostdin -hide_banner -loglevel error -i "$track" -map 0 -c copy -id3v2_version 3 \
      -metadata title="${name#* - }" -metadata track="${name%% - *}" -metadata album="$title" \
      "$tmp" && mv -f "$tmp" "$track"
  done
  ls -1 "$HOME/Downloads/$title"

  notify-send "yt_mp3" "Split by chapters complete" --icon=audio-x-generic
}

function getClipboardUrl(){
  # clipboard may contain extra text (e.g. copied terminal output) — take the last URL, unescape zsh backslashes
  xclip -o -selection clipboard | tr -d '\\' | grep -oE 'https?://[^[:space:]]+' | tail -n 1
}

function downloadMp4(){
  local youtube_url
  youtube_url=$(getClipboardUrl)

  if [[ $youtube_url != *youtube* && $youtube_url != *zen* && $youtube_url != *vkvideo* && $youtube_url != *vk.com/video* && $youtube_url != *rutube* ]]; then
    echo "${tmagenta}Error: Invalid YouTube/VK/Zen/Rutube URL.${treset}"
    return 1
  fi

  local quality height
  echo "${tgreen}1) 720p${treset}"
  echo "${tgreen}2) 1080p${treset}"
  echo "${tgreen}3) 2K (1440p)${treset}"
  echo "${tgreen}4) 4K (2160p)${treset}"
  read -rp "Select quality: " quality
  case $quality in
    1) height=720 ;;
    2) height=1080 ;;
    3) height=1440 ;;
    4) height=2160 ;;
    *)
      echo "${tmagenta}Invalid quality.${treset}"
      return 1
      ;;
  esac

  yt-dlp -o '%(title)s.%(ext)s' \
    --format "bestvideo[height<=$height]+bestaudio[ext=m4a]/bestvideo[height<=$height]+bestaudio/best[height<=$height]" \
    --merge-output-format mp4 --embed-chapters --cookies-from-browser firefox "$youtube_url"

  notify-send "yt_mp4" "Download complete" --icon=video-x-generic
}

function openInMpv(){
  local youtube_url
  youtube_url=$(getClipboardUrl)

  if [[ $youtube_url == *youtube* ]]; then
    echo "YouTube URL is valid."
    mpv --msg-level=ffmpeg=no,cplayer=warn "$youtube_url" &
  elif [[ $youtube_url == *twitch* ]]; then
    mpv --msg-level=ffmpeg=no,cplayer=warn "$youtube_url" &
  elif [[ $youtube_url == *vkvideo* ]]; then
    mpv --msg-level=ffmpeg=no,cplayer=warn "$youtube_url" &
  elif [[ $youtube_url == *rutube* ]]; then
    mpv --msg-level=ffmpeg=no,cplayer=warn "$youtube_url" &
  else
    echo "${tmagenta}Error: Invalid YouTube/Twitch/VK/Rutube URL.${treset}"
  fi
}

while true; do
  echo ""
  echo "${tblue}--- yt ---${treset}"
  echo "${tgreen}1) Download from clipboard as MP3${treset}"
  echo "${tgreen}2) Download from clipboard as MP4 (YouTube/VK/Zen/Rutube)${treset}"
  echo "${tgreen}3) Open clipboard URL in mpv (YouTube/Twitch/VK/Rutube)${treset}"
  echo "${tgreen}4) Download from clipboard as MP3 split by chapters (YouTube)${treset}"
  echo "5) Exit"

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
      downloadMp3Chapters
      ;;
    5)
      exit 0
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
