#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🗄️  Noctura Database Initialization"
echo "===================================="
echo ""

if [ ! -f .env ]; then
    echo "❌ Error: .env not found. Run ./scripts/setup.sh first"
    exit 1
fi

# shellcheck source=../.env
source .env

COUCHDB_PORT=${COUCHDB_PORT:-5984}
COUCHDB_USER=${COUCHDB_USER:-admin}
COUCHDB_PASSWORD=${COUCHDB_PASSWORD}
DB_NAME=${1:-obsidian}

# Use COUCHDB_URL and CURL_OPTS from environment if set (e.g., in CI)
# Otherwise, determine based on whether Caddy is being used
if [ -z "${COUCHDB_URL:-}" ]; then
    if docker compose ps caddy 2>/dev/null | grep -q "Up"; then
        COUCHDB_URL="https://localhost/couchdb"
        CURL_OPTS="-k"
    else
        COUCHDB_URL="http://localhost:${COUCHDB_PORT}"
        CURL_OPTS=""
    fi
fi

CURL_OPTS=${CURL_OPTS:-""}

echo "Initializing database: $DB_NAME"
echo "Using endpoint: $COUCHDB_URL"
echo ""

if ! curl -sf $CURL_OPTS "${COUCHDB_URL}/_up" > /dev/null 2>&1; then
    echo "❌ Error: CouchDB is not running"
    echo "   Run 'docker compose up -d' or './scripts/setup.sh'"
    exit 1
fi

echo "📋 Ensuring CouchDB system databases exist..."
curl -sf $CURL_OPTS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "${COUCHDB_URL}/_users" > /dev/null 2>&1 || echo "  _users already exists"
curl -sf $CURL_OPTS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "${COUCHDB_URL}/_replicator" > /dev/null 2>&1 || echo "  _replicator already exists"

echo "📋 Checking if database exists..."
if curl -sf $CURL_OPTS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    "${COUCHDB_URL}/${DB_NAME}" > /dev/null 2>&1; then
    echo "⚠️  Database '$DB_NAME' already exists"
    read -rp "Do you want to recreate it? This will DELETE all data! (type 'yes'): " CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        echo "🗑️  Deleting existing database..."
        curl -sf $CURL_OPTS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
            -X DELETE "${COUCHDB_URL}/${DB_NAME}" > /dev/null
        echo "✅ Database deleted"
    else
        echo "❌ Initialization cancelled"
        exit 0
    fi
fi

echo "📦 Creating database..."
RESPONSE=$(curl -s $CURL_OPTS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "${COUCHDB_URL}/${DB_NAME}")

if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✅ Database '$DB_NAME' created successfully"
else
    echo "❌ Failed to create database: $RESPONSE"
    exit 1
fi

echo ""
echo "🔧 Configuring database settings..."

echo "  • Enabling CORS..."
curl -sf $CURL_OPTS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "${COUCHDB_URL}/_node/_local/_config/httpd/enable_cors" \
    -d '"true"' > /dev/null || echo "    Warning: Could not enable CORS"

curl -sf $CURL_OPTS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "${COUCHDB_URL}/_node/_local/_config/cors/origins" \
    -d '"*"' > /dev/null || echo "    Warning: Could not set CORS origins"

curl -sf $CURL_OPTS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "${COUCHDB_URL}/_node/_local/_config/cors/credentials" \
    -d '"true"' > /dev/null || echo "    Warning: Could not set CORS credentials"

echo "  • Setting up compaction..."

curl -sf $CURL_OPTS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "${COUCHDB_URL}/${DB_NAME}/_compact" \
    -H "Content-Type: application/json" > /dev/null || echo "    Note: Compaction will run automatically"

echo ""
echo "✅ Database initialization complete!"
echo ""
echo "📱 Obsidian Configuration:"
echo "  • Remote URL: ${COUCHDB_URL}/${DB_NAME}"
echo "  • Username: ${COUCHDB_USER}"
echo "  • Password: (from .env file)"
echo "  • Database name: ${DB_NAME}"
echo ""
echo "💡 Next steps:"
echo "  1. Open Obsidian"
echo "  2. Install 'Self-hosted LiveSync' plugin"
echo "  3. Enter the configuration above"
echo "  4. Start syncing!"
echo ""
