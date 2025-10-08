#!/bin/sh
set -e

echo "🚀 Starting Caddy with TLS setup..."

# Start Caddy in background
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile 2>&1 &
CADDY_PID=$!

# Wait briefly for Caddy HTTP to be ready
echo "⏳ Waiting for Caddy HTTP..."
for i in $(seq 1 20); do
  if wget --spider -q http://localhost:80 2>/dev/null; then
    echo "✅ Caddy HTTP ready"
    break
  fi
  sleep 0.3
done

# Trigger HTTPS cert generation and wait for it (blocking)
echo "🔐 Triggering HTTPS certificate generation..."
for i in $(seq 1 60); do
  if wget --spider -q --no-check-certificate https://localhost:443 2>/dev/null; then
    echo "✅ Caddy HTTPS ready with self-signed certificate"
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "❌ HTTPS failed to initialize after 30 seconds"
    kill $CADDY_PID
    exit 1
  fi
  sleep 0.5
done

# Bring Caddy to foreground
echo "✅ Caddy fully initialized with HTTPS"
wait $CADDY_PID
