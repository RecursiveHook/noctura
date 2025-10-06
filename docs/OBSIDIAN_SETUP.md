# Obsidian LiveSync Configuration Guide

This guide walks you through configuring Obsidian's Self-hosted LiveSync plugin with your Noctura CouchDB instance.

## Prerequisites

- Noctura running (`docker compose up -d`)
- Obsidian installed on your device
- Self-hosted LiveSync plugin installed

## Setup Steps

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

### Desktop/Laptop

Repeat steps above with same credentials.

### Mobile (iOS/Android)

1. Install Obsidian app
2. Install Self-hosted LiveSync plugin
3. Use same database URL and credentials
4. For remote access, use your server's public IP or domain
5. Consider using HTTPS with reverse proxy for security

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
```

```
# Caddyfile
sync.yourdomain.com {
    reverse_proxy couchdb:5984
}
```

Then use `https://sync.yourdomain.com/obsidian` as URI.

## Troubleshooting

### Connection Failed

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
