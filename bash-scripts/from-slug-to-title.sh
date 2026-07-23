#!/usr/bin/env bash
# Reads clipboard, checks it's a slug (kebab-case), converts to Title Case
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
  command -v notify-send >/dev/null 2>&1 && notify-send -a "slug2title" "Converted to Title Case" "$1"
}

text="$(clip_get)"
text="${text#/}"

if ! [[ "$text" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Clipboard doesn't look like a slug: $text" >&2
  exit 1
fi

title="$(printf '%s' "$text" | tr '-' ' ' | sed -E 's/^([a-z])/\u\1/')"

clip_set "$title"
notify "$title"
printf '%s\n' "$title"
