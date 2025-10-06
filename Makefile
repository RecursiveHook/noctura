.PHONY: help setup start stop restart logs status backup restore test health clean install-obsidian show-access init-encryption build validate

help:
	@echo "Noctura - Obsidian LiveSync with CouchDB"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup            - Initial setup (creates .env, directories, starts services)"
	@echo "  make init-encryption  - Initialize encryption key"
	@echo "  make install-obsidian - Install Obsidian and configure LiveSync plugin"
	@echo "  make build            - Build all containers"
	@echo "  make start            - Start all services"
	@echo "  make stop             - Stop all services"
	@echo "  make restart          - Restart all services"
	@echo "  make logs             - View logs (Ctrl+C to exit)"
	@echo "  make status           - Show service status"
	@echo "  make health           - Run health checks"
	@echo "  make show-access      - Display access URLs and connection info"
	@echo "  make validate         - Validate configuration and scripts"
	@echo "  make test             - Run integration tests"
	@echo "  make backup           - Create backup"
	@echo "  make restore          - Restore from backup (prompts for file)"
	@echo "  make clean            - Stop services and remove containers (keeps data)"
	@echo "  make clean-all        - Remove everything including data (DANGEROUS)"
	@echo ""

setup:
	@./scripts/setup.sh

init-encryption:
	@./scripts/init-encryption.sh

install-obsidian:
	@./scripts/install-obsidian.sh

build:
	@echo "Building containers..."
	@docker compose build
	@echo "✅ Build complete"

start:
	@echo "Starting services..."
	@docker compose up -d
	@echo "✅ Services started"

stop:
	@echo "Stopping services..."
	@docker compose down
	@echo "✅ Services stopped"

restart:
	@echo "Restarting services..."
	@docker compose restart
	@echo "✅ Services restarted"

logs:
	@docker compose logs -f

status:
	@docker compose ps

health:
	@./scripts/health-check.sh

validate:
	@echo "Validating configuration and scripts..."
	@docker compose config > /dev/null && echo "✅ docker-compose.yml is valid" || echo "❌ docker-compose.yml is invalid"
	@command -v shellcheck > /dev/null && shellcheck scripts/*.sh && echo "✅ Shell scripts are valid" || echo "⚠️  shellcheck not installed"
	@echo "✅ Validation complete"

test:
	@./scripts/test.sh

backup:
	@./scripts/backup.sh

restore:
	@./scripts/restore.sh

clean:
	@echo "Stopping and removing containers..."
	@docker compose down
	@echo "✅ Cleanup complete (data preserved)"

clean-all:
	@echo "⚠️  WARNING: This will delete all data!"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	@docker compose down -v
	@rm -rf data/encrypted/* data/config/* data/secrets/* vaults/* backups/*
	@echo "✅ All data removed"

show-access:
	@./scripts/show-access.sh
