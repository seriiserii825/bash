#!/usr/bin/env bash
# clipboard-cyr2lat.sh — RU→LAT for clipboard (i3wm/X11)
# Deps: xclip (или xsel), libnotify (notify-send)

set -euo pipefail

# ---- Clipboard I/O (X11)
clip_get() {
  if command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -o
  elif command -v xsel  >/dev/null 2>&1; then xsel -b
  else
    echo "Install xclip or xsel" >&2; exit 1
  fi
}
clip_set() {
  if command -v xclip >/dev/null 2>&1; then printf '%s' "$1" | xclip -selection clipboard
  elif command -v xsel  >/dev/null 2>&1; then printf '%s' "$1" | xsel -b -i
  else
    echo "Install xclip or xsel" >&2; exit 1
  fi
}

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "cyr2lat" "Copied (RU→LAT)" "$1"
}

# ---- Options
slug=false      # lowercase + sanitize to dashed slug
raw=false       # only transliterate, no sanitization
for a in "$@"; do
  case "$a" in
    --slug) slug=true ;;
    --raw)  raw=true  ;;
  esac
done

# ---- Map (RU → LAT)
rus=( "Ё" "Й" "Ц" "У" "К" "Е" "Н" "Г" "Ш" "Щ" "З" "Х" "Ъ"
      "ё" "й" "ц" "у" "к" "е" "н" "г" "ш" "щ" "з" "х" "ъ"
      "Ф" "Ы" "В" "А" "П" "Р" "О" "Л" "Д" "Ж" "Э"
      "ф" "ы" "в" "а" "п" "р" "о" "л" "д" "ж" "э"
      "Я" "Ч" "С" "М" "И" "Т" "Ь" "Б" "Ю"
      "я" "ч" "с" "м" "и" "т" "ь" "б" "ю" )
eng=( "YO" "I"  "TS" "U" "K" "E" "N" "G" "SH" "SCH" "Z" "H" "I"
      "yo" "i"  "ts" "u" "k" "e" "n" "g" "sh" "sch" "z" "h" "i"
      "F"  "I"  "V"  "A" "P" "R" "O" "L" "D" "ZH" "E"
      "f"  "i"  "v"  "a" "p" "r" "o" "l" "d" "zh" "e"
      "Ya" "CH" "S"  "M" "I" "T" "I" "B" "YU"
      "ya" "ch" "s"  "m" "i" "t" "i" "b" "yu" )

sed_escape() { printf '%s' "$1" | sed -e 's/[.[\*^$(){}+?|\\/]/\\&/g'; }

# ---- Get clipboard
text="$(clip_get)"
[ -n "${text// /}" ] || exit 0

# ---- Transliterate (sed series of replacements)
out="$text"
for i in "${!rus[@]}"; do
  from=$(sed_escape "${rus[$i]}"); to=${eng[$i]}
  out="$(printf '%s' "$out" | sed "s/${from}/${to}/g")"
done

# ---- Sanitize
if [ "$raw" = false ]; then
  # spaces, () and & -> '-', collapse multiple '-', trim leading/trailing '-'
  out="$(printf '%s' "$out" | sed -E 's/[[:space:]()&]+/-/g; s/-{2,}/-/g; s/^-+//; s/-+$//')"
fi

# ---- Slug option (lowercase ASCII only after translit)
if [ "$slug" = true ]; then
  out="$(printf '%s' "$out" | tr '[:upper:]' '[:lower:]')"
fi

clip_set "$out"
notify "$out"
printf '%s\n' "$out"
