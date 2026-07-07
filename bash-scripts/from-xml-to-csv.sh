#!/bin/bash
# Выбирает xml из Downloads через fzf, вытаскивает url всех <allegato> (planimetria != 1)
# из каждого <annuncio> и сохраняет по csv на объявление в Downloads/annunci/<agency_id>/<annuncio_id>.csv

set -euo pipefail

downloads_dir="$HOME/Downloads"

xml_path=$(find "$downloads_dir" -maxdepth 1 -type f -name "*.xml" | fzf --height 40% --reverse)
[[ -z "$xml_path" ]] && echo "No file selected." && exit 1

xml_name=$(basename "$xml_path")

if [[ "$xml_name" =~ agenzia_([0-9]+) ]]; then
  agency_id="${BASH_REMATCH[1]}"
else
  echo "Не удалось извлечь id агентства из имени файла: $xml_name"
  exit 1
fi

out_dir="$downloads_dir/annunci/$agency_id"
mkdir -p "$out_dir"

python3 - "$xml_path" "$out_dir" <<'PYEOF'
import csv
import sys
import xml.etree.ElementTree as ET

xml_path, out_dir = sys.argv[1], sys.argv[2]

tree = ET.parse(xml_path)
root = tree.getroot()

for annuncio in root.findall(".//annuncio"):
    info_id_el = annuncio.find("info/id")
    if info_id_el is None or not info_id_el.text:
        continue
    annuncio_id = info_id_el.text.strip()

    rows = []
    for allegato in annuncio.findall(".//file_allegati/allegato"):
        if allegato.get("planimetria") == "1":
            continue
        file_path_el = allegato.find("file_path")
        if file_path_el is None or not file_path_el.text:
            continue
        rows.append((allegato.get("id"), file_path_el.text.strip()))

    if not rows:
        continue

    csv_path = f"{out_dir}/{annuncio_id}.csv"
    with open(csv_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["id", "url", "original"])
        for allegato_id, url in rows:
            writer.writerow([allegato_id, url, ""])

    print(f"Written {csv_path} ({len(rows)} rows)")
PYEOF

echo "Готово: $out_dir"
