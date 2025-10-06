# CouchDB Configuration Examples

This directory contains example CouchDB configuration files.

## Usage

1. Copy desired config to `data/config/`:
   ```bash
   cp config/local.ini.example data/config/local.ini
   ```

2. Restart CouchDB:
   ```bash
   docker compose restart couchdb
   ```

## Available Configurations

### local.ini.example
Standard configuration with sensible defaults:
- 500 max open databases
- CORS enabled for all origins
- 4GB max request size
- Auto-compaction at 70% fragmentation

### performance.ini.example
Optimized for performance:
- 1000 max open databases
- Snappy compression enabled
- 8GB max request size
- More aggressive compaction (60% threshold)
- Increased process limits

## Important Notes

- Custom configs in `data/config/` take precedence over defaults
- Restart required after any changes
- Use `docker compose logs couchdb` to check for errors
- Test changes before production use

## Security

For production environments, consider:
- Restricting CORS origins to your domain
- Enabling SSL/TLS via reverse proxy
- Adjusting max_http_request_size based on needs
- Setting appropriate log levels
