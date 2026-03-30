#!/usr/bin/env bash

tgreen='\e[32m'
tblue='\e[34m'
tgray='\e[90m'
treset='\e[0m'

shopt -s nullglob nocaseglob

count=0

for img in *.jpg *.jpeg *.png *.webp; do
  [[ -f "$img" ]] || continue

  w=$(identify -format "%w" "$img" 2>/dev/null)
  h=$(identify -format "%h" "$img" 2>/dev/null)

  if [[ -z "$w" || -z "$h" ]]; then
    echo -e "${tgray}skip (unreadable): $img${treset}"
    continue
  fi

  ext="${img##*.}"
  base="${img%.*}"

  # Skip if already postfixed with dimensions
  if [[ "$base" =~ _[0-9]+x[0-9]+$ ]]; then
    echo -e "${tgray}skip (already postfixed): $img${treset}"
    continue
  fi

  new="${base}_${w}x${h}.${ext}"

  if [[ "$img" == "$new" ]]; then
    echo -e "${tgray}skip (same name): $img${treset}"
    continue
  fi

  mv -- "$img" "$new"
  echo -e "${tgreen}renamed:${treset} ${tblue}$img${treset} → ${tgreen}$new${treset}"
  (( count++ ))
done

echo ""
echo -e "Done. ${tgreen}${count}${treset} file(s) renamed."
