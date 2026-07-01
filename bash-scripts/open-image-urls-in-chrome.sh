#!/usr/bin/env bash
# Picks a file with fzf, extracts all image URLs from it, and opens them all in Chrome
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Required: $1"; exit 1; }; }
need fzf
need fd

BROWSER="${BROWSER:-google-chrome-stable}"
ROOT="${1:-.}"

file=$(
  fd --type f --hidden \
    --exclude .git \
    --exclude node_modules \
    --exclude vendor \
    --exclude venv \
    . "$ROOT" \
  | fzf \
      --height=90% \
      --reverse \
      --prompt='📄 select file> ' \
      --preview 'bat --style=numbers --color=always -- "{}" 2>/dev/null || cat -- "{}"' \
      --preview-window=right,60%
) || exit 0

[[ -z "$file" ]] && exit 0

mapfile -t urls < <(
  grep -ioE 'https?://[^"'"'"'[:space:]<>)]+\.(jpe?g|png|gif|webp|svg|bmp|avif)([?][^"'"'"'[:space:]<>)]*)?' -- "$file" \
    | sort -u
)

if [ "${#urls[@]}" -eq 0 ]; then
  echo "❌ No image URLs found in: $file"
  exit 1
fi

echo "🖼  Found ${#urls[@]} image URL(s) in: $file"
printf '   %s\n' "${urls[@]}"

"$BROWSER" "${urls[@]}" &>/dev/null &
