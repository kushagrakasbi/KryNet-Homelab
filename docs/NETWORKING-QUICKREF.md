# 🌐 KryNet Networking Quick Reference

**One-Page Guide for Common Networking Tasks**

---

## 🗺️ Network Topology

```
                    ┌─────────────────┐
                    │    INTERNET     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
       ┌──────▼──────┐ ┌─────▼─────┐ ┌──────▼──────┐
       │ Cloudflare  │ │ Tailscale │ │   Router    │
       │   Tunnel    │ │    VPN    │ │   (Home)    │
       └──────┬──────┘ └─────┬─────┘ └──────┬──────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
              ╔══════════════▼══════════════╗
              ║      🔥 AGNI SERVER         ║
              ║       192.168.0.200         ║
              ║                             ║
              ║   Caddy ↔ Cloudflared       ║
              ║   AdGuard (Primary)         ║
              ║   AdGuard Home Sync         ║
              ║   Tailscale                 ║
              ╚══════════════╦══════════════╝
                             ║
              ╔══════════════▼══════════════╗
              ║      🌟 PRIME SERVER        ║
              ║       192.168.0.100         ║
              ║                             ║
              ║   AdGuard (Secondary)       ║
              ║   All Services              ║
              ╚═════════════════════════════╝
```

---

## 🔗 Access Domains

### Public Access (Cloudflare Tunnel + OAuth)

| Service | URL |
|---------|-----|
| Dashboard | `https://home.krynet.cc` |
| Photos | `https://photos.krynet.cc` |
| Media | `https://media.krynet.cc` |
| Requests | `https://request.krynet.cc` |
| Status | `https://status.krynet.cc` |

### Internal/VPN Access (No Auth Proxy)

| Service | URL |
|---------|-----|
| TrueNAS | `https://server.lan.kkasbi.in` |
| Portainer (Prime) | `https://portainer.lan.kkasbi.in` |
| Portainer (Agni) | `https://portainer2.lan.kkasbi.in` |
| Logs (Prime) | `https://logs.lan.kkasbi.in` |
| Logs (Agni) | `https://logs2.lan.kkasbi.in` |

---

## 🚦 Traffic Flow Summary

| From | To | Path |
|------|----|------|
| Home LAN | Service | DNS → 192.168.0.100/200 → Caddy → Service |
| Remote (Public) | Service | Cloudflare → Tunnel → Agni → Caddy → Service |
| Remote (VPN) | Service | Tailscale → P2P → Caddy → Service |
| Service to Service | Backend | Docker network (kry_net) |

---

## 🔧 Common Operations

### Check DNS Resolution

```bash
# From LAN (should return local IP)
nslookup photos.krynet.cc 192.168.0.200

# From external (should return Cloudflare IP)
nslookup photos.krynet.cc 1.1.1.1
```

### Restart Reverse Proxy

```bash
# On Agni
docker restart caddy
docker logs caddy --tail 20
```

### Check Tunnel Status

```bash
# On Agni
docker logs cloudflared --tail 20
```

### Check VPN Status

```bash
# On Agni
docker exec tailscale-agni tailscale status
```

### Reload Caddyfile

```bash
# On Agni
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## 📊 Key Ports

### Agni (192.168.0.200)

| Port | Service |
|------|---------|
| 53 | AdGuard DNS |
| 80/443 | Caddy |
| 3000 | Grafana |
| 3001 | Gatus |
| 8123 | Home Assistant |
| 9090 | Prometheus |

### Prime (192.168.0.100)

| Port | Service |
|------|---------|
| 53 | AdGuard DNS |
| 88 | TrueNAS UI |
| 2283 | Immich |
| 8096 | Jellyfin |
| 8989 | Sonarr |
| 7878 | Radarr |

---

## 🛠️ Troubleshooting

### Service Not Reachable

1. **Check Caddy:** `docker logs caddy`
2. **Check DNS:** `nslookup <domain> 192.168.0.200`
3. **Check container:** `docker ps | grep <service>`

### Slow Tunnel Performance

1. Use Tailscale VPN for large transfers
2. Check home upload speed: `speedtest-cli`
3. For media, use LAN URL when at home

### DNS Not Working

1. Check AdGuard: `docker ps | grep adguard`
2. Verify router DHCP DNS settings
3. Check AdGuard Sync status

---

## 📁 Config File Locations

| File | Path | Server |
|------|------|--------|
| Caddyfile | `/home/agni/apps/docker/caddy/Caddyfile` | Agni |
| AdGuard Config | `/home/agni/apps/docker/adguard/conf/` | Agni |
| AdGuard Config | `/mnt/orion/apps-config/adguardhome/conf/` | Prime |
| Prometheus | `/home/agni/apps/docker/prometheus/config/` | Agni |

---

## 📖 Full Documentation

| Document | Description |
|----------|-------------|
| [networking.md](networking.md) | Complete networking deep dive |
| [AGNI-SERVER.md](AGNI-SERVER.md) | Agni server documentation |
| [PRIME-SERVER.md](PRIME-SERVER.md) | Prime server documentation |

---

**Last Updated:** February 2026
