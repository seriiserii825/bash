#!/bin/bash

# Path to the .zshrc file
zshrc_file="$HOME/.zshrc"

# Define the script path
script_path="~/Documents/bash/bash-scripts/zsh_nvm"

# Escape the script path for sed
escaped_path=$(echo "$script_path" | sed 's/\//\\\//g')

# Check if the line is uncommented
if grep -q "^source $script_path" "$zshrc_file"; then
  # Comment the line
  sed -i "s|^source $escaped_path|#source $escaped_path|" "$zshrc_file"
  echo "The line has been commented."
else
  # Uncomment the line
  sed -i "s|^#source $escaped_path|source $escaped_path|" "$zshrc_file"
  echo "The line has been uncommented."
fi

# Reload zsh
exec zsh
