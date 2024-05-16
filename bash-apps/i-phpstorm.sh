#! /bin/bash

installApp() {
  file_name="PhpStorm-2023.2.4.tar.gz"
  cd ~/Downloads
  wget https://download.jetbrains.com/webide/$file_name
  has_file=$(ls | grep $file_name)
  if [ -z "$has_file" ]; then
    echo "PhpStorm download failed"
    exit 1
  fi
  sudo tar -xvzf $file_name -C /opt/
  phpstorm_dir=$(ls /opt/ | grep PhpStorm)
  sudo ln -s /opt/$phpstorm_dir/bin/phpstorm.sh /usr/bin/phpstorm
  rm $file_name
  echo "PhpStorm installed successfully"
}

installApp
