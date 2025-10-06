#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔐 Noctura Encryption Initialization"
echo "====================================="

if ! command -v openssl &> /dev/null; then
    echo "❌ Error: openssl is not installed"
    exit 1
fi

SECRETS_DIR="./data/secrets"
ENCRYPTION_KEY_FILE="${ENCRYPTION_KEY_FILE:-$SECRETS_DIR/encryption_key}"

mkdir -p "$SECRETS_DIR"

if [ -f "$ENCRYPTION_KEY_FILE" ]; then
    echo "⚠️  Encryption key already exists at $ENCRYPTION_KEY_FILE"
    read -p "Do you want to regenerate it? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "✅ Using existing encryption key"
        exit 0
    fi
    
    echo "⚠️  WARNING: Regenerating the key will make existing encrypted data inaccessible!"
    read -p "Are you absolutely sure? Type 'yes' to confirm: " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "❌ Aborted"
        exit 1
    fi
    
    mv "$ENCRYPTION_KEY_FILE" "${ENCRYPTION_KEY_FILE}.backup.$(date +%s)"
    echo "📦 Old key backed up"
fi

echo "🔑 Generating encryption key..."
openssl rand -base64 32 > "$ENCRYPTION_KEY_FILE"

chmod 600 "$ENCRYPTION_KEY_FILE"

echo "✅ Encryption key generated at $ENCRYPTION_KEY_FILE"
echo ""
echo "🔒 Key permissions set to 600 (read/write for owner only)"
echo ""
echo "⚠️  IMPORTANT:"
echo "  1. Back up this key in a secure location"
echo "  2. Without this key, encrypted data cannot be recovered"
echo "  3. Keep this key separate from your backups"
echo ""
echo "📋 To display the key (save it securely):"
echo "   cat $ENCRYPTION_KEY_FILE"
echo ""
