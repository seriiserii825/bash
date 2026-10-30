#!/bin/bash
# Creates air.toml in the current folder if it does not already exist.
# Usage: bash bash-scripts/air-toml.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_success() { echo -e "---- ${GREEN}✔ $1${NC} ----"; }
log_error()   { echo -e "---- ${RED}✘ $1${NC} ----"; }

FILE="air.toml"

if [ -f "$FILE" ]; then
  log_error "$FILE already exists, skipping."
  exit 0
fi

cat > "$FILE" <<'EOF'
[build]
cmd = "go build -o ./tmp/main ."
entrypoint = "./tmp/main"
EOF

log_success "Created $FILE"
