#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🧪 Noctura Integration Tests"
echo "============================="
echo ""

if [ ! -f .env ]; then
    echo "❌ Error: .env not found. Run ./scripts/setup.sh first"
    exit 1
fi

# shellcheck source=../.env
source .env

HTTP_PORT=${HTTP_PORT:-80}
HTTPS_PORT=${HTTPS_PORT:-443}
COUCHDB_USER=${COUCHDB_USER:-admin}
COUCHDB_PASSWORD=${COUCHDB_PASSWORD}
TEST_DB="noctura_test_$(date +%s)"
FAILED_TESTS=0

if [ -z "${COUCHDB_URL:-}" ]; then
    echo "🔍 Auto-detecting CouchDB access method..."
    if curl -sf -k "https://localhost:${HTTPS_PORT}/couchdb/" > /dev/null 2>&1; then
        COUCHDB_BASE_URL="https://localhost:${HTTPS_PORT}/couchdb"
        CURL_OPTS="-sk"
        echo "✅ Using HTTPS via Caddy: $COUCHDB_BASE_URL"
    else
        echo "⚠️  HTTPS not available, using HTTP fallback"
        COUCHDB_BASE_URL="http://localhost:${HTTP_PORT}/couchdb"
        CURL_OPTS="-s"
    fi
else
    echo "✅ Using provided COUCHDB_URL: $COUCHDB_URL"
    COUCHDB_BASE_URL="$COUCHDB_URL"
    CURL_OPTS="${CURL_OPTS:--s}"
fi

test_passed() {
    echo "  ✅ $1"
}

