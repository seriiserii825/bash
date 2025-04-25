#! /bin/bash 

read -p "Enter FileName: " filename

find . -type f -name "*$filename*" | sed "p;s/$filename/Home/" 

read -p "Do you want to rename the files? (y/n): " answer
if [[ $answer == "y" ]]; then
    find . -type f -name '*Hero*' | while read -r file; do
    newname="$(dirname "$file")/$(basename "$file" | sed 's/Hero/Home/g')"
    mv "$file" "$newname"
  done
echo "Files renamed successfully."
else
  echo "No files were renamed."
fi
