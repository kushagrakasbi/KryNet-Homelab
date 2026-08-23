# Caddyfile Changes for Agni

## 📋 Summary of Changes

Your Caddyfile has been updated to work on Agni (192.168.0.200) and route traffic correctly between Agni and Prime.

## 🔄 Key Changes Made

### Services Now on Agni (Local - 127.0.0.1)

| Service | Domain | Old Target | New Target | Port |
|---------|--------|------------|------------|------|
| **AdGuard Home** | adguard.krynet.cc | Container name | 127.0.0.1 | 7000 |
| **AdGuard Sync** | adsync.krynet.cc | Prime (192.168.0.100) | 127.0.0.1 | 8082 |
| **Home Assistant** | ha.krynet.cc | Prime (192.168.0.100) | 127.0.0.1 | 8123 |
| **Portainer (Agni)** | portainer2.krynet.cc | 192.168.0.200 | 127.0.0.1 | 9443 |

### Services Remaining on Prime (Remote - 192.168.0.100)

All other services now explicitly route to Prime:

- **Storage:** Immich, Paperless
- **Media:** Jellyfin, *arr stack, qBittorrent, SABnzbd
- **AI:** LiteLLM, OpenWebUI
- **Monitoring:** Uptime Kuma, Prometheus, Dozzle
- **Dashboards:** Homepage, Homarr
- **Infrastructure:** TrueNAS, Portainer (Prime), Syncthing

## 🎯 How It Works

```
User Request: https://ha.krynet.cc
         │
         ▼
    Caddy (Agni :443)
         │
         ├─ Local Service? → 127.0.0.1:port
         │  • AdGuard (7000)
         │  • Home Assistant (8123)
         │  • AdGuard Sync (8082)
         │  • Portainer2 (9443)
         │
         └─ Remote Service? → 192.168.0.100:port
            • All Prime services
```

## 📝 Detailed Changes

### 1. AdGuard Home
```caddyfile
# OLD (Prime)
@adguard host adguard.krynet.cc adguard.lan.kkasbi.in
handle @adguard {
    reverse_proxy adguardhome:80  # Container name
}

# NEW (Agni)
@adguard host adguard.krynet.cc adguard.lan.kkasbi.in
handle @adguard {
    reverse_proxy http://127.0.0.1:7000  # Local on Agni
}
```

**Why:** AdGuard now runs on Agni on port 7000 (not 80, to avoid conflict with Caddy)

### 2. AdGuard Home Sync
```caddyfile
# OLD (Prime)
@adsync host adsync.krynet.cc adsync.lan.kkasbi.in
handle @adsync {
    reverse_proxy adguardhome-sync:8080  # Container name
}

# NEW (Agni)
@adsync host adsync.krynet.cc adsync.lan.kkasbi.in
handle @adsync {
    reverse_proxy http://127.0.0.1:8082  # Local on Agni
}
```

**Why:** AdGuard Sync now runs on Agni to sync from Prime

### 3. Home Assistant
```caddyfile
# OLD (Prime)
@ha host ha.krynet.cc ha.lan.kkasbi.in
handle @ha {
    reverse_proxy http://192.168.0.100:8123  # Prime
}

# NEW (Agni)
@ha host ha.krynet.cc ha.lan.kkasbi.in
handle @ha {
    reverse_proxy http://127.0.0.1:8123  # Local on Agni
}
```

**Why:** Home Assistant migrated from Prime to Agni

### 4. Portainer (Agni)
```caddyfile
# OLD (Legion/Agni)
@portainer2 host portainer2.krynet.cc portainer2.lan.kkasbi.in
handle @portainer2 {
    reverse_proxy https://192.168.0.200:9443  # Remote
}

# NEW (Agni)
@portainer2 host portainer2.krynet.cc portainer2.lan.kkasbi.in
handle @portainer2 {
    reverse_proxy https://127.0.0.1:9443  # Local on Agni
}
```

**Why:** Portainer is now running locally on Agni

### 5. All Prime Services
All services still on Prime now explicitly use `http://192.168.0.100:port`:

- Immich → `http://192.168.0.100:2283`
- Jellyfin → `http://192.168.0.100:8096`
- Sonarr → `http://192.168.0.100:8989`
- Radarr → `http://192.168.0.100:7878`
- etc.

