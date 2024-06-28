#!/bin/bash

cd ~/Downloads

wget https://wordpress.org/latest.zip
wget https://downloads.wordpress.org/plugin/woocommerce.9.0.2.zip
wget https://downloads.wordpress.org/plugin/advanced-custom-fields.6.3.3.zip

for i in *.zip; do unzip $i; done
for i in *.zip; do rm $i; done

mkdir ~/Documents/wordpress
mv * ~/Documents/wordpress
