# Noctura - Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project scaffolding
- Docker Compose configuration for CouchDB 3.3
- Automated setup script with secure password generation
- Database initialization script with CORS configuration
- Comprehensive backup and restore scripts
- Health check script with detailed system validation
- Integration test suite for CouchDB operations
- Makefile for common operations
- GitHub Actions CI/CD workflows:
  - Shellcheck validation
  - Docker Compose validation
  - Integration tests
  - Multi-platform Docker image testing
  - Automated releases
- Example CouchDB configuration files (standard and performance)
- Comprehensive documentation:
  - Main README with quick start guide
  - Obsidian setup guide
  - CouchDB configuration guide
  - NextCloud integration roadmap
  - Project structure documentation
  - Contributing guidelines
  - Security policy
- Development configuration:
  - .shellcheckrc for script linting
  - .markdownlint.json for docs
  - .gitattributes for consistent line endings
  - .gitignore for data/backups

### Features
- Self-hosted CouchDB for Obsidian LiveSync
- Zero-config setup with sensible defaults
- Automated secure credential generation
- Volume-based persistence for easy backups
- Health monitoring and testing utilities
- Multi-device sync support
- Platform agnostic (amd64/arm64)

### Security
- Strong password generation by default
- No credentials in version control
- Comprehensive security documentation
- Regular backup automation support

## [0.1.0] - Initial Release (Planned)

### Target Features
- Stable CouchDB deployment
- Tested backup/restore workflow
- Documentation complete
- CI/CD pipeline validated

---

For more details, see [GitHub Releases](https://github.com/yourusername/noctura/releases)
