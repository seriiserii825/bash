#! /bin/bash
installApp() {
  cd ~
  sudo apt install -y zsh
  curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
  sudo  chsh -s $(which zsh)
  sudo chsh -s /bin/zsh serii
  if [ ! -d ~/zsh-autocomplete ]; then
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git
    source ~/zsh-autocomplete/zsh-autocomplete.plugin.zsh
  fi
  if [ ! -d ~/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
    source ./zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  fi
  if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
  fi
  wget "https://raw.githubusercontent.com/rupa/z/master/z.sh" -O "~/z.sh"
  sudo apt install sxiv vifm highlight libtesseract-dev tesseract-ocr
}
installApp
