#!/usr/bin/env bash
# Берёт URL картинки с watermark из буфера обмена и подбирает URL оригинала:
# порядковый номер оригинала отличается от номера watermark-версии и не вычисляется
# детерминированно, поэтому перебираем 000-999 параллельными батчами HEAD-запросов.
set -euo pipefail

WORKERS=20
HEAD_TIMEOUT=8
MAX_RETRIES=2
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"

clip_get() {
  if command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -o
  elif command -v xsel  >/dev/null 2>&1; then xsel -b
  else echo "Install xclip or xsel" >&2; exit 1; fi
}
clip_set() {
  if command -v xclip >/dev/null 2>&1; then printf '%s' "$1" | xclip -selection clipboard
  elif command -v xsel  >/dev/null 2>&1; then printf '%s' "$1" | xsel -b -i
  else echo "Install xclip or xsel" >&2; exit 1; fi
}
notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a "extract-original-image-url" "$1" "$2"
}

# HEAD с ретраем: повторяем только 429/503/таймаут(000), не 403/404
head_status() {
  local url="$1" attempt=0 status
  while :; do
    status=$(curl -s -o /dev/null -w '%{http_code}' --head \
      --max-time "$HEAD_TIMEOUT" -A "$USER_AGENT" "$url" 2>/dev/null) || status="000"
    if [[ "$status" == "429" || "$status" == "503" || "$status" == "000" ]] && (( attempt < MAX_RETRIES )); then
      attempt=$((attempt + 1))
      continue
    fi
    break
  done
  printf '%s' "$status"
}

url="$(clip_get)"
[ -n "${url// /}" ] || { echo "❌ Буфер обмена пуст" >&2; exit 1; }

base="${url%%[?#]*}"
dir="${base%/*}/"
filename="${base##*/}"

if [[ ! "$filename" =~ ^([0-9]{3}__)(.+)_wmk_[0-9]+\.([[:alnum:]]+)$ ]]; then
  echo "$url"
  clip_set "$url"
  notify "ℹ️ Уже оригинал (шаблон не совпал)" "$url"
  exit 0
fi

nome_base="${BASH_REMATCH[2]}"
ext="${BASH_REMATCH[3]}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

found_url=""
for ((batch_start = 0; batch_start < 1000; batch_start += WORKERS)); do
  batch_end=$((batch_start + WORKERS - 1))
  (( batch_end > 999 )) && batch_end=999

  declare -A pids=()
  for ((n = batch_start; n <= batch_end; n++)); do
    progressivo=$(printf '%03d' "$n")
    candidate="${dir}${progressivo}__${nome_base}.${ext}"
    outfile="$tmpdir/$n.status"
    urlfile="$tmpdir/$n.url"
    printf '%s' "$candidate" > "$urlfile"
    (
      status="$(head_status "$candidate")"
      printf '%s' "$status" > "$outfile"
    ) &
    pids[$n]=$!
  done

  # ждём первый 200 либо завершение всего батча, затем best-effort убиваем остальных
  while :; do
    all_done=true
    for n in "${!pids[@]}"; do
      if [[ -f "$tmpdir/$n.status" ]]; then
        if [[ "$(cat "$tmpdir/$n.status")" == "200" ]]; then
          found_url="$(cat "$tmpdir/$n.url")"
          break 2
        fi
      elif kill -0 "${pids[$n]}" 2>/dev/null; then
        all_done=false
      fi
    done
    $all_done && break
    sleep 0.05
  done

  for n in "${!pids[@]}"; do
    kill "${pids[$n]}" 2>/dev/null || true
  done
  wait 2>/dev/null || true
  unset pids

  [[ -n "$found_url" ]] && break
done

if [[ -n "$found_url" ]]; then
  echo "$found_url"
  clip_set "$found_url"
  notify "✅ Оригинал найден" "$found_url"
else
  echo "⚠️ Оригинал не найден, fallback на watermark-URL: $url" >&2
  clip_set "$url"
  notify "⚠️ Оригинал не найден (fallback)" "$url"
fi
