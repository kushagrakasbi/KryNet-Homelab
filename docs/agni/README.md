# KryNet-Agni Stack Configuration

**Node:** KryNet-Agni (192.168.0.200)  
**Role:** Network Core - Always-On "Brain"  
**OS:** Ubuntu Server 24.04 LTS

## 🎯 Purpose

This stack runs the critical network infrastructure services that need to be always available:
- **Caddy:** Reverse proxy with automatic HTTPS
- **AdGuard Home:** Primary DNS server with ad-blocking
- **Home Assistant:** Smart home automation hub
- **Tailscale:** Mesh VPN for remote access
- **Portainer:** Container management UI

## 📂 Directory Structure on Agni

```
~/apps/docker/
├── docker-compose.yml          # Main stack definition
├── .env                        # Environment variables (not in git)
├── caddy/
│   ├── Dockerfile             # Caddy with Cloudflare DNS plugin
│   ├── Caddyfile              # Reverse proxy configuration
│   ├── data/                  # SSL certificates (auto-generated)
│   └── config/                # Caddy runtime config
├── adguard/
│   ├── conf/                  # AdGuard configuration
│   └── work/                  # AdGuard data
├── ha/
│   └── config/                # Home Assistant configuration
└── tailscale/                 # Tailscale state
```

## 🚀 Deployment Instructions

### Prerequisites

1. **Agni is running Ubuntu Server 24.04** with static IP `192.168.0.200`
2. **Docker and Docker Compose are installed**
3. **Data has been migrated** from Prime to `~/apps/docker/`

### Step 1: Prepare the Environment

```bash
# Navigate to the docker directory
cd ~/apps/docker

# Copy the stack files from this repo
cp /path/to/home-server/stacks/agni/docker-compose.yml .
cp /path/to/home-server/stacks/agni/.env.example .env

# Create the Caddy directory and copy files
mkdir -p caddy
cp /path/to/home-server/stacks/agni/Dockerfile caddy/
cp /path/to/home-server/stacks/agni/Caddyfile caddy/

# Edit the .env file with your credentials
nano .env
```

### Step 2: Configure Environment Variables

Edit `.env` and add:
```bash
CLOUDFLARE_API_TOKEN=your_actual_token
TS_AUTHKEY=your_tailscale_auth_key
```

### Step 3: Update AdGuard Port

AdGuard's web UI needs to be moved to port 3000 to avoid conflicts with Caddy.

Edit `~/apps/docker/adguard/conf/AdGuardHome.yaml`:
```yaml
http:
  address: 0.0.0.0:3000  # Change from 80 to 3000
```

### Step 4: Build and Launch

```bash
# Build the Caddy image with Cloudflare DNS plugin
docker compose build caddy

# Start the stack
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### Step 5: Verify Services

- **Portainer:** https://192.168.0.200:9443
- **AdGuard:** http://192.168.0.200:3000
- **Home Assistant:** http://192.168.0.200:8123
- **Caddy:** Check logs with `docker compose logs caddy`

## 🔧 Configuration Notes

### Caddy (Reverse Proxy)

- **Network Mode:** `host` (required for proper DNS resolution)
- **SSL Certificates:** Auto-generated via Cloudflare DNS-01 challenge
- **Configuration:** All services routed through wildcard domains

**Local Services (on Agni):**
- AdGuard Home: `127.0.0.1:3000`
- Home Assistant: `127.0.0.1:8123`
- Portainer: `127.0.0.1:9443`

**Remote Services (on Prime - 192.168.0.100):**
- Immich, Jellyfin, *arr stack, etc.

### AdGuard Home

- **Network Mode:** `host` (required for DNS on port 53)
- **Web UI Port:** 3000 (changed from default 80)
- **DNS Ports:** 53/tcp, 53/udp
- **Configuration:** Migrated from Prime

### Home Assistant

- **Network Mode:** `host` (required for device discovery)
- **Port:** 8123
- **Configuration:** Migrated from Prime (includes `.storage` folder)

### Tailscale

- **Network Mode:** `host` (required for VPN routing)
- **Subnet Router:** Advertises `192.168.0.0/24`
- **Exit Node:** Enabled

## 🔄 Migration from Prime

The following services are being **offloaded from Prime to Agni**:

| Service | Old Location | New Location | Status |
|---------|--------------|--------------|--------|
| Caddy | Prime | Agni | ✅ Ready |
| AdGuard Home | Prime | Agni | ✅ Ready |
| Home Assistant | Prime | Agni | ✅ Ready |
| Tailscale | Prime | Agni | ✅ Ready |

**Services remaining on Prime:**
- All media services (Immich, Jellyfin, *arr stack)
- Storage-heavy applications
- GPU-dependent services (Tdarr, AI workloads)

## 🛠️ Troubleshooting

### Caddy won't start
```bash
# Check if port 80/443 are already in use
sudo ss -tulpn | grep ':80\|:443'

# View detailed logs
docker compose logs caddy
```

### AdGuard web UI not accessible
```bash
# Verify the port is set to 3000 in the config
cat ~/apps/docker/adguard/conf/AdGuardHome.yaml | grep address

# Check if AdGuard is running
docker compose ps adguardhome
```

### Home Assistant not discovering devices
- Ensure `network_mode: host` is set
- Check that `/run/dbus` is mounted correctly

### SSL Certificate Issues
```bash
# Check Cloudflare API token
docker compose exec caddy env | grep CLOUDFLARE

# Force certificate renewal
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## 📝 Maintenance

### Update Containers
```bash
docker compose pull
docker compose up -d
```

### Backup Configuration
```bash
# Backup entire docker directory
tar -czf ~/agni-backup-$(date +%Y%m%d).tar.gz ~/apps/docker
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f caddy
docker compose logs -f adguardhome
```

## 🔐 Security Notes

- **No ports exposed to internet** - All traffic via Cloudflare Tunnel or Tailscale
- **Cloudflare API token** - Scoped to DNS edit only
- **Tailscale auth key** - Use ephemeral keys for better security
- **AdGuard admin password** - Set during initial setup

## 📊 Resource Usage (Expected)

| Service | RAM | CPU | Notes |
|---------|-----|-----|-------|
| Caddy | ~50MB | Low | Spikes during cert renewal |
| AdGuard | ~100MB | Low | Increases with query volume |
| Home Assistant | ~200MB | Medium | Depends on integrations |
| Tailscale | ~30MB | Low | Minimal overhead |
| Portainer | ~50MB | Low | Only when accessed |

**Total:** ~500MB RAM baseline

## 🎯 Next Steps

1. **Update DNS settings** on router to point to `192.168.0.200` as primary DNS
2. **Test failover** by stopping services on Prime
3. **Monitor logs** for the first 24 hours
4. **Update Cloudflare Tunnel** to point to Agni instead of Prime
5. **Decommission services on Prime** once stable

---

**Last Updated:** January 2026  
**Maintainer:** Kushagra Kasbi
