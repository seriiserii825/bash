#!/usr/bin/env bash

set -e

echo "📦 Loading NVM..."

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v nvm >/dev/null 2>&1; then
  echo "❌ nvm not found"
  exit 1
fi

echo "📋 Fetching installed Node versions..."

VERSIONS=$(nvm ls --no-colors | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -u)

if [ -z "$VERSIONS" ]; then
  echo "⚠️ No Node versions found"
else
  echo "👉 Select versions to uninstall (TAB to select, ENTER to confirm):"

  SELECTED=$(echo "$VERSIONS" | fzf --multi --prompt="Delete Node versions > ")

  if [ -n "$SELECTED" ]; then
    echo "🗑 Removing selected versions..."
    for v in $SELECTED; do
      echo "→ Removing $v"
      nvm uninstall "$v"
    done
  else
    echo "⚠️ No versions selected"
  fi
fi

echo ""
echo "🧹 Cleaning caches..."

# npm
if command -v npm >/dev/null 2>&1; then
  echo "→ Cleaning npm cache..."
  npm cache clean --force
fi

# yarn
if command -v yarn >/dev/null 2>&1; then
  echo "→ Cleaning yarn cache..."
  yarn cache clean
fi

# bun
if [ -d "$HOME/.bun/install/cache" ]; then
  echo "→ Cleaning bun cache..."
  rm -rf "$HOME/.bun/install/cache"
fi

# general cache
if [ -d "$HOME/.cache" ]; then
  echo "→ Cleaning ~/.cache..."
  rm -rf "$HOME/.cache/"*
fi

echo ""
echo "✅ Done!"
