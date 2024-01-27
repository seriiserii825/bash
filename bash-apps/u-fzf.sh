#! /bin/bash

installApp() {
  sudo apt purge fzf -y
  rm ~/.fzf/bin/fzf
}
installApp
