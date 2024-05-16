#!/bin/bash
#
# Path to the JPEG image fil# Path to the input image file
input_image="settori.jpg"

# Path to the output image file
output_image="output_image.jpg"

# Get the dimensions of the input image
image_dimensions=$(identify -format "%wx%h" "$input_image")

# Draw a red vertical line in the center
convert "$input_image" -stroke red -strokewidth 2 -draw "line \"$((image_width / 2)),0 $((image_width / 2)),$image_height \"" "$output_image"
