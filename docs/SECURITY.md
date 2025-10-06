# Security Guide

This document describes the security features implemented in Noctura and best practices for secure deployment.

## Overview

Noctura implements multiple layers of security:

1. **Encryption at Rest**: Database files encrypted using gocryptfs
2. **Encryption in Flight**: TLS/HTTPS for all network traffic
3. **Secure Credentials**: Auto-generated strong passwords
4. **Access Control**: Password-protected VNC and database access

## Encryption at Rest

### How It Works

Noctura uses [gocryptfs](https://nuetzlich.net/gocryptfs/) to encrypt the CouchDB database files at rest. This provides transparent, per-file encryption with authenticated encryption (GCM).

- **Algorithm**: AES-256-GCM
- **Key Derivation**: scrypt with secure parameters
- **File Name Encryption**: Yes (secure by default)

### Key Management

The encryption key is:

- Generated automatically during setup (32 bytes, base64 encoded)
- Stored in `data/secrets/encryption_key` with 600 permissions
- Required for mounting the encrypted filesystem

**CRITICAL**: Without this key, your data cannot be recovered. Store it securely:

```bash
cp data/secrets/encryption_key ~/secure-backup-location/
chmod 400 ~/secure-backup-location/encryption_key
```

### Directory Structure

```
data/
├── encrypted/          # Encrypted data (safe to backup)
│   └── gocryptfs.conf  # Encryption metadata
├── secrets/
│   └── encryption_key  # NEVER backup with encrypted data
└── config/             # CouchDB config (unencrypted)
```

## Encryption in Flight (TLS/HTTPS)

### Development Mode

In development mode (`ENVIRONMENT=dev`), Caddy generates self-signed certificates:

- **Certificate**: Automatically generated on first run
- **Access**: `https://localhost:443`
- **Warning**: Browsers will show security warnings (expected)

### Production Mode

In production mode (`ENVIRONMENT=production`), Caddy automatically obtains Let's Encrypt certificates:

- **Requirements**:
  - Valid domain name pointing to your server
  - Ports 80 and 443 accessible from the internet
  - Valid email address in `TLS_EMAIL`

- **Automatic**: Certificates obtained and renewed automatically
- **Rate Limits**: Let's Encrypt has rate limits, test with staging first

#### Setup for Production

1. Set environment variables in `.env`:

   ```bash
   ENVIRONMENT=production
   DOMAIN=noctura.example.com
   TLS_EMAIL=admin@example.com
   ```

2. Ensure DNS points to your server:

   ```bash
   dig noctura.example.com
   ```

3. Start services:

   ```bash
   ./scripts/setup.sh
   ```

### Supported TLS Versions

- **TLS 1.2**: Supported (minimum)
- **TLS 1.3**: Supported (preferred)
- **TLS 1.0/1.1**: Disabled (insecure)

## Password Security

### Auto-Generated Passwords

During initial setup, three passwords are generated:

1. **CouchDB Password**: Database authentication
2. **VNC Password**: Remote desktop access
3. **Encryption Key**: Filesystem encryption

Each password is:

- 32 characters long
- Generated from cryptographically secure random data
- Base64 encoded (alphanumeric + special chars)

### Password Storage

Passwords are stored in `.env` with 600 permissions:

```bash
ls -l .env
# Expected: -rw------- 1 user user 512 Oct 6 12:00 .env
```

### Password Regeneration

To regenerate passwords:

```bash
rm .env
./scripts/setup.sh
```

**WARNING**: This will break access to existing encrypted data. Only do this for fresh installations.

## Network Security

### Port Configuration

By default, only Caddy ports are exposed:

- **Port 80**: HTTP (redirects to HTTPS)
- **Port 443**: HTTPS (all services)

Internal services are NOT directly exposed:

- CouchDB (5984): Only accessible via Caddy reverse proxy
- Obsidian Web (8080): Only accessible via Caddy reverse proxy
- VNC (5900): Only accessible via Caddy reverse proxy

### Reverse Proxy Benefits

All traffic flows through Caddy, providing:

- Centralized TLS termination
- Request logging
- Rate limiting (can be configured)
- Header manipulation
- Access control (can be configured)

### URL Structure

```
https://your-domain/couchdb/*  → CouchDB
https://your-domain/obsidian/* → Obsidian Web Interface
https://your-domain/vnc/*      → VNC noVNC Interface
```

## Backup Security

### What to Backup

**DO backup**:

- `data/encrypted/` - Your encrypted database
- `data/config/` - CouchDB configuration
- `vaults/` - Obsidian vault files

**DO NOT backup together with encrypted data**:

- `data/secrets/encryption_key` - Store separately!
- `.env` - Contains all passwords

### Backup Strategy

1. **Encrypted Data**: Can be safely backed up anywhere

   ```bash
   tar -czf backup-$(date +%Y%m%d).tar.gz data/encrypted/ data/config/ vaults/
   ```

2. **Encryption Key**: Store in a separate, secure location

   ```bash
   cp data/secrets/encryption_key ~/secure-location/
   ```

3. **Verify Backups**: Regularly test restoration

   ```bash
   ./scripts/backup.sh
   ```

### Backup Encryption

For additional security, encrypt your backups:

```bash
tar -czf - data/encrypted/ | gpg -c > backup-$(date +%Y%m%d).tar.gz.gpg
```

## Security Best Practices

### 1. System Updates

Keep your system and Docker updated:

```bash
apt update && apt upgrade
docker compose pull
docker compose up -d
```

### 2. Firewall Configuration

Use a firewall to restrict access:

```bash
# UFW example
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow ssh
ufw enable
```

### 3. SSH Hardening

If running on a server:

- Disable password authentication
- Use SSH keys only
- Change default SSH port
- Use fail2ban

### 4. Monitoring

Monitor your system:

```bash
./scripts/health-check.sh
docker compose logs -f
```

### 5. Regular Backups

Automate backups with cron:

```bash
0 2 * * * cd /path/to/noctura && ./scripts/backup.sh
```

### 6. Access Control

For production deployments, consider adding:

- HTTP Basic Authentication via Caddy
- IP whitelist for admin interfaces
- VPN for remote access

Example Caddy auth:

```caddyfile
https://your-domain {
  basicauth /couchdb/* {
    admin $2a$14$hashed_password
  }
}
```

## Threat Model

### What Noctura Protects Against

✅ **Data at rest compromise**: Encrypted storage  
✅ **Network eavesdropping**: TLS encryption  
✅ **Unauthorized access**: Password protection  
✅ **Backup exposure**: Encrypted database files  

### What Noctura Does NOT Protect Against

❌ **Compromised host system**: Full root access bypasses encryption  
❌ **Memory dumps**: Decrypted data in memory  
❌ **Keyloggers**: Password capture  
❌ **Social engineering**: User credential theft  
❌ **Zero-day exploits**: In Docker, Caddy, CouchDB, etc.

### Additional Hardening

For high-security environments, consider:

- Full disk encryption (LUKS)
- AppArmor/SELinux profiles
- Container runtime security (gVisor, Kata)
- Network segmentation
- Intrusion detection (Wazuh, OSSEC)

## Security Updates

Monitor security advisories for:

- [CouchDB](https://couchdb.apache.org/)
- [Caddy](https://caddyserver.com/)
- [Obsidian](https://obsidian.md/)
- [gocryptfs](https://github.com/rfjakob/gocryptfs)

## Reporting Security Issues

If you discover a security vulnerability, please:

1. **DO NOT** open a public issue
2. Email the maintainer directly
3. Include detailed reproduction steps
4. Allow time for a fix before disclosure

## Compliance

### Data Protection

Noctura's encryption features help meet requirements for:

- **GDPR**: Data encryption at rest and in transit
- **HIPAA**: Technical safeguards for ePHI
- **PCI DSS**: Encryption of cardholder data

**Note**: Compliance requires more than just encryption. Consult with your compliance officer.

## References

- [gocryptfs Documentation](https://nuetzlich.net/gocryptfs/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Let's Encrypt Best Practices](https://letsencrypt.org/docs/)
- [CouchDB Security](https://docs.couchdb.org/en/stable/intro/security.html)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
