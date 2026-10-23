#!/usr/bin/env bash

bin=/usr/local/hestia/bin
default=$("$bin/v-list-default-php" plain)

printf 'USER\tDOMAIN\tBACKEND\tPHP\n'

{
for user in $("$bin/v-list-users" list); do
  "$bin/v-list-web-domains" "$user" json |
    jq -r 'to_entries[] | [.key, (.value.BACKEND // "default")] | @tsv' |
    while IFS=$'\t' read -r domain backend; do
      if [[ "$backend" == default ]]; then
        minor=$default
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

