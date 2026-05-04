#!/bin/bash

OUTPUT_DIR="cyr-to-lat"

rus=("Ё" "Й" "Ц" "У" "К" "Е" "Н" "Г" "Ш" "Щ" "З" "Х" "Ъ" "ё" "й" "ц" "у" "к" "е" "н" "г" "ш" "щ" "з" "х" "ъ" "Ф" "Ы" "В" "А" "П" "Р" "О" "Л" "Д" "Ж" "Э" "ф" "ы" "в" "а" "п" "р" "о" "л" "д" "ж" "э" "Я" "Ч" "С" "М" "И" "Т" "Ь" "Б" "Ю" "я" "ч" "с" "м" "и" "т" "ь" "б" "ю")
eng=("YO" "I" "TS" "U" "K" "E" "N" "G" "SH" "SCH" "Z" "H" "I" "yo" "i" "ts" "u" "k" "e" "n" "g" "sh" "sch" "z" "h" "i" "F" "I" "V" "A" "P" "R" "O" "L" "D" "ZH" "E" "f" "i" "v" "a" "p" "r" "o" "l" "d" "zh" "e" "Ya" "CH" "S" "M" "I" "T" "I" "B" "YU" "ya" "ch" "s" "m" "i" "t" "i" "b" "yu")

function has_cyrillic {
  local file="$1"
  for rus_item in "${rus[@]}"; do
    [[ "$file" == *"$rus_item"* ]] && return 0
  done
  return 1
}

function compute_final_name {
  local file="${1//[ ()&]/-}"
  local file_extension="${file##*.}"
  local translated=""
  for (( i=0; i<${#file}; i++ )); do
    local letter="${file:$i:1}"
    if [[ "$letter" == "-" ]]; then
      translated+="-"
    else
      for (( j=0; j<${#rus[@]}; j++ )); do
        if [[ "$letter" == "${rus[j]}" ]]; then
          translated+="${eng[j]}"
          break
        fi
      done
    fi
  done
  echo "$translated.$file_extension"
}

# Collect files with Cyrillic
cyrillic_files=()
for f in *; do
  [[ -f "$f" ]] && has_cyrillic "$f" && cyrillic_files+=("$f")
done

if [[ ${#cyrillic_files[@]} -eq 0 ]]; then
  echo "Файлов с кириллицей не найдено."
  exit 0
fi

echo "Превью изменений (копии появятся в ./$OUTPUT_DIR/):"
echo "=================================================="
declare -A name_map
for f in "${cyrillic_files[@]}"; do
  new=$(compute_final_name "$f")
  printf "  %-40s →  %s/%s\n" "$f" "$OUTPUT_DIR" "$new"
  name_map["$f"]="$new"
done
echo ""

read -p "Запустить? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Отменено."
  exit 0
fi

mkdir -p "$OUTPUT_DIR"

echo ""
echo "Результат:"
echo "=================================================="
for orig in "${!name_map[@]}"; do
  new="${name_map[$orig]}"
  dest="$OUTPUT_DIR/$new"
  if [[ -f "$dest" ]]; then
    echo "  ОШИБКА: '$dest' уже существует, пропуск" >&2
    continue
  fi
  cp "$orig" "$dest"
  printf "  %-40s →  %s/%s\n" "$orig" "$OUTPUT_DIR" "$new"
done
