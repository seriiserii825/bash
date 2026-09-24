#!/usr/bin/env bash
# Shows SMPlayer keyboard shortcuts from its config, searchable via fzf

set -euo pipefail

SMPLAYER_INI="${SMPLAYER_INI:-$HOME/.config/smplayer/smplayer.ini}"

if ! command -v fzf &>/dev/null; then
    echo "Error: 'fzf' is required but not installed." >&2; exit 1
fi

if [[ ! -f "$SMPLAYER_INI" ]]; then
    echo "Error: SMPlayer config not found: $SMPLAYER_INI" >&2
    exit 1
fi

# [actions] section holds action=shortcut lines; unassigned actions have an empty value (shown as "-").
# Qt quotes values containing commas ("Left, Ctrl+Shift+B") and percent-encodes ':' in keys (aspect_16%3A9)
rows="$(sed -n '/^\[actions\]/,/^\[/{/^\[/d;/^$/d;p}' "$SMPLAYER_INI" \
    | sed -E 's/%3A/:/g; s/=$/=-/; s/^([^=]+)=/\1\t/; s/\t"(.*)"$/\t\1/' \
    | sort)"

if [[ -z "$rows" ]]; then
    echo "No shortcuts found in $SMPLAYER_INI"
    exit 0
fi

{ printf 'ACTION\tSHORTCUT\n'; printf '%s\n' "$rows"; } \
    | column -t -s $'\t' \
    | fzf --prompt="shortcut (esc to quit) > " --header-lines=1 --height=40% --no-info \
          --bind="esc:abort,ctrl-c:abort"
