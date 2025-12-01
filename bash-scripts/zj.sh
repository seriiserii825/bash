#!/usr/bin/env bash
set -euo pipefail

# Убираем escape-коды (цвета) из вывода
sessions=$(zellij list-sessions --short 2>/dev/null \
  | sed -r 's/\x1B\[[0-9;]*m//g' \
  | sed -r 's/\x1B\][0-9;]*//g' \
  | sed 's/\[m$//' \
  || true)

if [[ -z "$sessions" ]]; then
  echo "No zellij sessions found."
  exit 0
fi

selected=$(printf '%s\n' "$sessions" | fzf --prompt="Zellij session> ")

[[ -z "$selected" ]] && exit 0

exec zellij attach "$selected"
