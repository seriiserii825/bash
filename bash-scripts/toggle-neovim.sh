#!/usr/bin/env bash
# Toggles ~/.config/nvim between the Lua/lazy.nvim build and the old VimScript+CoC build.
# Also keeps each build's installed plugins/state/cache in its own directory,
# so switching back and forth doesn't require reinstalling anything.
# toggle-neovim.sh

set -e

NVIM_LINK="$HOME/.config/nvim"
LUA_CONFIG="$HOME/Documents/neovim-lua"
COC_CONFIG="$HOME/Documents/Apps/nvim-coc"

DATA_LINK="$HOME/.local/share/nvim"
STATE_LINK="$HOME/.local/state/nvim"
CACHE_LINK="$HOME/.cache/nvim"

LUA_DATA="$HOME/.local/share/nvim-lua"
COC_DATA="$HOME/.local/share/nvim-coc"
LUA_STATE="$HOME/.local/state/nvim-lua"
COC_STATE="$HOME/.local/state/nvim-coc"
LUA_CACHE="$HOME/.cache/nvim-lua"
COC_CACHE="$HOME/.cache/nvim-coc"

if [ ! -L "$NVIM_LINK" ]; then
  echo "$NVIM_LINK is not a symlink, refusing to touch it"
  exit 1
fi

CURRENT_TARGET="$(readlink -f "$NVIM_LINK")"

if [ "$CURRENT_TARGET" = "$LUA_CONFIG" ]; then
  echo "Current build: Lua (lazy.nvim)"
elif [ "$CURRENT_TARGET" = "$COC_CONFIG" ]; then
  echo "Current build: CoC"
else
  echo "~/.config/nvim points to an unrecognized target: $CURRENT_TARGET"
  echo "Expected either $LUA_CONFIG or $COC_CONFIG"
  exit 1
fi

read -r -p "Press Enter to toggle (Ctrl+C to cancel)..."

# Points $link at $new_target. If $link is still a real directory (first run,
# not yet split per-build), its contents belong to the build we're leaving,
# so they're moved into $old_target before the symlink is created.
switch_dir() {
  local link="$1" new_target="$2" old_target="$3"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    mkdir -p "$(dirname "$old_target")"
    mv "$link" "$old_target"
  fi
  mkdir -p "$new_target"
  ln -sfn "$new_target" "$link"
}

if [ "$CURRENT_TARGET" = "$LUA_CONFIG" ]; then
  switch_dir "$DATA_LINK" "$COC_DATA" "$LUA_DATA"
  switch_dir "$STATE_LINK" "$COC_STATE" "$LUA_STATE"
  switch_dir "$CACHE_LINK" "$COC_CACHE" "$LUA_CACHE"
  ln -sfn "$COC_CONFIG" "$NVIM_LINK"
  echo "Switched ~/.config/nvim -> $COC_CONFIG (CoC build)"
elif [ "$CURRENT_TARGET" = "$COC_CONFIG" ]; then
  switch_dir "$DATA_LINK" "$LUA_DATA" "$COC_DATA"
  switch_dir "$STATE_LINK" "$LUA_STATE" "$COC_STATE"
  switch_dir "$CACHE_LINK" "$LUA_CACHE" "$COC_CACHE"
  ln -sfn "$LUA_CONFIG" "$NVIM_LINK"
  echo "Switched ~/.config/nvim -> $LUA_CONFIG (Lua build)"
else
  echo "~/.config/nvim points to an unrecognized target: $CURRENT_TARGET"
  echo "Expected either $LUA_CONFIG or $COC_CONFIG"
  exit 1
fi
