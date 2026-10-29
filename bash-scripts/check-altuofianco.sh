#!/usr/bin/env bash
# Проверяет сайты из go-wp/list.csv: в футере ссылка на https://altuofianco.it
# текстом (TEXT) или картинкой (IMAGE). Выводит сайты, где ссылка — текст.
# Результат также сохраняется в ./altuofianco.txt (без цветов)
# Usage: check-altuofianco.sh [-a]   (-a — показать статус всех сайтов)
# Deps: curl, perl

set -uo pipefail

csv_file="/home/serii/Documents/go/go-wp/list.csv"
out_file="altuofianco.txt"
jobs=10

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
GRAY='\033[0;90m'
NC='\033[0m'

show_all=0
[ "${1:-}" = "-a" ] && show_all=1

[ -f "$csv_file" ] || { echo "Файл не найден: $csv_file" >&2; exit 1; }

# Печатает: STATUS<TAB>url<TAB>текст ссылки
# STATUS: TEXT | IMAGE | NONE (ссылки нет) | ERR (сайт не открылся)
check_site() {
  local url="$1" html
  html=$(curl -sL --max-time 20 -A "Mozilla/5.0" "$url") || { printf 'ERR\t%s\t\n' "$url"; return; }
  [ -n "$html" ] || { printf 'ERR\t%s\t\n' "$url"; return; }

  printf '%s' "$html" | perl -0777 -ne '
    my $url = $ENV{SITE_URL};
    # Берём часть страницы начиная с <footer, если он есть
    my $pos = index(lc $_, "<footer");
    my $part = $pos >= 0 ? substr($_, $pos) : $_;
    my ($text_found, $img_found, $label) = (0, 0, "");
    while ($part =~ m{<a\b[^>]*href=["\x27]https?://(?:www\.)?altuofianco\.it[^"\x27]*["\x27][^>]*>(.*?)</a>}gis) {
      my $inner = $1;
      (my $txt = $inner) =~ s/<[^>]*>//g;
      $txt =~ s/&nbsp;|&#160;/ /g;
      $txt =~ s/\s+/ /g; $txt =~ s/^ | $//g;
      if (length $txt) { $text_found = 1; $label = $txt; last }
      $img_found = 1 if $inner =~ /<(img|svg|picture)\b/i;
    }
    my $status = $text_found ? "TEXT" : $img_found ? "IMAGE" : "NONE";
    print "$status\t$url\t$label\n";
  '
}
export -f check_site

mapfile -t urls < <(cut -d',' -f4 "$csv_file" | grep -E '^https?://' | sort -u)
total=${#urls[@]}

# ---- Прогресс в stderr: [готово/всего] прошло секунд, последний проверенный сайт
results=""
done_count=0
start=$SECONDS
while IFS= read -r line; do
  results+="$line"$'\n'
  ((done_count++))
  IFS=$'\t' read -r status url _ <<< "$line"
  printf '\r\033[K[%d/%d] %ds  %-5s %s' "$done_count" "$total" "$((SECONDS - start))" "$status" "$url" >&2
done < <(printf '%s\n' "${urls[@]}" |
  xargs -P "$jobs" -I{} bash -c 'SITE_URL="$1" check_site "$1"' _ {})
printf '\r\033[KПроверено %d сайтов за %ds\n\n' "$total" "$((SECONDS - start))" >&2

text_count=0
: > "$out_file"
while IFS=$'\t' read -r status url label; do
  case "$status" in
    TEXT)  ((text_count++)); echo -e "${RED}TEXT${NC}   $url  ${GRAY}\"$label\"${NC}"
           printf 'TEXT   %s  "%s"\n' "$url" "$label" >> "$out_file" ;;
    IMAGE) ((show_all)) && { echo -e "${GREEN}IMAGE${NC}  $url"; printf 'IMAGE  %s\n' "$url" >> "$out_file"; } ;;
    NONE)  ((show_all)) && { echo -e "${YELLOW}NONE${NC}   $url"; printf 'NONE   %s\n' "$url" >> "$out_file"; } ;;
    ERR)   ((show_all)) && { echo -e "${GRAY}ERR${NC}    $url"; printf 'ERR    %s\n' "$url" >> "$out_file"; } ;;
  esac
done < <(printf '%s\n' "$results" | sort -t$'\t' -k1,1 -k2,2)

echo
echo "Сайтов с текстовой ссылкой: $text_count"
echo "Сайтов с текстовой ссылкой: $text_count" >> "$out_file"
echo "Сохранено в $(realpath "$out_file")"
