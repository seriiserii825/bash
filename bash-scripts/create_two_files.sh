#! /bin/bash

read -p "Enter file name withou extension: " file_name

touch "old-$file_name.php"
touch "new-$file_name.php"
