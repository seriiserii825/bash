#!/bin/bash



# Находим все .vue файлы в текущей папке и подпапках
# и помещаем их в массив
# mapfile -t vue_files < <(find . -type f -name "*.vue")


# Спрашиваем, где искать
echo "Где искать .vue файлы?"
echo "Enter  — текущая папка"
echo "f      — выбрать папку через fzf"
read -r -p "> " SEARCH_CHOICE

SEARCH_DIR="."

if [[ "$SEARCH_CHOICE" == "f" || "$SEARCH_CHOICE" == "F" ]]; then
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf не установлен"
    exit 1
  fi

  SEARCH_DIR=$(find . -type d \
    -not -path "*/node_modules/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    | fzf)

  [ -z "$SEARCH_DIR" ] && exit 0
fi
mapfile -t vue_files < <(find "$SEARCH_DIR" -type f -name "*.vue")

# Проверяем, найдены ли файлы
if [ ${#vue_files[@]} -eq 0 ]; then
  echo "${tmagenta}Файлы .vue не найдены в текущей директории${treset}"
  exit 0
fi

# Выводим количество найденных файлов
echo "${tblue}Найдено файлов .vue: ${#vue_files[@]}${treset}"
  echo "================================"

# Выводим список файлов
for i in "${!vue_files[@]}"; do
  echo "$((i+1)). ${vue_files[$i]}"
done

echo ""
echo "================================"
# Спрашиваем пользователя, хочет ли он искать использование компонентов
read -p "${tblue}Хотите найти, где используются эти компоненты? (y/n): ${treset}" answer

if [[ "$answer" != "y" && "$answer" != "Y" && "$answer" != "д" && "$answer" != "Д" ]]; then
  echo "${tmagenta}Поиск использования компонентов отменен.${treset}"
  exit 0
fi


echo ""
echo "${tblue}Начинаем поиск использования компонентов...${treset}"
echo "================================"

# Проходим по каждому .vue файлу
for vue_file in "${vue_files[@]}"; do
  # Получаем имя файла без пути и расширения
  filename=$(basename "$vue_file" .vue)

    # Ищем использование компонента в других файлах
    # Поиск по имени компонента (может быть в разных форматах: PascalCase, kebab-case)
    # Ищем в .vue, .js, .ts файлах
    matches=$(grep -r -l --include="*.vue" \
      --exclude-dir=node_modules \
      --exclude-dir=dist \
      --exclude-dir=build \
      -E "$filename|${filename//[A-Z]/-\L&}" . 2>/dev/null | grep -v "^$vue_file$")

    if [ -n "$matches" ]; then
      # Подсчитываем количество файлов
      match_count=$(echo "$matches" | wc -l)

  # Показываем только если используется больше чем в 1 файле
  if [ "$match_count" -gt 1 ]; then
    echo ""
    echo "${tgreen}Компонент: $filename (файл: $vue_file)${treset}"
    echo "---"
    echo "${tgreen}  ✓ Используется в следующих файлах:${treset}"
    echo "$matches" | while read -r match; do
    echo "    - $match"
  done
  fi
    fi
  done

  echo ""
  echo "================================"
  echo "${tgreen}Поиск завершен!${treset}"
