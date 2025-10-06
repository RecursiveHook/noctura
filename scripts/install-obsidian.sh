#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

OBSIDIAN_VERSION="${OBSIDIAN_VERSION:-latest}"
LIVESYNC_VERSION="${LIVESYNC_VERSION:-0.25.20}"
DEFAULT_VAULT_NAME="${VAULT_NAME:-noctura-vault}"
DEFAULT_VAULT_PATH="${PROJECT_ROOT}/vaults/${DEFAULT_VAULT_NAME}"

detect_architecture() {
  local arch
  arch="$(uname -m)"
  case "${arch}" in
    x86_64)
      echo "amd64"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    *)
      echo "❌ Error: Unsupported architecture: ${arch}"
      exit 1
      ;;
  esac
}

check_dependencies() {
  local deps=("curl" "jq")
  for dep in "${deps[@]}"; do
    if ! command -v "${dep}" &> /dev/null; then
      echo "❌ Error: ${dep} is required but not installed"
      exit 1
    fi
  done
  
  if ! uname -s | grep -q "Linux"; then
    echo "❌ Error: This script is designed for Linux servers only"
    echo "Detected OS: $(uname -s)"
    exit 1
  fi
}

get_latest_obsidian_version() {
  local latest_url="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"
  curl -sL "${latest_url}" | jq -r '.tag_name' | sed 's/^v//'
}

download_obsidian() {
  local arch="$1"
  local version="$2"
  local download_dir="${PROJECT_ROOT}/downloads"
  
  mkdir -p "${download_dir}"
  
  echo "📥 Downloading Obsidian ${version} for Linux (${arch})..."
  
  local download_url
  local filename
  
  if [[ "${arch}" == "amd64" ]]; then
    filename="Obsidian-${version}.AppImage"
    download_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/${filename}"
  else
    filename="Obsidian-${version}-arm64.AppImage"
    download_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/${filename}"
  fi
  
  local output_file="${download_dir}/${filename}"
  
  if [[ -f "${output_file}" ]]; then
    echo "✅ Obsidian already downloaded: ${output_file}"
  else
    curl -L -o "${output_file}" "${download_url}"
    echo "✅ Downloaded: ${output_file}"
  fi
  
  echo "${output_file}"
}

install_obsidian_linux() {
  local installer="$1"
  
  echo "🔧 Installing Obsidian..."
  
  local install_dir="/opt/noctura"
  sudo mkdir -p "${install_dir}"
  
  sudo cp "${installer}" "${install_dir}/Obsidian.AppImage"
  sudo chmod +x "${install_dir}/Obsidian.AppImage"
  
  sudo mkdir -p /usr/local/share/applications
  sudo tee /usr/local/share/applications/obsidian.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Obsidian
Exec=${install_dir}/Obsidian.AppImage %u
Terminal=false
Type=Application
Icon=obsidian
StartupWMClass=obsidian
Comment=Knowledge base
MimeType=x-scheme-handler/obsidian;
Categories=Office;
EOF
  
  echo "✅ Obsidian installed to ${install_dir}/Obsidian.AppImage"
}

create_vault() {
  local vault_path="$1"
  
  if [[ -d "${vault_path}" ]]; then
    echo "✅ Vault already exists: ${vault_path}"
  else
    echo "📁 Creating vault: ${vault_path}"
    mkdir -p "${vault_path}/.obsidian"
    
    cat > "${vault_path}/.obsidian/app.json" <<EOF
{}
EOF
    
    cat > "${vault_path}/README.md" <<EOF
# Noctura Vault

Welcome to your Noctura-managed Obsidian vault with Self-hosted LiveSync!

This vault is automatically synced to your CouchDB instance.

## Getting Started

Your vault is now configured with:
- Self-hosted LiveSync plugin (enabled)
- Automatic sync on save
- Live sync enabled

Start creating notes and they will sync automatically across all your devices.

## Support

For help and documentation, visit:
- Project: ${PROJECT_ROOT}
- Docs: ${PROJECT_ROOT}/docs/
EOF
    
    echo "✅ Vault created: ${vault_path}"
  fi
}

download_livesync_plugin() {
  local version="$1"
  local download_dir="${PROJECT_ROOT}/downloads/livesync"
  
  mkdir -p "${download_dir}"
  
  echo "📥 Downloading Self-hosted LiveSync plugin v${version}..."
  
  local base_url="https://github.com/vrtmrz/obsidian-livesync/releases/download/${version}"
  
  curl -L -o "${download_dir}/main.js" "${base_url}/main.js"
  curl -L -o "${download_dir}/manifest.json" "${base_url}/manifest.json"
  curl -L -o "${download_dir}/styles.css" "${base_url}/styles.css"
  
  echo "✅ Plugin downloaded to ${download_dir}"
  echo "${download_dir}"
}

