#! /bin/bash 

cd ~/.password-store

selected_file=$(fzf --height 40% --reverse --preview 'cat {}' --preview-window=up:30%:wrap)
echo "Selected file: $selected_file"

#extract file name without extension
file_name=$(basename "$selected_file" .gpg)
echo "File name without extension: $file_name"

# extract first line from file
first_line=$(pass show "$file_name" | head -n 1)
echo "First line: $first_line"

# copy filename to clipboard
echo -n "$file_name" | xclip -selection clipboard
notify-send "Copied to clipboard" "$file_name"
# copy first line to clipboard
echo -n "$first_line" | xclip -selection clipboard
notify-send "Copied to clipboard" "$first_line"
