#! /bin/bash

installApp() {
wget -O- https://baltocdn.com/i3-window-manager/signing.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/i3wm-signing.gpg
sudo apt install apt-transport-https --yes
echo "deb https://baltocdn.com/i3-window-manager/i3/i3-autobuild/ all main" | sudo tee /etc/apt/sources.list.d/i3-autobuild.list

sudo apt update
sudo apt install -y i3 feh rofi pulseaudio-utils alsa-tools locate libnotify-bin  lxpolkit i3status fonts-font-awesome
cp /etc/i3status.conf ~/.config/i3status/config
}
installApp
