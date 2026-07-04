FROM python:3.12-slim

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq5 \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

COPY backend /app/backend
COPY worker /app/worker

ENV PYTHONPATH=/app
WORKDIR /app

RUN chmod +x /app/worker/docker-entrypoint.sh

ENTRYPOINT ["/app/worker/docker-entrypoint.sh"]
CMD ["celery", "-A", "worker.celery_app", "worker", "--loglevel=info", "--concurrency=1"]
