#!/bin/bash

# Opens import-xml-crone.php in the browser to trigger a GestionaleImmobiliare
# XML import, on a domain picked interactively via fzf.
# Usage: bash bash-scripts/import-xml-crone.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_success() { echo -e "---- ${GREEN}✔ $1${NC} ----"; }
log_error()   { echo -e "---- ${RED}✘ $1${NC} ----"; }
log_info()    { echo -e "---- ${BLUE}ℹ $1${NC} ----"; }

command -v fzf >/dev/null 2>&1 || { log_error "fzf not found."; exit 1; }

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/export-xml-env.sh"
if [ ! -f "$ENV_FILE" ]; then
  log_error "Missing ${ENV_FILE}. Decrypt export-xml-env.sh.gpg first (see .gpgrc)."
  exit 1
fi
source "$ENV_FILE"

IMPORT_PATH="/wp-content/themes/bs-gardalive/import/import-xml-crone.php"
BROWSER="${BROWSER:-google-chrome-stable}"

CHOICE=$(printf '%s\n' "${GI_IMPORT_CRONE_DOMAINS[@]}" | cut -d'|' -f1 | fzf --height=20% --reverse --prompt='🌐 domain> ') || exit 0
[ -z "$CHOICE" ] && exit 0

DOMAIN=""
for ENTRY in "${GI_IMPORT_CRONE_DOMAINS[@]}"; do
  LABEL="${ENTRY%%|*}"
  if [ "$LABEL" = "$CHOICE" ]; then
    DOMAIN="${ENTRY#*|}"
    break
  fi
done

if [ -z "$DOMAIN" ]; then
  log_error "Could not resolve domain for: ${CHOICE}"
  exit 1
fi

URL="${DOMAIN}${IMPORT_PATH}?secret=${GI_IMPORT_CRONE_SECRET}"

log_info "Opening: ${URL}"
"$BROWSER" "$URL" &>/dev/null &
log_success "Launched: ${CHOICE}"
