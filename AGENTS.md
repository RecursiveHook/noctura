# Agent Guidelines for Noctura

## Build/Test Commands
- **Run all tests**: `make test` or `./scripts/test.sh`
- **Run health check**: `make health` or `./scripts/health-check.sh`
- **Validate scripts**: `shellcheck scripts/*.sh`
- **Validate compose**: `docker compose config`
- **Lint markdown**: Uses markdownlint (see `.markdownlint.json`)

## Code Style

### Shell Scripts
- Use `set -euo pipefail` at script start
- Use shellcheck (config: `.shellcheckrc` disables SC2312, enables all)
- Get script dir: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- Use error messages with emoji: `echo "❌ Error: message"`, success: `echo "✅ message"`
- Validate dependencies exist before running (e.g., check docker, .env file)
- Use `${VAR:-default}` for environment variables with defaults
- Quote all variable expansions: `"$VAR"` not `$VAR`

### YAML/Docker
- Use 2-space indentation
- Follow docker-compose.yml conventions: healthchecks, restart policies, named networks

### Commit Messages
Format: `type: description` (types: feat, fix, docs, chore, refactor)
