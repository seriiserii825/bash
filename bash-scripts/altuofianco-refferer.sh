#!/usr/bin/env bash
# Проверяет сайты из go-wp/list.csv + site-updates/total-sites.txt (объединённо, без дублей): в футере ссылка на https://altuofianco.it
# и есть ли у неё rel="noopener noreferrer" (или хотя бы одно из noopener / noreferrer).
# Выводит сайты, где такой rel есть.
# Результат также сохраняется в ./altuofianco-refferer.md (markdown-чеклист)
# Usage: altuofianco-refferer.sh [-a]   (-a — показать статус всех сайтов)
# Deps: curl, perl

set -uo pipefail

csv_file="/home/serii/Documents/go/go-wp/list.csv"
sites_file="/home/serii/Documents/site-updates/total-sites.txt"
out_file="altuofianco-refferer.md"
jobs=10

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
GRAY='\033[0;90m'
NC='\033[0m'

show_all=0
[ "${1:-}" = "-a" ] && show_all=1

for f in "$csv_file" "$sites_file"; do
  [ -f "$f" ] || { echo "Файл не найден: $f" >&2; exit 1; }
done

# Печатает: STATUS<TAB>url<TAB>значение rel
# STATUS: REL (ссылка есть и в rel есть noopener/noreferrer) | CLEAN (ссылка есть, без них)
#         NONE (ссылки нет) | ERR (сайт не открылся)
check_site() {
  local url="$1" html
  html=$(curl -sL --max-time 20 -A "Mozilla/5.0" "$url") || { printf 'ERR\t%s\t\n' "$url"; return; }
  [ -n "$html" ] || { printf 'ERR\t%s\t\n' "$url"; return; }

  printf '%s' "$html" | perl -0777 -ne '
    my $url = $ENV{SITE_URL};
    # Берём часть страницы начиная с <footer, если он есть
    my $pos = index(lc $_, "<footer");
    my $part = $pos >= 0 ? substr($_, $pos) : $_;
    my ($link_found, $rel_found, $rel_val) = (0, 0, "");
    while ($part =~ m{(<a\b[^>]*>)}gis) {
      my $tag = $1;
      next unless $tag =~ m{\bhref\s*=\s*["\x27]?https?://(?:www\.)?altuofianco\.it(?:[/"\x27?#\s>]|$)}i;
      $link_found = 1;
      if ($tag =~ m{\brel\s*=\s*(?:"([^"]*)"|\x27([^\x27]*)\x27|([^\s>]+))}i) {
        my $rel = defined $1 ? $1 : defined $2 ? $2 : $3;
        $rel =~ s/\s+/ /g; $rel =~ s/^ | $//g;
        if ($rel =~ /\b(?:noopener|noreferrer)\b/i) { $rel_found = 1; $rel_val = $rel; last }
      }
    }
    my $status = $rel_found ? "REL" : $link_found ? "CLEAN" : "NONE";
    print "$status\t$url\t$rel_val\n";
  '
}
export -f check_site

# ---- URL из list.csv (4-я колонка) + домены из total-sites.txt (дополняем https://).
# Дубли убираем по домену без www.; при совпадении приоритет у URL из csv (точная схема/www)
mapfile -t urls < <(
  {
    cut -d',' -f4 "$csv_file"
    sed -E '/^https?:\/\//! s|^|https://|' "$sites_file"
  } | sed -E 's/\r$//; s/^[[:space:]]+|[[:space:]]+$//g; s|/+$||' | grep -E '^https?://[^[:space:]]+$' |
    awk '{ host = tolower($0); sub(/^https?:\/\//, "", host); sub(/^www\./, "", host)
           if (!(host in seen)) { seen[host] = 1; print } }' | sort
)
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

rel_count=0
declare -A md_lines=([REL]="" [CLEAN]="" [NONE]="" [ERR]="")
while IFS=$'\t' read -r status url rel; do
  case "$status" in
    REL)   ((rel_count++)); echo -e "${RED}REL${NC}    $url  ${GRAY}rel=\"$rel\"${NC}" ;;
    CLEAN) ((show_all)) && echo -e "${GREEN}CLEAN${NC}  $url" ;;
    NONE)  ((show_all)) && echo -e "${YELLOW}NONE${NC}   $url" ;;
    ERR)   ((show_all)) && echo -e "${GRAY}ERR${NC}    $url" ;;
    *)     continue ;;
  esac
  if [ "$status" = REL ]; then
    md_lines[$status]+="- [ ] [$url]($url) — \`rel=\"$rel\"\`"$'\n'
  else
    md_lines[$status]+="- [ ] [$url]($url)"$'\n'
  fi
done < <(printf '%s\n' "$results" | sort -t$'\t' -k1,1 -k2,2)

# ---- Markdown-чеклист: сайты с noopener/noreferrer; с -a — ещё секции CLEAN/NONE/ERR
{
  echo "# Altuofianco — ссылки с rel noopener/noreferrer"
  echo
  printf '%s' "${md_lines[REL]}"
  if ((show_all)); then
    for st in CLEAN NONE ERR; do
      [ -n "${md_lines[$st]}" ] || continue
      echo
      echo "## $st"
      echo
      printf '%s' "${md_lines[$st]}"
    done
  fi
} > "$out_file"

echo
echo "Сайтов со ссылкой с noopener/noreferrer: $rel_count"
echo "Сохранено в $(realpath "$out_file")"
