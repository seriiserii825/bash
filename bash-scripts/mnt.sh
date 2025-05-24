#!/bin/bash

TARGET_UUID="bd51a002-3aea-4574-99c0-a98a67753b37"
MOUNT_POINT="/mnt"

# Use sudo with blkid in case root is required
device=$(sudo blkid -o device -t UUID="$TARGET_UUID")

if [ -n "$device" ]; then
  echo "${tgreen}✅ Found target device: $device${treset}"
  sudo mount "$device" "$MOUNT_POINT" && cd "$MOUNT_POINT"
  exec zsh
else
  echo "${tmagenta}⚠️ Target device not found. Choose manually.${treset}"

  lsblk
  devices=$(lsblk -dn -o NAME)

  PS3="Please choose your device: "
  COLUMNS=1
  select dev in $devices; do
    sudo mount /dev/$dev "$MOUNT_POINT" && cd "$MOUNT_POINT"
    exec zsh
    break
  done
fi
# #! /bin/bash
#
# devices=$(cat /proc/partitions | awk '{print $NF}')
# usb_uuid='bd51a002-3aea-4574-99c0-a98a67753b37'
#
# lsblk
#
# PS3="${tgreen}Please choose your device: ${treset}"
# COLUMNS=1
# select device in $devices
# do
#   sudo mount /dev/$device /mnt
#   cd /mnt
#   exec zsh
#   exit 0
# done
