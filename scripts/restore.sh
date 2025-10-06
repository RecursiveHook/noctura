#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

if [ $# -eq 0 ]; then
    echo "❌ Usage: $0 <backup-file.tar.gz>"
    echo ""
    echo "Available backups:"
    if ls -1t ./backups/noctura-*.tar.gz 2>/dev/null; then
        echo ""
        echo "Latest 5 backups:"
        ls -1t ./backups/noctura-*.tar.gz 2>/dev/null | head -5 | while read -r file; do
            SIZE=$(du -h "$file" | cut -f1)
            echo "  $file ($SIZE)"
        done
    else
        echo "  No backups found in ./backups/"
    fi
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "🔵 Noctura Restore Script"
echo "========================="
echo "📦 Restoring from: $BACKUP_FILE"
echo ""
echo "⚠️  WARNING: This will OVERWRITE all existing data!"
echo "   Current data will be backed up to ./backups/ before restore"
echo ""
read -rp "Continue? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Restore cancelled"
    exit 0
fi

echo "📦 Stopping containers..."
docker compose down || {
    echo "⚠️  Failed to stop containers, continuing anyway..."
}

if [ -d ./data ]; then
    echo "🗑️  Backing up current data..."
    SAFETY_BACKUP="./backups/pre-restore-$(date +%Y-%m-%d-%H%M%S).tar.gz"
    tar czf "$SAFETY_BACKUP" ./data .env 2>/dev/null || {
        echo "⚠️  Warning: Could not create safety backup"
    }
    echo "💾 Safety backup saved to: $SAFETY_BACKUP"
fi

echo "📂 Extracting backup..."
tar xzf "$BACKUP_FILE" || {
    echo "❌ Error: Failed to extract backup file"
    exit 1
}

echo "🚀 Starting containers..."
docker compose up -d

echo ""
echo "✅ Restore completed successfully"
if [ -n "${SAFETY_BACKUP:-}" ]; then
    echo "🛟 Safety backup saved to: $SAFETY_BACKUP"
fi
echo ""
echo "🔍 Verify your data and run: docker compose logs -f"
