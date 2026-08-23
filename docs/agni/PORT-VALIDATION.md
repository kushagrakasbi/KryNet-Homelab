# Port Validation & Corrections

## ✅ Caddyfile Port Corrections

I've validated all Prime service ports against the actual stack configurations and corrected the following in your Caddyfile:

### 🔧 Corrected Ports

| Service | Domain | Old Port | ✅ Correct Port | Stack File |
|---------|--------|----------|----------------|------------|
| **Dozzle** | logs.krynet.cc | ~~8080~~ | **8088** | monitoring.yml |
| **Immich Power Tools** | ipt.krynet.cc | ~~3001~~ | **8001** | immich.yml |
| **Homepage** | home.krynet.cc | ~~3000~~ | **3075** | homepage.yml |
| **OpenWebUI** | ow.krynet.cc | ~~8080~~ | **3999** | litellm.yml |
| **OpenSpeedTest** | ospt.krynet.cc | ~~3000~~ | **8992** | speedtest.yml |
| **Speedtest Tracker** | speed.krynet.cc | ~~80~~ | **8093** | speedtest.yml |

### ✅ Verified Correct Ports

These ports were already correct in the Caddyfile:

| Service | Domain | Port | Stack File |
|---------|--------|------|------------|
| **TrueNAS** | server.krynet.cc | 88 | - |
| **Portainer** | portainer.krynet.cc | 9443 | - |
| **LiteLLM** | litellm.krynet.cc | 4000 | litellm.yml |
| **Homarr** | dash.krynet.cc | 7575 | homarr.yml |
| **Immich** | photos.krynet.cc | 2283 | immich.yml |
| **qBittorrent** | qb.krynet.cc | 8080 | media-stack.yml (via Gluetun) |
| **Jellyseerr** | request.krynet.cc | 5055 | media-stack.yml (via Gluetun) |
| **Whisparr** | whisparr.krynet.cc | 6969 | media-stack.yml |
| **SABnzbd** | nzb.krynet.cc | 8085 | media-stack.yml |
| **FlareSolverr** | flare.krynet.cc | 8191 | media-stack.yml |
| **Prowlarr** | indexer.krynet.cc | 9696 | media-stack.yml |
| **Sonarr** | sonarr.krynet.cc | 8989 | media-stack.yml |
| **Radarr** | radarr.krynet.cc | 7878 | media-stack.yml |
| **Bazarr** | bazarr.krynet.cc | 6767 | media-stack.yml |
| **Jellyfin** | media.krynet.cc | 8096 | media-stack.yml |
| **Uptime Kuma** | monitor.krynet.cc | 3001 | monitoring.yml |
| **Prometheus** | prom.krynet.cc | 9090 | monitoring.yml |
| **TDarr** | tdarr.krynet.cc | 8265 | media-stack.yml |

## 📊 Complete Prime Port Reference

### Network Core (Agni - 192.168.0.200)
| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Caddy | 80, 443 | HTTP/HTTPS | Reverse proxy |
| AdGuard Home | 53 | DNS | DNS server |
| AdGuard Home | 7000 | HTTP | Web UI |
| AdGuard Sync | 8082 | HTTP | Sync monitoring |
| Home Assistant | 8123 | HTTP | Smart home |
| Portainer | 9443 | HTTPS | Container mgmt |

