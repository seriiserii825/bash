#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYA='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Run as root: sudo $0${NC}"
  exit 1
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

lsblk -ln -o MOUNTPOINT "/dev/$disk" | grep -v '^$' | while read -r mp; do
  umount "$mp" && echo "Unmounted: $mp"
done || true

echo -e "\n${YEL}Creating MBR partition table...${NC}"
parted -s "/dev/$disk" mklabel msdos

echo -e "${YEL}Creating FAT32 partition...${NC}"
parted -s "/dev/$disk" mkpart primary fat32 1MiB 100%

partprobe "/dev/$disk" 2>/dev/null || true
sleep 1

echo -e "${YEL}Formatting as FAT32...${NC}"
mkfs.fat -F 32 -n "USB" "/dev/${disk}1"

echo -e "\n${GRN}Done! Windows will now see the drive.${NC}"
lsblk -o NAME,SIZE,FSTYPE,LABEL "/dev/$disk"
