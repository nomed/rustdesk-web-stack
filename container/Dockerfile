FROM caddy:2.10.2-alpine

COPY container/Caddyfile /etc/caddy/Caddyfile
COPY dist/web/ /srv/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1
