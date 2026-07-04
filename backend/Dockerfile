FROM python:3.14-slim

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq5 \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

COPY backend /app/backend
COPY worker /app/worker

ENV PYTHONPATH=/app
WORKDIR /app/backend

RUN chmod +x /app/backend/docker-entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/app/backend/docker-entrypoint.sh"]
CMD ["sh", "-c", "gunicorn main:app -k uvicorn.workers.UvicornWorker -b 0.0.0.0:${PORT:-8000} -w ${GUNICORN_WORKERS:-2} --timeout 120 --access-logfile - --error-logfile -"]
