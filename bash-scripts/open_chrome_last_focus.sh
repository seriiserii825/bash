#!/bin/bash
if ! [ -x "$(command -v xdotool)" ]; then
  echo 'Error: xdotool is not installed.' >&2
  sudo pacman -S xdotool
fi

links=("https://search-emoji-pi.vercel.app/ru#Symbols", "https://google.com", "https://yandex.ru")

choosen_link=$(fzf <<< $(printf "%s\n" "${links[@]}"))


google-chrome-stable --new-tab "$choosen_link" &
sleep 0.5
xdotool search --class google-chrome-stable windowactivate
