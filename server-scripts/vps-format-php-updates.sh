#!/usr/bin/env bash
set -euo pipefail

# Pass log files as arguments for testing, or read the current and rotated dpkg logs.
if (($#)); then
  logs=("$@")
else
  shopt -s nullglob
  logs=(/var/log/dpkg.log*)
fi

if ((${#logs[@]} == 0)); then
  printf 'Не найдены журналы dpkg.\n' >&2
  exit 1
fi

rows=$(
  zcat -f -- "${logs[@]}" |
    awk '
      $3 == "upgrade" && $4 ~ /^php[0-9]+\.[0-9]+-fpm(:[^[:space:]]+)?$/ {
        branch = $4
        sub(/^php/, "", branch)
        sub(/-fpm.*/, "", branch)

        before = $5
        after = $6
        sub(/^[0-9]+:/, "", before)
        sub(/^[0-9]+:/, "", after)
        sub(/\+.*/, "", before)
        sub(/\+.*/, "", after)

        printf "%s %s\t%s\t%s\t%s\n", $1, $2, branch, before, after
      }
    ' |
    LC_ALL=C sort -t $'\t' -k1,1 -k2,2V
)

if [[ -z "$rows" ]]; then
  printf 'Обновлений PHP-FPM в журналах dpkg не найдено.\n'
  exit 0
fi

report="php-fpm-updates-$(date +%Y-%m-%d_%H%M%S).txt"

{
  printf '%-19s  %-5s  %-17s  %s\n' 'DATE AND TIME' 'PHP' 'BEFORE' 'AFTER'
  while IFS=$'\t' read -r timestamp branch before after; do
    printf '%-19s  %-5s  %-17s  %s\n' "$timestamp" "$branch" "$before" "$after"
  done <<< "$rows"
} | tee -- "$report"

printf '\nРезультат сохранён в %s\n' "$(realpath -- "$report")"
