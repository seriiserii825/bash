#!/bin/bash

clipboard=$(xclip -o -selection clipboard)
echo "Your clipboard is: $clipboard"
url=$(xclip -o -selection clipboard)
clean_url=${url#http://}
clean_url=${clean_url#https://}
echo "Your clean url is: $clean_url"

# if not installed dig, install with pacman sudo pacman -S bind-tools
if ! command -v dig &> /dev/null
then
    echo "dig could not be found, installing..."
    sudo pacman -S bind-tools --noconfirm
fi

api=$(dig +short $clean_url)
echo "Your IP address is: $api"

if [[ $api == "51.75.16.130" ]]
then
    echo "Vps 2"
  elif [[ $api == "51.178.82.114" ]]
  then
    echo "Vps 3"
  elif [[ $api == "185.116.60.81" ]]
  then
    echo "Vps 4"
  elif [[ $api == "151.80.119.73" ]]
  then
    echo "Vps 5"
  elif [[ $api == "37.187.90.56" ]]
  then
    echo "Vps 6"
  else
    echo "No vps founded"
fi
