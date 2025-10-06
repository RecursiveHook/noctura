# Quick Reference

## First-Time Setup

```bash
./scripts/setup.sh
# Or: make setup
```

## Daily Operations

| Task | Command |
|------|---------|
| Start services | `make start` or `docker compose up -d` |
| Stop services | `make stop` or `docker compose down` |
| View logs | `make logs` or `docker compose logs -f` |
| Check health | `make health` or `./scripts/health-check.sh` |
| Create backup | `make backup` or `./scripts/backup.sh` |
| Restore backup | `make restore` or `./scripts/restore.sh backup.tar.gz` |

## Obsidian Configuration

After setup completes, configure Self-hosted LiveSync plugin:

1. **Remote URL**: `http://localhost:5984/obsidian`
2. **Username**: Check `.env` file (default: `admin`)
3. **Password**: Check `.env` file (auto-generated)
4. **Database**: `obsidian`

For remote access, replace `localhost` with your server IP/domain.

## Troubleshooting

```bash
# Run diagnostics
make health

# Run integration tests
make test

# Check logs
docker compose logs couchdb

# Restart services
make restart
```

## File Locations

- **Configuration**: `.env`
- **Data**: `./data/couchdb/`
- **Backups**: `./backups/`
- **Logs**: `docker compose logs couchdb`

## Documentation

- [README.md](README.md) - Full documentation
- [docs/OBSIDIAN_SETUP.md](docs/OBSIDIAN_SETUP.md) - Obsidian configuration
- [docs/COUCHDB_CONFIG.md](docs/COUCHDB_CONFIG.md) - CouchDB tuning
- [SECURITY.md](SECURITY.md) - Security best practices

## Support

- Issues: [GitHub Issues](../../issues)
- Security: See [SECURITY.md](SECURITY.md)
- Contributing: See [CONTRIBUTING.md](CONTRIBUTING.md)