install_livesync_plugin() {
  local plugin_dir="$1"
  local vault_path="$2"
  
  local plugins_dir="${vault_path}/.obsidian/plugins/obsidian-livesync"
  mkdir -p "${plugins_dir}"
  
  echo "🔧 Installing LiveSync plugin to vault..."
  
  cp "${plugin_dir}/main.js" "${plugins_dir}/"
  cp "${plugin_dir}/manifest.json" "${plugins_dir}/"
  cp "${plugin_dir}/styles.css" "${plugins_dir}/"
  
  local community_plugins_file="${vault_path}/.obsidian/community-plugins.json"
  if [[ ! -f "${community_plugins_file}" ]]; then
    echo '["obsidian-livesync"]' > "${community_plugins_file}"
  else
    local current_plugins
    current_plugins=$(cat "${community_plugins_file}")
    if ! echo "${current_plugins}" | grep -q "obsidian-livesync"; then
      echo "${current_plugins}" | jq '. += ["obsidian-livesync"]' > "${community_plugins_file}"
    fi
  fi
  
  echo "✅ LiveSync plugin installed and enabled in ${plugins_dir}"
}

configure_livesync_plugin() {
  local vault_path="$1"
  
  # shellcheck disable=SC2154
  if [[ -f "${PROJECT_ROOT}/.env" ]]; then
    # shellcheck source=/dev/null
    source "${PROJECT_ROOT}/.env"
  else
    echo "❌ Error: .env file not found. Run setup.sh first."
    exit 1
  fi
  
  local config_file="${vault_path}/.obsidian/plugins/obsidian-livesync/data.json"
  
  echo "🔧 Configuring LiveSync plugin..."
  
  local couchdb_url="http://localhost:${COUCHDB_PORT:-5984}"
  local couchdb_user="${COUCHDB_USER:-admin}"
  local couchdb_password="${COUCHDB_PASSWORD:-}"
  
  cat > "${config_file}" <<EOF
{
  "couchDB_URI": "${couchdb_url}",
  "couchDB_USER": "${couchdb_user}",
  "couchDB_PASSWORD": "${couchdb_password}",
  "couchDB_DBNAME": "obsidian",
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
  "deviceAndVaultName": "",
  "usePluginSettings": false,
  "showOwnPlugins": false,
  "showStatusOnEditor": true,
  "showStatusOnStatusbar": true,
  "showOnlyIconsOnEditor": false
}
EOF
  
  echo "✅ LiveSync plugin configured with CouchDB connection"
  echo ""
  echo "📝 Connection details:"
  echo "   URL: ${couchdb_url}/obsidian"
  echo "   User: ${couchdb_user}"
  echo "   Database: obsidian"
  echo ""
}

main() {
  echo "🚀 Noctura Obsidian Installation Script (Linux Only)"
  echo ""
  
  check_dependencies
  
  local arch
  arch="$(detect_architecture)"
  
  echo "📋 System Info:"
  echo "   OS: Linux"
  echo "   Architecture: ${arch}"
  echo ""
  
  local version="${OBSIDIAN_VERSION}"
  if [[ "${version}" == "latest" ]]; then
    version="$(get_latest_obsidian_version)"
    echo "📦 Latest Obsidian version: ${version}"
  fi
  
  local obsidian_installer
  obsidian_installer="$(download_obsidian "${arch}" "${version}")"
  
  install_obsidian_linux "${obsidian_installer}"
  
  local vault_path="${1:-${DEFAULT_VAULT_PATH}}"
  
  echo ""
  echo "📁 Vault path: ${vault_path}"
  
  create_vault "${vault_path}"
  
  local plugin_dir
  plugin_dir="$(download_livesync_plugin "${LIVESYNC_VERSION}")"
  
  install_livesync_plugin "${plugin_dir}" "${vault_path}"
  configure_livesync_plugin "${vault_path}"
  
  echo ""
  echo "✅ Installation complete!"
  echo ""
  echo "Next steps:"
  echo "1. Launch Obsidian: /opt/noctura/Obsidian.AppImage"
  echo "2. Open vault: ${vault_path}"
  echo "3. The Self-hosted LiveSync plugin is already enabled and configured"
  echo "4. Go to Settings → Self-hosted LiveSync"
  echo "5. Click 'Test Database Connection' to verify"
  echo "6. Click 'Initialize Database' if this is the first device"
  echo "7. Click 'Start' to begin syncing"
  echo ""
  echo "📚 For more information, see: ${PROJECT_ROOT}/docs/OBSIDIAN_SETUP.md"
}

main "$@"
