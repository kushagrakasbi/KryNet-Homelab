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
              ║       192.168.1.200         ║
              ║   (SkullSaints Mini PC)     ║
              ║                             ║
              ║   Caddy ↔ Cloudflared       ║
              ║   AdGuard (Primary)         ║
              ║   AdGuard Home Sync         ║
              ║   Tailscale                 ║
              ╚══════════════╦══════════════╝
                             ║
              ╔══════════════▼══════════════╗
              ║      🌟 PRIME SERVER        ║
              ║       192.168.1.100         ║
              ║   (MSI Cabinet, TrueNAS)    ║
              ║                             ║
              ║   AdGuard (Secondary)       ║
              ║   All Storage + Services    ║
              ╚═════════════════════════════╝
```

---

## 🔗 Access Domains

### Public Access (Cloudflare Tunnel + OAuth)

| Service | URL |
|---------|-----|
| Dashboard | `https://home.example.com` |
| Photos | `https://photos.example.com` |
| Media | `https://media.example.com` |
| Requests | `https://request.example.com` |
| Status | `https://status.example.com` |

### Internal/VPN Access (No Auth Proxy)

| Service | URL |
|---------|-----|
| TrueNAS | `https://server.internal.home` |
| Portainer (Prime) | `https://portainer.internal.home` |
| Portainer (Agni) | `https://portainer2.internal.home` |
| Logs (Prime) | `https://logs.internal.home` |
| Logs (Agni) | `https://logs2.internal.home` |

---

## 🚦 Traffic Flow Summary

| From | To | Path |
|------|----|------|
| Home LAN | Service | DNS → 192.168.1.200 (Agni primary) → Caddy → Service |
| Remote (Public) | Service | Cloudflare → Tunnel → Agni → Caddy → Service |
| Remote (VPN) | Service | Tailscale → P2P → Caddy → Service |
| Service to Service | Backend | Docker network (kry_net) |

---

## 🔧 Common Operations

### Check DNS Resolution

```bash
# From LAN — should return local IP (queries Agni primary DNS)
nslookup photos.example.com 192.168.1.200

# From LAN — should also work via Prime secondary DNS
nslookup photos.example.com 192.168.1.100

# From external (should return Cloudflare IP)
nslookup photos.example.com 1.1.1.1
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

### Agni (192.168.1.200) — Network Core

| Port | Service |
|------|---------|
| 53 | AdGuard DNS (Primary) |
| 80/443 | Caddy |
| 3000 | Grafana |
| 3001 | Gatus |
| 8082 | AdGuard Home Sync |
| 8123 | Home Assistant |
| 9090 | Prometheus |

### Prime (192.168.1.100) — Storage Hub

| Port | Service |
|------|---------|
| 53 | AdGuard DNS (Secondary) |
| 88 | TrueNAS UI |
| 2283 | Immich |
| 8096 | Jellyfin |
| 8989 | Sonarr |
| 7878 | Radarr |
| 13378 | Audiobookshelf |

---

## 🛠️ Troubleshooting

### Service Not Reachable

1. **Check Caddy:** `docker logs caddy`
2. **Check DNS:** `nslookup <domain> 192.168.1.200` (primary on Agni)
3. **Check container:** `docker ps | grep <service>`

### Slow Tunnel Performance

1. Use Tailscale VPN for large transfers
2. Check home upload speed: `speedtest-cli`
3. For media, use LAN URL when at home

### DNS Not Working

1. Check AdGuard on Agni (primary): `docker ps | grep adguard`
2. Check AdGuard on Prime (secondary): same command on Prime
3. Verify router DHCP DNS settings point to Agni (192.168.1.200) and Prime (192.168.1.100)
4. Check AdGuard Home Sync status on Agni: `docker logs adguardhome-sync --tail 20`

---

## 📁 Config File Locations

| File | Path | Server |
|------|------|--------|
| Caddyfile | `/home/agni/apps/docker/caddy/Caddyfile` | Agni |
| AdGuard Config (Primary) | `/home/agni/apps/docker/adguard/conf/` | Agni |
| AdGuard Sync Config | `/home/agni/apps/docker/adguard-sync/` | Agni |
| AdGuard Config (Secondary) | `/mnt/orion/apps-config/adguardhome/conf/` | Prime |
| Prometheus | `/home/agni/apps/docker/prometheus/config/` | Agni |

---

## 📖 Full Documentation

| Document | Description |
|----------|-------------|
| [AGNI-SERVER.md](AGNI-SERVER.md) | Agni server documentation (Network Core) |
| [PRIME-SERVER.md](PRIME-SERVER.md) | Prime server documentation (Storage Hub) |

---

**Last Updated:** February 2026
