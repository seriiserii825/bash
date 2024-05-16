#! /bin/bash
file_name="telegram.tar.xz"
cd ~/Downloads
wget -O $file_name https://telegram.org/dl/desktop/linux
tar -xvf $file_name
sudo mv Telegram /opt/telegram
sudo ln -sf /opt/telegram/Telegram /usr/bin/telegram
