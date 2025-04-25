#! /bin/bash 

read -p "Enter FileName: " filename
read -p "New FileName: " newfilename

find . -type f -name "*$filename*" | sed "p;s/$filename/$newfilename/"

read -p "Do you want to rename the files? (y/n): " answer
if [[ $answer == "y" ]]; then
  find . -type f -name "*$filename*" | while read -r file; do
    newname="$(dirname "$file")/$(basename "$file" | sed "s/$filename/$newfilename/g")"
    mv "$file" "$newname"
  done
echo "Files renamed successfully."
else
  echo "No files were renamed."
fi
