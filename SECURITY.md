# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in Noctura, please report it responsibly:

1. **Do NOT** open a public GitHub issue
2. Email security concerns to the maintainers (see GitHub profile)
3. Include detailed steps to reproduce
4. Allow time for a fix before public disclosure

## Security Best Practices

When deploying Noctura:

### 1. Credentials
- Never commit `.env` to version control
- Use strong passwords (30+ characters)
- Rotate passwords periodically
- Don't share credentials across environments

### 2. Network Security
- Use HTTPS/TLS for remote access (reverse proxy required)
- Restrict CouchDB port exposure with firewall rules
- Consider VPN for remote access instead of public exposure
- Don't expose port 5984 directly to the internet

### 3. Data Protection
- Enable encryption passphrase in Obsidian LiveSync plugin
- Regular backups with `./scripts/backup.sh`
- Store backups securely and separately from production
- Test restore procedures regularly

### 4. CouchDB Hardening
- Keep CouchDB updated (latest 3.3.x)
- Restrict CORS origins in production (not `*`)
- Review and limit database permissions
- Enable audit logging for production environments

### 5. Container Security
- Keep Docker/Docker Compose updated
- Review and limit container resource usage
- Use read-only file systems where possible
- Scan images for vulnerabilities

### 6. Monitoring
- Run `./scripts/health-check.sh` regularly
- Monitor disk usage and set alerts
- Review CouchDB logs periodically
- Set up automated backup verification

## Known Limitations

- Default configuration uses HTTP (not HTTPS)
  - **Solution**: Use reverse proxy (Caddy/Traefik/Nginx)
- CORS enabled for all origins by default
  - **Solution**: Restrict in production (see docs/COUCHDB_CONFIG.md)
- No built-in authentication beyond CouchDB credentials
  - **Solution**: Use VPN or reverse proxy with additional auth

## Updates

Security updates will be announced via:
- GitHub Security Advisories
- Release notes
- README warnings

Subscribe to repository notifications for security updates.
