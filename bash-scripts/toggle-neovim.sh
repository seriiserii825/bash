#!/usr/bin/env bash
# Toggles ~/.config/nvim between the Lua/lazy.nvim build and the old VimScript+CoC build.
# toggle-neovim.sh

set -e

NVIM_LINK="$HOME/.config/nvim"
LUA_CONFIG="$HOME/Documents/neovim-lua"
COC_CONFIG="$HOME/Documents/Apps/nvim-coc"

if [ ! -L "$NVIM_LINK" ]; then
  echo "$NVIM_LINK is not a symlink, refusing to touch it"
  exit 1
fi

CURRENT_TARGET="$(readlink -f "$NVIM_LINK")"

if [ "$CURRENT_TARGET" = "$LUA_CONFIG" ]; then
  ln -sfn "$COC_CONFIG" "$NVIM_LINK"
  echo "Switched ~/.config/nvim -> $COC_CONFIG (CoC build)"
elif [ "$CURRENT_TARGET" = "$COC_CONFIG" ]; then
  ln -sfn "$LUA_CONFIG" "$NVIM_LINK"
  echo "Switched ~/.config/nvim -> $LUA_CONFIG (Lua build)"
else
  echo "~/.config/nvim points to an unrecognized target: $CURRENT_TARGET"
  echo "Expected either $LUA_CONFIG or $COC_CONFIG"
  exit 1
fi
