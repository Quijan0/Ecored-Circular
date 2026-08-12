#!/bin/sh
set -e

if [ -f /etc/secrets/firebase-service-account.json ]; then
    ln -sf \
      /etc/secrets/firebase-service-account.json \
      /app/backend/firebase-service-account.json
fi

cd /app/backend

gunicorn config.wsgi:application \
    --bind 127.0.0.1:8000 \
    --workers 1 \
    --access-logfile - \
    --error-logfile - &

exec nginx -g "daemon off;"