#!/bin/bash

tgreen='\e[32m'
tblue='\e[34m'
tyellow='\e[33m'
tgray='\e[90m'
treset='\e[0m'

if [[ "$1" == "--help" ]]; then
  echo -e "${tgreen}resize-cover${treset} — resize image to fill target dimensions exactly"
  echo ""
  echo -e "  ${tblue}1.${treset} Enter target ${tyellow}width,height${treset}   e.g. ${tgray}300,400${treset}"
  echo -e "  ${tblue}2.${treset} Pick image with ${tyellow}fzf${treset}         preview shows current size"
  echo -e "  ${tblue}3.${treset} Script checks proportions:"
  echo -e "     image wider than target  → scale by ${tyellow}height${treset}"
  echo -e "     image taller than target → scale by ${tyellow}width${treset}"
  echo -e "  ${tblue}4.${treset} Center-crop to exact target size"
  echo -e "  ${tblue}5.${treset} Saves as ${tgray}originalname_WxH_Gravity.ext${treset} for cover, ${tgray}originalname_WxH.ext${treset} for fit  (original untouched)"
  exit 0
fi

# Ask for target dimensions
read -rp "Target size (width,height): " size_input
target_w=$(echo "$size_input" | cut -d',' -f1 | tr -d ' ')
target_h=$(echo "$size_input" | cut -d',' -f2 | tr -d ' ')

if [[ -z "$target_w" || -z "$target_h" ]]; then
  echo "Invalid size. Use format: 300,400"
  exit 1
fi

# Ask resize mode
mode=$(printf "cover  — crop to exact size\nfit    — resize one side, keep proportions" \
  | fzf --prompt="Mode: " --height=4 --no-info)

if [[ -z "$mode" ]]; then
  echo "No mode selected."
  exit 1
fi

# Ask crop position (only for cover)
if [[ "$mode" == cover* ]]; then
  gravity=$(printf "Center\nNorth\nSouth\nWest\nEast\nNorthWest\nNorthEast\nSouthWest\nSouthEast" \
    | fzf --prompt="Crop position: " --height=11 --no-info)
  if [[ -z "$gravity" ]]; then
    echo "No crop position selected."
    exit 1
  fi
fi

# Select images with fzf (Tab = toggle, Ctrl-A = all)
mapfile -t images < <(find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
  | fzf --multi --preview 'identify -format "%f  %wx%h" {}' \
        --bind 'ctrl-a:select-all' \
        --prompt="Select images (Tab=multi, Ctrl-A=all): ")

if [[ ${#images[@]} -eq 0 ]]; then
  echo "No image selected."
  exit 1
fi

for image in "${images[@]}"; do
  # Get source dimensions
  img_w=$(identify -format "%w" "$image")
  img_h=$(identify -format "%h" "$image")

  echo "Source:   ${img_w}x${img_h}"
  echo "Target:   ${target_w}x${target_h}"

  # Compare aspect ratios to decide which dimension to scale by
  img_ratio_x100=$(( img_w * 100 / img_h ))
  tgt_ratio_x100=$(( target_w * 100 / target_h ))

  if (( img_ratio_x100 > tgt_ratio_x100 )); then
    scale_arg="x${target_h}"
    echo "Scale:    by height (image is wider)"
  else
    scale_arg="${target_w}x"
    echo "Scale:    by width (image is taller)"
  fi

  # Build output filename
  ext="${image##*.}"
  base="${image%.*}"
  if [[ "$mode" == cover* ]]; then
    output="${base}_${target_w}x${target_h}_${gravity}.${ext}"
  else
    output="${base}_${target_w}x${target_h}.${ext}"
  fi

  if [[ "$mode" == cover* ]]; then
    echo "Crop:     $gravity"
    convert "$image" \
      -resize "$scale_arg" \
      -gravity "$gravity" \
      -extent "${target_w}x${target_h}" \
      "$output"
  else
    convert "$image" \
      -resize "$scale_arg" \
      "$output"
  fi

  echo "Saved:   $output"
  identify -format "%f  %wx%h\n" "$output"
done
