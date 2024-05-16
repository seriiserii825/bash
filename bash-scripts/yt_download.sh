#!/usr/bin/bash

directory="$HOME/Music/youtube"
file_path="$HOME/Music/youtube/yt.txt"

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

function start(){
  clipboardToFile
  convertToMp3
}

function moveToDir(){
  read -p "Enter directory: " directory_name
  mkdir $directory_name
  mv $directory/*.mp3 $directory_name
}

echo "${tblue}Start downloading from clipboard?${treset}"

COLUMNS=1
select action in "Start"; do
  case $action in
    "Start")
      clear
      start
      cd $directory
      break
      ;;
    *)
      echo "ERROR! Please select between 1..3"
      ;;
  esac
done
