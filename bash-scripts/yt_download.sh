#!/usr/bin/bash

directory="$HOME/Downloads/youtube"
file_path="$HOME/Downloads/youtube/yt.txt"

if [ ! -d "$directory" ]; then
  mkdir $directory
  echo "Directory created at $directory"
fi

if [ ! -f "$file_path" ]; then
  touch $file_path
  echo "File created at $file_path"
fi

function convertToMp3(){
cd $directory
bat $file_path
while read -r line; do
  new_line=$(echo $line | sed 's/&list.*//g')
  yt-dlp -x  --audio-quality 0 --audio-format mp3 --embed-thumbnail --embed-metadata -o "%(title)s.%(ext)s" $new_line
done < yt.txt
cp $directory/*.mp3 $HOME/Downloads
}

function clipboardToFile(){
  xclip -selection clipboard -o > $file_path
  echo >> $file_path
}

function clearFile(){
  > $file_path
}

function viewFile(){
  bat $file_path
}

function removeFiles(){
  rm $directory/*.mp3
}

function clear(){
  viewFile
  clearFile
  removeFiles
  viewFile
}

function startYtDownload(){
  clipboardToFile
  convertToMp3
  rename 's/ /_/g' ~/Downloads/*.mp3
  id3v2 -D ~/Downloads/*.mp3
}

echo "${tblue}Start downloading from clipboard?${treset}"

clear
startYtDownload
