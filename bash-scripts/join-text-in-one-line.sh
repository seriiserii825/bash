#!/usr/bin/env bash
# Joins wrapped clipboard text into a single line, copies it back
# Deps: xclip (или xsel), libnotify (notify-send)

set -euo pipefail

clip_get() {
  if command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -o
  elif command -v xsel  >/dev/null 2>&1; then xsel -b
  else echo "Install xclip or xsel" >&2; exit 1; fi
}
clip_set() {
  if command -v xclip >/dev/null 2>&1; then printf '%s' "$1" | xclip -selection clipboard
  elif command -v xsel  >/dev/null 2>&1; then printf '%s' "$1" | xsel -b -i
  else echo "Install xclip or xsel" >&2; exit 1; fi
}

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "join-text-in-one-line" "Joined" "$1"
}

text="$(clip_get)"
[ -n "${text// /}" ] || exit 0

out="$(printf '%s' "$text" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ +//; s/ +$//')"

clip_set "$out"
notify "$out"
printf '%s\n' "$out"
