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

if mountpoint -q "$DECRYPTED_DIR"; then
    echo "⚠️  $DECRYPTED_DIR is already mounted, unmounting first..."
    fusermount -u "$DECRYPTED_DIR" || umount "$DECRYPTED_DIR" || true
    sleep 1
fi

if [ -d "$DECRYPTED_DIR" ] && [ "$(ls -A "$DECRYPTED_DIR" 2>/dev/null)" ]; then
    echo "⚠️  $DECRYPTED_DIR is not empty, clearing stale data before mount..."
    rm -rf "${DECRYPTED_DIR:?}/"* "${DECRYPTED_DIR:?}/".[!.]* 2>/dev/null || true
fi

echo "🔓 Mounting encrypted filesystem..."
exec gocryptfs $PASSFILE_ARG -allow_other -fg "$ENCRYPTED_DIR" "$DECRYPTED_DIR"
