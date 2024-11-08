#!/bin/bash

# Function to convert hex to RGB
hex_to_rgb() {
    local hex=$1
    r=$(printf '%d' "0x${hex:1:2}")
    g=$(printf '%d' "0x${hex:3:2}")
    b=$(printf '%d' "0x${hex:5:2}")
}

# Function to convert RGB back to hex
rgb_to_hex() {
    printf "#%02x%02x%02x\n" $1 $2 $3
}

# Function to adjust color brightness
adjust_brightness() {
    local component=$1
    local adjustment=$2

    # Calculate the new value with adjustment
    new_value=$(( component + (component * adjustment / 100) ))

    # Clamp the value between 0 and 255
    if [ $new_value -gt 255 ]; then
        new_value=255
    elif [ $new_value -lt 0 ]; then
        new_value=0
    fi

    echo $new_value
}

# Prompt for color, action, and percentage
read -p "Enter the hex color (e.g., #ff5733): " hex_color
read -p "Do you want to lighten or darken the color? (lighten/darken): " action
read -p "Enter the percentage to adjust (e.g., 10 for 10%): " adjustment

# Validate hex color input
if [[ ! $hex_color =~ ^#([A-Fa-f0-9]{6})$ ]]; then
    echo "Invalid hex color format. Please use #RRGGBB."
    exit 1
fi

# Ensure the action is either lighten or darken
if [ "$action" != "lighten" ] && [ "$action" != "darken" ]; then
    echo "Invalid action. Please use 'lighten' or 'darken'."
    exit 1
fi

# Convert to a negative percentage for darkening
if [ "$action" = "darken" ]; then
    adjustment=$(( -adjustment ))
fi

# Convert hex to RGB
hex_to_rgb "$hex_color"

# Adjust each color component
r=$(adjust_brightness $r $adjustment)
g=$(adjust_brightness $g $adjustment)
b=$(adjust_brightness $b $adjustment)

# Convert RGB back to hex
adjusted_color=$(rgb_to_hex $r $g $b)

echo "Original color: $hex_color"
echo "Adjusted color: $adjusted_color"
