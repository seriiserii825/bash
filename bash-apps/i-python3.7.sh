#! /bin/bash -x
installApp() {
  cd ~/Downloads
  wget https://www.python.org/ftp/python/3.7.16/Python-3.7.16.tar.xzi
  tar -xf Python-3.7.16
  sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev pkg-config make -y
  cd Python3.7.16
  ./configure --enable-optimizations --enable-shared
  make -j 6
  sudo make altinstall
  sudo ldconfig
  sudo python3.7 --version
  sudo apt install python3-pip
  wget https://bootstrap.pypa.io/get-pip.py
  python3.7 get-pip.py
  python3.7 -m pip install --upgrade pip
  pip3.7 --version
  sudo update-alternatives --config python
}
installApp
