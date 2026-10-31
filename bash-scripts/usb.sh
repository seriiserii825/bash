#!/usr/bin/env bash
# USB manager: list devices, check mount status, prepare for Windows,
# write ISO with dd, format as FAT32/exFAT

source /home/serii/dotfiles/zsh_modules/zsh_colors

get_usb_disks() {
  lsblk -dn -o NAME,TRAN | awk '$2=="usb"{print $1}'
}

listUsbDevices() {
  local disks model part mp
  disks=$(get_usb_disks)
  if [ -z "$disks" ]; then
    echo -e "${tred}No USB devices found${treset}"
    return
  fi
  while read -r d; do
    model=$(lsblk -dn -o MODEL "/dev/$d" | sed 's/[[:space:]]*$//')
    echo -e "${tcyan}--- /dev/$d (${model:-unknown}) ---${treset}"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS "/dev/$d"
    while read -r part mp; do
      [ -z "$mp" ] && continue
      echo -e "${tyellow}Usage of $mp:${treset}"
      df -h --output=size,used,avail,pcent,target "$mp" | tail -1
    done < <(lsblk -lnpo NAME,MOUNTPOINTS "/dev/$d" | awk 'NF>1')
    echo
  done <<<"$disks"
}

isMounted() {
  local disks part
  disks=$(get_usb_disks)
  if [ -z "$disks" ]; then
    echo -e "${tred}No USB devices found${treset}"
    return
  fi

  part=$(while read -r d; do lsblk -pn -o NAME,TYPE "/dev/$d" | awk '$2!="disk"{print $1}'; done <<<"$disks" | fzf --prompt="USB partition> ")
  [ -z "$part" ] && echo -e "${tred}No partition selected${treset}" && return

  if findmnt -S "$part" >/dev/null 2>&1; then
    echo -e "${tgreen}$part is mounted:${treset}"
    findmnt -S "$part" -o TARGET,SOURCE,FSTYPE,OPTIONS
  else
    echo -e "${tyellow}$part is not mounted${treset}"
  fi
}

usbToWindows() {
  local disks disk device confirm fs_choice fs max_label label part

  disks=$(get_usb_disks)
  if [ -z "$disks" ]; then
    echo -e "${tred}No USB devices found${treset}"
    return
  fi

  echo -e "${tcyan}USB disks:${treset}"
  while read -r d; do lsblk -d -o NAME,SIZE,MODEL "/dev/$d"; done <<<"$disks"

  disk=$(echo "$disks" | fzf --prompt="USB disk> ")
  [ -z "$disk" ] && echo -e "${tred}No USB selected${treset}" && return
  device="/dev/$disk"

  echo -e "${tyellow}Selected: $device ($(lsblk -dn -o SIZE "$device"))${treset}"
  echo -e "${tred}All data on $device will be destroyed!${treset}"
  read -rp "Type 'yes' to confirm: " confirm
  [ "$confirm" != "yes" ] && echo "Cancelled." && return

  echo "Filesystem:"
  echo "  1) FAT32 (max 4GB per file, label <= 11 chars)"
  echo "  2) exFAT (no 4GB limit, label <= 15 chars)"
  read -rp "Choose [1/2] (default 1): " fs_choice
  case "${fs_choice:-1}" in
    1) fs="fat32"; max_label=11 ;;
    2) fs="exfat"; max_label=15 ;;
    *) echo -e "${tred}Invalid choice${treset}"; return ;;
  esac

  if [ "$fs" = "exfat" ] && ! pacman -Qi exfatprogs &>/dev/null; then
    echo -e "${tyellow}exfatprogs not installed, installing...${treset}"
    sudo pacman -S --needed --noconfirm exfatprogs
  fi

  read -rp "Label (default USB, max $max_label chars): " label
  label="${label:-USB}"
  if [ "${#label}" -gt "$max_label" ]; then
    echo -e "${tred}Label too long (${#label} > $max_label)${treset}"
    return
  fi
  [ "$fs" = "fat32" ] && label="${label^^}"

  for part in $(lsblk -lnpo NAME,MOUNTPOINTS "$device" | awk 'NF > 1 {print $1}'); do
    sudo umount "$part" || return 1
  done

  echo -e "${tyellow}Creating MBR partition table...${treset}"
  sudo wipefs -a "$device" >/dev/null
  sudo parted -s "$device" mklabel msdos

  echo -e "${tyellow}Creating partition...${treset}"
  if [ "$fs" = "fat32" ]; then
    sudo parted -s "$device" mkpart primary fat32 1MiB 100%
  else
    # partition type 0x07 (ntfs) is the correct MBR id for exFAT
    sudo parted -s "$device" mkpart primary ntfs 1MiB 100%
  fi

  sudo partprobe "$device" 2>/dev/null
  sleep 1

  # new partition starts at the same offset as the old one — clear leftover fs signatures
  sudo wipefs -a "${device}1" >/dev/null

  if [ "$fs" = "fat32" ]; then
    echo -e "${tyellow}Formatting as FAT32 (label: $label)...${treset}"
    sudo mkfs.fat -F 32 -n "$label" "${device}1"
  else
    echo -e "${tyellow}Formatting as exFAT (label: $label)...${treset}"
    sudo mkfs.exfat -L "$label" "${device}1"
  fi

  echo -e "${tgreen}Done! Windows will now see the drive.${treset}"
  lsblk -o NAME,SIZE,FSTYPE,LABEL "$device"
}

