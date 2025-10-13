#!/usr/bin/env bash
# convert-font-for-pdf.sh
# ──────────────────────────────────────────────────────────────────────────────
# Интерактивно: выбрать PDF и шрифт; извлечь текст, почистить его и собрать
# новый PDF c выбранным шрифтом (только для просмотра; оригинал не меняется).
#
# Зависимости (Arch):
#   sudo pacman -S --needed poppler pandoc fontconfig fzf iconv sed
#   # PDF-движок (выбери один):
#   sudo pacman -S --needed tectonic                 # ← РЕКОМЕНДУЕМО
#   # либо: sudo pacman -S --needed texlive-bin texlive-core texlive-latexextra

set -euo pipefail

err()  { printf "\e[31m%s\e[0m\n" "$*" >&2; }
info() { printf "\e[36m%s\e[0m\n" "$*"; }
note() { printf "\e[33m%s\e[0m\n" "$*"; }

need_cmds=(pdftotext pandoc fc-list fc-match fzf iconv sed tr)
missing=()
for c in "${need_cmds[@]}"; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
if (( ${#missing[@]} )); then
  err "Отсутствуют инструменты: ${missing[*]}"
  echo "Установи (Arch): sudo pacman -S --needed poppler pandoc fontconfig fzf iconv sed"
  echo "И один из PDF-движков:  sudo pacman -S --needed tectonic   # РЕКОМЕНДУЕМО"
  exit 1
fi

pick_pdf_engine() {
  if command -v tectonic >/dev/null 2>&1; then
    printf '%s\n' "tectonic"
    return
  fi
  if command -v xelatex >/dev/null 2>&1; then
    printf '%s\n' "xelatex"
    return
  fi
  err "Не найден PDF-движок (tectonic или xelatex). Установи один из них."
  exit 1
}

# Подберём поддерживаемый pandoc-входной формат (у некоторых сборок нет 'plain')
pandoc_from() {
  if pandoc --list-input-formats 2>/dev/null | grep -qx 'plain'; then
    printf '%s\n' "plain"
  else
    printf '%s\n' "markdown_strict"
  fi
}

pick_pdf() {
  local sel
  sel="$(
    find . -type f -iname '*.pdf' -printf '%P\n' \
    | sort -f \
    | fzf --prompt='PDF > ' --height=80% --reverse --border --cycle
  )"
  [[ -n "${sel:-}" ]] || { err "Отмена выбора PDF"; exit 1; }
  printf '%s\n' "$sel"
}

list_families_unique() {
  fc-list : family \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]\+//; s/[[:space:]]\+$//' \
    | awk 'BEGIN{IGNORECASE=1} {k=tolower($0); if(!seen[k]++ && length($0)>0) print $0}' \
    | sort -f
}

pick_font() {
  local query="${1:-}"
  local sel
  sel="$(
    list_families_unique \
    | fzf --prompt='Font > ' --height=80% --reverse --border --cycle ${query:+--query="$query"}
  )"
  [[ -n "${sel:-}" ]] || { err "Отмена выбора шрифта"; exit 1; }
  printf '%s\n' "$sel"
}

font_exists() {
  local fam="$1"
  if fc-list ":family=$fam" | grep -q .; then
    return 0
  fi
  if fc-list | grep -qi --fixed-strings "$fam"; then
    return 0
  fi
  return 1
}

sanitize() {
  printf '%s' "$1" | sed -e 's/[[:space:]]\+/_/g' -e 's/[^A-Za-z0-9._+-]/_/g'
}

build_pdf() {
  local input="$1" font="$2" output="$3" engine="$4"
  local from_fmt
  from_fmt="$(pandoc_from)"

  # Временные файлы
  local tmp_txt tmp_clean
  tmp_txt="$(mktemp)"
  tmp_clean="$(mktemp)"
  cleanup() { rm -f -- "$tmp_txt" "$tmp_clean"; }
  trap cleanup RETURN

  info "📜 Извлекаю текст: $input"
  # UTF-8, без принудительных разрывов страниц
  pdftotext -enc UTF-8 -nopgbrk "$input" "$tmp_txt"

  # Санитация:
  #  - убираем управляющие \x00–\x1F (кроме таб/перевода строки)
  #  - NBSP (C2 A0) -> обычный пробел
  #  - soft hyphen (C2 AD) -> удалить
  #  - отбрасываем нечитаемые символы iconv'ом
  iconv -f utf-8 -t utf-8 -c "$tmp_txt" \
  | tr -d '\000-\010\013\014\016-\037' \
  | sed -e 's/\xC2\xA0/ /g' -e 's/\xC2\xAD//g' \
  > "$tmp_clean"

  # Проверяем, что текст не пустой
  if ! grep -q '[^[:space:]]' "$tmp_clean"; then
    err "Извлечён пустой текст. Вероятно, PDF — скан или без текстового слоя."
    note "OCR (пример): sudo pacman -S --needed ocrmypdf tesseract tesseract-data-eng"
    note "              ocrmypdf --deskew --optimize 3 '$input' '$(dirname -- "$output")/ocr_$(basename -- "$output")'"
    exit 1
  fi

  info "🛠 Собираю PDF со шрифтом: $font (движок: $engine; pandoc --from=$from_fmt)"
  if [[ "$engine" == "tectonic" ]]; then
    pandoc "$tmp_clean" \
      --from="$from_fmt" \
      -V mainfont="$font" \
      -V fontsize=11pt \
      -V geometry:"a4paper,margin=2cm" \
      --pdf-engine=tectonic \
      -o "$output"
  else
    if ! kpsewhich xelatex.fmt >/dev/null 2>&1; then
      err "У xelatex нет формата xelatex.fmt."
      echo "Попробуй (root):  sudo mktexlsr && sudo fmtutil-sys --byfmt xelatex  ||  sudo fmtutil-sys --all"
      echo "Либо поставь tectonic:  sudo pacman -S --needed tectonic"
      exit 1
    fi
    pandoc "$tmp_clean" \
      --from="$from_fmt" \
      -V mainfont="$font" \
      -V fontsize=11pt \
      -V geometry:"a4paper,margin=2cm" \
      --pdf-engine=xelatex \
      -o "$output"
  fi

  info "✅ Готово: $output"
}

main() {
  local input font output in_dir in_base base_no_ext font_safe engine

  input="$(pick_pdf)"
  [[ -f "$input" ]] || { err "Файл не найден: $input"; exit 1; }

  # Подсказка для поиска (можешь сменить): Noto/DejaVu/Inter/FiraCode
  font="$(pick_font "Noto Sans")"
  if ! font_exists "$font"; then
    err "Шрифт не найден в системе: $font"
    info "Проверь название у fontconfig:"
    echo "  fc-list | grep -i 'noto\\|dejavu\\|inter\\|fira'"
    echo "  fc-list ':family=$font'"
    info "Обновить кеш: fc-cache -fv"
    exit 1
  fi

  info "🔎 Какой файл подставит fontconfig (первые 3 кандидата):"
  fc-match -s "$font" | sed -n '1,3p' || true

  in_dir="$(dirname -- "$input")"
  in_base="$(basename -- "$input")"
  base_no_ext="${in_base%.*}"
  font_safe="$(sanitize "$font")"
  output="${in_dir}/${base_no_ext}_${font_safe}.pdf"

  engine="$(pick_pdf_engine)"
  build_pdf "$input" "$font" "$output" "$engine"
}

main
