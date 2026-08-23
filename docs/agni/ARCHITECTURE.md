# KryNet Architecture: "The Heavy & The Light"

## Network Topology

```
                                    INTERNET
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
              Cloudflare          Tailscale         ISP Router
               Tunnel                VPN          (192.168.0.1)
                    │                  │                  │
                    └──────────────────┴──────────────────┘
                                       │
                              ┌────────┴────────┐
                              │                 │
                    ┌─────────▼────────┐ ┌─────▼──────────┐
                    │  KryNet-Agni     │ │  KryNet-Prime  │
                    │  "The Light"     │ │  "The Heavy"   │
                    │  192.168.0.200   │ │  192.168.0.100 │
                    └──────────────────┘ └────────────────┘
```

## Service Distribution

### KryNet-Agni (192.168.0.200) - Network Core
**Role:** Always-On "Brain"  
**Hardware:** SkullSaints Agni Mini-PC (Intel N150, 16GB RAM)  
**OS:** Ubuntu Server 24.04 LTS  
**Power:** ~15W

```
┌─────────────────────────────────────────┐
│           KryNet-Agni Stack             │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │         Portainer               │   │
│  │    Container Management         │   │
│  │         :9443                   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │         Caddy v2                │   │
│  │    Reverse Proxy + SSL          │   │
│  │      :80, :443 (host)           │   │
│  │  • Cloudflare DNS Plugin        │   │
│  │  • Automatic HTTPS              │   │
│  │  • Routes to Local + Prime      │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │      AdGuard Home               │   │
│  │    Primary DNS Server           │   │
│  │      :53, :3000 (host)          │   │
│  │  • Ad Blocking                  │   │
│  │  • Split-Horizon DNS            │   │
│  │  • Custom Rewrites              │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │     Home Assistant              │   │
│  │    Smart Home Hub               │   │
│  │      :8123 (host)               │   │
│  │  • Device Discovery             │   │
│  │  • Automations                  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │       Tailscale                 │   │
│  │      Mesh VPN                   │   │
│  │        (host)                   │   │
│  │  • Subnet Router                │   │
│  │  • Exit Node                    │   │
│  │  • Advertises 192.168.0.0/24    │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### KryNet-Prime (192.168.0.100) - Compute & Storage
**Role:** Heavy Compute, Storage, Media  
**Hardware:** Custom Build (i5-7600K, 32GB RAM, GTX 1060)  
**OS:** TrueNAS Scale 24.10  
**Storage:** 13TB (ZFS)  
**Power:** ~150W

```
┌─────────────────────────────────────────┐
│          KryNet-Prime Stack             │
├─────────────────────────────────────────┤
│                                         │
│  Storage Services                       │
│  ├─ Immich (Photos)        :2283       │
│  ├─ Paperless (Docs)       :8000       │
│  └─ Syncthing              :8384       │
│                                         │
│  Media Services                         │
│  ├─ Jellyfin               :8096       │
│  ├─ *arr Stack (Sonarr, Radarr, etc)   │
│  ├─ qBittorrent (via VPN)  :8080       │
│  ├─ SABnzbd                :8085       │
│  └─ Tdarr (GPU Transcode)  :8265       │
│                                         │
│  AI/Compute Services                    │
│  ├─ LiteLLM                :4000       │
│  └─ OpenWebUI              :8080       │
│                                         │
│  Monitoring                             │
│  ├─ Uptime Kuma            :3001       │
│  ├─ Prometheus             :9090       │
│  ├─ Dozzle                 :8080       │
│  └─ Speedtest Tracker      :80         │
│                                         │
│  Dashboards                             │
│  ├─ Homepage               :3000       │
│  └─ Homarr                 :7575       │
│                                         │
└─────────────────────────────────────────┘
```

## Traffic Flow Diagrams

### 1. Local LAN Access

```
User Device (192.168.0.x)
         │
         │ DNS Query: ha.krynet.cc
         ▼
    AdGuard Home (Agni :53)
         │
         │ Split-Horizon DNS
         │ Returns: 192.168.0.200
         ▼
    Caddy (Agni :443)
         │
         │ TLS Termination
         │ Route: ha.krynet.cc
         ▼
    Home Assistant (Agni :8123)
         │
         ▼
    Response (1Gbps LAN speed)
```

### 2. Remote Access via Cloudflare Tunnel

```
Remote User
         │
         │ HTTPS: photos.krynet.cc
         ▼
    Cloudflare Edge
         │
         │ Encrypted Tunnel
         ▼
    Caddy (Agni :443)
         │
         │ Reverse Proxy
         │ Route to Prime
         ▼
    Immich (Prime :2283)
         │
         ▼
    Response via Tunnel
```

### 3. VPN Access via Tailscale

```
Remote User (Tailscale)
         │
         │ WireGuard Encrypted
         ▼
    Tailscale (Agni)
         │
         │ Subnet Router
         │ 192.168.0.0/24
         ▼
    LAN Services
    ├─ Agni Services (Direct)
    └─ Prime Services (Routed)
