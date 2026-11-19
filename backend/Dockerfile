# syntax=docker/dockerfile:1
FROM python:3.11-slim

WORKDIR /app

# Install build dependencies for compiling wheel packages if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create a non-root user for running the app
RUN groupadd -r mindpal && useradd -r -g mindpal -d /app -s /sbin/nologin mindpal

# Copy application code
COPY app ./app
COPY .env.example .env.example

# Environment variables (inject at runtime via --env-file or Docker secrets)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    HOST=0.0.0.0

# Create writable directories with correct ownership
RUN mkdir -p /app/chroma_data && \
    chown -R mindpal:mindpal /app

USER mindpal

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
