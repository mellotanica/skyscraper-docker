#!/usr/bin/env sh

CACHE_DIR=${SKYSCRAPER_CACHEDIR:-/cache}

if [ -n "$PGID" ]; then
    groupadd -g "$PGID" dockergroup 2> /dev/null || true
else
    PGID=$(id -g)
fi

if [ -n "$PUID" ]; then
    useradd -m -u "$PUID" -g "$PGID" dockeruser 2> /dev/null || true
else
    PUID=$(id -u)
fi

if [ ! -f config.ini ]; then
    if [ -f /configs/config.ini ]; then
        cp /configs/config.ini .
    fi
    echo "[main]
cacheFolder=\"${CACHE_DIR}\"
" >> config.ini
    chown "$PUID":"$PGID" config.ini
fi

chown -R "$PUID":"$PGID" /cache

exec su-exec $PUID:$PGID $@
