#!/bin/bash

read -p "Enter port number: " port
sudo lsof -i:$port
# kill all the processes running on the port

read -p "Do you want to kill the process running on the port? (y/n): " choice
if [ $choice == "y" ]; then
  sudo lsof -t -i tcp:$port -s tcp:listen | sudo xargs kill
fi
