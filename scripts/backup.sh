#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/noctura-$TIMESTAMP.tar.gz"

echo "🔵 Noctura Backup Script"
echo "========================"

if [ ! -f .env ]; then
    echo "❌ Error: .env file not found. Run ./scripts/setup.sh first"
    exit 1
fi

if ! docker compose ps | grep -q "noctura-couchdb"; then
    echo "⚠️  Warning: CouchDB container is not running"
fi

mkdir -p "$BACKUP_DIR"

echo "📦 Stopping containers..."
docker compose down || {
    echo "⚠️  Failed to stop containers, continuing anyway..."
}

echo "📂 Creating backup archive..."
BACKUP_ITEMS=""

if [ -d ./data ]; then
    BACKUP_ITEMS="$BACKUP_ITEMS ./data"
else
    echo "⚠️  Warning: ./data directory not found"
fi

if [ -d ./vaults ]; then
    BACKUP_ITEMS="$BACKUP_ITEMS ./vaults"
    echo "📔 Including Obsidian vaults in backup"
fi

if [ -f .env ]; then
    BACKUP_ITEMS="$BACKUP_ITEMS .env"
fi

if [ -z "$BACKUP_ITEMS" ]; then
    echo "❌ Error: No data to backup (no ./data or ./vaults directory found)"
    exit 1
fi

tar czf "$BACKUP_FILE" \
    --exclude='./backups' \
    --exclude='./.git' \
    --exclude='./node_modules' \
    $BACKUP_ITEMS 2>/dev/null || {
    tar czf "$BACKUP_FILE" --exclude='./backups' --exclude='./.git' $BACKUP_ITEMS
}
echo "✅ Backup created: $BACKUP_FILE"

echo "🚀 Restarting containers..."
docker compose up -d

echo "✅ Backup completed: $BACKUP_FILE"
echo "📊 Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"

BACKUP_COUNT=$(find "$BACKUP_DIR" -name "noctura-*.tar.gz" 2>/dev/null | wc -l)
echo "📚 Total backups: $BACKUP_COUNT"

if [ "$BACKUP_COUNT" -gt 10 ]; then
    echo "⚠️  Warning: More than 10 backups exist. Consider cleaning old backups."
    echo "    Oldest backups:"
    ls -lt "$BACKUP_DIR"/noctura-*.tar.gz | tail -n 3 | awk '{print "    " $9}'
fi
