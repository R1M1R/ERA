.PHONY: dev-infra dev-api dev-worker dev-frontend build-frontend prod-config prod-up prod-config-oci

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
export PYTHONPATH := $(ROOT)

COMPOSE_OCI := -f backend/production.docker-compose.yml -f deploy/oracle-cloud/compose.override.yml

dev-infra:
	docker compose --env-file $(ROOT)/.env up -d postgres redis

dev-api:
	cd backend && ./venv/bin/uvicorn main:app --reload --host 127.0.0.1 --port 8000

dev-worker:
	celery -A worker.celery_app worker --loglevel=info

dev-frontend:
	cd frontend && npm run dev

build-frontend:
	cd frontend && VITE_API_URL=$(VITE_API_URL) npm run build

prod-config:
	docker compose --env-file $(ROOT)/.env -f backend/production.docker-compose.yml config

prod-up:
	docker compose --env-file $(ROOT)/.env -f backend/production.docker-compose.yml up -d --build

prod-config-oci:
	docker compose --env-file $(ROOT)/.env $(COMPOSE_OCI) config
