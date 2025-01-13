#!/bin/bash

# toggle comment string source ~/Documents/bash-scripts/zsh_nvm in .zshrc

# check if .zshrc has string source ~/Documents/bash-scripts/zsh_nvm
script_path=~/Documents/bash/bash-scripts/zsh_nvm
escaped_path=$(echo $script_path | sed 's/\//\\\//g')

if grep -q "^source $script_path" ~/.zshrc; then
  #comment this string
  sed -i "s/^source $escaped_path/#source $escaped_path/g" ~/xubuntu/.zshrc
  echo "zsh_nvm commented"
  exec zsh
else
  sed -i "s/^#source $escaped_path/source $escaped_path/g" ~/xubuntu/.zshrc
  echo "zsh_nvm uncommented"
  exec zsh
fi
