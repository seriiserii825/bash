#!/bin/bash 
rename -v 's/[\ \(\)\&]/-/g' *
rus=("Ё" "Й" "Ц" "У" "К" "Е" "Н" "Г" "Ш" "Щ" "З" "Х" "Ъ" "ё" "й" "ц" "у" "к" "е" "н" "г" "ш" "щ" "з" "х" "ъ" "Ф" "Ы" "В" "А" "П" "Р" "О" "Л" "Д" "Ж" "Э" "ф" "ы" "в" "а" "п" "р" "о" "л" "д" "ж" "э" "Я" "Ч" "С" "М" "И" "Т" "Ь" "Б" "Ю" "я" "ч" "с" "м" "и" "т" "ь" "б" "ю")
eng=("YO" "I" "TS" "U" "K" "E" "N" "G" "SH" "SCH" "Z" "H" "I" "yo" "i" "ts" "u" "k" "e" "n" "g" "sh" "sch" "z" "h" "i" "F" "I" "V" "A" "P" "R" "O" "L" "D" "ZH" "E" "f" "i" "v" "a" "p" "r" "o" "l" "d" "zh" "e" "Ya" "CH" "S" "M" "I" "T" "I" "B" "YU" "ya" "ch" "s" "m" "i" "t" "i" "b" "yu")

function transliterate {
  file=$1
  file_extension="${file##*.}"
  translated=""
  for (( i=0; i<${#file}; i++ )); do
    letter="${file:$i:1}"
    if [[ "$letter" == "-" ]]; then
      translated+="-"
    else
      for (( j=0; j<${#rus[@]}; j++ )); do
        if [[ "$letter" == "${rus[j]}" ]]; then
          translated+="${eng[j]}"
        fi
      done
    fi
  done
  result="$translated.$file_extension"
  if [[ -f "$result" ]]; then
    exit 1
  else
    mv "$file" "$result"
  fi
}

files=$(ls -aA *)
for file in $files
do
  for rus_item in "${rus[@]}"; do
    if [[ $file == *"$rus_item"* ]]; then
      transliterate $file
    fi
  done
done
