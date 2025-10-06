#!/bin/bash

set -euo pipefail

VAULT_DIR="${VAULT_DIR:-/vault}"
COUCHDB_URI="${COUCHDB_URI:-http://couchdb:5984}"
COUCHDB_USER="${COUCHDB_USER:-admin}"
COUCHDB_PASSWORD="${COUCHDB_PASSWORD}"
COUCHDB_DBNAME="${COUCHDB_DBNAME:-obsidian}"
VAULT_NAME="${VAULT_NAME:-noctura-vault}"

echo "🚀 Starting Obsidian container..."
echo "📁 Vault directory: ${VAULT_DIR}"

mkdir -p "${VAULT_DIR}/.obsidian/plugins/obsidian-livesync"

if [[ ! -f "${VAULT_DIR}/.obsidian/app.json" ]]; then
    echo "🔧 Initializing vault structure..."
    cat > "${VAULT_DIR}/.obsidian/app.json" <<EOF
{
  "legacyEditor": false,
  "livePreview": true
}
EOF
fi

if [[ ! -f "${VAULT_DIR}/README.md" ]]; then
    cat > "${VAULT_DIR}/README.md" <<EOF
# ${VAULT_NAME}

Welcome to your Noctura-managed Obsidian vault!

This vault is running in a containerized environment with:
- Automatic sync via Self-hosted LiveSync
- Web access via noVNC
- Automatic backups

## Access

- Web Interface: http://localhost:8080/vnc.html
- VNC Direct: localhost:5900

## Support

For help and documentation, visit the Noctura documentation.
EOF
fi

echo "📦 Installing Self-hosted LiveSync plugin..."
cp /tmp/livesync/main.js "${VAULT_DIR}/.obsidian/plugins/obsidian-livesync/"
cp /tmp/livesync/manifest.json "${VAULT_DIR}/.obsidian/plugins/obsidian-livesync/"
cp /tmp/livesync/styles.css "${VAULT_DIR}/.obsidian/plugins/obsidian-livesync/"

if [[ ! -f "${VAULT_DIR}/.obsidian/community-plugins.json" ]]; then
    echo '["obsidian-livesync"]' > "${VAULT_DIR}/.obsidian/community-plugins.json"
fi

echo "🔧 Configuring LiveSync plugin..."
cat > "${VAULT_DIR}/.obsidian/plugins/obsidian-livesync/data.json" <<EOF
{
  "couchDB_URI": "${COUCHDB_URI}",
  "couchDB_USER": "${COUCHDB_USER}",
  "couchDB_PASSWORD": "${COUCHDB_PASSWORD}",
  "couchDB_DBNAME": "${COUCHDB_DBNAME}",
  "liveSync": true,
  "syncOnSave": true,
  "syncOnStart": true,
  "savingDelay": 200,
  "lessInformationInLog": false,
  "gcDelay": 0,
  "versionUpFlash": "",
  "minimumChunkSize": 20,
  "longLineThreshold": 250,
  "showVerboseLog": false,
  "suspendFileWatching": false,
  "trashInsteadDelete": true,
  "periodicReplication": false,
  "periodicReplicationInterval": 60,
  "syncOnFileOpen": false,
  "encrypt": false,
  "passphrase": "",
  "usePathObfuscation": false,
  "doNotDeleteFolder": false,
  "resolveConflictsByNewerFile": false,
  "batchSave": false,
  "deviceAndVaultName": "container-${HOSTNAME}",
  "usePluginSettings": false,
  "showOwnPlugins": false,
  "showStatusOnEditor": true,
  "showStatusOnStatusbar": true,
  "showOnlyIconsOnEditor": false
}
EOF

echo "✅ Vault initialized and configured"
echo "🌐 Starting services..."

exec "$@"
