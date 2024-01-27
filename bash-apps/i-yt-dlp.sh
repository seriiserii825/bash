#! /bin/bash

installApp(){
  sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
  sudo chmod a+rx /usr/local/bin/yt-dlp  # Make executable
  echo "Installed yt-dlp"
}
installApp
