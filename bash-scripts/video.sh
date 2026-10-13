#!/usr/bin/bash
# Video helper: pick an mp4 with fzf, show info or split it by timecodes

source /home/serii/dotfiles/zsh_modules/zsh_colors
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"

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

  splitAt "$input"
}

function splitByChapters(){
  local times
  # chapter start times except the first (0), e.g. 92.500000,301.000000
  times=$(ffprobe -v error -show_entries chapter=start_time -of csv=p=0 "$video" | tail -n +2 | paste -sd,)

  if [[ -z "$times" ]]; then
    echo "${tmagenta}No chapters in $video (download with yt.sh --embed-chapters).${treset}"
    return 1
  fi

  splitAt "$times"
}

# each selected chapter starts a new part
function splitBySelectedChapters(){
  local chapters times
  chapters=$(readChapters "$video")

  if [[ -z "$chapters" ]]; then
    echo "${tmagenta}No chapters in $video (download with yt.sh --embed-chapters).${treset}"
    return 1
  fi

  # "start<TAB>00:12:35 Title" — fzf shows only the second column; first chapter (0) can't be a cut point
  times=$(awk -F'\t' 'NR > 1 {
      t = int($1)
      printf "%s\t%02d:%02d:%02d %s\n", $1, t / 3600, t % 3600 / 60, t % 60, $3
    }' <<< "$chapters" |
    fzf_multiselect --delimiter='\t' --with-nth=2 --prompt="Cut before chapters: " |
    cut -f1 | sort -n | paste -sd,)

  if [[ -z "$times" ]]; then
    echo "${tmagenta}No chapters selected.${treset}"
    return 1
  fi

  splitAt "$times"
}

# $1 — comma separated split points
function splitAt(){
  local input="$1"
  local name="${video%.*}"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  # stream copy is fast, but cuts snap to the nearest keyframe
  ffmpeg -hide_banner -loglevel warning -i "$video" \
    -map 0 -c copy -f segment -segment_times "$input" -reset_timestamps 1 \
    "$tmp_dir/part%03d.mp4"

  local chapters
  chapters=$(readChapters "$video")

  # each part is named after its start time: my-video-01-32-44.mp4
  # chapters are shifted by the real part start (sum of previous part durations)
  local starts=(0 ${input//,/ })
  local i=0 offset=0 part out dur text clipboard=""
  echo "${tgreen}Done:${treset}"
  for part in "$tmp_dir"/part*.mp4; do
    out="${name}-$(toHms "${starts[$i]}").mp4"
    dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$part")

    if [[ -n "$chapters" ]]; then
      chaptersMetadata "$chapters" "$offset" "$dur" > "$tmp_dir/meta.txt"
      ffmpeg -hide_banner -loglevel warning -y -i "$part" -i "$tmp_dir/meta.txt" \
        -map 0 -map_chapters 1 -c copy "$out"
      rm "$part" "$tmp_dir/meta.txt"

      text=$(chaptersText "$chapters" "$offset" "$dur")
      echo "$text" > "${out%.*}.txt"
      clipboard+="${out}"$'\n'"${text}"$'\n\n'
    else
      mv "$part" "$out"
    fi

    echo "$out"
    offset=$(awk -v a="$offset" -v b="$dur" 'BEGIN { print a + b }')
    ((i++))
  done
  rmdir "$tmp_dir"

  if [[ -n "$clipboard" ]]; then
    printf "%s" "${clipboard%$'\n\n'}" | xclip -selection clipboard &>/dev/null
    echo "${tgreen}Chapters of each part copied to clipboard and saved to .txt next to parts${treset}"
  fi
}

function copyChapters(){
  local chapters text
  chapters=$(readChapters "$video")

  if [[ -z "$chapters" ]]; then
    echo "${tmagenta}No chapters in $video (download with yt.sh --embed-chapters).${treset}"
    return 1
  fi

  text=$(chaptersText "$chapters" 0 999999999)
  echo "$text"
  echo "$text" > "${video%.*}.txt"
  printf "%s" "$text" | xclip -selection clipboard &>/dev/null
  echo "${tgreen}Copied to clipboard and saved to ${video%.*}.txt${treset}"
}

# prints chapters of $1 as "start<TAB>end<TAB>title" (seconds)
function readChapters(){
  ffprobe -v error -show_entries chapter=start_time,end_time:chapter_tags=title -of default "$1" |
    awk '
      /^start_time=/ { s = substr($0, 12) }
      /^end_time=/   { e = substr($0, 10) }
      /^TAG:title=/  { t = substr($0, 11) }
      /^\[\/CHAPTER\]/ { print s "\t" e "\t" t; t = "" }
    '
}

# chapters overlapping the part [offset, offset + dur), shifted to the part start;
# a chapter that started in the previous part shows as 00:00:00
# 1s tolerance at the end: a chapter that starts right at the (keyframe-snapped) cut belongs to the next part
function chaptersInPart(){
  awk -F'\t' -v off="$2" -v dur="$3" '
    $1 < off + dur - 1 && $2 > off + 1 {
      s = $1 - off; if (s < 0) s = 0
      e = $2 - off; if (e > dur) e = dur
      print s "\t" e "\t" $3
    }
  ' <<< "$1"
}

# "00:12:35 Title" lines — Telegram makes them clickable in a video caption
function chaptersText(){
  chaptersInPart "$@" | awk -F'\t' '{
    t = int($1)
    printf "%02d:%02d:%02d %s\n", t / 3600, t % 3600 / 60, t % 60, $3
  }'
}

function chaptersMetadata(){
  echo ";FFMETADATA1"
  chaptersInPart "$@" | awk -F'\t' '{
    title = $3
    gsub(/[\\=;#]/, "\\\\&", title)
    printf "[CHAPTER]\nTIMEBASE=1/1000\nSTART=%d\nEND=%d\ntitle=%s\n", $1 * 1000, $2 * 1000, title
  }'
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
  echo "${tgreen}3) Split video by chapters${treset}"
  echo "${tgreen}4) Split video by selected chapters (fzf)${treset}"
  echo "${tgreen}5) Copy chapters to clipboard (+ .txt)${treset}"
  echo "6) Exit"

  read -rp "Select an option: " option
  case $option in
    1)
      showInfo
      ;;
    2)
      splitVideo
      ;;
    3)
      splitByChapters
      ;;
    4)
      splitBySelectedChapters
      ;;
    5)
      copyChapters
      ;;
    6)
      exit 0
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
