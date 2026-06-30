# Nexlayer fix — inventree (AUTHORITATIVE / PINNED)

Root cause (confirmed): The official `mirror.gcr.io/inventree/inventree:stable`
image requires INVENTREE_SECRET_KEY (was missing) and a Postgres DB.
The previous SQLite single-pod approach with CMD overrides failed — CMD
overrides are stripped on the redeploy path, and `image: "# filled by
pipeline"` has no image available on a yaml-only redeploy, causing
"malformed yaml" errors.

Fix: Use the official image directly (no Dockerfile override needed) with an
explicit Postgres companion pod. All required env vars set including
INVENTREE_SECRET_KEY. INVENTREE_AUTO_UPDATE=True handles migrations via the
image's own built-in entrypoint.

## Fixed nexlayer.yaml
```yaml
application:
  name: inventree
  pods:
  - name: app
    image: mirror.gcr.io/inventree/inventree:stable
    path: /
    servicePorts:
    - 8000
    vars:
      INVENTREE_DB_ENGINE: postgresql
      INVENTREE_DB_NAME: inventree
      INVENTREE_DB_USER: inventree
      INVENTREE_DB_PASSWORD: inventree
      INVENTREE_DB_HOST: inventree-postgres.pod
      INVENTREE_DB_PORT: "5432"
      INVENTREE_AUTO_UPDATE: "True"
      INVENTREE_SITE_URL: https://relaxed-weasel-inventree.cloud.nexlayer.ai
      INVENTREE_TRUSTED_ORIGINS: https://relaxed-weasel-inventree.cloud.nexlayer.ai
      INVENTREE_ADMIN_USER: admin
      INVENTREE_ADMIN_PASSWORD: inventree
      INVENTREE_ADMIN_EMAIL: admin@example.com
      INVENTREE_GUNICORN_TIMEOUT: "300"
      INVENTREE_SECRET_KEY: nexlayer250appsInvenTreeSecretKey2026xKp9mZqRt
      INVENTREE_STATIC_ROOT: /home/inventree/data/static
      INVENTREE_MEDIA_ROOT: /home/inventree/data/media
    volumes:
    - name: inventree-data-v3
      mountPath: /home/inventree/data
      size: 10Gi
  - name: inventree-postgres
    image: mirror.gcr.io/library/postgres:16-alpine
    servicePorts:
    - 5432
    vars:
      POSTGRES_DB: inventree
      POSTGRES_USER: inventree
      POSTGRES_PASSWORD: inventree
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
    - name: inventree-db-v3
      mountPath: /var/lib/postgresql
      size: 10Gi
```
