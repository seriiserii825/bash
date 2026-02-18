#!/bin/bash
# find with 
#lsblk -o NAME,SIZE,MOUNTPOINT,LABEL,UUID  and get UUID
TARGET_UUID="bd51a002-3aea-4574-99c0-a98a67753b37"
MOUNT_POINT="/mnt"

device=$(sudo blkid -o device -t UUID="$TARGET_UUID")

if [ -n "$device" ]; then
  echo "✅ Found target device: $device"
  sudo mount "$device" "$MOUNT_POINT" && cd "$MOUNT_POINT"
  exec zsh
else
  echo "⚠️ Target device not found. Choose manually."
  lsblk
  devices=$(lsblk -ln -o NAME,TYPE | awk '$2=="part"{print $1}')
  PS3="Please choose your partition: "
  COLUMNS=1
  select dev in $devices; do
    sudo mount /dev/$dev "$MOUNT_POINT" && cd "$MOUNT_POINT"
    exec zsh
    break
  done
fi
