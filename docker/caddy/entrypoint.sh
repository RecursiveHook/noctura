#!/bin/sh
set -e

echo "🚀 Starting Caddy with TLS setup..."

# Start Caddy in background
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
CADDY_PID=$!

# Wait for Caddy to start (HTTP)
echo "⏳ Waiting for Caddy HTTP..."
for i in $(seq 1 30); do
  if wget --spider -q http://localhost:80 2>/dev/null; then
    echo "✅ Caddy HTTP ready"
    break
  fi
  sleep 0.5
done

# Trigger HTTPS cert generation by making a request
echo "🔐 Triggering HTTPS certificate generation..."
for i in $(seq 1 30); do
  if wget --spider -q --no-check-certificate https://localhost:443 2>/dev/null; then
    echo "✅ Caddy HTTPS ready with certificate"
    break
  fi
  sleep 0.5
done

# Bring Caddy to foreground
wait $CADDY_PID
