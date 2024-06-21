#!/bin/bash

# choose video mp4 file with fzf
video_url=$(find . -type f -name "*.mp4" | fzf)

function hasVideoAudio(){
  ffprobe -i $video_url -show_streams 2>&1 | grep 'Stream #0:1'
  if [ $? -eq 0 ]; then
    echo "${tmagenta}Video has audio${treset}"
  else
    echo "${tmagenta}Video has no audio${treset}"
  fi
}

function optimizeVideo(){
  read -p "Enter quality by default is 24 (0-51): " quality

  if [ -z "$quality" ]; then
    quality=24
  fi


  output_file=$(echo $video_url | sed "s/.mp4/_$quality.mp4/g")

  if [ -f $output_file ]; then
    echo "${tmagenta}File already exists${treset}"
    read -p "Enter new file name: " output_file
  fi


  read -p "Remove video audio? (y/n): " remove_audio

  if [ "$remove_audio" == "y" ]; then
    output_file=$(echo $video_url | sed "s/.mp4/_$quality-no-audio.mp4/g")
    ffmpeg -i $video_url -vcodec libx265 -crf $quality -an $output_file
  else
    ffmpeg -i $video_url -vcodec libx265 -crf $quality $output_file
  fi
}

select action in "hasAudio" "Optimize video" "Cancel"; do
  case $action in
    "hasAudio")
      hasVideoAudio
      ;;
    "Optimize video")
      optimizeVideo
      ;;
    "Cancel")
      exit
      ;;
  esac
done



