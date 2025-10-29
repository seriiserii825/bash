# ~/.local/bin/ff
#!/usr/bin/env bash
set -euo pipefail

# deps
for bin in rg fzf nvim; do
  command -v "$bin" >/dev/null 2>&1 || { echo "❌ Need $bin"; exit 1; }
done

ROOT="${1:-.}"

# Unicode token: first letter, then letters/digits/_/-
# Works in ripgrep's default (Rust) regex engine — no -P/PCRE needed.
TOKEN_RE='\p{L}[\p{L}\p{N}_-]*'

# Produce lines: path:line:col:token
RG=(rg --hidden --no-heading --line-number --column --color=never -o -e "$TOKEN_RE" \
       --glob '!.git' --glob '!node_modules' --glob '!vendor' --glob '!venv' "$ROOT")

SEL="$("${RG[@]}" \
  | fzf --height=90% --reverse --prompt='🔎 symbol> ' --delimiter=':' \
        --with-nth=4.. \
        --preview '
          TOKEN=$(printf "%s" {4})
          # show from the match line to end (simple & robust)
          (bat --style=numbers --color=always --line-range {2}: {1} 2>/dev/null \
           || sed -n "{2},\$p" -- {1}) \
          | perl -pe "s/\Q$TOKEN\E/\e[1;4m$&\e[0m/g"
        ' \
        --preview-window=right,60%,+{2}-/2 \
)" || exit 0

[ -n "${SEL:-}" ] || exit 0

IFS=':' read -r FILE LINE COL TOKEN <<<"$SEL"
LINE="${LINE:-1}"
COL="${COL:-1}"

exec nvim +"normal! ${LINE}G${COL}|" -- "$FILE"
