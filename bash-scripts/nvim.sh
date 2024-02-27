#!/bin/bash

select nvim in "Install NvimCoc" "Install NvimLua" "Quit"
do
  case $nvim in
    "Install NvimCoc" ) 
      echo "Installing NvimCoc"
      mv ~/.local/share/nvim ~/.local/share/nvim-lua.bak
      mv ~/.local/state/nvim ~/.local/state/nvim-lua.bak
      mv ~/.cache/nvim ~/.cache/nvim-lua.bak
      mv ~/.config/nvim ~/.config/nvim-lua.bak

      mv ~/.local/share/nvim-coc.bak ~/.local/share/nvim
      mv ~/.local/state/nvim-coc.bak ~/.local/state/nvim
      mv ~/.cache/nvim-coc.bak ~/.cache/nvim
      mv ~/.config/nvim-coc.bak ~/.config/nvim
      ;;
    "Install NvimLua" )
      echo "Installing NvimLua"
      mv ~/.local/share/nvim ~/.local/share/nvim-coc.bak
      mv ~/.local/state/nvim ~/.local/state/nvim-coc.bak
      mv ~/.cache/nvim ~/.cache/nvim-coc.bak
      mv ~/.config/nvim ~/.config/nvim-coc.bak

      mv ~/.local/share/nvim-lua.bak ~/.local/share/nvim
      mv ~/.local/state/nvim-lua.bak ~/.local/state/nvim
      mv ~/.cache/nvim-lua.bak ~/.cache/nvim
      mv ~/.config/nvim-lua.bak ~/.config/nvim
      ;;
    Quit ) echo "Quitting"
      break
      exit 0
      ;;
  esac
done
