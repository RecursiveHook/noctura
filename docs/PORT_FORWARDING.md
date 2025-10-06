# Port Forwarding in Docker-in-Docker Environments

## The Issue

When running Noctura in a devcontainer or GitHub Codespaces (Docker-in-Docker), ports exposed by nested Docker containers may not be accessible via `localhost` from the host machine. This is because the Docker daemon running inside the devcontainer creates its own network namespace.

## Solutions

### Option 1: Use VS Code Port Forwarding (Recommended)

VS Code automatically detects and forwards ports from devcontainers:

1. Open the **Ports** panel in VS Code (View → Ports, or `Cmd/Ctrl+Shift+P` → "Ports: Focus on Ports View")
2. Ports 8080, 5900, and 5984 should auto-forward
3. Click the "Local Address" column to open in your browser
4. If ports don't appear, click "Forward Port" and add them manually

### Option 2: Use Container IPs Directly

Access services directly via their Docker network IPs:

```bash
make show-access
```

This command shows:
- Obsidian noVNC: `http://172.x.x.x:8080/vnc.html`
- VNC Server: `172.x.x.x:5900`
- CouchDB: `http://172.x.x.x:5984`

### Option 3: Use GitHub Codespaces Port Forwarding

If running in GitHub Codespaces:

1. Open the **Ports** tab in the integrated terminal
2. Ports should be automatically detected and forwarded
3. Click the globe icon to open in browser
4. Use the "Visibility" column to make ports public or private

### Option 4: Manual Port Forwarding with `gh` CLI

```bash
gh codespace ports forward 8080:8080 5900:5900 5984:5984
```

## Verification

Check if port forwarding is working:

```bash
# Should return HTML content if working
curl http://localhost:8080

# Or use the health check
make health
```

## Why This Happens

- **Docker-in-Docker**: The devcontainer runs Docker inside a container
- **Nested Networking**: Docker containers inside Docker have their own network
- **Port Binding**: Ports bind to the inner Docker daemon, not the host
- **Solution**: Port forwarding bridges the gap between network layers

## Configuration

The devcontainer is pre-configured with port forwarding:

```json
{
  "forwardPorts": [8080, 5900, 5984],
  "portsAttributes": {
    "8080": { "label": "Obsidian Web (noVNC)" },
    "5900": { "label": "VNC Server" },
    "5984": { "label": "CouchDB" }
  }
}
```

## Troubleshooting

### Ports not appearing in VS Code

1. Reload window: `Cmd/Ctrl+Shift+P` → "Developer: Reload Window"
2. Restart containers: `make restart`
3. Check containers are running: `make status`

### Connection refused errors

1. Verify services are running: `docker compose ps`
2. Check container logs: `make logs`
3. Use container IPs: `make show-access`

### Firewall blocking connections

1. Check your firewall settings
2. Try using different ports (edit `.env`)
3. Use SSH tunneling as a workaround

## Production Deployment

Port forwarding issues **only affect development environments**. In production:

- Docker containers run directly on the host
- Ports bind to host network interfaces
- Standard `localhost:8080` access works normally
- No special configuration needed

## Additional Resources

- [VS Code Port Forwarding Docs](https://code.visualstudio.com/docs/remote/ssh#_forwarding-a-port-creating-ssh-tunnel)
- [GitHub Codespaces Ports Guide](https://docs.github.com/en/codespaces/developing-in-codespaces/forwarding-ports-in-your-codespace)
- [Docker Networking Overview](https://docs.docker.com/network/)
