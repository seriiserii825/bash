#!/bin/bash

# Check if magick is installed 
if ! [ -x "$(command -v magick)" ]; then
  echo 'Error: magick is not installed.' >&2
  exit 1
fi

# check magick version is greater than 7
if [ "$(magick -version | grep -oP '(?<=Version: ImageMagick )\d+')" -lt 7 ]; then
  echo 'Error: magick version is less than 7.' >&2
  exit 1
fi

# check if web files exist
if [ ! ls *.webp 1> /dev/null 2>&1 ]; then
  echo 'Error: No .webp files found.' >&2
  exit 1
fi

# Convert all .webp files to .jpg files
for file in *.webp; do
  # magick input.webp output.jpg
  magick "$file" "${file%.webp}.jpg"
done
