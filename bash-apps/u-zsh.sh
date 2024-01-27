#! /bin/bash

installApp() {
  cd ~
  sudo apt purge -y zsh
  sudo chsh -s /bin/bash serii
  bash
  exit 0
}
installApp
