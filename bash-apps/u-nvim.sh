#! /bin/bash

uninstallApp(){
  has_nvim=$(which nvim)
  if [ -z "$has_nvim" ]; then
    echo "nvim is not installed"
    exit 1
  fi
  sudo rm -rf /opt/nvim*
  sudo rm -rf /usr/local/bin/nvim

  rm -rf ~/.local/share/nvim
  rm -rf ~/.local/state/nvim
  rm -rf ~/.cache/nvim
  echo "nvim has been removed"
}

uninstallApp

