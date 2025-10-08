#!/bin/bash
set -euo pipefail

ENCRYPTED_DIR="${ENCRYPTED_DIR:-/encrypted}"
DECRYPTED_DIR="${DECRYPTED_DIR:-/decrypted}"
PASSWORD_FILE="${PASSWORD_FILE:-}"
PASSWORD="${PASSWORD:-}"

if [ -n "$PASSWORD_FILE" ] && [ -f "$PASSWORD_FILE" ]; then
    echo "🔑 Using password from file: $PASSWORD_FILE"
    PASSFILE_ARG="-passfile $PASSWORD_FILE"
elif [ -n "$PASSWORD" ]; then
    echo "🔑 Using password from environment variable"
    PASSWORD_FILE="/tmp/gocryptfs_pass"
    echo -n "$PASSWORD" > "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
    PASSFILE_ARG="-passfile $PASSWORD_FILE"
else
    echo "❌ Error: No password provided. Set PASSWORD or PASSWORD_FILE"
    exit 1
fi

if [ ! -f "$ENCRYPTED_DIR/gocryptfs.conf" ]; then
    echo "🔐 Initializing encrypted filesystem..."
    gocryptfs -init $PASSFILE_ARG "$ENCRYPTED_DIR"
    echo "✅ Encrypted filesystem initialized"
fi

echo "🔓 Mounting encrypted filesystem..."
gocryptfs $PASSFILE_ARG -allow_other "$ENCRYPTED_DIR" "$DECRYPTED_DIR"

echo "✅ Encrypted filesystem mounted at $DECRYPTED_DIR"
echo "📊 Keeping container alive..."

trap "echo '🔒 Unmounting...'; fusermount -u $DECRYPTED_DIR; exit 0" SIGTERM SIGINT

while true; do
    sleep 3600
done
