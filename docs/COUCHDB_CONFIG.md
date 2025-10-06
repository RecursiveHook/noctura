# CouchDB Configuration

Advanced CouchDB configuration options for Noctura.

## Environment Variables

Edit `.env` to configure:

```bash
COUCHDB_USER=admin
COUCHDB_PASSWORD=your_secure_password
COUCHDB_PORT=5984
COUCHDB_DATA_DIR=./data/couchdb
COUCHDB_CONFIG_DIR=./data/config
```

## Custom Configuration

Create custom config in `./data/config/local.ini`:

```ini
[couchdb]
max_dbs_open = 500
delayed_commits = false

[chttpd]
max_http_request_size = 4294967296

[httpd]
enable_cors = true

[cors]
origins = *
credentials = true
headers = accept, authorization, content-type, origin, referer
methods = GET, PUT, POST, HEAD, DELETE
```

Restart after changes:
```bash
docker compose restart couchdb
```

## Performance Tuning

### Increase Max Open Databases

```ini
[couchdb]
max_dbs_open = 1000
```

### Enable Compression

```ini
[couchdb]
file_compression = snappy
```

### Adjust Request Size

For large attachments:
```ini
[chttpd]
max_http_request_size = 8589934592
```

## Database Compaction

Compact databases to reclaim disk space:

```bash
curl -X POST http://admin:password@localhost:5984/obsidian/_compact \
     -H "Content-Type: application/json"
```

Automatic compaction:
```ini
[compactions]
_default = [{db_fragmentation, "70%"}, {view_fragmentation, "60%"}]
```

## Security Hardening

### Disable Admin Party

Ensure admin user is set (done automatically by setup script).

### Restrict CORS

```ini
[cors]
origins = https://yourdomain.com
```

### Enable SSL/TLS

Use reverse proxy (Caddy/Nginx) instead of CouchDB native SSL for easier management.

## Monitoring

### Health Check

```bash
curl http://localhost:5984/_up
```

### Active Tasks

```bash
curl http://admin:password@localhost:5984/_active_tasks
```

### Database Info

```bash
curl http://admin:password@localhost:5984/obsidian
```

## Backup Configuration

Backup includes both data and config:

```bash
./scripts/backup.sh
```

Manual config backup:
```bash
tar czf config-backup.tar.gz ./data/config
```

## Multi-User Setup

CouchDB supports multiple databases for different users/vaults:

1. Create per-user databases
2. Set per-database permissions
3. Each user uses different database name in Obsidian

```bash
curl -X PUT http://admin:password@localhost:5984/obsidian-alice
curl -X PUT http://admin:password@localhost:5984/obsidian-bob
```

## Resource Limits

Edit `docker-compose.yml`:

```yaml
services:
  couchdb:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          memory: 512M
```

## Logging

View logs:
```bash
docker compose logs -f couchdb
```

Adjust log level in config:
```ini
[log]
level = info
```

## Troubleshooting

### Database Locked

```bash
docker compose restart couchdb
```

### Port Already in Use

Change `COUCHDB_PORT` in `.env` to different port.

### Disk Space Issues

1. Check disk usage: `du -sh ./data/couchdb`
2. Run compaction
3. Clean old backups

### Permission Errors

```bash
sudo chown -R 5984:5984 ./data/couchdb
docker compose restart couchdb
```

## Migration

### Export Database

```bash
curl -X GET http://admin:password@localhost:5984/obsidian/_all_docs?include_docs=true > export.json
```

### Import Database

```bash
curl -X POST http://admin:password@localhost:5984/obsidian/_bulk_docs \
     -H "Content-Type: application/json" \
     -d @export.json
```

## References

- [CouchDB Configuration Docs](https://docs.couchdb.org/en/stable/config/index.html)
- [Performance Best Practices](https://docs.couchdb.org/en/stable/best-practices/index.html)
