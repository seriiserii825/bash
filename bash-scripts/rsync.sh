#!/usr/bin/env bash
set -euo pipefail

# === deps ===
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Требуется $1"; exit 1; }; }
need fzf
need rsync
need find

# === выбор источника (текущая директория, 1-й уровень) ===
echo "🔎 Выбери файл или папку (только первый уровень текущей директории):"
SRC="$(
  find . -mindepth 1 -maxdepth 1 -printf '%P\0' \
  | fzf --read0 --height=80% --reverse \
        --prompt="Источник > " \
        --preview 'p="{}"; if [ -d "$p" ]; then ls -la --color=always -- "$p"; else file -b -- "$p"; fi' \
        --preview-window=right,60%
)"
[ -n "${SRC}" ] || { echo "Отменено."; exit 1; }

# Определяем тип источника
if [ -d "$SRC" ]; then
  ITEM_TYPE="dir"
  SRC="${SRC%/}"   # копируем папку целиком
else
  ITEM_TYPE="file"
fi
echo "📦 Источник: $SRC ($ITEM_TYPE)"

# === выбор области назначения ===
echo
echo "🌍 Где выбрать папку назначения?"
CHOICE="$(
  printf "1) /mnt\n2) $HOME\n" \
  | fzf --prompt="Выбери область > " --height=20% --reverse
)"

case "$CHOICE" in
  1*) ROOT="/mnt" ;;
  2*) ROOT="$HOME" ;;
  *) echo "Отменено."; exit 1 ;;
esac

# === выбор уровня вложенности ===
read -r -p "🔢 Введи максимальную глубину поиска (по умолчанию 5): " DEPTH
DEPTH="${DEPTH:-5}"

# Проверка, что число
if ! [[ "$DEPTH" =~ ^[0-9]+$ ]]; then
  echo "❌ Некорректное значение глубины. Использую 5."
  DEPTH=5
fi

# === выбор папки назначения ===
echo "📁 Выбери папку назначения из $ROOT (глубина: $DEPTH):"
DEST="$(
  find "$ROOT" -mindepth 1 -maxdepth "$DEPTH" -type d -print0 2>/dev/null \
  | fzf --read0 --height=80% --reverse \
        --prompt="Папка назначения > " \
        --preview 'ls -la --color=always -- "{}"' \
        --preview-window=right,60%
)"
[ -n "${DEST}" ] || { echo "Отменено."; exit 1; }

echo "🛬 Назначение: $DEST"

# === dry-run ===
read -r -p "Сделать пробный запуск (dry-run)? [y/N]: " DRY
DRY_FLAG=()
[[ "$DRY" =~ ^[Yy]$ ]] && DRY_FLAG=(--dry-run)

echo
echo "▶️  Команда:"
echo "rsync -ah --info=progress2 ${DRY_FLAG[*]:-} --partial --inplace -- \"${SRC}\" \"${DEST}/\""
echo

# === запуск ===
rsync -ah --info=progress2 "${DRY_FLAG[@]}" --partial --inplace --human-readable -- \
  "${SRC}" "${DEST}/"

echo "✅ Готово."
