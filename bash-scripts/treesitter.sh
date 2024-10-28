#!/bin/bash


#!/bin/bash

if grep -q -F "#source \$HOME/.config/nvim/modules/treesitter.vim" ~/.config/nvim/init.vim; then
  echo "to uncomment"
  #comment line
  sed -i 's/#source \$HOME\/.config\/nvim\/modules\/treesitter.vim/source \$HOME\/.config\/nvim\/modules\/treesitter.vim/g' ~/.config/nvim/init.vim
elif grep -q -F "source \$HOME/.config/nvim/modules/treesitter.vim" ~/.config/nvim/init.vim; then
  echo "to comment"
  #uncomment line
  sed -i 's/source \$HOME\/.config\/nvim\/modules\/treesitter.vim/#source \$HOME\/.config\/nvim\/modules\/treesitter.vim/g' ~/.config/nvim/init.vim
fi
