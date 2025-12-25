#!/bin/bash

packages=()
dev_mode=false

show_selected() {
  if [ ${#packages[@]} -eq 0 ]; then
    echo "📦 Выбрано: (пусто)"
  else
    echo "📦 Выбрано: ${packages[*]}"
  fi
  if [ "$dev_mode" = true ]; then
    echo "📌 Режим: devDependencies"
  else
    echo "📌 Режим: dependencies"
  fi
  echo ""
}

search_package() {
  local query=$1
  local result=$(npm search --json "$query" 2>/dev/null | jq -r '.[] | "\(.name) | \(.description)"')
  
  if [ -z "$result" ]; then
    echo "Ничего не найдено"
    return 1
  fi
  
  local selected_list="(пусто)"
  if [ ${#packages[@]} -gt 0 ]; then
    selected_list="${packages[*]}"
  fi
  
  local mode_label="dependencies"
  if [ "$dev_mode" = true ]; then
    mode_label="devDependencies"
  fi
  
  local menu=$(echo -e "🔍 ИСКАТЬ ЕЩЁ\n✅ УСТАНОВИТЬ ВЫБРАННЫЕ\n❌ ОЧИСТИТЬ ВЫБОР\n---\n$result")
  
  local selected=$(echo "$menu" | fzf \
    --height=50% \
    --reverse \
    --header="📦 Выбрано: $selected_list | 📌 $mode_label" \
    --header-first)
  
  case "$selected" in
    "🔍 ИСКАТЬ ЕЩЁ")
      return 2
      ;;
    "✅ УСТАНОВИТЬ ВЫБРАННЫЕ")
      return 3
      ;;
    "❌ ОЧИСТИТЬ ВЫБОР")
      packages=()
      echo "Выбор очищен"
      return 2
      ;;
    "---")
      return 1
      ;;
    "")
      return 3
      ;;
    *)
      local name=$(echo "$selected" | cut -d'|' -f1 | xargs)
      packages+=("$name")
      clear
      show_selected
      echo "✓ Добавлен: $name"
      return 2
      ;;
  esac
}

clear
read -p "Установить как devDependencies? [y/N]: " dev_choice
if [[ "$dev_choice" =~ ^[Yy]$ ]]; then
  dev_mode=true
fi

clear
show_selected

while true; do
  read -p "Поиск пакета (Enter для установки): " query
  
  if [ -z "$query" ]; then
    break
  fi
  
  while true; do
    search_package "$query"
    status=$?
    
    if [ $status -eq 2 ]; then
      read -p "Новый поиск: " query
      if [ -z "$query" ]; then
        break
      fi
    elif [ $status -eq 3 ]; then
      break 2
    else
      break
    fi
  done
done

echo ""
if [ ${#packages[@]} -eq 0 ]; then
  echo "Нет пакетов для установки"
  exit 0
fi

echo "🚀 Установка: ${packages[*]}"
echo ""

if [ "$dev_mode" = true ]; then
  bun add -d "${packages[@]}"
else
  bun add "${packages[@]}"
fi
