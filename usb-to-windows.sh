#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYA='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
  exec sudo "$(realpath "$0")" "$@"
fi

echo -e "${CYA}Available disks:${NC}"
echo "----------------------------------------------"
lsblk -d -o NAME,SIZE,TRAN,VENDOR,MODEL | awk 'NR==1 || $3=="usb"'
echo ""
lsblk -d -o NAME,SIZE,TRAN | awk '$3=="usb" {print NR") /dev/"$1" — "$2}'
echo "----------------------------------------------"

read -rp "Enter disk name (e.g. sda): " disk
disk="${disk#/dev/}"

if [[ ! -b "/dev/$disk" ]]; then
  echo -e "${RED}Disk /dev/$disk not found!${NC}"
  exit 1
fi

echo ""
echo -e "${YEL}Selected: /dev/$disk ($(lsblk -dn -o SIZE "/dev/$disk"))${NC}"
echo ""
echo -e "${RED}!!! All data will be destroyed !!!${NC}"
read -rp "Type 'yes' to confirm: " confirm

[[ "$confirm" != "yes" ]] && echo "Cancelled." && exit 0

echo ""
echo "Filesystem:"
echo "  1) FAT32 (max 4GB per file, max label 11 chars)"
echo "  2) exFAT (no 4GB limit, max label 15 chars)"
read -rp "Choose [1/2] (default 1): " fs_choice

case "${fs_choice:-1}" in
  1) fs="fat32"; max_label=11 ;;
  2) fs="exfat"; max_label=15 ;;
  *) echo -e "${RED}Invalid choice!${NC}"; exit 1 ;;
esac

if [[ "$fs" == "exfat" ]] && ! pacman -Qi exfatprogs &>/dev/null; then
  echo -e "${YEL}exfatprogs not installed, installing...${NC}"
  pacman -S --needed --noconfirm exfatprogs
fi

read -rp "Label (default USB, max $max_label chars): " label
label="${label:-USB}"
if (( ${#label} > max_label )); then
  echo -e "${RED}Label too long (${#label} > $max_label)!${NC}"
  exit 1
fi
[[ "$fs" == "fat32" ]] && label="${label^^}"

lsblk -ln -o MOUNTPOINT "/dev/$disk" | grep -v '^$' | while read -r mp; do
  umount "$mp" && echo "Unmounted: $mp"
done || true

echo -e "\n${YEL}Creating MBR partition table...${NC}"
wipefs -a "/dev/$disk" >/dev/null
parted -s "/dev/$disk" mklabel msdos

echo -e "${YEL}Creating partition...${NC}"
if [[ "$fs" == "fat32" ]]; then
  parted -s "/dev/$disk" mkpart primary fat32 1MiB 100%
else
  # partition type 0x07 (ntfs) is the correct MBR id for exFAT
  parted -s "/dev/$disk" mkpart primary ntfs 1MiB 100%
fi

partprobe "/dev/$disk" 2>/dev/null || true
sleep 1

# new partition starts at the same offset as the old one — clear leftover fs signatures
wipefs -a "/dev/${disk}1" >/dev/null

if [[ "$fs" == "fat32" ]]; then
  echo -e "${YEL}Formatting as FAT32 (label: $label)...${NC}"
  mkfs.fat -F 32 -n "$label" "/dev/${disk}1"
else
  echo -e "${YEL}Formatting as exFAT (label: $label)...${NC}"
  mkfs.exfat -L "$label" "/dev/${disk}1"
fi

echo -e "\n${GRN}Done! Windows will now see the drive.${NC}"
lsblk -o NAME,SIZE,FSTYPE,LABEL "/dev/$disk"