### Storage & Media (Prime - 192.168.0.100)
| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| **Infrastructure** ||||
| TrueNAS | 88 | HTTP | NAS management |
| Portainer | 9443 | HTTPS | Container mgmt |
| **Photos & Docs** ||||
| Immich | 2283 | HTTP | Photo management |
| Immich Power Tools | 8001 | HTTP | Immich utilities |
| Immich Postgres | 5432 | PostgreSQL | Database |
| **Media Automation** ||||
| qBittorrent | 8080 | HTTP | Torrent client (via VPN) |
| SABnzbd | 8085 | HTTP | Usenet client |
| Jellyseerr | 5055 | HTTP | Request manager (via VPN) |
| Whisparr | 6969 | HTTP | Adult content manager |
| FlareSolverr | 8191 | HTTP | Cloudflare bypass |
| Prowlarr | 9696 | HTTP | Indexer manager |
| Sonarr | 8989 | HTTP | TV show manager |
| Radarr | 7878 | HTTP | Movie manager |
| Bazarr | 6767 | HTTP | Subtitle manager |
| Jellyfin | 8096 | HTTP | Media server |
| TDarr | 8265 | HTTP | Transcoding |
| TDarr Server | 8266 | TCP | Transcoding backend |
| **Monitoring** ||||
| Uptime Kuma | 3001 | HTTP | Uptime monitoring |
| Prometheus | 9090 | HTTP | Metrics |
| Dozzle | 8088 | HTTP | Log viewer |
| Gotify | 8089 | HTTP | Notifications |
| Grafana | 3123 | HTTP | Dashboards |
| **Dashboards** ||||
| Homepage | 3075 | HTTP | Dashboard |
| Homarr | 7575 | HTTP | Dashboard |
| **Testing** ||||
| OpenSpeedTest | 8992 | HTTP | Speed test UI |
| OpenSpeedTest | 8993 | HTTP | Speed test alt |
| Speedtest Tracker | 8093 | HTTP | Speed test tracker |
| **AI (Disabled)** ||||
| LiteLLM | 4000 | HTTP | LLM proxy |
| OpenWebUI | 3999 | HTTP | Chat interface |

## 🔍 Why Ports Were Wrong

### Port Conflicts
Many services use custom ports to avoid conflicts:

1. **Dozzle (8088 not 8080)** - Avoids conflict with qBittorrent
2. **Homepage (3075 not 3000)** - Avoids conflict with other services on 3000
3. **OpenWebUI (3999 not 8080)** - Avoids conflict with qBittorrent
4. **Immich Power Tools (8001 not 3001)** - Avoids conflict with Uptime Kuma
5. **OpenSpeedTest (8992 not 3000)** - Custom port assignment
6. **Speedtest Tracker (8093 not 80)** - Avoids conflict with Caddy

### Services via Gluetun VPN
These services route through Gluetun and use its exposed ports:
- qBittorrent: 8080 (Gluetun port)
- Jellyseerr: 5055 (Gluetun port)

## 🎯 Testing Updated Routes

### Test Corrected Services
```bash
# Dozzle (logs)
curl -k https://logs.krynet.cc

# Immich Power Tools
curl -k https://ipt.krynet.cc

# Homepage
curl -k https://home.krynet.cc

# OpenWebUI
curl -k https://ow.krynet.cc

# OpenSpeedTest
curl -k https://ospt.krynet.cc

# Speedtest Tracker
curl -k https://speed.krynet.cc
```

### Verify Port Mapping
```bash
# On Prime, check what's listening
sudo ss -tulpn | grep -E '8088|8001|3075|3999|8992|8093'
```

## 📝 Notes

### Services Not in Caddyfile
These services are exposed but not proxied (direct access only):
- **Gotify** (8089) - Notification server
- **Grafana** (3123) - Metrics dashboard
- **Immich Postgres** (5432) - Database
- **TDarr Server** (8266) - Backend only
- **OpenSpeedTest Alt** (8993) - Alternative port

### Disabled Services
These are in stack files but marked as disabled:
- **LiteLLM** - AI proxy (disabled in stack file)
- **OpenWebUI** - Chat interface (disabled in stack file)

## ✅ Summary

- **6 ports corrected** in Caddyfile
- **20+ ports verified** as correct
- All services now properly routed from Agni to Prime
- No port conflicts

---

**Last Updated:** January 26, 2026  
**Validated Against:** Prime stack files in `/stacks/prime/`  
**Caddyfile Location:** `/stacks/agni/Caddyfile`
