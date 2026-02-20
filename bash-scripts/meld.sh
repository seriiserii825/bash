#!/usr/bin/env bash
# fzf-2diff.sh
# Choose 2 files from current dir with fzf → diff them

set -u

# ─── Config ────────────────────────────────────────────────
# Choose your preferred diff tool here
DIFF_TOOL="${DIFF_TOOL:-meld}"           # meld, vimdiff, nvim -d, delta, diff-so-fancy, diff ...

# Optional: preview command (works great with bat)
PREVIEW_CMD='bat --color=always --style=header,grid,numbers --line-range :500 {} 2>/dev/null || cat {}'

# Colors / style (optional)
export FZF_DEFAULT_OPTS="
  --height 70% --border --reverse --cycle
  --preview '$PREVIEW_CMD' --preview-window=right:55%:wrap
  --color=bg+:#2d2d2e,fg+:#ffffff,hl+:#ffcc66
  --prompt='Pick file 1/2 > ' --header='  Select first file'
"

# ─── Logic ─────────────────────────────────────────────────

pick_file() {
  local prompt="$1"
  local header="$2"

  fzf \
    --prompt="$prompt" \
    --header="$header" \
    --preview="$PREVIEW_CMD" \
    --preview-window=right:60%:wrap \
    --height=70% --border --reverse --cycle \
    --info=inline \
    --bind 'ctrl-y:execute-silent(echo {} | wl-copy || xclip -sel clip || pbcopy)+abort'
}

echo -e "\n  Select first file:"
file1=$(pick_file "First file > " "  Select FILE #1")

[ -z "$file1" ] && { echo "Nothing selected. Bye."; exit 1; }

echo -e "\n  Select second file (compare with → $file1):"
file2=$(pick_file "Second file > " "  Compare with → $file1")

[ -z "$file2" ] && { echo "Nothing selected. Bye."; exit 1; }

echo
echo "Comparing:"
echo "  1) $file1"
echo "  2) $file2"
echo

# ─── Launch diff tool ──────────────────────────────────────

case "$DIFF_TOOL" in
  meld)
    meld "$file1" "$file2" &>/dev/null &
    ;;
  vimdiff|vimdiff3)
    vimdiff "$file1" "$file2"
    ;;
  nvim)
    nvim -d "$file1" "$file2"
    ;;
  delta)
    diff -u "$file1" "$file2" | delta
    ;;
  diff-so-fancy)
    diff -u "$file1" "$file2" | diff-so-fancy | less --tabs=4 -RFX
    ;;
  *)
    # fallback to plain diff
    command diff --color=always -u "$file1" "$file2" | less -R
    ;;
esac
