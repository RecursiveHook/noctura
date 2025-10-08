# Noctura

[![CI](https://github.com/RecursiveHook/noctura/actions/workflows/ci.yml/badge.svg)](https://github.com/RecursiveHook/noctura/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/RecursiveHook/noctura/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Turnkey containerized deployment for Obsidian with Self-Hosted LiveSync via CouchDB. Easy to deploy, manage, backup, and migrate your personal knowledge base.

## Features

- **Self-Hosted Sync**: CouchDB-powered LiveSync for complete data ownership
- **Encrypted Storage**: AES-256-GCM database encryption at rest with gocryptfs
- **Secure Access**: TLS/HTTPS encryption in flight with automatic Let's Encrypt certificates
- **Containerized Deployment**: Docker Compose setup for portability and ease of management
- **Backup Ready**: Volume-based persistence with simple backup/restore workflows
- **NextCloud Integration**: Planned support for file attachment syncing
- **Multi-Device Support**: Sync across desktop, mobile, and web clients
- **Zero-Config**: Sensible defaults with optional customization

## Quick Start

```bash
./scripts/setup.sh
```

Or using Make:
```bash
make setup
```

The setup script will:
- Generate secure credentials and encryption keys
- Initialize encrypted database storage
- Create necessary directories
- Start all containers (CouchDB, Obsidian, Caddy reverse proxy, encryption layer)
- Display connection information

Access Obsidian via web browser at `https://localhost` (development) or configure your local Obsidian client with the displayed credentials.

## Components

### Caddy Reverse Proxy
- Default ports: `80` (HTTP) and `443` (HTTPS)
- Automatic HTTPS with Let's Encrypt in production
- Self-signed certificates in development mode
- Routes: `/couchdb`, `/obsidian`, `/vnc`

### CouchDB
- Internal port: `5984` (accessed via Caddy reverse proxy)
- Admin interface: `https://localhost/couchdb/_utils`
- Data persistence: Encrypted volume managed by gocryptfs

### Obsidian (Containerized)
- Web interface: `https://localhost/obsidian`
- VNC access: `https://localhost/vnc`
- Vault persistence: `./vaults`
- Pre-configured with Self-hosted LiveSync plugin

### Security Layer (gocryptfs)
- AES-256-GCM encryption at rest
- Transparent encryption/decryption
- 32-byte secure encryption key
- Protects all CouchDB data

### Configuration
- Credentials and encryption keys in `.env` (created on first run)
- TLS certificates managed automatically by Caddy

## Setup

### Automated Setup (Recommended)

```bash
./scripts/setup.sh
```

Or with Make:
```bash
make setup
```

### Manual Setup

```bash
cp .env.example .env
nano .env  # Configure credentials and encryption key
mkdir -p data/config data/encrypted data/secrets data/logs/caddy backups vaults
echo "your-32-byte-encryption-key" > data/secrets/encryption_key
chmod 600 data/secrets/encryption_key .env
docker compose up -d
```

### Initialize Database

```bash
./scripts/init-db.sh
# Or: make init-db
```

This creates the Obsidian database and configures optimal settings.

### Access Obsidian

#### Containerized Web Access (Recommended)

After running setup, access Obsidian via web browser:

**Development:**
```
https://localhost (self-signed certificate)
```

**Production:**
```
https://your-domain.com
```

The vault is automatically initialized with Self-hosted LiveSync plugin configured and connected to CouchDB.

**Credentials**: Displayed once during setup (save them securely)

#### Local Desktop Client

Alternatively, use your local Obsidian installation:

1. Install "Self-hosted LiveSync" plugin in Obsidian
2. Open plugin settings
3. Configure remote database:
   - URL: `https://your-domain.com/couchdb/noctura` (or `https://localhost/couchdb/noctura` for dev)
   - Username/Password: From `.env`
4. Initialize sync and start syncing

See [docs/OBSIDIAN_SETUP.md](docs/OBSIDIAN_SETUP.md) for detailed instructions.

## Architecture

```
┌─────────────────────┐       ┌──────────────────┐
│  Obsidian Desktop   │       │ Obsidian Web UI  │
│   (Local Client)    │       │   (Container)    │
└──────────┬──────────┘       └────────┬─────────┘
           │                           │
      LiveSync Plugin             Auto-configured
           │                           │
           └───────────┬───────────────┘
                       │
                  HTTPS (TLS)
                       │
                       ▼
              ┌────────────────┐
              │  Caddy Proxy   │
              │  (443/80)      │
              └────────┬───────┘
                       │
                       ▼
              ┌─────────────────┐      ┌──────────────┐
              │    CouchDB      │◄────►│  NextCloud   │
              │  (Internal)     │      │  (Optional)  │
              └─────────┬───────┘      └──────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │  gocryptfs      │
              │  AES-256-GCM    │
              └─────────┬───────┘
                        │
                        ▼
                 ./data/encrypted
                 (Encrypted Volume)
                        │
                        ▼
                   ./vaults/
               (Obsidian Vaults)
```

## Backup & Restore

### Automated Backup
```bash
./scripts/backup.sh
# Or: make backup
```

Creates timestamped backup: `./backups/noctura-YYYY-MM-DD-HHMMSS.tar.gz`

### Restore
```bash
./scripts/restore.sh ./backups/noctura-YYYY-MM-DD-HHMMSS.tar.gz
# Or: make restore
```

### Scheduled Backups
Add to crontab for daily backups at 2 AM:
```bash
0 2 * * * cd /path/to/noctura && ./scripts/backup.sh >> /var/log/noctura-backup.log 2>&1
```

## NextCloud Integration (Roadmap)

- Sync attachments to NextCloud storage
- WebDAV support for large files
- Shared vault collaboration

## Security Considerations

- **Encryption at Rest**: All database data encrypted with AES-256-GCM
- **Encryption in Flight**: TLS/HTTPS for all network communication
- **Secure Key Storage**: Encryption keys stored with 600 permissions
- **Automatic SSL**: Let's Encrypt certificates in production mode
- **Network Isolation**: Internal services not directly exposed
- **Reverse Proxy**: Caddy handles all external access
- **Credential Security**: Auto-generated strong passwords

For detailed security information, see [docs/SECURITY.md](docs/SECURITY.md).

## Troubleshooting

### Health Check
```bash
./scripts/health-check.sh
# Or: make health
```

### Run Tests
```bash
./scripts/test.sh
# Or: make test
```

### Sync Conflicts
Check CouchDB conflicts UI in plugin settings, resolve manually.

### Connection Issues
```bash
docker compose logs couchdb
docker compose logs obsidian
docker compose logs caddy
docker compose logs gocryptfs
curl https://localhost/couchdb  # Should return: {"couchdb":"Welcome",...}
curl https://localhost/obsidian # Should return Obsidian web interface
```

### Database Corruption
Restore from backup or use CouchDB's built-in repair tools.

See [docs/COUCHDB_CONFIG.md](docs/COUCHDB_CONFIG.md) for advanced troubleshooting.

## Requirements

- Docker 20.10+
- Docker Compose 2.0+
- 1GB RAM minimum
- 10GB+ disk space (scales with vault size)

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `COUCHDB_USER` | `admin` | CouchDB admin username |
| `COUCHDB_PASSWORD` | (generated) | CouchDB admin password |
| `COUCHDB_DATABASE` | `noctura` | Database name for sync |
| `VAULT_NAME` | `noctura` | Obsidian vault name |
| `OBSIDIAN_VAULTS_DIR` | `./vaults` | Vaults persistence path |
| `VNC_PASSWORD` | (generated) | VNC access password |
| `ENCRYPTION_KEY` | (generated) | 32-byte encryption key |
| `ENCRYPTION_KEY_FILE` | `./data/secrets/encryption_key` | Path to encryption key file |
| `ENCRYPTED_DATA_DIR` | `./data/encrypted` | Encrypted data storage |
| `ENVIRONMENT` | `dev` | Deployment mode: `dev` or `production` |
| `DOMAIN` | `localhost` | Domain for production TLS |
| `TLS_EMAIL` | - | Email for Let's Encrypt certificates |
| `HTTP_PORT` | `80` | HTTP port (redirects to HTTPS) |
| `HTTPS_PORT` | `443` | HTTPS port |
| `CADDY_LOG_DIR` | `./data/logs/caddy` | Caddy logs directory |

### Advanced Options

See example configurations in `config/`:
- `local.ini.example` - Standard configuration
- `performance.ini.example` - Optimized settings

Apply custom config:
```bash
cp config/performance.ini.example data/config/local.ini
docker compose restart couchdb
```

Edit `docker-compose.yml` to customize:
- Network configuration
- Resource limits
- Additional services

## Management Commands

### Using Make (Recommended)

```bash
make setup      # Initial setup
make start      # Start services
make stop       # Stop services
make restart    # Restart services
make logs       # View logs
make status     # Show service status
make health     # Run health checks
make test       # Run integration tests
make backup     # Create backup
make restore    # Restore from backup
make build      # Build all containers
make validate   # Validate configuration files
make init-encryption  # Initialize encryption key
```

### Using Scripts Directly

```bash
./scripts/setup.sh         # Initial setup
./scripts/init-db.sh       # Initialize database
./scripts/backup.sh        # Create backup
./scripts/restore.sh       # Restore backup
./scripts/health-check.sh  # Health check
./scripts/test.sh          # Integration tests
```

### Using Docker Compose

```bash
docker compose up -d       # Start services
docker compose down        # Stop services
docker compose logs -f     # View logs
docker compose ps          # List services
docker compose restart     # Restart services
```

## Performance Tuning

Use the performance configuration template:
```bash
cp config/performance.ini.example data/config/local.ini
docker compose restart couchdb
```

Key optimizations:
- Increase `max_dbs_open` for large vaults (1000+)
- Enable Snappy compression
- Use SSD storage for data directory
- Configure automatic compaction schedules
- Adjust request size limits for attachments

See [docs/COUCHDB_CONFIG.md](docs/COUCHDB_CONFIG.md) for detailed tuning options.

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Areas needing help:
- NextCloud integration
- Multi-platform testing
- Performance optimization
- Documentation improvements

## Testing

The project includes comprehensive test coverage with **20 automated tests**:

### Test Categories

1. **Encryption Tests** (3 tests)
   - Encryption key file existence
   - Key file permissions (600)
   - Key size validation (≥32 bytes)

2. **Gocryptfs Container** (2 tests)
   - Container running status
   - Encrypted mount point validation

3. **TLS/HTTPS Tests** (4 tests)
   - Caddy reverse proxy health
   - HTTP to HTTPS redirect
   - HTTPS endpoint accessibility
   - TLS certificate validation

4. **CouchDB Tests** (5 tests)
   - CouchDB via reverse proxy
   - Authentication
   - Database creation
   - Document creation/retrieval
   - Database cleanup

5. **Obsidian Tests** (2 tests)
   - Container running status
   - Web interface via HTTPS

6. **Script Tests** (4 tests)
   - Backup script validation
   - Restore script validation
   - Health check script
   - Encryption init script

7. **Configuration Tests** (2 tests)
   - Docker Compose validation
   - .env file permissions (600)

### Running Tests

```bash
make test              # Run all tests
./scripts/test.sh      # Direct script execution
./scripts/health-check.sh  # Health checks only
```

### CI/CD

GitHub Actions automatically runs all tests on push/PR:
- **Shellcheck**: Validates shell script quality
- **Docker validation**: Ensures compose file is valid
- **Build tests**: Verifies container builds
- **Integration tests**: Full system testing (20 tests)
- **Markdown lint**: Documentation quality

View test results: [![CI](https://github.com/RecursiveHook/noctura/actions/workflows/ci.yml/badge.svg)](https://github.com/RecursiveHook/noctura/actions/workflows/ci.yml)

## License

MIT License - See LICENSE file

## Acknowledgments

- [Obsidian](https://obsidian.md) - Knowledge base application
- [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) - Plugin by vrtmrz
- [CouchDB](https://couchdb.apache.org) - Database backend

## Support

- Issues: GitHub Issues
- Documentation: [Wiki](../../wiki)
- Community: Discord/Reddit

---

**Status**: 🚧 In Development - Core sync working, NextCloud integration planned
