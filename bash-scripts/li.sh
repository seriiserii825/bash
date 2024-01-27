#!/bin/bash
# Check if the correct number of arguments is provided
cd ~/Downloads
filename='list.txt'
touch "$filename"
xclip -o >> "$filename"
new_file="new_file.txt"
if [ -f "$new_file" ]; then
    rm "$new_file"
fi
touch "$new_file"

echo "<ul>" >> "$new_file"
while IFS= read -r line; do
    echo "<li>${line}</li>" >> "$new_file"
done < "$filename"
echo "</ul>" >> "$new_file"

cat "$new_file" > "$filename"

xclip -sel clip < "$filename"
rm "$filename"

