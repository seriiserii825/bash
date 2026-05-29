#!/usr/bin/env bash
# Picks a file with fzf (using fd) and opens it in Chrome
set -euo pipefail

# deps
for bin in fzf fd; do
  command -v "$bin" >/dev/null 2>&1 || { echo "❌ Need $bin"; exit 1; }
done

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
      --prompt='🌐 open in browser> ' \
      --preview '
        case "{}" in
          *.png|*.jpg|*.jpeg|*.gif|*.webp|*.svg)
            file "{}" ;;
          *)
            bat --style=numbers --color=always -- "{}" 2>/dev/null \
              || cat -- "{}"
        esac
      ' \
      --preview-window=right,60%
) || exit 0

[[ -z "$file" ]] && exit 0

abs=$(realpath "$file")
echo "Opening: $abs"
"$BROWSER" "$abs" &>/dev/null &
