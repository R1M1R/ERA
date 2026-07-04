#!/bin/sh
set -eu

echo "Applying database schema..."
python /app/backend/scripts/init_db.py

echo "Starting API server..."
exec "$@"
