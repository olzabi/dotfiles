COMPOSE ?= podman compose
ENGINE  ?= podman

-include .env
export

POSTGRES_USER ?= postgres
POSTGRES_DB   ?= dev
MYSQL_ROOT_PASSWORD ?= rootsecret
MYSQL_USER    ?= admin
MYSQL_PASSWORD ?= secret
MYSQL_DB      ?= dev
BACKUP_DIR    ?= backups
STAMP         := $(shell date +%Y%m%d_%H%M%S)

.DEFAULT_GOAL := help
.PHONY: help up-% down-% down logs logs-% ps health shell-postgres shell-mysql \
        backup-postgres backup-mysql restore-postgres restore-mysql volumes pull update

help: ## Show this help
	@grep -hE '^[a-zA-Z_%-]+:.*## ' $(MAKEFILE_LIST) | \
	  awk -F':.*## ' '{printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

up-%: ## Start a profile: up-postgres | up-mysql | up-searxng | up-sql | up-all
	$(COMPOSE) --profile $* up -d

down-%: ## Stop one service: down-postgres | down-mysql | down-searxng
	$(COMPOSE) stop $*

down: ## Stop and remove all containers (volumes are kept)
	$(COMPOSE) --profile all down

logs: ## Follow logs of everything
	$(COMPOSE) --profile all logs -f

logs-%: ## Follow logs of one service
	$(COMPOSE) logs -f $*

ps: ## List containers
	$(COMPOSE) --profile all ps

health: ## Show container health
	@$(ENGINE) ps --filter label=io.podman.compose.project=infra \
	  --format '{{.Names}}\t{{.Status}}' || true

shell-postgres: ## psql shell
	$(COMPOSE) exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

shell-mysql: ## mysql shell
	$(COMPOSE) exec -e MYSQL_PWD=$(MYSQL_PASSWORD) mysql mysql -u$(MYSQL_USER) $(MYSQL_DB)

backup-postgres: ## Dump Postgres to backups/
	@mkdir -p $(BACKUP_DIR)
	$(COMPOSE) exec -T postgres pg_dump -U $(POSTGRES_USER) $(POSTGRES_DB) > $(BACKUP_DIR)/postgres_$(STAMP).sql
	@echo "→ $(BACKUP_DIR)/postgres_$(STAMP).sql"

backup-mysql: ## Dump MySQL to backups/
	@mkdir -p $(BACKUP_DIR)
	$(COMPOSE) exec -T -e MYSQL_PWD=$(MYSQL_ROOT_PASSWORD) mysql \
	  mysqldump -uroot --single-transaction $(MYSQL_DB) > $(BACKUP_DIR)/mysql_$(STAMP).sql
	@echo "→ $(BACKUP_DIR)/mysql_$(STAMP).sql"

restore-postgres: ## Restore: make restore-postgres FILE=backups/x.sql
	@test -n "$(FILE)" || { echo "usage: make $@ FILE=path.sql"; exit 1; }
	$(COMPOSE) exec -T postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) < $(FILE)

restore-mysql: ## Restore: make restore-mysql FILE=backups/x.sql
	@test -n "$(FILE)" || { echo "usage: make $@ FILE=path.sql"; exit 1; }
	$(COMPOSE) exec -T -e MYSQL_PWD=$(MYSQL_ROOT_PASSWORD) mysql mysql -uroot $(MYSQL_DB) < $(FILE)

volumes: ## List project volumes
	$(ENGINE) volume ls --filter name=infra_

pull: ## Pull latest images
	$(COMPOSE) --profile all pull

update: pull ## Pull and recreate running services
	$(COMPOSE) up -d
