#!/usr/bin/env bash
# Зависимости: rtmpdump, wget, bash

url="$1"
target=$(echo "$url" | cut -d'=' -f2)
xml="http://bl2.rutube.ru/${target}.xml"
s=$(wget -q -O - "$xml")
rtmp_url=$(echo "$s" | grep -oP 'rtmp.*?(?=\]\])')
link=$(echo "$rtmp_url" | cut -d'/' -f1-3)/
rest=$(echo "$rtmp_url" | cut -d'/' -f4-)
app=$(echo "$rest" | grep -oP '^.*(?=mp4:)')
playpath=$(echo "$rest" | grep -oP 'mp4:.*')
live=""
# Проверка на live-поток
[[ $app == "vod/" ]] && live="--live"

outfile="output_video0.flv"
n=0
while [[ -e "$outfile" ]]; do
  ((n++))
  outfile="output_video${n}.flv"
done

echo "Скачиваю в файл: $outfile"
rtmpdump --rtmp "$link" --app "$app" --swfUrl "http://rutube.ru/player.swf" \
  --playpath "$playpath" --flv "$outfile" $live
