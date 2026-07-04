#!/usr/bin/env bash
# First-time production setup on a clean Ubuntu server.
# Run as a normal user with sudo (and docker group after install).
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/R1M1R/ERA.git}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/ERA}"
USE_OCI_PROFILE=false

while [ $# -gt 0 ]; do
  case "$1" in
    --oci) USE_OCI_PROFILE=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--oci]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

COMPOSE_ARGS=(--env-file .env -f backend/production.docker-compose.yml)
if [ "$USE_OCI_PROFILE" = true ]; then
  COMPOSE_ARGS+=(-f deploy/oracle-cloud/compose.override.yml)
  echo "[ERA] Using Oracle Cloud resource profile (2 Gunicorn workers, Celery concurrency 1)."
fi

echo "[ERA] Checking Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "[ERA] Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo "[ERA] Docker installed. Log out and back in, then re-run this script."
  exit 0
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "[ERA] Docker Compose plugin is required."
  exit 1
fi

if [ ! -d "$INSTALL_DIR/.git" ]; then
  echo "[ERA] Cloning repository to $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

if [ ! -f .env ]; then
  cp .env.example .env
  echo ""
  echo "[ERA] Created .env from template. Edit it before continuing:"
  echo "  nano $INSTALL_DIR/.env"
  echo ""
  echo "Required: POSTGRES_PASSWORD, ERA_SERVER_SALT, OPENAI_API_KEY, CORS_ORIGINS"
  exit 1
fi

echo "[ERA] Building and starting production stack..."
docker compose "${COMPOSE_ARGS[@]}" up -d --build

echo "[ERA] Waiting for API health..."
for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null 2>&1; then
    curl -fsS http://127.0.0.1:8000/health
    echo ""
    echo "[ERA] Backend is up."
    echo "[ERA] Next: configure Nginx — see backend/README_DEPLOY.md section 6"
    exit 0
  fi
  sleep 2
done

echo "[ERA] API did not become healthy in time. Check logs:"
echo "  docker compose ${COMPOSE_ARGS[*]} logs api"
exit 1
