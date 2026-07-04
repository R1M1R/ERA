#!/usr/bin/env bash
# Run DB migrations before Celery worker starts (PaaS / Docker).
set -eu
python /app/backend/scripts/init_db.py
exec "$@"
