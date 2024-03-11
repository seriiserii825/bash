#! /bin/bash


sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
sudo apt-cache policy docker-ce
sudo apt install docker-ce
sudo systemctl status docker


sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

sudo apt install php-xml
sudo apt-get install php-mbstring

sudo usermod -aG docker ${USER}
su - ${USER}
id -nG
sudo usermod -aG docker serii

sudo chmod 666 /var/run/docker.sock
sudo usermod -aG docker serii
sudo chmod 666 /var/run/docker.sock
newgrp docker


