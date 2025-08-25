#!/usr/bin/env bash
set -euo pipefail

JSON="${1:?Usage: ./fix-order.sh path/to/file.json}"

# 1) Получаем префикс таблиц WP
prefix="$(wp db prefix)"

# 2) Достаём ключи полей в порядке следования (только верхний уровень .fields)
readarray -t KEYS < <(jq -r '
  (if type=="array" then . else [.] end)
  | .[]
  | select(has("fields") and (.fields|type=="array"))
  | .fields[]
  | select(type=="object" and has("key"))
  | .key
' "$JSON")

[ "${#KEYS[@]}" -gt 0 ] || { echo "No .fields[].key in JSON"; exit 1; }

# 3) Генерим один SQL-пакет и применяем
tmp="$(mktemp)"
{
  echo "START TRANSACTION;"
  i=0
  for key in "${KEYS[@]}"; do
    printf "UPDATE %sposts SET menu_order=%d WHERE post_type='acf-field' AND post_name='%s';\n" "$prefix" "$i" "$key"
    i=$((i+1))
  done
  echo "COMMIT;"
} > "$tmp"

wp db query < "$tmp"
rm -f "$tmp"

# 4) Быстрая проверка (ORDER BY menu_order, ID)
wp db query "SELECT post_title, post_name, menu_order, ID
FROM ${prefix}posts
WHERE post_type='acf-field' AND post_parent=(
  SELECT ID FROM ${prefix}posts
  WHERE post_type='acf-field-group' AND post_name='group_uv2mushvbichc'
)
ORDER BY menu_order, ID;"
