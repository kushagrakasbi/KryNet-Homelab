# 🌌 Project KryNet: Production-Grade Private Cloud

**Architected for Resilience | Powered by ZFS | Secured by Zero Trust**

Welcome to KryNet, a production-grade private cloud ecosystem serving a family of four. This repository documents the complete hardware, software, and networking architecture of a self-hosted infrastructure that rivals commercial cloud services while maintaining complete data sovereignty.

---

## 📋 Table of Contents

1. [Philosophy & Design Principles](#philosophy--design-principles)
2. [Hardware Architecture](#hardware-architecture)
3. [Storage Architecture (ZFS)](#storage-architecture)
4. [Networking Stack](#networking-stack)
5. [Service Ecosystem](#service-ecosystem)
6. [Backup & Resilience](#backup--resilience)
7. [Security Implementation](#security-implementation)
8. [Monitoring & Operations](#monitoring--operations)
9. [Future Roadmap](#future-roadmap)

---

## 🎯 Philosophy & Design Principles

KryNet operates under the **"Home Utility"** model — when the system is down, the house is "broken."

### Core Pillars

**Digital Sovereignty**
- 100% ownership of 500GB+ family photos, documents, and media
- No monthly storage subscriptions or vendor lock-in
- Complete control over personal data lifecycle
- Successful migration from Google Photos to self-hosted Immich

**The WAF (Wife Approval Factor)**
- Services must match "Big Tech" reliability and UX
- 99.9% uptime target (8.76 hours downtime/year)
- If kids can't watch movies or wife can't backup photos, system is "down"
- Seamless experience across all devices

**Zero Trust Architecture**
- No open ports exposed to internet
- Identity-based access via Google OAuth 2.0
- Split-horizon DNS for intelligent routing
- All external traffic through encrypted tunnels

**Production Standards**
- Infrastructure-as-Code via Docker Compose
- Automated health monitoring and alerting
- Centralized logging with Dozzle
- Quarterly backup restoration tests

---

## 🖥️ Hardware Architecture

### KryNet-Prime (Primary Server)

| Component | Specification |
|-----------|---------------|
| **Chassis** | Fractal Design Node 804 (Dual-chamber, optimized for HDD cooling) |
| **CPU** | Intel i5-7600K (4C/4T @ 3.8GHz) - Strong single-core for microservices |
| **RAM** | 32GB Crucial DDR4 - ZFS ARC + 40+ containers + ML workloads |
| **GPU** | NVIDIA GTX 1060 6GB - NVENC transcoding + Immich facial recognition |
| **OS** | TrueNAS SCALE (Dragonfish 24.10) - Linux-based NAS with Docker |
| **Network** | 1Gbps Ethernet (Intel I219-V) |
| **IP** | 192.168.0.100 (Static DHCP) |

**Role:** Storage hub, media processing, AI workloads, core infrastructure

---

### KryNet-Legion (Secondary Sentinel)

| Component | Specification |
|-----------|---------------|
| **Hardware** | Repurposed Ubuntu Server Laptop |
| **OS** | Ubuntu Server 24.04 LTS |
| **RAM** | 16GB DDR4 |
| **Storage** | 512GB NVMe SSD |
| **Network** | 1Gbps Ethernet |
| **IP** | 192.168.0.200 (Static DHCP) |
| **Power** | ~20W (clamshell mode, display off) |

**Services:**
- AdGuard Home (Secondary DNS with auto-failover)
- Syncthing (Real-time config backup from Prime)
- Portainer Agent (Remote management)
- Tailscale (Mesh VPN node)
- OpenSpeedTest (Network testing)

**Planned Upgrade:** Awaiting **SkullSaints Agni Mini-PC** (Intel N150, 16GB RAM, built-in LCD) for lower power consumption and better form factor.

---

## 💾 Storage Architecture

All storage managed via **TrueNAS SCALE** with ZFS providing enterprise-grade data integrity.

### Storage Pools

| Pool | Hardware | Type | Capacity | Purpose |
|------|----------|------|----------|---------|
| **orion** | 2x 4TB WD Red Plus | Mirror | ~4TB | **The Vault** - App configs, databases |
| **comet** | 2x 1TB NVMe SSD | Mirror | ~1TB | **The Ingest** - Downloads, Tdarr cache |
| **andromeda** | 1x 8TB Seagate IronWolf | Single | 8TB | **The Archive** - Media, photos, documents |

### Dataset Structure

```
/mnt/orion/apps-config/     # All Docker container configs (30+ services)
/mnt/comet/downloads/       # qBittorrent & SABnzbd active downloads
/mnt/comet/tdarr-cache/     # Transcoding temporary files
/mnt/andromeda/apps/immich/ # 500GB+ family photos & videos
/mnt/andromeda/apps/paperless/ # Scanned documents
/mnt/andromeda/data/media/  # Movies, TV shows, documentaries
```

### ZFS Configuration

**Snapshot Strategy:**
- **orion:** Every 6 hours, 48h retention (config protection)
- **comet:** Daily, 7-day retention (download protection)
- **andromeda:** Weekly, 4-week retention (media protection)

**Data Integrity:**
- Automatic checksum verification on every read
- Self-healing from mirror copies
- Weekly scrubs (Sundays 02:00 AM)
- SMART tests: Long monthly, short weekly

**Performance:**
- ARC: ~20GB RAM allocated
- Compression: LZ4 (~15% space savings)
- Recordsize: 128K (databases), 1M (media)

---

## 🌐 Networking Stack (The Secret Sauce)

### Architecture Overview

```
Internet
    │
    ├─→ Cloudflare Tunnel (cloudflared) ─→ Caddy ─→ Services
    ├─→ Tailscale VPN Mesh ──────────────→ Caddy ─→ Services  
    └─→ LAN → AdGuard (Split-Horizon) ───→ Caddy ─→ Services
```

### 4.1 Reverse Proxy: Caddy v2

**Evolution:**
1. **Nginx Proxy Manager** → Retired (lack of automation)
2. **Traefik v3** → Replaced (label complexity)
3. **Caddy v2** → Current (simplicity + power)

**Why Caddy:**
- Centralized Caddyfile (Infrastructure-as-Code)
- Native Cloudflare DNS-01 challenge
- 3 lines config vs 15+ Traefik labels
- Automatic HTTPS with zero configuration
- HTTP/3 (QUIC) support enabled

**Configuration Pattern:**
```caddyfile
*.mydomain.com, *.lan.mydomain2.com {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    
    @immich host photos.mydomain.com photos.lan.mydomain2.com
    handle @immich {
        reverse_proxy immich-server:2283
    }
}
```

### 4.2 Split-Horizon DNS

**Primary:** AdGuard Home on Prime (192.168.0.100)  
**Secondary:** AdGuard Home on Legion (192.168.0.200)  
**Sync:** AdGuard Home Sync (every 5 minutes)

| Location | URL | Resolves To | Speed |
|----------|-----|-------------|-------|
| Home LAN | `photos.mydomain.com` | 192.168.0.100 | 1Gbps |
| Remote | `photos.mydomain.com` | Cloudflare Tunnel | ISP Upload |
| Tailscale | `photos.lan.mydomain2.com` | 100.x.x.x | P2P Mesh |

**Benefits:**
- Local traffic stays on LAN (no internet consumption)
- Services work even if internet is down
- Transparent to users (same URL everywhere)

### 4.3 Domain Strategy

**mydomain.com (Public):**
- Cloudflare-managed DNS
- Exposed via Cloudflare Tunnel
- Google OAuth 2.0 protected
- Services: Immich, Jellyfin, Jellyseerr, Homepage

**mydomain2.com (Internal/VPN):**
- AdGuard DNS rewrites
- `*.lan.mydomain2.com` → LAN access
- No public DNS records (security)
- Admin interfaces only

### 4.4 Cloudflare Tunnel

**How It Works:**
```
User → Cloudflare Edge → Encrypted Tunnel → Caddy → Service
```

**Benefits:**
- No open ports on router
- Home IP hidden behind Cloudflare
- DDoS protection included
- Works behind CGNAT

**Security:** Cloudflare Zero Trust Access
- Google OAuth 2.0 authentication
- Email whitelist (family members only)
- 24-hour session duration

### 4.5 Tailscale Mesh VPN

**Prime Configuration:**
- Subnet router (advertises 192.168.0.0/24)
- Exit node (route internet through home)
- MagicDNS enabled

**Use Cases:**
- SSH administrative access
- Access internal services (Portainer, logs)
- Secure public Wi-Fi usage
- Direct NAS access via Samba

**Security:**
- End-to-end WireGuard encryption
- Key-based authentication
- Per-device ACLs

---

## 🎬 Service Ecosystem

**40+ Docker containers** deployed via Portainer Stacks.

### Media Automation (*arr Stack)

**Workflow:**
```
Jellyseerr (Request) → Prowlarr (Search) → Sonarr/Radarr (Manage)
→ qBittorrent/SABnzbd (Download) → Tdarr (Optimize) → Jellyfin (Stream)
```

| Service | Purpose | Access |
|---------|---------|--------|
| Jellyseerr | User requests | `request.mydomain.com` |
| Prowlarr | Indexer management | Admin only |
| Sonarr | TV automation | Admin only |
| Radarr | Movie automation | Admin only |
| Bazarr | Subtitle management | Admin only |
| qBittorrent | Torrent client (via Gluetun VPN) | Admin only |
| SABnzbd | Usenet client | Admin only |
| Tdarr | GPU transcoding to HEVC (~40% savings) | Admin only |
| Jellyfin | Media streaming (4K hardware accel) | `media.mydomain.com` |

**Gluetun VPN:** All downloads through Surfshark WireGuard with kill switch.

### Personal Data & Productivity

**Immich (Photo Management)**
- 500GB+ migrated from Google Photos
- GPU facial recognition
- Natural language search ("beach photos")
- Access: `photos.mydomain.com`

**Paperless-ngx (Documents)**
- OCR for scanned mail/documents
- Automatic tagging and categorization
- Storage: andromeda pool
- Mobile scan → auto-import workflow

**FreshRSS** - RSS feed aggregation (currently disabled)

### AI Playground

**LiteLLM** - Centralized LLM proxy gateway (currently disabled)
**OpenWebUI** - ChatGPT-style interface (currently disabled)

### Dashboards

**Homepage** - Primary dashboard with service status  
**Homarr** - Alternative icon-based launcher

### Home Automation

**Home Assistant** - Smart home control (host network mode)

---

## 🔄 Backup & Resilience

### 3-2-1 Backup Rule

**3 Copies:**
1. Live data on ZFS pools
2. Local mirror via Syncthing to Legion
3. Encrypted cloud backup (Backblaze B2)

**2 Media:**
- HDD (orion, andromeda)
- SSD (comet)

**1 Offsite:**
- Critical photos encrypted (age + rclone)
- Nightly incremental sync at 02:00 AM

### Application Backups

**Syncthing Mirroring:**
- Source: `/mnt/orion/apps-config` (Prime)
- Destination: Legion (read-only sync)
- Real-time with 60s scan interval

**What's Backed Up:**
- All Portainer stack configs
- Environment files
- Database dumps (weekly cron)
- SSL certificates

---

## 🔒 Security Implementation

### Zero Trust Layers

1. **Network:** No router ports open, tunnels only
2. **Application:** Google OAuth for public services
3. **Service:** Docker network isolation

### Docker Security

**Networks:**
- `kry_net` - Internal service communication
- `traefik_proxy` - Web-exposed containers
- `host` - Tailscale, Home Assistant, AdGuard

**Isolation:**
- User namespacing (PUID/PGID)
- Read-only mounts where possible
- Minimal `privileged` flag usage

### VPN Kill Switch (Gluetun)

- Firewall blocks traffic if VPN drops
- DNS leak protection
- Only allows local networks + VPN server

---

## 📊 Monitoring & Operations

### Health Monitoring

**Uptime Kuma**
- HTTP 200 checks for all services
- Docker container health status
- Disk space alerts (80% warning)
- Certificate expiry warnings

**Notifications:** Gotify push to mobile

### Metrics & Logging

**Prometheus** - Metrics collection (15-day retention)  
**Grafana** - Visualization dashboards  
**Dozzle** - Real-time container logs  

### Automated Maintenance

**Watchtower** - Daily updates at 04:00 AM (currently disabled)  
**Speedtest Tracker** - Hourly ISP monitoring

---

## 🚀 Future Roadmap

### Infrastructure
- [ ] Deploy SkullSaints Agni (replacing Legion)
- [ ] Vaultwarden password manager
- [ ] Nextcloud collaborative editing
- [ ] Grafana custom dashboards

### Storage
- [ ] Expand orion: Add 2x 8TB (mirror vdev)
- [ ] Convert andromeda to mirror (2nd 8TB)
- [ ] Hot spare drive for auto-resilver

### Networking
- [ ] WireGuard backup VPN
- [ ] IPv6 support throughout stack

### Services
- [ ] Audiobookshelf for audiobooks
- [ ] Calibre-Web for ebooks
- [ ] Mealie recipe management
- [ ] Re-enable AI stack (LiteLLM + OpenWebUI)

---

## 📚 Lessons Learned

### What Went Right
- ZFS saved data from drive errors multiple times
- Split-horizon DNS eliminates internet dependency
- GPU transcoding: 40% storage savings, no quality loss
- Cloudflare Tunnel more reliable than dynamic DNS

### What I'd Do Differently
- Start with Caddy (skip Traefik migration)
- ECC RAM from day one (future build)
- Proper VLAN segmentation for IoT
- More modular UPS for easier expansion

### Key Takeaways
- **Backups are not optional** - Test restores quarterly
- **Documentation saves hours** - Future you is grateful
- **KISS principle** - Complexity kills reliability
- **WAF is real** - Family usability = success metric

---

## 🙏 Acknowledgments

- **TrueNAS Community** - Excellent documentation
- **r/selfhosted** - Inspiration and troubleshooting
- **LinuxServer.io** - Quality Docker images
- **Caddy Team** - Powerful, simple reverse proxy

---

**Last Updated:** January 2026  
**TrueNAS Version:** Dragonfish 24.10  
**Storage:** ~13TB usable  
**Services:** 40+ Docker containers  
**Uptime Target:** 99.9%

*Built with ❤️ for digital sovereignty and family convenience.*
