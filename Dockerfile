# Thin wrapper over the official InvenTree all-in-one image.
# The stock image's CMD only starts gunicorn — it neither waits for the
# database nor runs migrations (those are offloaded to a django-q worker that
# does not exist in a single-pod deploy). On Nexlayer we run a startup sequence
# that waits for postgres, applies migrations + collects static, then serves.
FROM mirror.gcr.io/inventree/inventree:stable

# init.sh (the image ENTRYPOINT) runs first and then exec's this CMD.
CMD ["sh", "-c", "invoke wait && invoke update && exec gunicorn -c ./gunicorn.conf.py InvenTree.wsgi -b 0.0.0.0:${INVENTREE_WEB_PORT} --chdir ${INVENTREE_BACKEND_DIR}/InvenTree"]
