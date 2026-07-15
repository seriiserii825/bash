#!/bin/bash
# Picks an image with fzf, creates 2 resized versions (height=1080 and 250x350 cropped cover), then deletes the original

tgreen='\e[32m'
tblue='\e[34m'
tyellow='\e[33m'
tgray='\e[90m'
treset='\e[0m'

if [[ "$1" == "--help" ]]; then
  echo -e "${tgreen}resize-image-1080-250x350${treset} — pick an image, generate 2 resized versions"
  echo ""
  echo -e "  ${tblue}1.${treset} Pick image with ${tyellow}fzf${treset}    preview shows current size"
  echo -e "  ${tblue}2.${treset} Saves ${tgray}originalname-1080.ext${treset}      height resized to 1080, proportional width"
  echo -e "  ${tblue}3.${treset} Saves ${tgray}originalname-250x350.ext${treset}   resized + center-cropped to exact 250x350"
  echo -e "  ${tblue}4.${treset} Deletes the original"
  exit 0
fi

target_w=250
target_h=350

# Select image with fzf
image=$(find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
  | fzf --preview 'identify -format "%f  %wx%h" {}' \
        --prompt="Select image: ")

if [[ -z "$image" ]]; then
  echo "No image selected."
  exit 1
fi

ext="${image##*.}"
base="${image%.*}"

img_w=$(identify -format "%w" "$image")
img_h=$(identify -format "%h" "$image")
echo "Source:   ${img_w}x${img_h}"

# 1. Resize height to 1080, keep proportions
height_output="${base}-1080.${ext}"
convert "$image" -resize "x1080" "$height_output"
echo "Saved:    $height_output"
identify -format "%f  %wx%h\n" "$height_output"

# 2. Resize + center-crop to exact 250x350
img_ratio_x100=$(( img_w * 100 / img_h ))
tgt_ratio_x100=$(( target_w * 100 / target_h ))

if (( img_ratio_x100 > tgt_ratio_x100 )); then
  scale_arg="x${target_h}"
else
  scale_arg="${target_w}x"
fi

crop_output="${base}-${target_w}x${target_h}.${ext}"
convert "$image" \
  -resize "$scale_arg" \
  -gravity center \
  -extent "${target_w}x${target_h}" \
  "$crop_output"
echo "Saved:    $crop_output"
identify -format "%f  %wx%h\n" "$crop_output"

# Remove original
rm "$image"
echo "Removed:  $image"
