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

COUCHDB_PORT=${COUCHDB_PORT:-5984}
COUCHDB_USER=${COUCHDB_USER:-admin}
COUCHDB_PASSWORD=${COUCHDB_PASSWORD}
TEST_DB="noctura_test_$(date +%s)"
FAILED_TESTS=0

test_passed() {
    echo "  ✅ $1"
}

test_failed() {
    echo "  ❌ $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

echo "1️⃣  Testing CouchDB Connectivity..."
if curl -sf "http://localhost:${COUCHDB_PORT}/_up" > /dev/null 2>&1; then
    test_passed "CouchDB is reachable"
else
    test_failed "CouchDB is not reachable"
    exit 1
fi

echo ""
echo "2️⃣  Testing Authentication..."
if curl -sf -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" "http://localhost:${COUCHDB_PORT}/_all_dbs" > /dev/null 2>&1; then
    test_passed "Authentication successful"
else
    test_failed "Authentication failed"
    exit 1
fi

echo ""
echo "3️⃣  Testing Database Creation..."
RESPONSE=$(curl -s -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "http://localhost:${COUCHDB_PORT}/${TEST_DB}")
if echo "$RESPONSE" | grep -q '"ok":true'; then
    test_passed "Database creation successful"
else
    test_failed "Database creation failed: $RESPONSE"
fi

echo ""
echo "4️⃣  Testing Document Creation..."
DOC_ID="test_doc_$(date +%s)"
RESPONSE=$(curl -s -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X PUT "http://localhost:${COUCHDB_PORT}/${TEST_DB}/${DOC_ID}" \
    -H "Content-Type: application/json" \
    -d '{"test": "data", "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}')
if echo "$RESPONSE" | grep -q '"ok":true'; then
    test_passed "Document creation successful"
    REV=$(echo "$RESPONSE" | grep -o '"rev":"[^"]*"' | cut -d'"' -f4)
else
    test_failed "Document creation failed: $RESPONSE"
fi

echo ""
echo "5️⃣  Testing Document Retrieval..."
RESPONSE=$(curl -s -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    "http://localhost:${COUCHDB_PORT}/${TEST_DB}/${DOC_ID}")
if echo "$RESPONSE" | grep -q '"test":"data"'; then
    test_passed "Document retrieval successful"
else
    test_failed "Document retrieval failed: $RESPONSE"
fi

echo ""
echo "6️⃣  Testing Document Update..."
if [ -n "${REV:-}" ]; then
    RESPONSE=$(curl -s -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
        -X PUT "http://localhost:${COUCHDB_PORT}/${TEST_DB}/${DOC_ID}?rev=${REV}" \
        -H "Content-Type: application/json" \
        -d '{"test": "updated", "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}')
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        test_passed "Document update successful"
        NEW_REV=$(echo "$RESPONSE" | grep -o '"rev":"[^"]*"' | cut -d'"' -f4)
    else
        test_failed "Document update failed: $RESPONSE"
    fi
else
    test_failed "Document update skipped (no revision)"
fi

echo ""
echo "7️⃣  Testing Document Deletion..."
if [ -n "${NEW_REV:-}" ]; then
    RESPONSE=$(curl -s -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
        -X DELETE "http://localhost:${COUCHDB_PORT}/${TEST_DB}/${DOC_ID}?rev=${NEW_REV}")
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        test_passed "Document deletion successful"
    else
        test_failed "Document deletion failed: $RESPONSE"
    fi
else
    test_failed "Document deletion skipped (no revision)"
fi

echo ""
echo "8️⃣  Testing Database Deletion..."
RESPONSE=$(curl -s -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" \
    -X DELETE "http://localhost:${COUCHDB_PORT}/${TEST_DB}")
if echo "$RESPONSE" | grep -q '"ok":true'; then
    test_passed "Database deletion successful"
else
    test_failed "Database deletion failed: $RESPONSE"
fi

echo ""
echo "9️⃣  Testing Backup Script..."
if [ -x "./scripts/backup.sh" ]; then
    test_passed "Backup script is executable"
else
    test_failed "Backup script is not executable"
fi

echo ""
echo "🔟 Testing Restore Script..."
if [ -x "./scripts/restore.sh" ]; then
    test_passed "Restore script is executable"
else
    test_failed "Restore script is not executable"
fi

echo ""
echo "================================"
if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ $FAILED_TESTS test(s) failed"
    exit 1
fi
