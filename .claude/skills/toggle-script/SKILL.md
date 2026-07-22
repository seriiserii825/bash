---
name: toggle-script
description: Use when creating a new toggle_*.sh script in bash-scripts/ that comments/uncomments a line in a file (WP constants, .gitignore entries, config flags, etc). Standardizes colors, line detection, indentation-preserving sed toggle, and confirmation prompt.
---

# toggle-script

Стандартный шаблон для новых `bash-scripts/toggle_*.sh` — скриптов, которые
комментируют/раскомментируют одну строку в файле (WP-константа, запись в
`.gitignore`, scss-правило и т.п.). Основан на разборе существующих
`toggle_dist_in_gitignore.sh`, `toggle_body_after.sh`, `toggle-neovim.sh`,
`toggle-macros.sh` и `toggle_wp_http_block_external.sh` — последний считается
эталоном (самый полный и переносимый).

## Именование и права

- Файл: `bash-scripts/toggle_<what>.sh`.
- После создания: `chmod +x bash-scripts/toggle_<what>.sh`.

## Шаблон

```bash
#!/usr/bin/env bash
# <краткое описание, что именно тоглится и где>

set -e

# Setup colors for output — самодостаточный блок, не полагаться на внешние
# переменные $tmagenta/$tgreen (в отличие от toggle_body_after.sh, где они
# нигде не определяются).
tblue=$(tput setaf 4)
tgreen=$(tput setaf 2)
tmagenta=$(tput setaf 5)
treset=$(tput sgr0)

# Precondition-проверки (нужный файл/контекст существует)
if [ ! -f "$FILE" ]; then
  echo "${tmagenta}⚠️ ...${treset}"
  exit 1
fi

TARGET="..."

# Поиск целевой строки: номер + содержимое одним grep, а не парой regex
# (commented/uncommented), как в старых скриптах — надёжнее и проще.
MATCH=$(grep -n "$TARGET" "$FILE" | head -n1)

if [ -z "$MATCH" ]; then
  echo "${tmagenta}⚠️ ${TARGET} not found in ${FILE}${treset}"
  exit 1
fi

LINE_NUM=$(echo "$MATCH" | cut -d: -f1)
LINE_CONTENT=$(echo "$MATCH" | cut -d: -f2-)

# Определение состояния по маркеру комментария в начале строки
# (// для php/js, # для shell/yaml, /* ... */ для css/scss — по типу файла)
if echo "$LINE_CONTENT" | grep -Eq '^[[:space:]]*//'; then
  STATUS="commented"
  echo "${tmagenta}🔵 ${TARGET} is currently commented:${treset}"
else
  STATUS="active"
  echo "${tgreen}🟢 ${TARGET} is currently active:${treset}"
fi

echo "${LINE_CONTENT}"

# Подтверждение перед изменением — обязательно, не пропускать
read -rp "${tblue}Do you want to toggle it? (y/N): ${treset}" answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
  if [ "$STATUS" == "commented" ]; then
    # Toggle через sed с сохранением исходного отступа (backreference \1)
    sed -i "${LINE_NUM}s#^\([[:space:]]*\)//[[:space:]]*#\1#" "$FILE"
    echo "${tgreen}🟢 Uncommented ${TARGET}${treset}"
  else
    sed -i "${LINE_NUM}s#^\([[:space:]]*\)#\1// #" "$FILE"
    echo "${tmagenta}🔵 Commented ${TARGET}${treset}"
  fi
else
  echo "Skipped"
fi
```

Ключевые правила:

1. **Цвета** — только через `tput`, определять их в самом скрипте.
2. **`set -e`** в начале.
3. **Поиск строки** — `grep -n | head -n1` + `cut -d: -f1` / `cut -d: -f2-`,
   не собирать вручную отдельные regex под "закомментировано" и
   "раскомментировано".
4. **sed с backreference** для отступа — никогда не заменять строку целиком
   фиксированным текстом (кроме блочных `/* ... */` комментариев, где
   допустим фиксированный отступ, как в `toggle_body_after.sh`).
5. **Подтверждение обязательно** (`read -rp ... (y/N)` + `[[ $answer =~ ^[Yy]$ ]]`).
6. **Эмодзи-статусы**: 🟢 активно, 🔵 закомментировано, ⚠️ ошибка/предупреждение.

## Рецепт: поиск wp-config.php из темы WordPress

Если скрипт тоглит константу в `wp-config.php`, а запускается из папки темы:

```bash
# Тема WordPress: есть functions.php и style.css в текущей директории
if [ ! -f "functions.php" ] || [ ! -f "style.css" ]; then
  echo "${tmagenta}⚠️ This is not a WordPress theme folder.${treset}"
  exit 1
fi

# В структуре Local by Flywheel (.../app/public/wp-content/themes/<theme>)
# wp-config.php лежит на 3 уровня выше — проверено на реальном сайте
# lc-gardalive. Не 4 (первая версия toggle_wp_http_block_external.sh
# ошибочно использовала 4 уровня).
WP_CONFIG="../../../wp-config.php"
```

## Множественный выбор

Если скрипту нужно выбрать одну из нескольких целей — использовать
`fzf_multiselect` из `bash-scripts/libs/fzf-multiselect.sh` (см. правило в
`CLAUDE.md`), а не `fzf -m`/`fzf --multi` напрямую.
