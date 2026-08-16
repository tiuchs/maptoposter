FROM python:3.11-slim-bookworm

# scipy's compiled extensions dynamically link libgomp (GCC's OpenMP
# runtime); tzdata provides the named zones the TZ env var needs; gosu
# drops root privileges after the entrypoint's PUID/PGID setup.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgomp1 tzdata gosu \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY create_map_poster.py font_management.py ./
COPY themes/ themes/
COPY fonts/ fonts/
COPY webapp/ webapp/
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN useradd --create-home --uid 1000 appuser \
    && mkdir -p posters cache fonts/cache \
    && chown -R appuser:appuser /app \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# Stays root here on purpose: docker-entrypoint.sh remaps appuser to
# PUID/PGID, fixes ownership of the mounted data dirs, then drops to
# appuser via gosu before running the actual command.

ENV PYTHONUNBUFFERED=1 \
    MPLBACKEND=Agg \
    HOST=0.0.0.0 \
    PORT=8000 \
    PUID=1000 \
    PGID=1000

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/')" || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["python", "webapp/server.py"]
