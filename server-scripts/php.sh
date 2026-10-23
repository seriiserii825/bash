#!/usr/bin/env bash
# PHP helpers for a HestiaCP VPS: check apt for PHP updates, show PHP version of every site,
# show PHP-FPM upgrades from dpkg logs, restart PHP-FPM after the last upgrade.

tgreen=$'\e[32m'
tblue=$'\e[34m'
tmagenta=$'\e[35m'
tyellow=$'\e[33m'
treset=$'\e[0m'

bin=/usr/local/hestia/bin

# One row per PHP branch (taken from its fpm/cli package), then the apt command that upgrades only those.
function checkPhpUpdates() {
  local rows branch before after answer branches=() packages=() services=()

  rows=$(
    apt list --upgradable 2>/dev/null |
      awk '
        $1 ~ /^php[0-9]+\.[0-9]+-(fpm|cli)\// {
          branch = $1
          sub(/^php/, "", branch)
          sub(/-.*/, "", branch)
          if (seen[branch]++) next

          after = $2
          before = $NF
          sub(/\]$/, "", before)
          sub(/^[0-9]+:/, "", before)
          sub(/^[0-9]+:/, "", after)
          sub(/\+.*/, "", before)
          sub(/\+.*/, "", after)

          printf "%s\t%s\t%s\n", branch, before, after
        }
      ' |
      sort -t $'\t' -k1,1Vr
  )

  if [[ -z "$rows" ]]; then
    printf 'No PHP updates available\n'
    return 0
  fi

  printf '%-5s  %-10s     %s\n' 'PHP' 'CURRENT' 'NEW'
  while IFS=$'\t' read -r branch before after; do
    printf '%-5s  %-10s  →  %s\n' "$branch" "$before" "$after"
    branches+=("$branch")
    packages+=("php$branch-fpm" "php$branch-cli")
    services+=("php$branch-fpm")
  done <<< "$rows"

  printf '\napt install --only-upgrade'
  for branch in "${branches[@]}"; do
    printf ' \\\n    php%s-fpm php%s-cli' "$branch" "$branch"
  done
  printf '\n\n'

  read -rp 'Install updates? [y/N] ' answer || return 0
  [[ "$answer" == [yY] ]] || return 0

  apt install --only-upgrade -- "${packages[@]}" || return 1

  echo
  restartPhpFpm "${services[@]}"
}

function restartPhpFpm() {
  local answer service

  read -rp "Restart $*? [y/N] " answer || return 0
  [[ "$answer" == [yY] ]] || return 0

  systemctl restart -- "$@"
  for service; do
    printf '%-12s  %s\n' "$service" "$(systemctl is-active -- "$service")"
  done
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
          "$user" "$domain" "$backend" "${full:-unknown}"
      done
  done
  } | LC_ALL=C sort -t $'\t' -k4,4V -k2,2
  } | column -t -s $'\t'
}

# Prints "date time<TAB>branch<TAB>before<TAB>after" for every PHP-FPM upgrade, oldest first.
# Pass log files as arguments for testing, or read the current and rotated dpkg logs.
function phpFpmUpgradeRows() {
  local logs

  if (($#)); then
    logs=("$@")
  else
    shopt -s nullglob
    logs=(/var/log/dpkg.log*)
  fi

  if ((${#logs[@]} == 0)); then
    printf 'No dpkg logs found.\n' >&2
    return 1
  fi

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
}

function showPhpUpdates() {
  local rows report

  rows=$(phpFpmUpgradeRows "$@") || return 1

  if [[ -z "$rows" ]]; then
    printf 'No PHP-FPM upgrades found in dpkg logs.\n'
    return 0
  fi

  report="php-fpm-updates-$(date +%Y-%m-%d_%H%M%S).txt"

  {
    printf '%-19s  %-5s  %-17s  %s\n' 'DATE AND TIME' 'PHP' 'BEFORE' 'AFTER'
    while IFS=$'\t' read -r timestamp branch before after; do
      printf '%-19s  %-5s  %-17s  %s\n' "$timestamp" "$branch" "$before" "$after"
    done <<< "$rows"
  } | tee -- "$report"

  printf '\nSaved to %s\n' "$(realpath -- "$report")"
}

# Takes the PHP-FPM branches upgraded on the day of the last upgrade and restarts
# those whose service is still running from before the upgrade.
function restartUpdatedPhp() {
  local rows last timestamp branch before after since status services=()

  rows=$(phpFpmUpgradeRows "$@") || return 1

  if [[ -z "$rows" ]]; then
    printf 'No PHP-FPM upgrades found in dpkg logs.\n'
    return 0
  fi

  last=$(tail -n1 <<< "$rows" | cut -c1-10)
  rows=$(
    awk -F'\t' -v day="$last" '
      substr($1, 1, 10) == day { latest[$2] = $0 }
      END { for (branch in latest) print latest[branch] }
    ' <<< "$rows" |
      sort -t $'\t' -k2,2Vr
  )

  printf 'Last PHP-FPM upgrade: %s\n\n' "$last"
  printf '%-5s  %-10s  %-19s  %-19s  %s\n' 'PHP' 'VERSION' 'UPDATED' 'RUNNING SINCE' 'STATUS'

  while IFS=$'\t' read -r timestamp branch before after; do
    since=$(systemctl show -p ActiveEnterTimestamp --value -- "php$branch-fpm")

    if [[ -z "$since" ]] || ! systemctl is-active --quiet -- "php$branch-fpm"; then
      status='not running'
      since='-'
    elif (($(date -d "$since" +%s) < $(date -d "$timestamp" +%s))); then
      status='needs restart'
      since=$(date -d "$since" '+%F %T')
      services+=("php$branch-fpm")
    else
      status='ok'
      since=$(date -d "$since" '+%F %T')
    fi

    printf '%-5s  %-10s  %-19s  %-19s  %s\n' "$branch" "$after" "$timestamp" "$since" "$status"
  done <<< "$rows"

  echo
  if ((${#services[@]} == 0)); then
    printf 'All upgraded PHP-FPM services are already restarted.\n'
    return 0
  fi

  restartPhpFpm "${services[@]}"
}

while true; do
  echo
  echo "${tgreen}1) Check PHP for updates${treset}"
  echo "${tblue}2) Check PHP for all sites${treset}"
  echo "${tmagenta}3) Show PHP after update${treset}"
  echo "${tyellow}4) Restart PHP after update${treset}"
  echo "5) Exit"
  read -rp "Select an option: " option || exit 0

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
      restartUpdatedPhp
      ;;
    5)
      exit 0
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
done
