#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED_CHECKS=0

echo "🔍 Noctura Health Check"
echo "======================="
echo ""

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 not found"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_directory() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 exists"
    else
        echo -e "${YELLOW}⚠${NC} $1 not found (will be created on setup)"
    fi
    return 0
}

echo "📋 Checking Prerequisites..."
check_command docker
check_command curl
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗${NC} docker compose is not available"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
    echo -e "${GREEN}✓${NC} docker compose is available"
fi

echo ""
echo "📁 Checking Project Files..."
check_file "docker-compose.yml"
check_file ".env.example"
check_file "scripts/setup.sh"
check_file "scripts/backup.sh"
check_file "scripts/restore.sh"

echo ""
echo "📂 Checking Directories..."
check_directory "data/couchdb"
check_directory "data/config"
check_directory "backups"

echo ""
if [ -f .env ]; then
    echo "🔧 Checking Configuration..."
    source .env
    
    if [ -z "${COUCHDB_PASSWORD:-}" ] || [ "${COUCHDB_PASSWORD}" == "change_this_secure_password" ]; then
        echo -e "${RED}✗${NC} COUCHDB_PASSWORD not set or using default"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    else
        echo -e "${GREEN}✓${NC} COUCHDB_PASSWORD is configured"
    fi
    
    COUCHDB_PORT=${COUCHDB_PORT:-5984}
    echo -e "${GREEN}✓${NC} COUCHDB_PORT set to $COUCHDB_PORT"
else
    echo -e "${YELLOW}⚠${NC} .env file not found (run ./scripts/setup.sh)"
fi

echo ""
echo "🐳 Checking Docker Services..."

if docker compose ps 2>/dev/null | grep -q "noctura-couchdb"; then
    CONTAINER_STATUS=$(docker compose ps --format json 2>/dev/null | grep couchdb | grep -o '"State":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    
    if [ "$CONTAINER_STATUS" == "running" ]; then
        echo -e "${GREEN}✓${NC} CouchDB container is running"
        
        if [ -f .env ]; then
            source .env
            COUCHDB_PORT=${COUCHDB_PORT:-5984}
            
            echo ""
            echo "🌐 Checking CouchDB Health..."
            
            if curl -sf "http://localhost:${COUCHDB_PORT}/_up" > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} CouchDB health check passed"
                
                COUCHDB_VERSION=$(curl -s "http://localhost:${COUCHDB_PORT}/" 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
                echo -e "${GREEN}✓${NC} CouchDB version: $COUCHDB_VERSION"
                
                if curl -sf -u "${COUCHDB_USER:-admin}:${COUCHDB_PASSWORD}" "http://localhost:${COUCHDB_PORT}/_all_dbs" > /dev/null 2>&1; then
                    echo -e "${GREEN}✓${NC} CouchDB authentication working"
                    echo -e "${GREEN}✓${NC} CouchDB is accessible"
                else
                    echo -e "${RED}✗${NC} CouchDB authentication failed"
                    FAILED_CHECKS=$((FAILED_CHECKS + 1))
                fi
            else
                echo -e "${RED}✗${NC} CouchDB health check failed"
                FAILED_CHECKS=$((FAILED_CHECKS + 1))
            fi
        fi
    else
        echo -e "${YELLOW}⚠${NC} CouchDB container exists but is not running (status: $CONTAINER_STATUS)"
    fi
else
    echo -e "${YELLOW}⚠${NC} CouchDB container is not running"
    echo "   Run './scripts/setup.sh' or 'docker compose up -d' to start"
fi

if docker compose ps 2>/dev/null | grep -q "noctura-obsidian"; then
    OBSIDIAN_STATUS=$(docker compose ps --format json 2>/dev/null | grep obsidian | grep -o '"State":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    
    if [ "$OBSIDIAN_STATUS" == "running" ]; then
        echo -e "${GREEN}✓${NC} Obsidian container is running"
        
        if [ -f .env ]; then
            source .env
            OBSIDIAN_WEB_PORT=${OBSIDIAN_WEB_PORT:-8080}
            
            echo ""
            echo "🌐 Checking Obsidian Web Interface..."
            
            if curl -sf "http://localhost:${OBSIDIAN_WEB_PORT}" > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} Obsidian web interface is accessible"
                echo -e "${GREEN}✓${NC} Web URL: http://localhost:${OBSIDIAN_WEB_PORT}/vnc.html"
            else
                echo -e "${YELLOW}⚠${NC} Obsidian web interface not ready yet (may still be starting)"
            fi
        fi
    else
        echo -e "${YELLOW}⚠${NC} Obsidian container exists but is not running (status: $OBSIDIAN_STATUS)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Obsidian container is not running"
fi

echo ""
echo "💾 Checking Data Persistence..."
if [ -d "data/couchdb" ] && [ "$(ls -A data/couchdb 2>/dev/null)" ]; then
    DATA_SIZE=$(du -sh data/couchdb 2>/dev/null | cut -f1 || echo "unknown")
    echo -e "${GREEN}✓${NC} CouchDB data exists (size: $DATA_SIZE)"
else
    echo -e "${YELLOW}⚠${NC} No CouchDB data found (fresh install)"
fi

if [ -d "vaults" ] && [ "$(ls -A vaults 2>/dev/null)" ]; then
    VAULT_SIZE=$(du -sh vaults 2>/dev/null | cut -f1 || echo "unknown")
    VAULT_COUNT=$(find vaults -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l)
    echo -e "${GREEN}✓${NC} Obsidian vaults exist (count: $VAULT_COUNT, size: $VAULT_SIZE)"
else
    echo -e "${YELLOW}⚠${NC} No Obsidian vaults found (will be created on first run)"
fi

BACKUP_COUNT=$(find backups -name "noctura-*.tar.gz" 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} $BACKUP_COUNT backup(s) found"
else
    echo -e "${YELLOW}⚠${NC} No backups found"
fi

echo ""
echo "======================================"
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED_CHECKS check(s) failed${NC}"
    echo ""
    echo "Recommendations:"
    echo "  • Run './scripts/setup.sh' to initialize the project"
    echo "  • Check 'docker compose logs couchdb' for errors"
    echo "  • Verify .env configuration"
    exit 1
fi
