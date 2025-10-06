# Obsidian LiveSync Configuration Guide

This guide walks you through using Obsidian with your Noctura CouchDB instance.

## Quick Start (Containerized - Recommended)

The easiest way to get started is using the containerized Obsidian instance:

1. Run setup:
   ```bash
   ./scripts/setup.sh
   # Or: make setup
   ```

2. Access Obsidian via web browser:
   ```
   http://localhost:8080/vnc.html
   ```

3. Your vault is automatically initialized with:
   - Self-hosted LiveSync plugin installed and enabled
   - CouchDB connection pre-configured
   - Vault located at `./vaults/noctura` (persistent)

4. Start using Obsidian immediately - sync is already configured!

### Customizing the Container

Edit `.env` to customize:

```bash
VAULT_NAME=my-vault              # Change vault name
OBSIDIAN_WEB_PORT=8080          # Change web access port
OBSIDIAN_VNC_PORT=5900          # Change VNC port
VNC_PASSWORD=your-password      # Change VNC password
COUCHDB_DATABASE=my-database    # Change database name
```

Then restart:
```bash
docker compose restart obsidian
```

## Alternative: Local Desktop Client

If you prefer using your local Obsidian installation:

## Manual Setup Steps

### 1. Install Plugin

1. Open Obsidian Settings
2. Go to Community Plugins
3. Search for "Self-hosted LiveSync"
4. Install and Enable

### 2. Configure Remote Database

1. Open Self-hosted LiveSync settings
2. Under "Remote Database Configuration":
   - **URI**: `http://localhost:5984/obsidian` (or your server IP)
   - **Username**: From your `.env` file (default: `admin`)
   - **Password**: From your `.env` file
   - **Database name**: `obsidian` (or custom name)

### 3. Test Connection

Click "Test Database Connection" - should show success.

### 4. Initialize Database

1. Click "Create New Database"
2. Wait for confirmation
3. Set up encryption passphrase (optional but recommended)

### 5. Configure Sync Settings

Recommended settings:
- **Sync on Save**: Enabled
- **Sync on Start**: Enabled
- **Live Sync**: Enabled
- **Batch Size**: 50 (default)
- **Batch Limit**: 25 (default)

### 6. Perform Initial Sync

1. Click "Replicate Now"
2. Choose "Safe Replication"
3. Wait for initial upload to complete

## Multi-Device Setup

### Additional Containerized Instances

To run multiple Obsidian instances (e.g., on different servers), simply deploy Noctura on each server. All containers will sync to the same CouchDB database.

### Desktop/Laptop

Follow the local client setup above with same credentials.

### Mobile (iOS/Android)

1. Install Obsidian app
2. Install Self-hosted LiveSync plugin
3. Use same database URL and credentials
   - For remote access: `http://your-server-ip:5984/noctura`
   - Or domain: `https://sync.yourdomain.com/noctura`
4. Consider using HTTPS with reverse proxy for security

### Accessing Container from Multiple Locations

The containerized Obsidian web interface can be accessed from any device with a web browser:
- Same network: `http://localhost:8080/vnc.html`
- Remote (with port forward): `http://your-server-ip:8080/vnc.html`
- Remote (with reverse proxy): `https://obsidian.yourdomain.com/vnc.html`

## Remote Access

### Option 1: Direct Port Forwarding

Forward port 5984 on your router to your server.

**Warning**: Insecure - only use with strong passwords and trusted networks.

### Option 2: VPN (Recommended)

Set up Tailscale/WireGuard and access via private IP.

### Option 3: Reverse Proxy with HTTPS (Production)

Use Caddy or Traefik:

```yaml
# docker-compose.yml addition
caddy:
  image: caddy:latest
  ports:
    - "443:443"
  volumes:
    - ./Caddyfile:/etc/caddy/Caddyfile
    - caddy-data:/data
  networks:
    - noctura-net
```

```
# Caddyfile
sync.yourdomain.com {
    reverse_proxy couchdb:5984
}

obsidian.yourdomain.com {
    reverse_proxy obsidian:8080
}
```

Then use:
- CouchDB: `https://sync.yourdomain.com/noctura`
- Web UI: `https://obsidian.yourdomain.com/vnc.html`

## Troubleshooting

### Container Not Starting

```bash
# Check logs
docker compose logs obsidian

# Check if CouchDB is ready
docker compose ps

# Restart container
docker compose restart obsidian
```

### Web Interface Not Loading

- Wait 60 seconds after container start (initialization time)
- Check health: `curl http://localhost:8080`
- Verify port not in use: `netstat -tuln | grep 8080`

### Connection Failed (Local Client)

```bash
# Test CouchDB is accessible
curl http://localhost:5984

# Check logs
docker compose logs couchdb
```

### Sync Conflicts

1. Open LiveSync settings
2. Go to "Conflict Resolution"
3. Choose resolution strategy
4. Manually resolve in conflict view

### Database Corruption

```bash
# Restore from backup
./scripts/restore.sh ./backups/noctura-YYYY-MM-DD-HHMMSS.tar.gz
```

### Slow Sync

- Reduce batch size
- Increase batch limit
- Check network bandwidth
- Enable compression in CouchDB

## Advanced Configuration

### Custom Database Name

Multiple vaults can share one CouchDB instance with different database names:
- Vault 1: `obsidian-personal`
- Vault 2: `obsidian-work`

### Encryption

Enable end-to-end encryption in plugin settings. Remember your passphrase - it cannot be recovered.

### Selective Sync

Use `.syncignore` file in vault root to exclude files/folders.

## Security Best Practices

1. Use strong passwords (30+ characters)
2. Enable HTTPS for remote access
3. Use encryption passphrase
4. Regular backups (`./scripts/backup.sh`)
5. Restrict CouchDB port to localhost when not remote syncing
6. Consider VPN instead of public exposure

## Performance Tips

- Exclude large attachments from sync
- Use periodic compaction
- Monitor CouchDB disk usage
- Optimize sync frequency based on needs

## References

- [Self-hosted LiveSync Documentation](https://github.com/vrtmrz/obsidian-livesync)
- [CouchDB Documentation](https://docs.couchdb.org/)
