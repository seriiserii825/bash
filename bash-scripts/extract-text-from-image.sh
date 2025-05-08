#!/bin/bash

read -p "Enter psm mode (0-13), by default is 6: " psm_mode
if [[ -z "$psm_mode" ]]; then
    psm_mode=6
fi

intro_img="$HOME/Downloads/screen.jpg"
output_img="$HOME/Downloads/preprocessed.png"
output_txt="$HOME/Downloads/screen"

# Capture screenshot
maim -f jpg -s "$intro_img"

# Preprocess image for better OCR
convert "$intro_img" \
    -resize 300% \
    -colorspace Gray \
    -contrast-stretch 0 \
    -sharpen 0x1 \
    "$output_img"

# Run Tesseract with specific options
tesseract "$output_img" "$output_txt" -l eng --psm $psm_mode

# Copy non-empty lines to clipboard
sed '/^[[:space:]]*$/d' "$output_txt.txt" | xclip -selection clipboard
