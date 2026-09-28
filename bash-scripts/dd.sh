#! /bin/bash
# Writes an ISO file to a USB drive with dd (ISO and USB are selected via fzf)

green='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
bold='\033[1m'
reset='\033[0m'

echo -e "${bold}${green}Disks and partitions:${reset}"
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL,FSTYPE,MOUNTPOINTS
echo

echo -e "${bold}${green}USB devices:${reset}"
usb_list=$(lsblk -dpno NAME,SIZE,TRAN,MODEL | awk '$3 == "usb"')
if [ -z "$usb_list" ]; then
  echo -e "${red}No USB devices found${reset}"
else
  echo "$usb_list"
fi
echo

echo -e "${bold}${green}Mounted:${reset}"
findmnt -lno SOURCE,TARGET,FSTYPE | awk '$1 ~ "^/dev/"'
echo

echo -e "${bold}${yellow}How it works:${reset}"
echo "  1. Select the ISO file (searched in current directory and ~/Downloads)"
echo "  2. Select the USB drive (only USB disks are listed)"
echo "  3. Confirm — mounted partitions of the USB are unmounted and the ISO is written with dd"
echo -e "  ${red}All data on the selected USB drive will be destroyed!${reset}"
echo

read -rp "Press Enter to select ISO file..."

file_iso=$(find "$PWD" "$HOME/Downloads" -type f -iname '*.iso' 2>/dev/null | sort -u | fzf --prompt="ISO> ")

if [ -z "$file_iso" ]; then
  echo -e "${red}No ISO file selected${reset}"
  exit 1
fi
echo -e "ISO: ${green}$file_iso${reset}"
echo

if [ -z "$usb_list" ]; then
  echo -e "${red}No USB devices found${reset}"
  exit 1
fi

read -rp "Press Enter to select USB..."

device=$(echo "$usb_list" | fzf --prompt="USB> " | awk '{print $1}')

if [ -z "$device" ]; then
  echo -e "${red}No USB selected${reset}"
  exit 1
fi
echo -e "USB: ${green}$device${reset}"
echo

echo -e "${bold}${red}Write${reset} ${green}$file_iso${reset} ${bold}${red}to${reset} ${green}$device${reset}${bold}${red}? All data on it will be lost.${reset}"
read -rp "Type y to continue: " confirm
if [ "$confirm" != "y" ]; then
  echo "Canceled"
  exit 1
fi

for part in $(lsblk -lnpo NAME,MOUNTPOINTS "$device" | awk 'NF > 1 {print $1}'); do
  sudo umount "$part" || exit 1
done

sudo dd if="$file_iso" of="$device" bs=4M status=progress oflag=sync && sync
echo -e "${green}Done${reset}"
