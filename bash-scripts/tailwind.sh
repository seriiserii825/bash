#!/bin/bash 
# set -x

# check if is installed tailwind-colors-vars with npm
if ! command -v tailwind-colors &> /dev/null
then
    echo "tailwind-colors-vars could not be found, installing..."
    npm install -g tailwind-colors-vars
    rm -rf node_modules package*
fi

# tailwind-colors -f hex -e scss
tailwind_file="tailwind-colors-vars.scss"
if [ ! -e "$tailwind_file" ]; then
  tailwind-colors -f hex -e css --print > "$tailwind_file"
fi

# remove all lines leav just started with --
sed -i '/--/!d' "$tailwind_file"
bat "$tailwind_file" --color=always | head -n 20

# get line with fzf
selected_line=$(cat "$tailwind_file" | fzf --height 40% --reverse --inline-info --preview "bat --color=always {}")
# get color from line
echo $selected_line
color=$(echo "$selected_line" | cut -d':' -f2)
cleared_color=$(echo "$color" | cut -d';' -f1)
# copy to clipboard
echo -n "$cleared_color" | xclip -selection clipboard
notify-send "Color copied to clipboard" "$cleared_color"
rm "$tailwind_file"


