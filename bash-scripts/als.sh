#!/bin/bash
# Fuzzy-search zsh aliases by name or command (e.g. "go-scripts"), copy selected alias name to clipboard

alias_dirs=(~/.zshrc ~/dotfiles/zsh_modules ~/Documents/global-aliases)

# aliases live in the interactive zsh config, bash can't see them directly
aliases=$(zsh -ic 'alias' 2>/dev/null | sed -E "s/^([^=]+)=(.*)$/\1\t\2/; s/\t'(.*)'$/\t\1/")

if [ -z "$aliases" ]; then
  echo "No aliases found"
  exit 1
fi

selected=$(echo "$aliases" | column -t -s $'\t' | fzf \
  --query "$*" \
  --prompt "alias> " \
  --preview "grep -rn --color=always -E \"alias +(-g +)?{1}=\" ${alias_dirs[*]} 2>/dev/null" \
  --preview-window down:3:wrap)

[ -z "$selected" ] && exit 0

name=$(echo "$selected" | awk '{print $1}')
echo -n "$name" | xclip -selection clipboard
echo "$selected"
echo "Copied: $name"
