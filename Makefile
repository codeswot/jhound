.PHONY: help build up down restart logs ps test test-verbose test-in-docker clean-cache db-shell shell reload-workflows reset-bootstrap setup-metabase

help:
	@echo "jHound — make targets:"
	@echo ""
	@echo "  build               Build the custom n8n image (Python + Node deps baked in)"
	@echo "  up                  docker compose up -d (auto-builds on first run)"
	@echo "  down                Stop & remove containers (volumes survive)"
	@echo "  restart             Restart the n8n service"
	@echo "  logs                Tail n8n logs"
	@echo "  ps                  Show service status"
	@echo ""
	@echo "  test                Run integration tests locally (creates .venv-test)"
	@echo "  test-verbose        Same with verbose output"
	@echo "  test-in-docker      Run tests inside the running n8n container"
	@echo ""
	@echo "  setup-metabase      Auto-add jhound Postgres datasource (idempotent)"
	@echo "  reload-workflows    Re-import + re-activate workflows from disk (after editing JSON)"
	@echo "  reset-bootstrap     Reset bootstrap flag — next restart will re-import workflows"
	@echo "  db-shell            psql into the Postgres container"
	@echo "  shell               sh into the n8n container"
	@echo "  clean-cache         Clear __pycache__ + redis hunter counters"

build:
	docker compose build n8n

up:
	docker compose up -d --build
	@sleep 5
	@$(MAKE) setup-metabase

down:
	docker compose down

restart:
	docker compose restart n8n

logs:
	docker compose logs -f n8n

ps:
	docker compose ps

.venv-test:
	python3 -m venv .venv-test
	.venv-test/bin/pip install --quiet requests beautifulsoup4 lxml psycopg2-binary redis

test: .venv-test
	.venv-test/bin/python tests/test_pipeline.py

test-verbose: .venv-test
	.venv-test/bin/python tests/test_pipeline.py --verbose

test-in-docker:
	docker exec -i jHound-n8n python3 /home/node/tests/test_pipeline.py

reload-workflows:
	docker exec -it jHound-n8n sh -c 'n8n import:workflow --separate --input=/home/node/workflows && n8n update:workflow --all --active=true'

reset-bootstrap:
	docker exec -it jHound-n8n sh -c 'rm -f /home/node/.n8n/.jhound-bootstrap-done'
	@echo "Bootstrap flag cleared — next 'make restart' will re-import workflows"

db-shell:
	docker exec -it jHound-postgres psql -U jhound -d jhound

shell:
	docker exec -it jHound-n8n sh

setup-metabase:
	docker exec -i jHound-n8n python3 /home/node/scripts/metabase_setup.py

clean-cache:
	find . -name '__pycache__' -type d -not -path './.venv-test/*' -exec rm -rf {} + 2>/dev/null || true
	docker exec -i jHound-redis sh -c 'redis-cli --scan --pattern "hunter_*" | xargs -r redis-cli DEL' 2>/dev/null || true
