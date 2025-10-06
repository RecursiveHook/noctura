# Obsidian Installation Quick Reference

## Automated Installation (Linux Servers)

The `install-obsidian.sh` script automates the complete setup of Obsidian with Self-hosted LiveSync on Linux servers (AMD64 or ARM64).

### Basic Usage

```bash
# Use default vault location (./vaults/noctura-vault)
./scripts/install-obsidian.sh

# Specify custom vault path
./scripts/install-obsidian.sh /path/to/my/vault

# Or via Make
make install-obsidian
```

### Environment Variables

```bash
# Use specific Obsidian version (default: latest)
OBSIDIAN_VERSION=1.5.3 ./scripts/install-obsidian.sh

# Use custom vault name (default: noctura-vault)
VAULT_NAME=my-vault ./scripts/install-obsidian.sh

# Combine both
OBSIDIAN_VERSION=1.5.3 VAULT_NAME=work ./scripts/install-obsidian.sh
```

### What It Does

1. **Detects System**: Linux AMD64 or ARM64
2. **Downloads Obsidian**: AppImage from GitHub releases
3. **Installs**: Places AppImage at `/opt/noctura/Obsidian.AppImage`
4. **Creates Vault**: At specified path or `./vaults/noctura-vault`
5. **Downloads Plugin**: Self-hosted LiveSync from GitHub
6. **Installs Plugin**: Into vault's `.obsidian/plugins/` directory
7. **Configures Plugin**: Reads CouchDB credentials from `.env`
8. **Enables Plugin**: Adds to `community-plugins.json`

### After Installation

1. Launch Obsidian:
   ```bash
   /opt/noctura/Obsidian.AppImage
   ```

2. Open your vault (path displayed by script)

3. Go to Settings → Self-hosted LiveSync

4. Click "Test Database Connection"

5. First device:
   - Click "Initialize Database"

6. Additional devices:
   - Click "Rebuild Database"

7. Click "Start" to begin syncing

### Multiple Vaults

You can create multiple vaults with different configurations:

```bash
# Personal vault
VAULT_NAME=personal ./scripts/install-obsidian.sh

# Work vault
VAULT_NAME=work ./scripts/install-obsidian.sh

# Each vault syncs to the same CouchDB but can use different database names
# Edit the plugin settings to change database name per vault
```

### Server Deployment

For headless servers, you can pre-configure vaults that users can access:

```bash
# On server: Install and configure
./scripts/install-obsidian.sh /srv/obsidian/shared-vault

# Users can then:
# 1. Install Obsidian on their local machine
# 2. Install Self-hosted LiveSync plugin
# 3. Configure with same CouchDB credentials
# 4. Sync to the shared database
```

### Troubleshooting

**Script fails with "jq not found":**
```bash
sudo apt-get install jq curl
```

**Script fails with ".env not found":**
```bash
./scripts/setup.sh  # Run setup first
```

**AppImage won't execute:**
```bash
# Install FUSE
sudo apt-get install fuse
```

**Plugin not enabled:**
- Open Obsidian
- Go to Settings → Community Plugins
- Enable "Self-hosted LiveSync"

### Architecture Support

- **AMD64 (x86_64)**: Uses `Obsidian-VERSION.AppImage`
- **ARM64 (aarch64)**: Uses `Obsidian-VERSION-arm64.AppImage`

Both architectures use AppImage format for maximum compatibility across Linux distributions.

### Files Created

```
/opt/noctura/
└── Obsidian.AppImage           # Obsidian application

./vaults/
└── noctura-vault/              # Default vault
    ├── .obsidian/
    │   ├── app.json
    │   ├── community-plugins.json
    │   └── plugins/
    │       └── obsidian-livesync/
    │           ├── main.js
    │           ├── manifest.json
    │           ├── styles.css
    │           └── data.json    # Plugin configuration
    └── README.md

./downloads/                     # Cached downloads
├── Obsidian-VERSION.AppImage
└── livesync/
    ├── main.js
    ├── manifest.json
    └── styles.css
```

All `downloads/` and `vaults/` directories are gitignored for security and size.
