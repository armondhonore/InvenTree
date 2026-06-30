# Nexlayer fix — inventree (AUTHORITATIVE / PINNED)

Root cause (confirmed from container logs): the pipeline built InvenTree FROM
SOURCE (python:3.12-slim + pip) and that image was broken —
`ModuleNotFoundError: No module named 'django'` at /app/src/backend/InvenTree/manage.py.
Building from source is unnecessary; the official `inventree/inventree` image is
complete.

Facts that must hold (verified in InvenTree source):
- In production the server `sys.exit()`s on boot unless `INVENTREE_SITE_URL`
  and `INVENTREE_TRUSTED_ORIGINS` are set.
- The stock image CMD only starts gunicorn; it neither waits for the DB nor runs
  migrations (offloaded to a django-q worker absent in a single web pod). The CMD
  below waits for postgres, runs `invoke update` (migrate + collectstatic), then
  serves.
- Postgres uses POSTGRES_HOST_AUTH_METHOD=trust (no password) so the platform's
  secret-redaction step has no POSTGRES_PASSWORD to rewrite into an
  unprovisionable ${POSTGRES_PASSWORD}. Safe for test data.

## Fixed Dockerfile
```dockerfile
FROM mirror.gcr.io/inventree/inventree:stable
CMD ["sh", "-c", "invoke wait && invoke update && exec gunicorn -c ./gunicorn.conf.py InvenTree.wsgi -b 0.0.0.0:8000 --chdir ${INVENTREE_BACKEND_DIR}/InvenTree"]
EXPOSE 8000
```

## Fixed nexlayer.yaml
```yaml
application:
  name: inventree
  pods:
  - name: app
    image: "# filled by pipeline"
    path: /
    servicePorts:
    - 8000
    vars:
      INVENTREE_DB_ENGINE: postgresql
      INVENTREE_DB_NAME: inventree
      INVENTREE_DB_USER: inventree
      INVENTREE_DB_HOST: inventree-postgres.pod
      INVENTREE_DB_PORT: "5432"
      INVENTREE_AUTO_UPDATE: "True"
      INVENTREE_SITE_URL: https://relaxed-weasel-inventree.cloud.nexlayer.ai
      INVENTREE_TRUSTED_ORIGINS: https://relaxed-weasel-inventree.cloud.nexlayer.ai
      INVENTREE_ADMIN_USER: admin
      INVENTREE_ADMIN_EMAIL: admin@example.com
      INVENTREE_GUNICORN_TIMEOUT: "300"
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
      POSTGRES_HOST_AUTH_METHOD: trust
    volumes:
    - name: inventree-db-v3
      mountPath: /var/lib/postgresql/data
      size: 10Gi
```
