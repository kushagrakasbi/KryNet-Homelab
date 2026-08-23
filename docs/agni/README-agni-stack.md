# KryNet-Agni Stack Files

This directory contains the Docker Compose stack configuration for KryNet-Agni (192.168.0.200).

## 📁 Files in This Directory

- **`docker-compose.yml`** - Main stack definition (Portainer-ready)
- **`Dockerfile`** - Caddy with Cloudflare DNS plugin
- **`Caddyfile`** - Reverse proxy configuration
- **`.env.example`** - Environment variable template
- **`.gitignore`** - Prevents committing sensitive data

## 📚 Documentation

All documentation, guides, and deployment scripts have been moved to:

**[`/docs/agni/`](../../docs/agni/)**

### Quick Links

- **[INDEX.md](../../docs/agni/INDEX.md)** - Start here! Navigation guide
- **[SUMMARY.md](../../docs/agni/SUMMARY.md)** - Overview & quick deployment
- **[README.md](../../docs/agni/README.md)** - Comprehensive setup guide
- **[ARCHITECTURE.md](../../docs/agni/ARCHITECTURE.md)** - System design & diagrams
- **[MIGRATION.md](../../docs/agni/MIGRATION.md)** - Migration procedures
- **[QUICKREF.md](../../docs/agni/QUICKREF.md)** - Quick reference

### Deployment Scripts

- **[deploy.sh](../../docs/agni/deploy.sh)** - Automated deployment
- **[validate.sh](../../docs/agni/validate.sh)** - Pre-deployment validation

## 🚀 Quick Deployment

### Using Portainer

1. **Create a new stack** in Portainer
2. **Copy the contents** of `docker-compose.yml`
3. **Add environment variables**:
   - `CLOUDFLARE_API_TOKEN`
   - `TS_AUTHKEY`
4. **Deploy the stack**

### Using Command Line

```bash
# On Agni (192.168.0.200)
cd /home/agni/apps/docker

# Copy stack files
cp /path/to/repo/stacks/agni/docker-compose.yml .
cp /path/to/repo/stacks/agni/Dockerfile caddy/
cp /path/to/repo/stacks/agni/Caddyfile caddy/
cp /path/to/repo/stacks/agni/.env.example .env

# Edit environment variables
nano .env

# Deploy
docker compose build caddy
docker compose up -d
```

## ⚙️ Configuration Notes

### Paths

All paths in `docker-compose.yml` use **absolute paths** pointing to `/home/agni/apps/docker/`:

```yaml
volumes:
  - /home/agni/apps/docker/caddy/Caddyfile:/etc/caddy/Caddyfile
  - /home/agni/apps/docker/adguard/conf:/opt/adguardhome/conf
  - /home/agni/apps/docker/ha/config:/config
  - /home/agni/apps/docker/tailscale:/var/lib/tailscale
```

This ensures the stack works correctly when deployed via **Portainer**.

### Services

The stack includes:
- **Portainer** - Container management
- **Caddy** - Reverse proxy with automatic HTTPS
- **AdGuard Home** - DNS server (web UI on port 3000)
- **Home Assistant** - Smart home hub
- **Tailscale** - Mesh VPN

All services use `network_mode: host` for proper network access.

## 📖 Full Documentation

For complete setup instructions, troubleshooting, and migration guides, see:

👉 **[/docs/agni/](../../docs/agni/)**

---

**Node:** KryNet-Agni (192.168.0.200)  
**Role:** Network Core - Always-On "Brain"  
**OS:** Ubuntu Server 24.04 LTS
