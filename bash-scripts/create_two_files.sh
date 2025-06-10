#! /bin/bash

clipboard=$(xclip -o)
file_name="$clipboard"

touch "old-$file_name.php"
touch "new-$file_name.php"
