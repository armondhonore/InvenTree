# Thin wrapper over the official InvenTree image — no source rebuild.
# (A from-source build fails: ModuleNotFoundError: No module named 'django'.)
FROM mirror.gcr.io/inventree/inventree:stable
# init.sh (the image ENTRYPOINT) runs first, then exec's this CMD.
# Run migrations + collect static synchronously (SQLite — no DB wait needed), then serve.
CMD ["sh", "-c", "invoke update && exec gunicorn -c ./gunicorn.conf.py InvenTree.wsgi -b 0.0.0.0:8000 --chdir ${INVENTREE_BACKEND_DIR}/InvenTree"]
EXPOSE 8000