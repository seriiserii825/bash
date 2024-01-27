#! /bin/bash

devices=$(cat /proc/partitions | awk '{print $NF}')

lsblk

PS3="${tgreen}Please choose your device: ${treset}"
COLUMNS=1
select device in $devices
do
  sudo mount /dev/$device /mnt
  cd /mnt
  exec zsh
  exit 0
done
