#!/bin/bash
# GestionaleImmobiliare agency credentials for export-xml.sh.
# Format per entry: Label|agenzia_id|public_key
# This file is encrypted at rest (see .gpgrc) — never commit it unencrypted.

declare -a GI_AGENCIES=(
  "Salò|5726|2a556bc1dbbaf89a"
  "Manerba|9070|10b9c86a3b9bed18"
  "Toscolano Maderno|5730|875862a3994181da"
  "Sirmione|5727|120603d438db2a22"
)

# Domains for import-xml-crone.sh. Format per entry: Label|base_url (no trailing slash)
declare -a GI_IMPORT_CRONE_DOMAINS=(
  "Local (lc-gardalive.local)|http://lc-gardalive.local"
  "Production (gardalive.altuofianco.com)|https://gardalive.altuofianco.com"
)

# Shared secret for import-xml-crone.php, used by import-xml-crone.sh
GI_IMPORT_CRONE_SECRET="x7k2mQr9pZ"
