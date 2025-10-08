#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

VERSION=$(cat "${PROJECT_ROOT}/VERSION" 2>/dev/null || echo "unknown")

echo "🔵 Noctura Setup Script v${VERSION}"
echo "===================================="
echo ""
    echo "🔐 IMPORTANT: Save these credentials securely!"
    echo "=============================================="
    echo "CouchDB Password: $COUCHDB_PASSWORD"
    echo "VNC Password:     $VNC_PASSWORD"
    echo "Encryption Key:   $ENCRYPTION_KEY"
    echo "=============================================="
    echo ""
    read -p "Press Enter after saving these credentials (they won't be shown again)..."
    echo ""
else
    echo "✅ .env file already exists"
fi

source .env

if [ -z "${COUCHDB_PASSWORD:-}" ]; then
    echo "❌ Error: COUCHDB_PASSWORD is not set in .env"
    exit 1
fi

if [ -z "${ENCRYPTION_KEY:-}" ]; then
    echo "❌ Error: ENCRYPTION_KEY is not set in .env"
    exit 1
fi

echo "📁 Creating data directories..."
mkdir -p data/config data/encrypted data/secrets data/logs/caddy backups vaults

echo "🔐 Initializing encryption..."
if [ ! -f "${ENCRYPTION_KEY_FILE:-./data/secrets/encryption_key}" ]; then
    echo "${ENCRYPTION_KEY}" > "${ENCRYPTION_KEY_FILE:-./data/secrets/encryption_key}"
    chmod 600 "${ENCRYPTION_KEY_FILE:-./data/secrets/encryption_key}"
    echo "✅ Encryption key saved to ${ENCRYPTION_KEY_FILE:-./data/secrets/encryption_key}"
else
    echo "✅ Encryption key already exists"
fi

echo "🚀 Starting services..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

MAX_RETRIES=30
RETRY=0
HTTPS_PORT=${HTTPS_PORT:-443}
HTTP_PORT=${HTTP_PORT:-80}
DOMAIN=${DOMAIN:-localhost}

while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -sf "http://localhost:${HTTP_PORT}" > /dev/null 2>&1; then
        echo "✅ Caddy reverse proxy is ready!"
        break
    fi
    RETRY=$((RETRY + 1))
    echo "   Waiting for services... ($RETRY/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "⚠️  Services may not be fully ready. Check logs: docker compose logs"
fi

echo ""
echo "✅ Noctura is ready!"
echo "===================="
echo ""

if [ "${ENVIRONMENT:-dev}" = "production" ]; then
    echo "🌐 Access URL: https://${DOMAIN}"
    echo "   - CouchDB: https://${DOMAIN}/couchdb"
    echo "   - Obsidian Web: https://${DOMAIN}/obsidian"
    echo "   - VNC: https://${DOMAIN}/vnc"
else
    echo "🌐 Access URLs (development mode with self-signed certs):"
    echo "   - HTTP: http://localhost:${HTTP_PORT}"
    echo "   - HTTPS: https://localhost:${HTTPS_PORT} (self-signed)"
fi

echo ""
echo "👤 CouchDB Credentials:"
echo "   Username: ${COUCHDB_USER:-admin}"
echo "   Password: (stored in .env file)"
echo "   Database: ${COUCHDB_DATABASE:-noctura}"
echo ""
echo "📱 Next Steps:"
echo "  1. Access Obsidian via the web interface"
echo "  2. Self-hosted LiveSync plugin is pre-installed"
echo "  3. Configure sync with the credentials above"
echo ""
echo "🔧 Management commands:"
echo "  docker compose logs -f     # View logs"
echo "  docker compose restart     # Restart services"
echo "  ./scripts/backup.sh        # Backup data"
echo "  ./scripts/health-check.sh  # Check system health"
echo ""
echo "🔐 Security Features:"
echo "  ✅ Database encryption at rest (gocryptfs)"
echo "  ✅ TLS/HTTPS encryption in flight"
if [ "${ENVIRONMENT:-dev}" = "production" ]; then
    echo "  ✅ Automatic SSL certificates (Let's Encrypt)"
else
    echo "  ⚠️  Using self-signed certificates (dev mode)"
fi
echo ""
