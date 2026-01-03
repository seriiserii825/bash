#!/bin/bash
# Загрузить переменные из .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found!"
    exit 1
fi

# Настройки из .env
CONTAINER_NAME=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -n 1)
DB_USER="${DB_USERNAME}"
DB_NAME="${DB_NAME}"

# Check if fzf is installed
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed!"
    echo "Install it with: sudo apt install fzf (Debian/Ubuntu) or brew install fzf (macOS)"
    exit 1
fi

# Check if backups directory exists
if [ ! -d "./backups" ]; then
    echo "Error: ./backups directory not found!"
    exit 1
fi

# Check if there are any backups
if [ -z "$(ls -A ./backups/backup_*.sql.gz 2>/dev/null)" ]; then
    echo "Error: No backup files found in ./backups/"
    exit 1
fi

# Use fzf to select backup file
echo "Select a backup file to restore:"
BACKUP_FILE=$(ls -t ./backups/backup_*.sql.gz | fzf \
    --height=40% \
    --reverse \
    --border \
    --prompt="Select backup: " \
    --preview="echo 'File: {}'; echo ''; ls -lh {}; echo ''; echo 'Created:'; stat -c '%y' {} 2>/dev/null || stat -f '%Sm' {}" \
    --preview-window=right:50%)

# Check if user cancelled selection
if [ -z "$BACKUP_FILE" ]; then
    echo "No backup selected. Exiting."
    exit 0
fi

# Validate selected file
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo ""
echo "Database: $DB_NAME"
echo "Container: $CONTAINER_NAME"
echo "Backup file: $BACKUP_FILE"
echo ""
echo "⚠️  WARNING: This will DROP and recreate the database!"
echo "All current data will be lost!"
read -p "Continue? (yes/no): " -r
echo

if [[ $REPLY == "yes" ]]; then
    echo "Starting restore process..."
    
    # Отключить все подключения
    echo "Disconnecting active connections..."
    docker exec $CONTAINER_NAME psql -U $DB_USER -d postgres -c \
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();"
    
    # Пересоздать базу
    echo "Dropping database..."
    docker exec $CONTAINER_NAME psql -U $DB_USER -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
    
    echo "Creating database..."
    docker exec $CONTAINER_NAME psql -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"
    
    # Восстановить
    echo "Restoring data..."
    if [[ $BACKUP_FILE == *.gz ]]; then
        gunzip < $BACKUP_FILE | docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME
    else
        docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME < $BACKUP_FILE
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ Restore completed successfully!"
    else
        echo "❌ Restore failed!"
        exit 1
    fi
else
    echo "Restore cancelled."
    exit 0
fi