writeIso() {
  local disks file_iso iso_bytes iso_size device confirm part

  disks=$(lsblk -dpno NAME,SIZE,TRAN,MODEL | awk '$3 == "usb"')
  if [ -z "$disks" ]; then
    echo -e "${tred}No USB devices found${treset}"
    return
  fi
  echo -e "${tcyan}USB devices:${treset}"
  echo "$disks"
  echo

  file_iso=$(find "$PWD" "$HOME/Downloads" -type f -iname '*.iso' 2>/dev/null | sort -u | fzf --prompt="ISO> ")
  [ -z "$file_iso" ] && echo -e "${tred}No ISO file selected${treset}" && return

  iso_bytes=$(stat -c %s "$file_iso")
  iso_size="$(numfmt --to=iec-i --suffix=B "$iso_bytes") ($iso_bytes bytes)"
  echo -e "ISO: ${tgreen}$file_iso${treset}"
  echo -e "Size: ${tgreen}$iso_size${treset}"

  device=$(echo "$disks" | fzf --prompt="USB> " | awk '{print $1}')
  [ -z "$device" ] && echo -e "${tred}No USB selected${treset}" && return
  echo -e "USB: ${tgreen}$device${treset}"

  echo -e "${tred}Write $file_iso to $device? All data on it will be lost.${treset}"
  read -rp "Type y to continue: " confirm
  [ "$confirm" != "y" ] && echo "Cancelled" && return

  for part in $(lsblk -lnpo NAME,MOUNTPOINTS "$device" | awk 'NF > 1 {print $1}'); do
    sudo umount "$part" || return 1
  done

  echo -e "Writing ${tgreen}$iso_size${treset} — compare with 'bytes copied' below:"
  sudo dd if="$file_iso" of="$device" bs=4M status=progress oflag=sync && sync
  echo -e "${tgreen}Done${treset}"
}

formatUsbPartition() {
  local fs="$1" max_label disks part label confirm mp

  [ "$fs" = "fat32" ] && max_label=11 || max_label=15

  disks=$(get_usb_disks)
  if [ -z "$disks" ]; then
    echo -e "${tred}No USB devices found${treset}"
    return
  fi

  part=$(while read -r d; do lsblk -pn -o NAME,TYPE,SIZE,FSTYPE "/dev/$d" | awk '$2!="disk"'; done <<<"$disks" | fzf --prompt="USB partition> " | awk '{print $1}')
  [ -z "$part" ] && echo -e "${tred}No partition selected${treset}" && return

  echo -e "${tred}All data on $part will be destroyed!${treset}"
  read -rp "Type 'yes' to confirm: " confirm
  [ "$confirm" != "yes" ] && echo "Cancelled." && return

  read -rp "Label (default USB, max $max_label chars): " label
  label="${label:-USB}"
  if [ "${#label}" -gt "$max_label" ]; then
    echo -e "${tred}Label too long (${#label} > $max_label)${treset}"
    return
  fi

  if [ "$fs" = "exfat" ] && ! pacman -Qi exfatprogs &>/dev/null; then
    echo -e "${tyellow}exfatprogs not installed, installing...${treset}"
    sudo pacman -S --needed --noconfirm exfatprogs
  fi

  mp=$(lsblk -no MOUNTPOINT "$part")
  [ -n "$mp" ] && { sudo umount "$part" || return 1; }

  if [ "$fs" = "fat32" ]; then
    label="${label^^}"
    echo -e "${tyellow}Formatting $part as FAT32 (label: $label)...${treset}"
    sudo mkfs.fat -F 32 -n "$label" "$part"
  else
    echo -e "${tyellow}Formatting $part as exFAT (label: $label)...${treset}"
    sudo mkfs.exfat -L "$label" "$part"
  fi

  echo -e "${tgreen}Done${treset}"
  lsblk -o NAME,SIZE,FSTYPE,LABEL "$part"
}

while true; do
  echo ""
  echo "${tcyan}--- USB ---${treset}"
  echo "${tgreen}1) List USB devices${treset}"
  echo "${tgreen}2) Is mounted (check a USB partition)${treset}"
  echo "${tblue}3) Prepare USB for Windows (repartition + format)${treset}"
  echo "${tblue}4) Write ISO to USB (dd)${treset}"
  echo "${tyellow}5) Format USB partition as FAT32${treset}"
  echo "${tyellow}6) Format USB partition as exFAT${treset}"
  echo "7) Exit"

  read -rp "Select an option: " option
  case $option in
    1) listUsbDevices ;;
    2) isMounted ;;
    3) usbToWindows ;;
    4) writeIso ;;
    5) formatUsbPartition fat32 ;;
    6) formatUsbPartition exfat ;;
    7) exit 0 ;;
    *) echo "Invalid option. Please try again." ;;
  esac
done
