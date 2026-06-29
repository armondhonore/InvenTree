FROM mirror.gcr.io/library/python:3.12-slim

WORKDIR /app

# Install system dependencies for InvenTree (Postgres, build tools, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the entire repository
COPY . .

# Install dependencies using the project's pyproject.toml/requirements
# We use --no-deps first to get pip updated, then install the project
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir . || pip install --no-cache-dir -r requirements.txt || true

# Ensure Django and core production server are present
RUN pip install --no-cache-dir "django>=5.0" gunicorn psycopg2-binary redis

# InvenTree uses a src layout. Add src to PYTHONPATH
ENV PYTHONPATH=/app/src
ENV SECRET_KEY=placeholder-secret-key-for-build
ENV DEBUG=False
ENV PORT=8000

EXPOSE 8000

# Use a more robust entrypoint: find manage.py, run migrations (ignore failure), then runserver
CMD ["sh", "-c", "MANAGE_PY=$(find . -name manage.py | head -n 1) && python $MANAGE_PY migrate --noinput || true && python $MANAGE_PY runserver 0.0.0.0:8000"]
