#! /bin/bash -x
installApp() {
  has_fzf=$(which fzf)
  if [ -z "$has_fzf" ]; then
    cd ~
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
    sudo apt intall -y ripgrep universal-ctags silversearcher-ag fd-find
  fi
  has_bat=$(which bat)
  if [ -z "$has_bat" ]; then
    cd ~/Downloads
    wget -O bat.deb  https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-musl_0.24.0_amd64.deb
    sudo dpkg -i bat.deb
  fi
	sudo apt install ack-grep -y
	sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
}
installApp
