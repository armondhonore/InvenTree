# Nexlayer fix — inventree (AUTHORITATIVE / PINNED)

Root cause (confirmed from container logs): the pipeline built InvenTree FROM
SOURCE (python:3.12-slim + pip) and that image was broken —
`ModuleNotFoundError: No module named 'django'`. Building from source is
unnecessary; the official `inventree/inventree` image is complete. Separately,
the multi-pod postgres topology kept tripping the deploy step.

Fix: single self-contained pod backed by SQLite on the data volume (fine for
test data) — same shape as other working single-pod apps, no companion DB pod.
- `invoke update` runs migrations + collectstatic synchronously before gunicorn.
- In production the server `sys.exit()`s without INVENTREE_SITE_URL /
  INVENTREE_TRUSTED_ORIGINS — both set.

## Fixed Dockerfile
```dockerfile
FROM mirror.gcr.io/inventree/inventree:stable
CMD ["sh", "-c", "invoke update && exec gunicorn -c ./gunicorn.conf.py InvenTree.wsgi -b 0.0.0.0:8000 --chdir ${INVENTREE_BACKEND_DIR}/InvenTree"]
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
      INVENTREE_DB_ENGINE: sqlite3
      INVENTREE_DB_NAME: /home/inventree/data/inventree.sqlite3
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
```
