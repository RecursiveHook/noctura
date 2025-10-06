#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔵 Noctura Setup Script"
echo "======================="

if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v docker compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose is not available"
    exit 1
fi

if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    if [ ! -f .env.example ]; then
        echo "❌ Error: .env.example not found"
        exit 1
    fi
    cp .env.example .env
    
    if command -v openssl &> /dev/null; then
        RANDOM_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/change_this_secure_password/$RANDOM_PASSWORD/" .env
        else
            sed -i "s/change_this_secure_password/$RANDOM_PASSWORD/" .env
        fi
        echo "✅ Generated secure password"
    else
        echo "⚠️  OpenSSL not found. Please edit .env and set a secure COUCHDB_PASSWORD"
    fi
else
    echo "✅ .env file already exists"
fi

source .env

if [ -z "${COUCHDB_PASSWORD:-}" ]; then
    echo "❌ Error: COUCHDB_PASSWORD is not set in .env"
    exit 1
fi

echo "📁 Creating data directories..."
mkdir -p data/couchdb data/config backups

echo "🚀 Starting services..."
docker compose up -d

echo ""
echo "⏳ Waiting for CouchDB to be ready..."
sleep 5

MAX_RETRIES=30
RETRY=0
COUCHDB_PORT=${COUCHDB_PORT:-5984}

while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -sf "http://localhost:${COUCHDB_PORT}/_up" > /dev/null 2>&1; then
        echo "✅ CouchDB is ready!"
        break
    fi
    RETRY=$((RETRY + 1))
    echo "   Waiting... ($RETRY/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "❌ CouchDB failed to start. Check logs: docker compose logs couchdb"
    exit 1
fi

echo ""
echo "✅ Noctura is ready!"
echo "===================="
echo ""
echo "🌐 CouchDB URL: http://localhost:${COUCHDB_PORT}"
echo "👤 Username: ${COUCHDB_USER:-admin}"
echo "🔑 Password: (check .env file)"
echo ""
echo "📱 Next Steps:"
echo "  1. Open Obsidian"
echo "  2. Install 'Self-hosted LiveSync' plugin"
echo "  3. Configure with the credentials above"
echo "  4. Database name: obsidian"
echo ""
echo "🔧 Management commands:"
echo "  docker compose logs -f     # View logs"
echo "  docker compose restart     # Restart services"
echo "  ./scripts/backup.sh        # Backup data"
echo "  ./scripts/health-check.sh  # Check system health"
echo ""
