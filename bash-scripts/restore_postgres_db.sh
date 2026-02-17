#!/bin/bash
set -euo pipefail

# Load .env
if [ -f .env ]; then
  set -a
  source .env
  set +a
else
  echo "Error: .env file not found!"
  exit 1
fi

# Required vars from .env
: "${DB_USERNAME:?DB_USERNAME is not set in .env}"
: "${DB_NAME:?DB_NAME is not set in .env}"

DB_USER="$DB_USERNAME"
DB_NAME="$DB_NAME"

# Find postgres container (adjust name filter if needed)
CONTAINER_NAME="$(docker ps --format '{{.Names}}' | grep -i postgres | head -n 1 || true)"

if [ -z "$CONTAINER_NAME" ]; then
  echo "Error: Postgres container not found (docker ps | grep postgres)."
  exit 1
fi

# fzf check
if ! command -v fzf >/dev/null 2>&1; then
  echo "Error: fzf is not installed!"
  echo "Install on Arch: sudo pacman -S fzf"
  exit 1
fi

# backups dir check
if [ ! -d "./backups" ]; then
  echo "Error: ./backups directory not found!"
  exit 1
fi

# if ! ls ./backups/backup_*.sql.gz >/dev/null 2>&1; then
#   echo "Error: No backup files found in ./backups/ (backup_*.sql.gz)"
#   exit 1
# fi

echo "Select a backup file to restore:"
BACKUP_FILE="$(ls -t ./backups/*.sql.gz | fzf \
  --height=40% \
  --reverse \
  --border \
  --prompt="Select backup: " \
  --preview="echo 'File: {}'; echo ''; ls -lh {}; echo ''; echo 'Created:'; stat -c '%y' {} 2>/dev/null || stat -f '%Sm' {}" \
  --preview-window=right:50%)"

if [ -z "$BACKUP_FILE" ]; then
  echo "No backup selected. Exiting."
  exit 0
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo
echo "Database:  $DB_NAME"
echo "Container: $CONTAINER_NAME"
echo "Backup:    $BACKUP_FILE"
echo
echo "⚠️  WARNING: This will DROP and recreate the database!"
read -p "Continue? (yes/no): " -r
echo

if [[ "$REPLY" != "yes" ]]; then
  echo "Restore cancelled."
  exit 0
fi

echo "Starting restore process..."

echo "Disconnecting active connections..."
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();"

echo "Dropping database..."
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c \
  "DROP DATABASE IF EXISTS \"$DB_NAME\";"

echo "Creating database..."
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c \
  "CREATE DATABASE \"$DB_NAME\";"

echo "Restoring data..."
gunzip -c "$BACKUP_FILE" | docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"

echo "✅ Restore completed successfully!"
