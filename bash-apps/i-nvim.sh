#! /bin/bash
installApp() {
  file_name="nvim-linux64.tar.gz"
  cd ~/Downloads
  wget -O $file_name https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz
  has_file=$(ls | grep $file_name)
  if [ -z "$has_file" ]; then
    echo "nvim download failed"
    exit 1
  fi
  sudo tar -xvzf $file_name -C /opt/
  sudo ln -s /opt/nvim-linux64/bin/nvim /usr/local/bin
  nvim -v
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  sudo apt install -y fzf ripgrep universal-ctags silversearcher-ag fd-find
  sudo apt -y install python3-pynvim
}
installApp
