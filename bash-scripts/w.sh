#! /bin/bash
# Opens a new Kitty terminal window in the current directory
current_dir=$(pwd)

# Open a new terminal window with the current directory
kitty "$current_dir" &
