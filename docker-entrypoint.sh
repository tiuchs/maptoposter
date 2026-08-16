#!/bin/sh
# Runs as root at container start. Remaps the built-in "appuser" to the
# requested PUID/PGID and fixes ownership of the bind-mounted data
# directories, then drops privileges and execs the real command. This means
# the app itself never runs as root, and no manual `chown` on the host is
# needed regardless of what already owns those directories.
set -e

TARGET_UID="${PUID:-1000}"
TARGET_GID="${PGID:-1000}"

if [ "$(id -u)" = "0" ]; then
    if [ "$(id -g appuser)" != "$TARGET_GID" ]; then
        groupmod -o -g "$TARGET_GID" appuser
    fi
    if [ "$(id -u appuser)" != "$TARGET_UID" ]; then
        usermod -o -u "$TARGET_UID" appuser
    fi

    chown -R appuser:appuser /app/posters /app/cache /app/fonts/cache

    exec gosu appuser "$@"
fi

exec "$@"
