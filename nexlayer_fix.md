# Nexlayer fix guidance — inventree (PINNED)

Do NOT regenerate the Dockerfile or nexlayer.yaml. They are hand-tuned and correct.

## Root cause of prior failures
The stock `inventree/inventree` image CMD only starts gunicorn. It does NOT wait
for postgres and does NOT run migrations (InvenTree offloads migrations to a
django-q worker that is absent in a single web pod). Result: the web process
raced postgres and/or served on an unmigrated DB → crash loop → HTTP 503.

## The fix (already applied — keep as-is)
- Root `Dockerfile` extends `mirror.gcr.io/inventree/inventree:stable` and sets a
  CMD that runs `invoke wait && invoke update && gunicorn ...` so the DB is
  reachable and migrated before serving.
- `nexlayer.yaml`: app pod on :8000 + a dedicated `inventree-postgres` pod.
  Required env: INVENTREE_SITE_URL and INVENTREE_TRUSTED_ORIGINS (the prod
  server calls sys.exit() without them), INVENTREE_DB_* pointing at
  inventree-postgres.pod:5432, admin bootstrap vars.

Pinned=true. Do not rewrite these files.
