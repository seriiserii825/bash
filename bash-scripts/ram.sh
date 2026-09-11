#!/usr/bin/env bash
# Show RAM usage per process via ps_mem (sudo), installing ps_mem if missing

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/libs/fzf-multiselect.sh"

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

show_usage() {
  command -v ps_mem >/dev/null 2>&1 || install_ps_mem
  sudo ps_mem
}

kill_selected() {
  selected=$(ps -eo pid,rss,%mem,comm --no-headers \
    | awk '{printf "%-8s %8.1f MiB %5s%%  %s\n", $1, $2/1024, $3, $4}' \
    | fzf_multiselect --prompt="Kill process: ")
  [ -z "$selected" ] && return
  echo "$selected" | awk '{print $1}' | xargs -r sudo kill -9
}

read -rp "Просмотреть процессы или убить? [p/k]: " action
case "$action" in
  k) kill_selected ;;
  *) show_usage ;;
esac