```

### 4. Cross-Node Service Access

```
User Request: photos.krynet.cc
         │
         ▼
    Caddy (Agni :443)
         │
         │ Caddyfile Route:
         │ @immich host photos.krynet.cc
         │ reverse_proxy http://192.168.0.100:2283
         ▼
    Immich (Prime :2283)
         │
         ▼
    Response via Caddy
```

## DNS Resolution Flow

### Split-Horizon DNS Configuration

```
┌─────────────────────────────────────────────────────┐
│              AdGuard Home (Agni)                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Public Domains (*.krynet.cc)                      │
│  ├─ LAN Clients → 192.168.0.200 (Agni)            │
│  └─ External → Cloudflare Tunnel                   │
│                                                     │
│  Internal Domains (*.lan.kkasbi.in)                │
│  └─ All Clients → 192.168.0.200 (Agni)            │
│                                                     │
│  Custom DNS Rewrites                               │
│  ├─ *.krynet.cc → 192.168.0.200                   │
│  ├─ *.lan.kkasbi.in → 192.168.0.200               │
│  └─ server.krynet.cc → 192.168.0.100 (TrueNAS)    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Port Mapping Reference

### Agni (192.168.0.200)

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 53 | TCP/UDP | AdGuard | DNS Server |
| 80 | TCP | Caddy | HTTP (redirects to HTTPS) |
| 443 | TCP/UDP | Caddy | HTTPS + HTTP/3 |
| 3000 | TCP | AdGuard | Web UI |
| 8123 | TCP | Home Assistant | Web UI |
| 9443 | TCP | Portainer | Management UI |

### Prime (192.168.0.100)

| Port | Service | Proxied via Caddy |
|------|---------|-------------------|
| 88 | TrueNAS | server.krynet.cc |
| 2283 | Immich | photos.krynet.cc |
| 8096 | Jellyfin | media.krynet.cc |
| 8989 | Sonarr | sonarr.krynet.cc |
| 7878 | Radarr | radarr.krynet.cc |
| 9696 | Prowlarr | indexer.krynet.cc |
| 5055 | Jellyseerr | request.krynet.cc |
| ... | (30+ services) | ... |

## Data Flow: Photo Upload Example

```
1. Mobile App Upload
         │
         ▼
2. DNS Resolution (AdGuard)
   photos.krynet.cc → 192.168.0.200
         │
         ▼
3. HTTPS Request to Caddy (Agni)
   TLS Termination
         │
         ▼
4. Reverse Proxy Decision
   Caddyfile: @immich → 192.168.0.100:2283
         │
         ▼
5. Forward to Immich (Prime)
   HTTP (internal, no TLS needed)
         │
         ▼
6. Immich Processing
   ├─ Store in /mnt/andromeda/apps/immich
   ├─ Generate thumbnails (GPU)
   ├─ Facial recognition (GPU)
   └─ Update database
         │
         ▼
7. Response via Caddy
         │
         ▼
8. User sees uploaded photo
```

## Failover Strategy

### DNS Failover
```
Primary DNS: 192.168.0.200 (Agni)
    │
    │ If Agni fails
    ▼
Secondary DNS: 1.1.1.1 (Cloudflare)
    │
    │ Public resolution only
    │ No split-horizon
    ▼
Services still accessible via public IPs
```

### Service Failover
```
If Agni fails:
├─ DNS: Use Cloudflare DNS (1.1.1.1)
├─ Reverse Proxy: Direct access via IP:Port
├─ Home Assistant: Access via 192.168.0.200:8123
└─ AdGuard: Use Prime's AdGuard (if configured)

If Prime fails:
├─ Storage services unavailable
├─ Media services unavailable
└─ Network core (Agni) continues working
```

## Security Layers

```
┌─────────────────────────────────────────┐
│         External Access                 │
├─────────────────────────────────────────┤
│  Layer 1: No Open Ports                 │
│  └─ All traffic via Cloudflare Tunnel   │
│     or Tailscale VPN                    │
│                                         │
│  Layer 2: Cloudflare Zero Trust         │
│  └─ Google OAuth 2.0                    │
│     Email whitelist                     │
│                                         │
│  Layer 3: Caddy TLS                     │
│  └─ Automatic HTTPS                     │
│     Cloudflare DNS-01 challenge         │
│                                         │
│  Layer 4: Service Authentication        │
│  └─ Individual service logins           │
│                                         │
└─────────────────────────────────────────┘
```

## Backup Strategy

```
┌─────────────────────────────────────────┐
│         3-2-1 Backup Rule               │
├─────────────────────────────────────────┤
│                                         │
│  3 Copies:                              │
│  ├─ Live (Prime ZFS)                    │
│  ├─ Local Mirror (Syncthing → Legion)  │
│  └─ Cloud (Backblaze B2)                │
│                                         │
│  2 Media:                               │
│  ├─ HDD (Prime)                         │
│  └─ SSD (Comet pool)                    │
│                                         │
│  1 Offsite:                             │
│  └─ Encrypted cloud backup              │
│                                         │
└─────────────────────────────────────────┘
```

---

**Architecture:** "The Heavy & The Light"  
**Design Philosophy:** Separation of concerns  
**Agni:** Network core, always-on, low power  
**Prime:** Compute, storage, high power when needed
