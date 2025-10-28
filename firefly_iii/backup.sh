#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "📦 Starting backup..."

# Load environment variables
source .env

# Backup database (logical dump - no downtime)
echo "  → Backing up database..."
docker exec firefly_iii_db mysqldump \
  -u"${MYSQL_USER}" \
  -p"${MYSQL_PASSWORD}" \
  "${MYSQL_DATABASE}" \
  --single-transaction \
  --quick \
  --lock-tables=false \
  > "$BACKUP_DIR/firefly-db-$DATE.sql"

# Backup uploads using Docker (avoids permission issues)
echo "  → Backing up uploads..."
docker run --rm \
  -v "$(pwd)/data/upload:/source:ro" \
  -v "$(pwd)/backups:/backup" \
  alpine:latest \
  tar -czf "/backup/firefly-uploads-$DATE.tar.gz" -C /source .

# Optional: Create combined backup
echo "  → Creating combined backup..."
tar -czf "$BACKUP_DIR/firefly-complete-$DATE.tar.gz" \
  "$BACKUP_DIR/firefly-db-$DATE.sql" \
  "$BACKUP_DIR/firefly-uploads-$DATE.tar.gz"

# Cleanup individual files (keep only combined)
rm "$BACKUP_DIR/firefly-db-$DATE.sql"
rm "$BACKUP_DIR/firefly-uploads-$DATE.tar.gz"

# Keep only last 7 backups
ls -t "$BACKUP_DIR"/firefly-complete-*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f

echo "✅ Backup completed: $BACKUP_DIR/firefly-complete-$DATE.tar.gz"
echo "📊 Backup size: $(du -h "$BACKUP_DIR/firefly-complete-$DATE.tar.gz" | cut -f1)"
