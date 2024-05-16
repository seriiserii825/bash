#!/bin/bash

select nvim in "Install NvimCoc" "Install NvimLua" "Quit"
do
  case $nvim in
    "Install NvimCoc" ) 
      echo "Installing NvimCoc"
      if [ -d ~/.local/share/nvim ]; then
        mv ~/.local/share/nvim ~/.local/share/nvim-lua.bak
        if [ -d ~/.local/state/nvim ]; then
          mv ~/.local/state/nvim ~/.local/state/nvim-lua.bak
        fi
        if [ -d ~/.cache/nvim ]; then
          mv ~/.cache/nvim ~/.cache/nvim-lua.bak
        fi
        if [ -d ~/.config/nvim ]; then
          mv ~/.config/nvim ~/.config/nvim-lua.bak
        fi
      fi

      if [ -d ~/.local/share/nvim-coc.bak ]; then
        mv ~/.local/share/nvim-coc.bak ~/.local/share/nvim
        if [ -d ~/.local/state/nvim-coc.bak ]; then
          mv ~/.local/state/nvim-coc.bak ~/.local/state/nvim
        fi
        if [ -d ~/.cache/nvim-coc.bak ]; then
          mv ~/.cache/nvim-coc.bak ~/.cache/nvim
        fi
        if [ -d ~/.config/nvim-coc.bak ]; then
          mv ~/.config/nvim-coc.bak ~/.config/nvim
        fi
        echo "NvimCoc installed from cache"
      else
        rm -rf ~/.config/nvim
        ln -s ~/Documents/Apps/nvim-coc ~/.config/nvim
        echo "NvimCoc installed from symlink"
      fi
      exit 0
      ;;
    "Install NvimLua" )
      echo "Installing NvimLua"
      if [ -d ~/.local/share/nvim ]; then
        mv ~/.local/share/nvim ~/.local/share/nvim-coc.bak
        if [ -d ~/.local/state/nvim ]; then
          mv ~/.local/state/nvim ~/.local/state/nvim-coc.bak
        fi
        if [ -d ~/.cache/nvim ]; then
          mv ~/.cache/nvim ~/.cache/nvim-coc.bak
        fi
        if [ -d ~/.config/nvim ]; then
          mv ~/.config/nvim ~/.config/nvim-coc.bak
        fi
      fi
      if [ -d ~/.local/share/nvim-lua.bak ]; then
        mv ~/.local/share/nvim-lua.bak ~/.local/share/nvim
        if [ -d ~/.local/state/nvim-lua.bak ]; then
          mv ~/.local/state/nvim-lua.bak ~/.local/state/nvim
        fi

        if [ -d ~/.cache/nvim-lua.bak ]; then
          mv ~/.cache/nvim-lua.bak ~/.cache/nvim
        fi
        if [ -d ~/.config/nvim-lua.bak ]; then
          mv ~/.config/nvim-lua.bak ~/.config/nvim
        fi
        echo "NvimLua installed from cache"
      else
        rm -rf ~/.config/nvim
        ln -s ~/Documents/Apps/nvim-new-lua ~/.config/nvim
        echo "NvimLua installed from symlink"
      fi
      exit 0
      ;;
    Quit ) echo "Quitting"
      break
      exit 0
      ;;
  esac
done
