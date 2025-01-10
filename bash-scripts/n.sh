#!/bin/bash

# toggle comment string source ~/Documents/bash-scripts/zsh_nvm in .zshrc

# check if .zshrc has string source ~/Documents/bash-scripts/zsh_nvm

if grep -q "^source ~/Documents/bash/bash-scripts/zsh_nvm" ~/.zshrc; then
  #comment this string
  sed -i 's/^source ~\/Documents\/bash\/bash-scripts\/zsh_nvm/#source ~\/Documents\/bash\/bash-scripts\/zsh_nvm/g' ~/xubuntu/.zshrc
  echo "zsh_nvm commented"
  exec zsh
else
  sed -i 's/^#source ~\/Documents\/bash\/bash-scripts\/zsh_nvm/source ~\/Documents\/bash\/bash-scripts\/zsh_nvm/g' ~/xubuntu/.zshrc
  echo "zsh_nvm uncommented"
  exec zsh
fi
