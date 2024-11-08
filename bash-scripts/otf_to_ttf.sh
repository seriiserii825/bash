#!/bin/bash

# check if fontforge is installed
if ! [ -x "$(command -v fontforge)" ]; then
    echo "Error: fontforge is not installed." >&2
    sudo pacman -S fontforge
fi

# Convert all .otf files in the current directory to .ttf files
for otf_file in *.otf; do
    ttf_file="${otf_file%.otf}.ttf"
    fontforge -lang=ff -c "Open('$otf_file'); Generate('$ttf_file')" && echo "Converted $otf_file to $ttf_file"
done
rm *.otf

# for otf_file in "*.otf"; do
#     ttf_file="${otf_file%.otf}.ttf"
#     fontforge -lang=ff -c "Open('$otf_file'); Generate('$ttf_file')" && echo "Converted $otf_file to $ttf_file"
# done
