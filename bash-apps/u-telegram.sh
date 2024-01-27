#! /bin/bash

uninstallApp(){
has_telegram=$(which telegram)
if [ -z "$has_telegram" ]; then
  echo "Telegram is not installed"
  exit 1
fi

sudo rm -rf /opt/telegram
sudo rm -rf /usr/bin/telegram
echo "Telegram has been uninstalled"
}
uninstallApp
