#!/bin/bash

# Загрузить переменные из .env
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "Error: .env file not found!"
    exit 1
fi

# Настройки из .env
CONTAINER_NAME=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -n 1)
DB_USER="${DB_USERNAME}"
DB_NAME="${DB_NAME}"
BACKUP_DIR="./backups"
RETENTION_DAYS=7

# Создать папку если не существует
mkdir -p $BACKUP_DIR

# Имя файла с датой
read -p "Enter backup name : " BACKUP_NAME

if [ -z "$BACKUP_NAME" ]; then
    BACKUP_NAME="backup_${DB_NAME}_$(date +%Y%m%d_%H%M%S)"
else
    BACKUP_NAME="${BACKUP_NAME}_$(date +%Y%m%d_%H%M%S)"
fi

BACKUP_NAME_SAFE=$(echo "$BACKUP_NAME" | tr ' ' '_' | tr -cd 'A-Za-z0-9_-')

BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME_SAFE}.sql.gz"

# BACKUP_FILE="$BACKUP_DIR/backup_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql.gz"

# Создать бэкап
echo "Creating backup of database: $DB_NAME"
echo "Container: $CONTAINER_NAME"
docker exec $CONTAINER_NAME pg_dump -U $DB_USER -d $DB_NAME | gzip > $BACKUP_FILE

# Проверить успешность
if [ $? -eq 0 ]; then
    echo "✅ Backup successful: $BACKUP_FILE"
    echo "Size: $(du -h $BACKUP_FILE | cut -f1)"
    
    # Удалить старые бэкапы но оставить последние 4
    ls -1t "$BACKUP_DIR"/backup_"${DB_NAME}"_*.sql.gz 2>/dev/null | tail -n +5 | xargs -r rm -f
else
    echo "❌ Backup failed!"
    exit 1
fi
