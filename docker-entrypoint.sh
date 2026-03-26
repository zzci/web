#!/bin/sh
set -e

# If the first argument is a shell or known command, exec it directly
case "${1:-}" in
  sh|ash|/bin/sh|/bin/ash)
    exec "$@"
    ;;
esac

# If any arguments are passed, treat them as static-web-server args
if [ $# -gt 0 ]; then
  exec static-web-server "$@"
fi

# Default: start static-web-server with env-based configuration
exec static-web-server \
  --host "${SERVER_HOST:-::}" \
  --port "${SERVER_PORT:-80}" \
  --root "${SERVER_ROOT:-/public}" \
  --log-level "${SERVER_LOG_LEVEL:-info}"
