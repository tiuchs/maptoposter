FROM python:3.11-slim-bookworm

# scipy's compiled extensions dynamically link libgomp (GCC's OpenMP
# runtime), which the slim base image doesn't ship by default.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY create_map_poster.py font_management.py ./
COPY themes/ themes/
COPY fonts/ fonts/
COPY webapp/ webapp/

RUN useradd --create-home --uid 1000 appuser \
    && mkdir -p posters cache fonts/cache \
    && chown -R appuser:appuser /app
USER appuser

ENV PYTHONUNBUFFERED=1 \
    MPLBACKEND=Agg \
    HOST=0.0.0.0 \
    PORT=8000

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/')" || exit 1

CMD ["python", "webapp/server.py"]
