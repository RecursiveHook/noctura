#!/bin/bash
set -euo pipefail

ENCRYPTED_DIR="${ENCRYPTED_DIR:-/encrypted}"
DECRYPTED_DIR="${DECRYPTED_DIR:-/decrypted}"
PASSWORD_FILE="${PASSWORD_FILE:-/run/secrets/encryption_key}"

if [ ! -f "$PASSWORD_FILE" ]; then
    echo "❌ Error: Password file not found at $PASSWORD_FILE"
    exit 1
fi

if [ ! -f "$ENCRYPTED_DIR/gocryptfs.conf" ]; then
    echo "🔐 Initializing encrypted filesystem..."
    gocryptfs -init -passfile "$PASSWORD_FILE" "$ENCRYPTED_DIR"
    echo "✅ Encrypted filesystem initialized"
fi

echo "🔓 Mounting encrypted filesystem..."
gocryptfs -passfile "$PASSWORD_FILE" -allow_other "$ENCRYPTED_DIR" "$DECRYPTED_DIR"

echo "✅ Encrypted filesystem mounted at $DECRYPTED_DIR"
echo "📊 Keeping container alive..."

trap "echo '🔒 Unmounting...'; fusermount -u $DECRYPTED_DIR; exit 0" SIGTERM SIGINT

while true; do
    sleep 3600
done
