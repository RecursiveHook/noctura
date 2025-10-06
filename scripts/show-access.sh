#!/bin/bash
set -euo pipefail

echo "🌐 Noctura Access Information"
echo "=============================="
echo ""

# Check if containers are running
if ! docker ps | grep -q noctura-obsidian; then
    echo "❌ Obsidian container is not running"
    echo "   Run: docker compose up -d"
    exit 1
fi

if ! docker ps | grep -q noctura-couchdb; then
    echo "❌ CouchDB container is not running"
    echo "   Run: docker compose up -d"
    exit 1
fi

# Get container IPs
OBSIDIAN_IP=$(docker inspect noctura-obsidian -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

echo "✅ All containers running"
echo ""
echo "📱 Obsidian Web Interface (noVNC):"
echo "   • Container IP: http://${OBSIDIAN_IP}:8080/vnc.html"
echo "   • Localhost:    http://localhost:8080/vnc.html"
echo ""
echo "🖥️  VNC Direct Connection:"
echo "   • Container IP: ${OBSIDIAN_IP}:5900"
echo "   • Localhost:    localhost:5900"
echo ""
echo "💾 CouchDB Database:"
echo "   • Container IP: http://${OBSIDIAN_IP}:5984/_utils"
echo "   • Localhost:    http://localhost:5984/_utils"
echo "   • Username:     admin"
echo "   • Password:     (see .env file)"
echo ""

# Check if we're in a devcontainer
if [ -f "/.dockerenv" ] || grep -q "docker" /proc/1/cgroup 2>/dev/null; then
    echo "ℹ️  Note: You're running in a devcontainer (Docker-in-Docker)"
    echo "   If localhost URLs don't work, use the container IPs above"
    echo "   or configure port forwarding in VS Code's Ports panel"
    echo ""
fi

# Test if localhost works
if timeout 2 curl -sf http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Localhost port forwarding is working!"
else
    echo "⚠️  Localhost ports not accessible from this environment"
    echo "   Use container IPs or configure VS Code port forwarding"
fi

echo ""