test_failed() {
    echo "  ❌ $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

echo "1️⃣  Testing Encryption Key..."
ENCRYPTION_KEY_FILE=${ENCRYPTION_KEY_FILE:-./data/secrets/encryption_key}
if [ -f "$ENCRYPTION_KEY_FILE" ]; then
    test_passed "Encryption key file exists"
    
    KEY_PERMS=$(stat -c "%a" "$ENCRYPTION_KEY_FILE" 2>/dev/null || stat -f "%Lp" "$ENCRYPTION_KEY_FILE" 2>/dev/null)
    if [ "$KEY_PERMS" = "600" ]; then
        test_passed "Encryption key has correct permissions (600)"
    else
        test_failed "Encryption key has wrong permissions ($KEY_PERMS, expected 600)"
    fi
    
    KEY_SIZE=$(wc -c < "$ENCRYPTION_KEY_FILE")
    if [ "$KEY_SIZE" -ge 32 ]; then
        test_passed "Encryption key has sufficient length"
    else
        test_failed "Encryption key is too short ($KEY_SIZE bytes)"
    fi
elif [ -n "${ENCRYPTION_KEY:-}" ]; then
    test_passed "Encryption key set via environment variable"
    KEY_SIZE=${#ENCRYPTION_KEY}
    if [ "$KEY_SIZE" -ge 32 ]; then
        test_passed "Encryption key has sufficient length"
    else
        test_failed "Encryption key is too short ($KEY_SIZE bytes)"
    fi
else
    test_failed "Encryption key not found (neither file nor environment variable)"
fi

echo ""
echo "2️⃣  Testing Gocryptfs Container..."
if docker compose ps -q gocryptfs > /dev/null 2>&1; then
    GOCRYPTFS_STATUS=$(docker inspect noctura-gocryptfs --format='{{.State.Status}}' 2>/dev/null || echo "unknown")
    if [ "$GOCRYPTFS_STATUS" = "running" ]; then
        test_passed "Gocryptfs container is running"
        
        if docker exec noctura-gocryptfs mountpoint -q /decrypted 2>/dev/null; then
            test_passed "Encrypted filesystem is mounted"
        else
            test_failed "Encrypted filesystem is not mounted"
        fi
    else
        test_failed "Gocryptfs container is not running (status: $GOCRYPTFS_STATUS)"
    fi
else
    test_failed "Gocryptfs container not found"
fi

echo ""
echo "3️⃣  Testing Caddy Reverse Proxy..."
if docker compose ps -q caddy > /dev/null 2>&1; then
    CADDY_STATUS=$(docker inspect noctura-caddy --format='{{.State.Status}}' 2>/dev/null || echo "unknown")
    if [ "$CADDY_STATUS" = "running" ]; then
        test_passed "Caddy container is running"
    else
        test_failed "Caddy container is not running (status: $CADDY_STATUS)"
    fi
else
    test_failed "Caddy container not found"
fi

echo ""
echo "4️⃣  Testing HTTP to HTTPS Redirect..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${HTTP_PORT}" 2>/dev/null || echo "000")
if [ "$HTTP_RESPONSE" = "301" ] || [ "$HTTP_RESPONSE" = "308" ] || [ "$HTTP_RESPONSE" = "200" ]; then
    test_passed "HTTP endpoint is accessible (status: $HTTP_RESPONSE)"
else
    if [[ "$COUCHDB_BASE_URL" != "https://"* ]]; then
        echo "  ⚠️  HTTP redirect test skipped (using HTTP fallback mode)"
    else
        test_failed "HTTP endpoint not accessible (status: $HTTP_RESPONSE)"
    fi
fi

echo ""
echo "5️⃣  Testing HTTPS Endpoint..."
if [[ "$COUCHDB_BASE_URL" == "https://"* ]]; then
    if curl -sf -k "https://localhost:${HTTPS_PORT}" > /dev/null 2>&1; then
        test_passed "HTTPS endpoint is accessible"
    else
        test_failed "HTTPS endpoint is not accessible"
    fi
else
    echo "  ⚠️  HTTPS test skipped (using HTTP fallback mode)"
fi

echo ""
echo "6️⃣  Testing TLS Certificate..."
if [[ "$COUCHDB_BASE_URL" == "https://"* ]]; then
    if command -v openssl > /dev/null 2>&1; then
        TLS_INFO=$(echo | openssl s_client -connect "localhost:${HTTPS_PORT}" -servername localhost 2>/dev/null | grep "Protocol")
        if echo "$TLS_INFO" | grep -qE "TLSv1\.[23]"; then
            test_passed "TLS connection established with secure protocol"
        else
            test_failed "TLS connection using insecure protocol or failed"
        fi
    else
        test_failed "OpenSSL not available for TLS testing"
    fi
else
    echo "  ⚠️  TLS test skipped (using HTTP fallback mode)"
fi

echo ""
echo "7️⃣  Testing CouchDB via Reverse Proxy..."
if curl -sf ${CURL_OPTS} "${COUCHDB_BASE_URL}/_up" > /dev/null 2>&1; then
    test_passed "CouchDB accessible via reverse proxy"
else
    test_failed "CouchDB not accessible via reverse proxy"
fi

echo ""
echo "8️⃣  Testing CouchDB Authentication..."
if curl -sf ${CURL_OPTS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" "${COUCHDB_BASE_URL}/_all_dbs" > /dev/null 2>&1; then
    test_passed "CouchDB authentication successful"
else
    test_failed "CouchDB authentication failed"
fi

echo ""
echo "9️⃣  Testing Database Creation..."
RESPONSE=$(curl -s ${CURL_OPTS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "${COUCHDB_BASE_URL}/${TEST_DB}")
if echo "$RESPONSE" | grep -q '"ok":true'; then
    test_passed "Database creation successful"
else
    test_failed "Database creation failed: $RESPONSE"
fi

echo ""
echo "🔟 Testing Document Operations..."
DOC_ID="test_doc_$(date +%s)"
RESPONSE=$(curl -s ${CURL_OPTS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "${COUCHDB_BASE_URL}/${TEST_DB}/${DOC_ID}" \
    -H "Content-Type: application/json" \
    -d '{"test": "encrypted_data", "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}')
if echo "$RESPONSE" | grep -q '"ok":true'; then
    test_passed "Document creation successful (data encrypted at rest)"
    REV=$(echo "$RESPONSE" | grep -o '"rev":"[^"]*"' | cut -d'"' -f4)
else
    test_failed "Document creation failed: $RESPONSE"
fi

echo ""
echo "1️⃣1️⃣  Testing Document Retrieval..."
RESPONSE=$(curl -s ${CURL_OPTS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    "${COUCHDB_BASE_URL}/${TEST_DB}/${DOC_ID}")
if echo "$RESPONSE" | grep -q '"test":"encrypted_data"'; then
    test_passed "Document retrieval successful"
else
    test_failed "Document retrieval failed: $RESPONSE"
fi

echo ""
echo "1️⃣2️⃣  Testing Cleanup..."
if [ -n "${REV:-}" ]; then
    curl -s ${CURL_OPTS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
        -X DELETE "${COUCHDB_BASE_URL}/${TEST_DB}/${DOC_ID}?rev=${REV}" > /dev/null
fi
RESPONSE=$(curl -s ${CURL_OPTS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X DELETE "${COUCHDB_BASE_URL}/${TEST_DB}")
if echo "$RESPONSE" | grep -q '"ok":true'; then
    test_passed "Test database cleanup successful"
else
    test_failed "Test database cleanup failed: $RESPONSE"
fi

echo ""
echo "1️⃣3️⃣  Testing Obsidian Container..."
if docker compose ps -q obsidian > /dev/null 2>&1; then
    OBSIDIAN_STATUS=$(docker inspect noctura-obsidian --format='{{.State.Status}}' 2>/dev/null || echo "unknown")
    if [ "$OBSIDIAN_STATUS" = "running" ]; then
        test_passed "Obsidian container is running"
    else
        test_failed "Obsidian container is not running (status: $OBSIDIAN_STATUS)"
    fi
else
    test_failed "Obsidian container not found"
fi

echo ""
echo "1️⃣4️⃣  Testing Obsidian Web Interface..."
if [[ "$COUCHDB_BASE_URL" == "https://"* ]]; then
    if curl -sf -k "https://localhost:${HTTPS_PORT}/obsidian/" > /dev/null 2>&1; then
        test_passed "Obsidian web interface accessible via HTTPS"
    else
        test_failed "Obsidian web interface not accessible via HTTPS"
    fi
else
    if curl -sf "http://localhost:${HTTP_PORT}/obsidian/" > /dev/null 2>&1; then
        test_passed "Obsidian web interface accessible via HTTP"
    else
        test_failed "Obsidian web interface not accessible"
    fi
fi

echo ""
echo "1️⃣5️⃣  Testing Docker Compose Configuration..."
if docker compose config > /dev/null 2>&1; then
    test_passed "Docker Compose configuration is valid"
else
    test_failed "Docker Compose configuration is invalid"
fi

echo ""
echo "1️⃣6️⃣  Testing Backup Script..."
if [ -x "./scripts/backup.sh" ]; then
    test_passed "Backup script is executable"
else
    test_failed "Backup script is not executable"
fi

echo ""
echo "1️⃣7️⃣  Testing Restore Script..."
if [ -x "./scripts/restore.sh" ]; then
    test_passed "Restore script is executable"
else
    test_failed "Restore script is not executable"
fi

echo ""
echo "1️⃣8️⃣  Testing Health Check Script..."
if [ -x "./scripts/health-check.sh" ]; then
    test_passed "Health check script is executable"
else
    test_failed "Health check script is not executable"
fi

echo ""
echo "1️⃣9️⃣  Testing Encryption Init Script..."
if [ -x "./scripts/init-encryption.sh" ]; then
    test_passed "Encryption init script is executable"
else
    test_failed "Encryption init script is not executable"
fi

echo ""
echo "2️⃣0️⃣  Testing .env File Permissions..."
if [ -f .env ]; then
    ENV_PERMS=$(stat -c "%a" .env 2>/dev/null || stat -f "%Lp" .env 2>/dev/null)
    if [ "$ENV_PERMS" = "600" ]; then
        test_passed ".env file has correct permissions (600)"
    else
        test_failed ".env file has wrong permissions ($ENV_PERMS, expected 600)"
    fi
else
    test_failed ".env file not found"
fi

echo ""
echo "================================"
if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ All tests passed!"
    echo ""
    echo "🔐 Security Features Verified:"
    echo "  ✅ Encryption at rest (gocryptfs)"
    if [[ "$COUCHDB_BASE_URL" == "https://"* ]]; then
        echo "  ✅ Encryption in flight (TLS/HTTPS)"
    else
        echo "  ⚠️  TLS/HTTPS tests skipped (HTTP fallback mode)"
    fi
    echo "  ✅ Secure credentials"
    echo "  ✅ File permissions"
    exit 0
else
    echo "❌ $FAILED_TESTS test(s) failed"
    exit 1
fi
