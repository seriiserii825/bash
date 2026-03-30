#!/usr/bin/env bash
set -euo pipefail

# Проверка зависимостей
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Требуется $1"; exit 1; }; }
need fzf
need rsync

# Проверка аргумента (путь назначения)
DEST="${1:-}"
if [ -z "$DEST" ]; then
  echo "❌ Укажи путь назначения!"
  echo "Пример: ./rsync.sh /mnt/Courses/typescript"
  exit 1
fi

# Проверка существования папки
if [ ! -d "$DEST" ]; then
  read -r -p "Папка '$DEST' не существует. Создать? [y/N]: " MK
  [[ "$MK" =~ ^[Yy]$ ]] || { echo "Отменено."; exit 1; }
  mkdir -p -- "$DEST"
fi

echo "🔎 Выбери файл или папку (только первый уровень текущей директории):"
SELECTED="$(
  find . -mindepth 1 -maxdepth 1 -printf '%T@ %P\0' \
  | sort -rz -k1,1 \
  | sed -z 's/^[^ ]* //' \
  | fzf --read0 --height=80% --reverse \
        --preview 'p="{}"; if [ -d "$p" ]; then ls -la --color=always -- "$p"; else file -b -- "$p"; fi' \
        --preview-window=right,60%
)"
[ -n "${SELECTED}" ] || { echo "Отменено."; exit 1; }

# Определяем тип и путь
if [ -d "$SELECTED" ]; then
  ITEM_TYPE="dir"
  SRC="${SELECTED%/}"   # копировать папку целиком
else
  ITEM_TYPE="file"
  SRC="$SELECTED"
fi

echo "📦 Источник: $SRC ($ITEM_TYPE)"
echo "🛬 Назначение: $DEST"

# Dry-run (по желанию)
read -r -p "Сделать пробный запуск (dry-run)? [y/N]: " DRY
DRY_FLAG=()
[[ "$DRY" =~ ^[Yy]$ ]] && DRY_FLAG=(--dry-run)

echo
echo "▶️  Команда:"
echo "rsync -ah --info=progress2 ${DRY_FLAG[*]:-} --partial --inplace \"$SRC\" \"$DEST/\""
echo

# Запуск rsync
rsync -ah --info=progress2 "${DRY_FLAG[@]}" --partial --inplace --human-readable \
  -- "$SRC" "$DEST/"

echo "✅ Готово."
