#!/bin/bash
# Image converter: jpg/jpeg to webp, png to webp (multi-select via fzf)

source /home/serii/dotfiles/zsh_modules/zsh_colors
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"

C_RESET=$treset

if ! [ -x "$(command -v magick)" ]; then
  echo "Error: magick is not installed." >&2
  exit 1
fi

function convertToWebp() {
  local label=$1
  shift
  local files
  files=$(find . -maxdepth 1 -type f \( "$@" \) | sort \
    | fzf_multiselect --prompt="Select ${label} files to convert: ")
  [ -z "$files" ] && echo "No files selected." && return

  while IFS= read -r file; do
    local out="${file%.*}.webp"
    magick "$file" "$out" && echo "${tgreen}Converted: $file -> $out${C_RESET}"
  done <<< "$files"
}

while true; do
  echo ""
  echo "${tgreen}1) jpg/jpeg to webp (multi-select)${C_RESET}"
  echo "${tblue}2) png to webp (multi-select)${C_RESET}"
  echo "3) Exit"

  read -rp "Select an option: " option
  case $option in
    1)
      convertToWebp "jpg/jpeg" -iname "*.jpg" -o -iname "*.jpeg"
      ;;
    2)
      convertToWebp "png" -iname "*.png"
      ;;
    3)
      exit 0
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
