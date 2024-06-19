#! /bin/bash
current_dir=$(pwd)

# Open a new terminal window with the current directory
xfce4-terminal --working-directory="$current_dir" &
