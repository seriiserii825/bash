#! /bin/bash
# Creates two PHP files named old-<name>.php and new-<name>.php from clipboard content

clipboard=$(xclip -o)
file_name="$clipboard"

touch "old-$file_name.php"
touch "new-$file_name.php"
