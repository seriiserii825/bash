#! /bin/bash


installApp(){
  cd ~
  has_app=$(ls | grep powerlevel10k)

  if [ -z "$has_app" ]; then
    sed -i '/ZSH_THEME/s/^/#/g' ~/.zshrc  #  (to comment)
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
    ln -s ~/xubuntu/.p10k.zsh
    echo "powerlevel10k installed"
  else
    echo "powerlevel10k already installed"
    exit 1
  fi

}

installApp
