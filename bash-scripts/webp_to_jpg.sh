#!/bin/bash

# check if web files exist
if [ ! -f *.webp ]; then
  echo "No .webp files found in the current directory."
  exit 1
fi

# Convert all .webp files to .jpg files
for file in *.webp; do
  # magick input.webp output.jpg
  magick "$file" "${file%.webp}.jpg"
done
