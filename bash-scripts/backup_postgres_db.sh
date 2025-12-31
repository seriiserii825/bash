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
BACKUP_DIR="./backups"
RETENTION_DAYS=7

# Создать папку если не существует
mkdir -p $BACKUP_DIR

# Имя файла с датой
BACKUP_FILE="$BACKUP_DIR/backup_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql.gz"

# Создать бэкап
echo "Creating backup of database: $DB_NAME"
echo "Container: $CONTAINER_NAME"
docker exec $CONTAINER_NAME pg_dump -U $DB_USER -d $DB_NAME | gzip > $BACKUP_FILE

# Проверить успешность
if [ $? -eq 0 ]; then
    echo "✅ Backup successful: $BACKUP_FILE"
    echo "Size: $(du -h $BACKUP_FILE | cut -f1)"
    
    # Удалить старые бэкапы
    find $BACKUP_DIR -name "backup_${DB_NAME}_*.sql.gz" -mtime +$RETENTION_DAYS -delete
    echo "Old backups cleaned up (older than $RETENTION_DAYS days)"
else
    echo "❌ Backup failed!"
    exit 1
fi
