#! /bin/bash

installApp(){
  file_name="telegram.tar.xz"
  cd ~/Downloads
  wget -O $file_name https://telegram.org/dl/desktop/linux
  has_file=$(ls | grep $file_name)

  if [ -z "$has_file" ]; then
    echo "File not found"
    exit 1
  fi

  tar -xvf $file_name
  sudo mv Telegram /opt/telegram
  sudo ln -sf /opt/telegram/Telegram /usr/bin/telegram
  rm $file_name
  echo "Telegram has been installed"
}
installApp
