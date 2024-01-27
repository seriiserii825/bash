#! /bin/bash

uninstallApp(){
  has_phpstorm=$(which phpstorm)
  if [ -z "$has_phpstorm" ]; then
    echo "PhpStorm is not installed"
    exit 1
  fi
  sudo rm -rf /opt/PhpStorm*
  sudo rm -rf /usr/bin/phpstorm
  echo "PhpStorm has been removed"
}

uninstallApp
