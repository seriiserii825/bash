#!/usr/bin/bash
# Video helper: pick an mp4 with fzf, show info or split it by timecodes

source /home/serii/dotfiles/zsh_modules/zsh_colors

video=$(find . -maxdepth 1 -type f -iname "*.mp4" -printf '%P\n' | sort | fzf --prompt="Video: ")

if [[ -z "$video" ]]; then
  echo "${tmagenta}No video selected.${treset}"
  exit 1
fi

function showInfo(){
  local duration size bitrate
  duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$video")
  size=$(du -h "$video" | cut -f1)
  bitrate=$(ffprobe -v error -show_entries format=bit_rate -of default=nw=1:nk=1 "$video")

  echo "${tblue}File:${treset}     $video"
  echo "${tblue}Size:${treset}     $size"
  echo "${tblue}Duration:${treset} $(date -u -d "@${duration%.*}" +%H:%M:%S)"
  echo "${tblue}Bitrate:${treset}  $((bitrate / 1000)) kb/s"

  ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name,width,height,r_frame_rate \
    -of default=nw=1 "$video" | while IFS='=' read -r key value; do
      [[ $key == r_frame_rate ]] && key=fps && value=$(awk -F/ '{ printf "%.2f", $1 / $2 }' <<< "$value")
      echo "${tgreen}video ${key}:${treset} $value"
    done

  ffprobe -v error -select_streams a \
    -show_entries stream=codec_name,sample_rate,channels \
    -of default=nw=1 "$video" | while IFS='=' read -r key value; do
      echo "${tgreen}audio ${key}:${treset} $value"
    done
}

function splitVideo(){
  local input
  echo "Timecodes separated by comma (e.g. 1:30,00:05:00,1:02:15)"
  read -rp "Timecodes: " input
  input=${input// /}

  if [[ ! $input =~ ^[0-9]+(:[0-9]{1,2}){0,2}(\.[0-9]+)?(,[0-9]+(:[0-9]{1,2}){0,2}(\.[0-9]+)?)*$ ]]; then
    echo "${tmagenta}Invalid timecodes: $input${treset}"
    return 1
  fi

  local name="${video%.*}"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  # stream copy is fast, but cuts snap to the nearest keyframe
  ffmpeg -hide_banner -loglevel warning -i "$video" \
    -map 0 -c copy -f segment -segment_times "$input" -reset_timestamps 1 \
    "$tmp_dir/part%03d.mp4"

  # each part is named after its start time: my-video-01-32-44.mp4
  local starts=(0 ${input//,/ })
  local i=0 part out
  echo "${tgreen}Done:${treset}"
  for part in "$tmp_dir"/part*.mp4; do
    out="${name}-$(toHms "${starts[$i]}").mp4"
    mv "$part" "$out"
    echo "$out"
    ((i++))
  done
  rmdir "$tmp_dir"
}

# 90 / 1:30 / 0:01:30.5 → 00-01-30
function toHms(){
  local p total=0
  IFS=':' read -ra p <<< "${1%.*}"
  for v in "${p[@]}"; do
    total=$((total * 60 + 10#$v))
  done
  printf "%02d-%02d-%02d" $((total / 3600)) $((total % 3600 / 60)) $((total % 60))
}

while true; do
  echo ""
  echo "${tblue}--- video: $video ---${treset}"
  echo "${tgreen}1) Show video info${treset}"
  echo "${tgreen}2) Split video by timecodes (comma separated)${treset}"
  echo "3) Exit"

  read -rp "Select an option: " option
  case $option in
    1)
      showInfo
      ;;
    2)
      splitVideo
      ;;
    3)
      exit 0
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
