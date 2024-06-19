#! /bin/bash

file_iso=$(fzf)

if [ -z $file_iso ]; then
  echo "No file selected"
  exit 1
fi
# if file don't end iwth iso
if [[ $file_iso != *.iso ]]; then
  echo "File is not an iso"
  exit 1
fi

devices=$(cat /proc/partitions | awk '{print $NF}')

lsblk

PS3="${tgreen}Please choose your device: ${treset}"
COLUMNS=1
select device in $devices
do
  sudo dd if=$file_iso of=/dev/$device bs=4M status=progress  oflag=sync
  exit 0
done
