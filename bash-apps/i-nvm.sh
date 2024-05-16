#! /bin/bash

installApp() {
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
exec zsh
nvm install 16
nvm use 16
}
installApp
