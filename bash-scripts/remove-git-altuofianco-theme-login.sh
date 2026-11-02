#!/usr/bin/env bash
# Рекурсивно ищет в папке все директории altuofianco-theme-login, проверяет, есть ли внутри .git,
# показывает список найденных .git и после подтверждения удаляет их.
# Usage: remove-git-altuofianco-theme-login.sh [папка] [имя_директории]
#   папка          — где искать (по умолчанию текущая)
#   имя_директории — что искать (по умолчанию altuofianco-theme-login)

set -uo pipefail

root="${1:-.}"
name="${2:-altuofianco-theme-login}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
GRAY='\033[0;90m'
NC='\033[0m'

[ -d "$root" ] || { echo -e "${RED}Папка не найдена: $root${NC}" >&2; exit 1; }

found_dirs=()
git_dirs=()

while IFS= read -r -d '' dir; do
  found_dirs+=("$dir")
  # .git может быть директорией (обычный репо) или файлом (submodule/worktree)
  [ -e "$dir/.git" ] && git_dirs+=("$dir/.git")
done < <(find "$root" -type d -name "$name" -not -path '*/.git/*' -print0 2>/dev/null)

if [ ${#found_dirs[@]} -eq 0 ]; then
  echo -e "${YELLOW}Директорий '$name' в '$root' не найдено${NC}"
  exit 0
fi

echo -e "Найдено директорий '$name': ${#found_dirs[@]}"
for dir in "${found_dirs[@]}"; do
  if [ -e "$dir/.git" ]; then
    echo -e "  ${RED}[.git]${NC} $dir"
  else
    echo -e "  ${GRAY}[clean]${NC} $dir"
  fi
done
echo

if [ ${#git_dirs[@]} -eq 0 ]; then
  echo -e "${GREEN}Ни в одной нет .git — удалять нечего${NC}"
  exit 0
fi

echo -e "Будут удалены (${#git_dirs[@]}):"
for g in "${git_dirs[@]}"; do
  echo -e "  ${RED}$g${NC}"
done
echo

read -rp "Удалить? [y/N] " answer
if [[ ! "$answer" =~ ^[yY]$ ]]; then
  echo -e "${YELLOW}Отменено${NC}"
  exit 0
fi

failed=0
for g in "${git_dirs[@]}"; do
  if rm -rf -- "$g"; then
    echo -e "  ${GREEN}удалено${NC} $g"
  else
    echo -e "  ${RED}ошибка${NC} $g"
    failed=$((failed + 1))
  fi
done

[ "$failed" -eq 0 ] && echo -e "${GREEN}Готово${NC}" || { echo -e "${RED}Ошибок: $failed${NC}"; exit 1; }
