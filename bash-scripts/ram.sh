#!/usr/bin/env bash
# Show RAM usage per process via ps_mem (sudo), installing ps_mem if missing

set -euo pipefail

err()  { printf "\e[31m%s\e[0m\n" "$*" >&2; }
note() { printf "\e[33m%s\e[0m\n" "$*"; }
ok()   { printf "\e[32m%s\e[0m\n" "$*"; }

install_ps_mem() {
  note "ps_mem not found, installing..."
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm ps_mem
  elif command -v pip >/dev/null 2>&1; then
    sudo pip install ps_mem
  elif command -v pip3 >/dev/null 2>&1; then
    sudo pip3 install ps_mem
  else
    err "No supported package manager found (pacman/pip/pip3) to install ps_mem"
    exit 1
  fi
  ok "ps_mem installed"
}

command -v ps_mem >/dev/null 2>&1 || install_ps_mem

sudo ps_mem
