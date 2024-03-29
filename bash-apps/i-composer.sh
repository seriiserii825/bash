#! /bin/bash
sudo apt install php-cli unzip

cd ~
curl -sS https://getcomposer.org/installer -o composer-setup.php

HASH=`curl -sS https://composer.github.io/installer.sig`

echo $HASH

php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"

install global
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer

composer
