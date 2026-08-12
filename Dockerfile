# syntax=docker/dockerfile:1
 
# ============================================================
# ETAPA 1 - Construir React
# ============================================================
 
FROM node:24-bookworm-slim AS frontend-build
 
WORKDIR /frontend
 
COPY frontend/package.json frontend/package-lock.json ./
 
RUN npm ci
 
COPY frontend/ ./
 
# Frontend y backend compartirán el mismo origen.
ENV VITE_API_URL=/api
 
RUN npm run build
 
 
# ============================================================
# ETAPA 2 - Imagen final
# ============================================================
 
FROM python:3.13-slim-bookworm
 
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
 
RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*
 
WORKDIR /app
 
# requirements.txt debe estar guardado en UTF-8
COPY backend/requirements.txt /tmp/requirements.txt
 
RUN python -m pip install \
    --no-cache-dir \
    -r /tmp/requirements.txt
 
COPY backend/ /app/backend/
 
COPY --from=frontend-build \
    /frontend/dist \
    /usr/share/nginx/html
 
COPY nginx.conf /etc/nginx/nginx.conf
 
COPY start.sh /start.sh
 
RUN sed -i 's/\r$//' /start.sh \
    && chmod +x /start.sh \
    && nginx -t
 
EXPOSE 10000
 
HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=30s \
    --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:10000/api/health/', timeout=3)"
 
CMD ["/start.sh"]