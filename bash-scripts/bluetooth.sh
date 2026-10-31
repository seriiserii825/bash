#!/usr/bin/env bash
# Bluetooth manager: check/install packages, list devices, scan for new ones,
# pick a device and connect / disconnect / remove it

source /home/serii/dotfiles/zsh_modules/zsh_colors

PACKAGES=(bluez bluez-utils blueman)
SCAN_SECONDS=15

checkPackages() {
  local missing=() p
  for p in "${PACKAGES[@]}"; do
    pacman -Qi "$p" &>/dev/null || missing+=("$p")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${tyellow}Missing packages: ${missing[*]}, installing...${treset}"
    sudo pacman -S --needed --noconfirm "${missing[@]}" || exit 1
  fi

  if ! systemctl is-active --quiet bluetooth; then
    echo -e "${tyellow}bluetooth.service is not running, enabling...${treset}"
    sudo systemctl enable --now bluetooth || exit 1
    sleep 1
  fi

  if rfkill list bluetooth | grep -q 'Soft blocked: yes'; then
    echo -e "${tyellow}Bluetooth is soft-blocked, unblocking...${treset}"
    rfkill unblock bluetooth
    sleep 1
  fi

  if ! bluetoothctl show | grep -q 'Powered: yes'; then
    bluetoothctl power on >/dev/null
  fi
}

# "MAC Name" lines
allDevices() {
  bluetoothctl devices | awk '$1=="Device"{ $1=""; sub(/^ /,""); print }'
}

isPaired() { bluetoothctl info "$1" | grep -q 'Paired: yes'; }
isConnected() { bluetoothctl info "$1" | grep -q 'Connected: yes'; }

listDevices() {
  local devices mac name status
  devices=$(allDevices)
  if [ -z "$devices" ]; then
    echo -e "${tyellow}No known devices. Use Find to scan.${treset}"
    return
  fi
  echo -e "${tcyan}--- Devices ---${treset}"
  while read -r mac name; do
    if isConnected "$mac"; then
      status="${tgreen}connected${treset}"
    elif isPaired "$mac"; then
      status="${tblue}paired${treset}"
    else
      status="${tyellow}new${treset}"
    fi
    echo -e "$mac  $name  [$status]"
  done <<<"$devices"
}

findDevices() {
  echo -e "${tyellow}Put the device into pairing mode. Scanning ${SCAN_SECONDS}s...${treset}"
  bluetoothctl --timeout "$SCAN_SECONDS" scan on | grep --line-buffered -E 'NEW.*Device'
  echo
  listDevices
}

connectDevice() {
  local mac="$1" scan_pid
  if ! isPaired "$mac"; then
    # an unpaired device is dropped from bluez cache soon after discovery stops,
    # so keep scanning while pairing
    bluetoothctl --timeout 30 scan on >/dev/null &
    scan_pid=$!
    sleep 3
    echo -e "${tyellow}Pairing $mac...${treset}"
    if ! bluetoothctl pair "$mac"; then
      kill "$scan_pid" 2>/dev/null
      echo -e "${tred}Pairing failed. Is the device in pairing mode? Try Find first.${treset}"
      return
    fi
    kill "$scan_pid" 2>/dev/null
    bluetoothctl trust "$mac" >/dev/null
  fi
  echo -e "${tyellow}Connecting $mac...${treset}"
  if bluetoothctl connect "$mac" | grep -q 'Connection successful'; then
    echo -e "${tgreen}Connected${treset}"
  else
    echo -e "${tred}Connection failed${treset}"
  fi
}

chooseDevice() {
  local devices line mac name action
  devices=$(allDevices)
  if [ -z "$devices" ]; then
    echo -e "${tyellow}No known devices. Use Find to scan.${treset}"
    return
  fi

  line=$(echo "$devices" | fzf --prompt="Device> ")
  [ -z "$line" ] && echo -e "${tred}No device selected${treset}" && return
  read -r mac name <<<"$line"
  echo -e "Selected: ${tgreen}$name ($mac)${treset}"

  action=$(printf '%s\n' connect disconnect remove info | fzf --prompt="Action> ")
  case "$action" in
    connect) connectDevice "$mac" ;;
    disconnect) bluetoothctl disconnect "$mac" ;;
    remove) bluetoothctl remove "$mac" ;;
    info) bluetoothctl info "$mac" ;;
    *) echo -e "${tred}No action selected${treset}" ;;
  esac
}

checkPackages
listDevices

while true; do
  echo ""
  echo "${tcyan}--- Bluetooth ---${treset}"
  echo "${tgreen}1) Find (scan for new devices)${treset}"
  echo "${tgreen}2) Choose (connect / disconnect / remove)${treset}"
  echo "${tblue}3) List devices${treset}"
  echo "4) Exit"

  read -rp "Select an option: " option
  case $option in
    1) findDevices ;;
    2) chooseDevice ;;
    3) listDevices ;;
    4) exit 0 ;;
    *) echo "Invalid option. Please try again." ;;
  esac
done
