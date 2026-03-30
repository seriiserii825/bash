#!/bin/bash

# Ask for extension
read -p "Extension (e.g. jpg, png): " ext
ext="${ext#.}"  # strip leading dot if user typed it

# Count matching files
files=( *."$ext" )
if [[ ! -e "${files[0]}" ]]; then
  echo "No files found with extension: $ext"
  exit 1
fi
total=${#files[@]}

# Ask for new base name
read -p "New base name (e.g. image): " base

# Determine padding width based on total count
if (( total > 100 )); then
  pad=3
elif (( total > 10 )); then
  pad=2
else
  pad=1
fi

# Confirm
first=$(printf "%0${pad}d" 1)
last=$(printf "%0${pad}d" "$total")
echo ""
echo "Found $total file(s) with .$ext"
echo "Will rename to: ${base}-${first}.$ext ... ${base}-${last}.$ext"
read -p "Continue? (y/n): " confirm
[[ "$confirm" != "y" ]] && echo "Aborted." && exit 0

# Rename files
count=1
for file in "${files[@]}"; do
  num=$(printf "%0${pad}d" "$count")
  newname="${base}-${num}.${ext}"
  if [[ "$file" == "$newname" ]]; then
    (( count++ ))
    continue
  fi
  mv -- "$file" "$newname"
  echo "  $file -> $newname"
  (( count++ ))
done

echo ""
echo "Done. Renamed $total file(s)."
