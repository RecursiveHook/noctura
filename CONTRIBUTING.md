# Contributing to Noctura

Thank you for considering contributing to Noctura!

## How to Contribute

### Reporting Issues

- Check existing issues first
- Provide detailed reproduction steps
- Include environment details (OS, Docker version)
- Attach relevant logs

### Feature Requests

- Describe the use case
- Explain why it's valuable
- Consider backward compatibility
- Check the roadmap first

### Pull Requests

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit PR with clear description

## Development Setup

```bash
git clone https://github.com/yourusername/noctura.git
cd noctura
cp .env.example .env
./scripts/setup.sh
```

## Testing

Before submitting:

```bash
docker compose down
docker compose up -d
docker compose logs -f
```

Test sync functionality with Obsidian.

## Code Style

- Shell scripts: Use shellcheck
- YAML: 2-space indentation
- Markdown: Use standard formatting
- Comments: Explain why, not what

## Documentation

Update relevant docs when changing:
- Configuration options
- Setup procedures
- API changes
- New features

## Commit Messages

Format: `type: description`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `chore`: Maintenance
- `refactor`: Code improvement

Examples:
```
feat: add automatic backup scheduling
fix: resolve CouchDB connection timeout
docs: improve NextCloud integration guide
```

## Areas Needing Help

- [ ] NextCloud integration
- [ ] Automated testing
- [ ] Performance optimization
- [ ] Multi-architecture support
- [ ] Documentation improvements
- [ ] Security hardening

## Community

- Discussions: GitHub Discussions
- Issues: GitHub Issues
- Security: See SECURITY.md

## License

By contributing, you agree to license your contributions under the MIT License.