**Why:** Caddy on Agni needs to know where to find Prime services

## ✅ What This Achieves

### 1. **Centralized Reverse Proxy**
- All traffic goes through Caddy on Agni
- Single point for SSL termination
- Unified access to all services

### 2. **Service Distribution**
- **Agni (Light):** Network core services (DNS, HA, Caddy)
- **Prime (Heavy):** Storage, media, compute-intensive services

### 3. **Transparent Access**
- Users access services the same way
- `ha.krynet.cc` → Agni
- `photos.krynet.cc` → Prime (via Agni proxy)
- No need to remember which server hosts what

### 4. **Failover Ready**
- If Prime fails, Agni services still work
- DNS, Home Assistant, Portainer remain accessible
- Can quickly redirect traffic if needed

## 🔍 Testing Your Setup

### Test Local Services (Agni)
```bash
# From any device on your network
curl -k https://adguard.krynet.cc
curl -k https://ha.krynet.cc
curl -k https://portainer2.krynet.cc
curl -k https://adsync.krynet.cc
```

### Test Remote Services (Prime via Agni)
```bash
curl -k https://photos.krynet.cc  # Immich on Prime
curl -k https://media.krynet.cc   # Jellyfin on Prime
curl -k https://portainer.krynet.cc  # Portainer on Prime
```

### Verify Routing
```bash
# On Agni, check Caddy logs
docker logs -f caddy

# You should see:
# - Local services: 127.0.0.1:port
# - Remote services: 192.168.0.100:port
```

## 🛠️ Port Reference

### Agni Local Services
| Service | Port | Access |
|---------|------|--------|
| Caddy | 80, 443 | Reverse proxy |
| AdGuard Home | 7000 | Web UI |
| AdGuard DNS | 53 | DNS queries |
| AdGuard Sync | 8082 | Sync monitoring |
| Home Assistant | 8123 | Smart home |
| Portainer | 9443 | Container mgmt |
| Tailscale | - | VPN mesh |

### Prime Remote Services
All accessed via Agni's Caddy, but hosted on Prime (192.168.0.100)

## 🚨 Important Notes

### 1. AdGuard Port Change
AdGuard's web UI is on **port 7000** (not 80) to avoid conflict with Caddy.

Make sure your AdGuard configuration has:
```yaml
http:
  address: 0.0.0.0:7000
```

### 2. Network Mode
Caddy uses `network_mode: host`, so it can access:
- `127.0.0.1` → Local Agni services
- `192.168.0.100` → Prime services
- `192.168.0.200` → Legion services (if any)

### 3. DNS Resolution
For this to work, your DNS (AdGuard) must resolve:
- `*.krynet.cc` → `192.168.0.200` (Agni)
- `*.lan.kkasbi.in` → `192.168.0.200` (Agni)

Then Caddy routes internally to the correct backend.

### 4. SSL Certificates
Caddy will automatically obtain SSL certificates for all domains using Cloudflare DNS-01 challenge.

## 📊 Traffic Flow Example

### Example 1: Accessing Home Assistant
```
User → https://ha.krynet.cc
  ↓
DNS (AdGuard on Agni) → 192.168.0.200
  ↓
Caddy (Agni :443) → SSL termination
  ↓
Caddyfile route: @ha → 127.0.0.1:8123
  ↓
Home Assistant (Agni) → Response
```

### Example 2: Accessing Immich
```
User → https://photos.krynet.cc
  ↓
DNS (AdGuard on Agni) → 192.168.0.200
  ↓
Caddy (Agni :443) → SSL termination
  ↓
Caddyfile route: @immich → 192.168.0.100:2283
  ↓
Immich (Prime) → Response via Caddy
```

## 🎯 Next Steps

1. **Deploy Caddy** with updated Caddyfile
2. **Update DNS** to point to Agni (192.168.0.200)
3. **Test all services** using the domains
4. **Monitor Caddy logs** for any routing issues
5. **Update Cloudflare Tunnel** to point to Agni

---

**Last Updated:** January 26, 2026  
**Caddy Location:** Agni (192.168.0.200)  
**Configuration:** Centralized reverse proxy for all KryNet services
