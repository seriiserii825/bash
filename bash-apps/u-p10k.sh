#! /bin/bash

uninstallApp(){
  cd ~
  has_file=$(ls | grep powerlevel10k)
  if [ -z "$has_file" ]; then
    echo "powerlevel10k not installed"
    exit 1
  fi
  rm -rf ~/powerlevel10k
  rm -rf ~/.p10k.zsh
  sed -i '/p10k.zsh/d' ~/.zshrc
  sed -i '/powerlevel10k/d' ~/.zshrc
  echo "powerlevel10k uninstalled"
  echo "ZSH_THEME=robbyrussell" >> ~/.zshrc
  sed -i '/ZSH_THEME/s/^#//g' ~/.zshrc  #  (to uncomment)
}

uninstallApp
