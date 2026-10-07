#!/usr/bin/env bash
# Добавляет новую запись (тема,логин,пароль,url) в list.csv на основе буфера обмена
# Буфер обмена должен содержать 3 строки: url, логин, пароль
# Deps: xclip (или xsel)

set -euo pipefail

csv_file="/home/serii/Documents/python/py-wp/list.csv"

clip_get() {
  if command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -o
  elif command -v xsel  >/dev/null 2>&1; then xsel -b
  else echo "Install xclip or xsel" >&2; exit 1; fi
}

die() {
  echo "Ошибка: $1" >&2
  exit 1
}

[ -f "$csv_file" ] || die "Файл не найден: $csv_file"

# ---- Читаем 3 строки из буфера обмена
mapfile -t lines < <(clip_get)

[ "${#lines[@]}" -eq 3 ] || die "В буфере обмена должно быть ровно 3 строки (url, логин, пароль), найдено: ${#lines[@]}"

url="${lines[0]}"
login="${lines[1]}"
password="${lines[2]}"

# ---- Обрезаем завершающий слэш у url
url="${url%/}"

# ---- Валидация содержимого
[[ "$url" =~ ^https?://[^[:space:]]+$ ]] || die "Первая строка не похожа на url: '$url'"
[[ -n "$login" && ! "$login" =~ [[:space:]] ]] || die "Вторая строка (логин) некорректна: '$login'"
[[ -n "$password" && ! "$password" =~ [[:space:]] ]] || die "Третья строка (пароль) некорректна: '$password'"

for field in "$url" "$login" "$password"; do
  [[ "$field" != *,* ]] || die "Поле не должно содержать запятую: '$field'"
done

# ---- Спрашиваем название темы
read -rp "Название темы: " theme
[ -n "$theme" ] || die "Название темы не может быть пустым"
[[ "$theme" != *,* ]] || die "Название темы не должно содержать запятую"

new_line="${theme},${login},${password},${url}"

# ---- Точное совпадение (тема + url + логин + пароль) — уже есть, выходим с ошибкой
if awk -F',' -v t="$theme" -v l="$login" -v p="$password" -v u="$url" \
  '$1 == t && $2 == l && $3 == p && $4 == u { found=1 } END { exit !found }' "$csv_file"; then
  die "Тема '$theme' с такими url/логином/паролем уже есть в $csv_file"
fi

# ---- Тема есть, но данные отличаются — показываем оригинал и новую строку, спрашиваем подтверждение
existing_line="$(awk -F',' -v t="$theme" '$1 == t { print; exit }' "$csv_file")"
if [ -n "$existing_line" ]; then
  echo "Оригинал: $existing_line"
  echo "Новое:    $new_line"
  read -rp "Данные отличаются. Дописать новую запись? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Отменено."; exit 0; }
fi

# ---- Добавляем запись в конец файла
echo "$new_line" >> "$csv_file"

echo "Добавлено в $csv_file: $new_line"
