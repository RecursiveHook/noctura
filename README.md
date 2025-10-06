# Noctura

Turnkey containerized deployment for Obsidian with Self-Hosted LiveSync via CouchDB. Easy to deploy, manage, backup, and migrate your personal knowledge base.

## Features

- **Self-Hosted Sync**: CouchDB-powered LiveSync for complete data ownership
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
- Generate secure credentials
- Create necessary directories
- Start CouchDB and Obsidian containers
- Display connection information

Access Obsidian via web browser at `http://localhost:8080/vnc.html` or configure your local Obsidian client with the displayed credentials.

## Components

### CouchDB
- Default port: `5984`
- Admin interface: `http://localhost:5984/_utils`
- Data persistence: `./data/couchdb`

### Obsidian (Containerized)
- Web interface: `http://localhost:8080/vnc.html`
- VNC port: `5900`
- Vault persistence: `./vaults`
- Pre-configured with Self-hosted LiveSync plugin

### Configuration
- Default credentials in `.env` (created on first run)
- SSL/TLS support via reverse proxy (Caddy/Traefik)

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
nano .env  # Configure credentials
mkdir -p data/couchdb data/config backups
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

```
http://localhost:8080/vnc.html
```

The vault is automatically initialized with Self-hosted LiveSync plugin configured and connected to CouchDB.

**Optional VNC Password**: Set in `.env` (default: `noctura`)

#### Local Desktop Client

Alternatively, use your local Obsidian installation:

1. Install "Self-hosted LiveSync" plugin in Obsidian
2. Open plugin settings
3. Configure remote database:
   - URL: `http://your-server:5984/noctura`
   - Username/Password: From `.env`
4. Initialize sync and start syncing

See [docs/OBSIDIAN_SETUP.md](docs/OBSIDIAN_SETUP.md) for detailed instructions.

## Architecture

```
┌─────────────────────┐       ┌──────────────────┐
│  Obsidian Desktop   │       │ Obsidian Web UI  │
│   (Local Client)    │       │ (Container:8080) │
└──────────┬──────────┘       └────────┬─────────┘
           │                           │
      LiveSync Plugin             Auto-configured
           │                           │
           └───────────┬───────────────┘
                       ▼
              ┌─────────────────┐      ┌──────────────┐
              │    CouchDB      │◄────►│  NextCloud   │
              │  (Port 5984)    │      │  (Optional)  │
              └─────────────────┘      └──────────────┘
                       │
                       ▼
                ./data/couchdb
                (Docker Volume)
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

- Change default credentials immediately
- Use HTTPS/TLS in production (reverse proxy recommended)
- Restrict CouchDB port exposure (use firewall/VPN)
- Regular backup automation
- Consider database encryption at rest

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
curl http://localhost:5984  # Should return: {"couchdb":"Welcome",...}
curl http://localhost:8080  # Should return Obsidian web interface
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
| `COUCHDB_PORT` | `5984` | Exposed CouchDB port |
| `COUCHDB_DATA_DIR` | `./data/couchdb` | Data persistence path |
| `COUCHDB_DATABASE` | `noctura` | Database name for sync |
| `VAULT_NAME` | `noctura` | Obsidian vault name |
| `OBSIDIAN_WEB_PORT` | `8080` | Web interface port |
| `OBSIDIAN_VNC_PORT` | `5900` | VNC direct access port |
| `OBSIDIAN_VAULTS_DIR` | `./vaults` | Vaults persistence path |
| `VNC_PASSWORD` | `noctura` | VNC access password |

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
- Additional services (Caddy, Traefik)

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

The project includes comprehensive tests:

- **Shellcheck**: Validates shell script quality
- **Docker validation**: Ensures compose file is valid
- **Integration tests**: Full CouchDB CRUD operations
- **Health checks**: System validation

GitHub Actions automatically runs all tests on push/PR.

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
