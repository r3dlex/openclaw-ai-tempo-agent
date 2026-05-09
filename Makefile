# openclaw-ai-tempo-agent Makefile
.PHONY: up down logs shell build restart help

COMPOSE_FILE ?= docker-compose.yml

help:
	@echo "Usage: make [target]"
	@echo "  up       — Start agent"
	@echo "  down     — Stop agent"
	@echo "  logs     — Tail agent logs"
	@echo "  shell    — Open shell in agent container"
	@echo "  build    — Build Docker image"
	@echo "  restart  — Restart agent (down + up)"

up:
	docker-compose -f $(COMPOSE_FILE) up -d

down:
	docker-compose -f $(COMPOSE_FILE) down

logs:
	docker-compose -f $(COMPOSE_FILE) logs -f

shell:
	docker-compose -f $(COMPOSE_FILE) exec backend sh

build:
	docker-compose -f $(COMPOSE_FILE) build

restart: down up
