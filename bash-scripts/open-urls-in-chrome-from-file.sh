#!/usr/bin/env bash
# Picks a file with fzf, validates every non-empty line is a URL, and opens them all in Chrome
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Required: $1"; exit 1; }; }
need fzf
need fd

BROWSER="${BROWSER:-google-chrome-stable}"
ROOT="${1:-.}"
URL_RE='^https?://[^[:space:]]+$'

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

mapfile -t lines < "$file"

urls=()
bad=()
for i in "${!lines[@]}"; do
  line="${lines[$i]}"
  [[ -z "${line// }" ]] && continue
  if [[ "$line" =~ $URL_RE ]]; then
    urls+=("$line")
  else
    bad+=("$((i + 1)): $line")
  fi
done

if [ "${#bad[@]}" -gt 0 ]; then
  echo "❌ Not a URL — found ${#bad[@]} invalid line(s) in: $file"
  printf '   %s\n' "${bad[@]}"
  exit 1
fi

if [ "${#urls[@]}" -eq 0 ]; then
  echo "❌ No URLs found in: $file"
  exit 1
fi

echo "🔗 Found ${#urls[@]} URL(s) in: $file"
printf '   %s\n' "${urls[@]}"

"$BROWSER" "${urls[@]}" &>/dev/null &
