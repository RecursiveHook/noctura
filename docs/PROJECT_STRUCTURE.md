# Noctura Project Structure

```
noctura/
├── README.md                      # Main documentation
├── LICENSE                        # MIT License
├── CONTRIBUTING.md                # Contribution guidelines
├── docker-compose.yml             # Docker services configuration
├── .env.example                   # Environment template
├── .gitignore                     # Git ignore rules
│
├── scripts/                       # Utility scripts
│   ├── setup.sh                   # Initial setup automation
│   ├── backup.sh                  # Backup creation
│   └── restore.sh                 # Backup restoration
│
├── data/                          # Persistent data (git-ignored)
│   ├── couchdb/                   # CouchDB database files
│   └── config/                    # CouchDB configuration
│
├── backups/                       # Backup archives (git-ignored)
│
└── docs/                          # Documentation
    ├── OBSIDIAN_SETUP.md          # Obsidian plugin configuration
    ├── COUCHDB_CONFIG.md          # CouchDB tuning guide
    └── NEXTCLOUD_INTEGRATION.md   # Future NextCloud plans
```

## Key Files

### docker-compose.yml
Defines CouchDB service with health checks, volume mounts, and network configuration.

### .env
Contains sensitive configuration (passwords, ports). Created from `.env.example` during setup.

### scripts/setup.sh
Automated setup that:
- Generates secure credentials
- Creates directories
- Starts services
- Validates health

### scripts/backup.sh
Creates timestamped backups of data and configuration.

### scripts/restore.sh
Restores from backup with safety confirmation.

## Data Persistence

All data stored in `./data/`:
- `data/couchdb/` - Database files
- `data/config/` - CouchDB configuration

Backups stored in `./backups/`:
- Named: `noctura-YYYY-MM-DD-HHMMSS.tar.gz`
- Contains data directory and .env file

## Quick Commands

```bash
./scripts/setup.sh              # First-time setup
docker compose up -d            # Start services
docker compose logs -f          # View logs
docker compose restart          # Restart services
docker compose down             # Stop services
./scripts/backup.sh             # Create backup
./scripts/restore.sh backup.tar.gz  # Restore backup
```
