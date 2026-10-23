#!/usr/bin/env bash
# PHP helpers for a HestiaCP VPS: check apt for PHP updates, show PHP version of every site,
# show PHP-FPM upgrades from dpkg logs.

tgreen=$'\e[32m'
tblue=$'\e[34m'
tmagenta=$'\e[35m'
treset=$'\e[0m'

bin=/usr/local/hestia/bin

function checkPhpUpdates() {
  apt list --upgradable 2>/dev/null | grep -E '^php[0-9]+\.[0-9]+-' || echo 'Доступных обновлений PHP нет'
}

function checkPhpForAllSites() {
  local default
  default=$("$bin/v-list-default-php" plain)

  {
  printf 'USER\tDOMAIN\tBACKEND\tPHP\n'
  printf -- '----\t------\t-------\t---\n'
  {
  for user in $("$bin/v-list-users" list); do
    "$bin/v-list-web-domains" "$user" json |
      jq -r 'to_entries[] | [.key, (.value.BACKEND // "default")] | @tsv' |
      while IFS=$'\t' read -r domain backend; do
        # v-list-default-php may print several versions, so take the one whose FPM pool serves the domain
        if [[ "$backend" == default ]]; then
          pool=$(compgen -G "/etc/php/*/fpm/pool.d/$domain.conf" | head -n1)
          if [[ -n "$pool" ]]; then
            minor=$(basename "$(dirname "$(dirname "$(dirname "$pool")")")")
          elif [[ "$default" != *$'\n'* ]]; then
            minor=$default
          else
            minor=
          fi
        elif [[ "$backend" =~ (^|-)PHP-([0-9]+)_([0-9]+)$ ]]; then
          minor="${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
        else
          minor=
        fi

        full=
        if [[ -n "$minor" && -x "/usr/sbin/php-fpm$minor" ]]; then
          full=$("/usr/sbin/php-fpm$minor" -v | awk 'NR == 1 {print $2}')
        fi

        printf '%s\t%s\t%s\t%s\n' \
          "$user" "$domain" "$backend" "${full:-не определена}"
      done
  done
  } | LC_ALL=C sort -t $'\t' -k4,4V -k2,2
  } | column -t -s $'\t'
}

# Pass log files as arguments for testing, or read the current and rotated dpkg logs.
function showPhpUpdates() {
  local logs rows report

  if (($#)); then
    logs=("$@")
  else
    shopt -s nullglob
    logs=(/var/log/dpkg.log*)
  fi

  if ((${#logs[@]} == 0)); then
    printf 'Не найдены журналы dpkg.\n' >&2
    return 1
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
    return 0
  fi

  report="php-fpm-updates-$(date +%Y-%m-%d_%H%M%S).txt"

  {
    printf '%-19s  %-5s  %-17s  %s\n' 'DATE AND TIME' 'PHP' 'BEFORE' 'AFTER'
    while IFS=$'\t' read -r timestamp branch before after; do
      printf '%-19s  %-5s  %-17s  %s\n' "$timestamp" "$branch" "$before" "$after"
    done <<< "$rows"
  } | tee -- "$report"

  printf '\nРезультат сохранён в %s\n' "$(realpath -- "$report")"
}

echo "${tgreen}1) Check PHP for updates${treset}"
echo "${tblue}2) Check PHP for all sites${treset}"
echo "${tmagenta}3) Show PHP after update${treset}"
echo "4) Exit"
read -rp "Select an option: " option

case $option in
  1)
    checkPhpUpdates
    ;;
  2)
    checkPhpForAllSites
    ;;
  3)
    showPhpUpdates
    ;;
  4)
    exit 0
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac
