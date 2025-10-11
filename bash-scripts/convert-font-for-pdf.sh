#!/usr/bin/env bash
# Интерактивно: выбрать PDF и шрифт; собрать новый PDF c постфиксом _<font>
# Зависимости: poppler (pdftotext), pandoc, texlive-core, texlive-fontsextra, fzf

set -euo pipefail

err()  { printf "\e[31m%s\e[0m\n" "$*" >&2; }
info() { printf "\e[36m%s\e[0m\n" "$*"; }

need_cmds=(pdftotext pandoc xelatex fc-list fzf)
missing=()
for c in "${need_cmds[@]}"; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
if (( ${#missing[@]} )); then
  err "Отсутствуют инструменты: ${missing[*]}"
  echo "Установи (Arch): sudo pacman -S poppler pandoc texlive-core texlive-fontsextra fzf"
  exit 1
fi

pick_pdf() {
  local sel
  sel="$(find . -type f -iname '*.pdf' | sed 's|^\./||' | fzf --prompt='PDF > ' --height=80% --reverse)"
  [[ -n "${sel:-}" ]] || { err "Отмена выбора PDF"; exit 1; }
  printf '%s\n' "$sel"
}

list_families_unique() {
  fc-list : family \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]\+//; s/[[:space:]]\+$//' \
    | awk 'BEGIN{IGNORECASE=1} !seen[tolower($0)]++ && length($0)>0' \
    | sort -f
}

pick_font() {
  local sel
  sel="$(list_families_unique | fzf --prompt='Font > ' --height=80% --reverse --query='Inter')"
  [[ -n "${sel:-}" ]] || { err "Отмена выбора шрифта"; exit 1; }
  printf '%s\n' "$sel"
}

sanitize() {
  printf '%s' "$1" | sed -e 's/[[:space:]]\+/_/g' -e 's/[^A-Za-z0-9._+-]/_/g'
}

build_pdf() {
  local input="$1" font="$2" output="$3"
  local tmp_txt
  tmp_txt="$(mktemp)"
  trap 'rm -f "$tmp_txt"' EXIT

  info "📜 Извлекаю текст: $input"
  pdftotext "$input" "$tmp_txt"

  info "🛠 Собираю PDF со шрифтом: $font"
  pandoc "$tmp_txt" \
    -V mainfont="$font" \
    -V fontsize=11pt \
    -V geometry:"a4paper,margin=2cm" \
    --pdf-engine=xelatex \
    -o "$output"

  info "✅ Готово: $output"
}

main() {
  local input font output in_dir in_base base_no_ext font_safe
  input="$(pick_pdf)"
  [[ -f "$input" ]] || { err "Файл не найден: $input"; exit 1; }

  font="$(pick_font)"
  if ! fc-list | grep -qi --fixed-strings "$font"; then
    err "Шрифт не найден в системе: $font"
    exit 1
  fi

  in_dir="$(dirname -- "$input")"
  in_base="$(basename -- "$input")"
  base_no_ext="${in_base%.*}"
  font_safe="$(sanitize "$font")"
  output="${in_dir}/${base_no_ext}_${font_safe}.pdf"

  build_pdf "$input" "$font" "$output"
}

main
