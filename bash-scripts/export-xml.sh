#!/bin/bash

# GestionaleImmobiliare XML feed manager: downloads all agency feeds, then
# extracts attachment URLs from every downloaded XML into per-listing CSV files.
# Usage: bash bash-scripts/export-xml.sh
# Single linear flow, no menu: download all agencies -> extract CSV for each XML.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_success() { echo -e "---- ${GREEN}✔ $1${NC} ----"; }
log_error()   { echo -e "---- ${RED}✘ $1${NC} ----"; }
log_info()    { echo -e "---- ${BLUE}ℹ $1${NC} ----"; }

if ! command -v python3 &> /dev/null; then
  log_error "python3 not found (required for CSV extraction)."
  exit 1
fi

DOWNLOAD_DIR="$HOME/Downloads"
mkdir -p "$DOWNLOAD_DIR"

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/export-xml-env.sh"
if [ ! -f "$ENV_FILE" ]; then
  log_error "Missing ${ENV_FILE}. Decrypt export-xml-env.sh.gpg first (see .gpgrc)."
  exit 1
fi
source "$ENV_FILE"

declare -a AGENCIES=()
for ENTRY in "${GI_AGENCIES[@]}"; do
  IFS='|' read -r LABEL AGENZIA_ID PUBLIC_KEY <<<"$ENTRY"
  AGENCIES+=("${LABEL}|https://pannello.gestionaleimmobiliare.it/export_xml_annunci.html?agenzia_id=${AGENZIA_ID}&geo_id=1&agente=1&latlng=1&abstract=1&i18n=1&etichette=1&video=1&public_key=${PUBLIC_KEY}")
done

# Filename pattern produced by the download step
XML_GLOB="export_gi_agenzia_*.xml"

download_all() {
  local SUCCESS=0
  local ERROR=0

  for ENTRY in "${AGENCIES[@]}"; do
    local LABEL="${ENTRY%%|*}"
    local URL="${ENTRY#*|}"

    log_info "Downloading: ${LABEL}"

    local HEADERS_FILE BODY_FILE HTTP_CODE CURL_EXIT ARCHIVE
    HEADERS_FILE=$(mktemp)
    BODY_FILE=$(mktemp)

    HTTP_CODE=$(curl -sSL -w '%{http_code}' -D "$HEADERS_FILE" -o "$BODY_FILE" "$URL")
    CURL_EXIT=$?

    if [ $CURL_EXIT -ne 0 ] || [ "$HTTP_CODE" != "200" ]; then
      log_error "Download failed (${LABEL}), http_code=${HTTP_CODE}"
      rm -f "$HEADERS_FILE" "$BODY_FILE"
      ERROR=$((ERROR + 1))
      continue
    fi

    ARCHIVE=$(grep -i '^content-disposition:' "$HEADERS_FILE" | tail -1 | sed -E 's/.*filename=([^;[:space:]]+).*/\1/' | tr -d '\r"')
    rm -f "$HEADERS_FILE"

    if [ -z "$ARCHIVE" ]; then
      ARCHIVE="export_$(echo "$LABEL" | tr ' ' '_').tar.gz"
    fi

    mv "$BODY_FILE" "$DOWNLOAD_DIR/$ARCHIVE"

    log_info "Extracting: ${ARCHIVE}"
    if tar -xzf "$DOWNLOAD_DIR/$ARCHIVE" -C "$DOWNLOAD_DIR"; then
      rm -f "$DOWNLOAD_DIR/$ARCHIVE"
      log_success "Completed: ${LABEL}"
      SUCCESS=$((SUCCESS + 1))
    else
      log_error "Extraction failed: ${LABEL}"
      ERROR=$((ERROR + 1))
    fi
  done

  echo ""
  log_info "Download done: ${SUCCESS} succeeded, ${ERROR} failed"
}

# Extracts attachment URLs (planimetria != 1) from every downloaded XML into
# Downloads/annunci/<agency_id>/<annuncio_id>.csv
extract_all_csv() {
  local XML_FILES=()
  while IFS= read -r -d '' FILE; do
    XML_FILES+=("$FILE")
  done < <(find "$DOWNLOAD_DIR" -maxdepth 1 -name "$XML_GLOB" -print0)

  if [ ${#XML_FILES[@]} -eq 0 ]; then
    log_error "No XML files found in ${DOWNLOAD_DIR}."
    return
  fi

  for XML_PATH in "${XML_FILES[@]}"; do
    local XML_NAME AGENCY_ID OUT_DIR
    XML_NAME=$(basename "$XML_PATH")

    if [[ "$XML_NAME" =~ agenzia_([0-9]+) ]]; then
      AGENCY_ID="${BASH_REMATCH[1]}"
    else
      log_error "Could not extract agency id from filename: ${XML_NAME}"
      continue
    fi

    OUT_DIR="$DOWNLOAD_DIR/annunci/$AGENCY_ID"
    mkdir -p "$OUT_DIR"

    log_info "Extracting CSV: ${XML_NAME}"
    python3 - "$XML_PATH" "$OUT_DIR" <<'PYEOF'
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
    log_success "CSV done: ${XML_NAME}"
  done
}

log_info "Agenzie configurate"
printf "%-25s %s\n" "Nome" "ID"
for ENTRY in "${AGENCIES[@]}"; do
  LABEL="${ENTRY%%|*}"
  URL="${ENTRY#*|}"
  AGENZIA_ID=$(echo "$URL" | grep -oE 'agenzia_id=[0-9]+' | cut -d= -f2)
  printf "%-25s %s\n" "$LABEL" "$AGENZIA_ID"
done
echo ""

read -r -p "Procedere con l'export? [y/N] " EXPORT_ANSWER
if [[ ! "$EXPORT_ANSWER" =~ ^[Yy]$ ]]; then
  log_info "Export annullato."
  exit 0
fi

read -r -p "Convertire gli XML scaricati in CSV? [y/N] " CONVERT_ANSWER

download_all

if [[ "$CONVERT_ANSWER" =~ ^[Yy]$ ]]; then
  extract_all_csv
else
  log_info "Conversione CSV saltata."
fi
