#!/bin/bash
# Optimize selected images: JPG -> jpegoptim, PNG -> JPG + jpegoptim
# Originals are moved to ./original before processing

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"

mapfile -t selected_files < <(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -printf '%P\n' | sort | fzf_multiselect)
[[ ${#selected_files[@]} -eq 0 ]] && echo "No files selected." && exit 0
echo "${tgreen}Selected: ${selected_files[*]}${treset}"

read -p "Enter quality (default 85): " quality
[[ -z "$quality" ]] && quality=85

if [[ ! "$quality" =~ ^[0-9]+$ ]] || (( quality > 100 )); then
  echo "${tmagenta}Quality must be a number between 0 and 100.${treset}"
  exit 1
fi

mkdir -p original

for img in "${selected_files[@]}"; do
  if [[ -e "original/$img" ]]; then
    echo "${tmagenta}Skipped: original/$img already exists${treset}"
    continue
  fi

  if [[ "${img,,}" =~ \.png$ ]]; then
    out="${img%.*}.jpg"
    if [[ -e "$out" ]]; then
      echo "${tmagenta}Skipped: $out already exists${treset}"
      continue
    fi
    mv "$img" original/
    magick "original/$img" -background white -flatten "$out" || continue
    echo "${tblue}Converted: $img -> $out${treset}"
  else
    out="$img"
    mv "$img" original/
    cp -p "original/$img" "$out"
  fi

  # -p preserve timestamps, -t totals, -m <q>
  jpegoptim --strip-all --all-progressive -pt -m "$quality" "$out"
done

echo "${tgreen}Done. Originals are in ./original${treset}"
