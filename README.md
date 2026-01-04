# 🌌 Project KryNet: The Private Cloud Homelab

**Architected for Resilience | Powered by ZFS | Secured by Zero Trust**

> A production-grade private cloud ecosystem serving a family of four, built on enterprise networking principles with complete data sovereignty.

---

## 📋 Table of Contents

- [Philosophy & Design Principles](#philosophy--design-principles)
- [Hardware Architecture](#hardware-architecture)
- [Storage Architecture (ZFS)](#storage-architecture-zfs)
- [Networking Stack](#networking-stack)
- [Service Ecosystem](#service-ecosystem)
- [Backup & Resilience Strategy](#backup--resilience-strategy)
- [Security Implementation](#security-implementation)
- [Monitoring & Operations](#monitoring--operations)

---

## 🎯 Philosophy & Design Principles

KryNet operates under the **"Home Utility"** model — when the system is down, the house is "broken."

### Core Pillars

**Digital Sovereignty**
- 100% ownership of photos, documents, and media
- No monthly storage subscriptions or vendor lock-in
- Complete control over personal data lifecycle

**The WAF (Wife Approval Factor)**
- Services must be as reliable and intuitive as their "Big Tech" counterparts
- 99.9% uptime target for family-critical services
- Seamless user experience across all devices

**Zero Trust Architecture**
- No open ports exposed to the internet
- Identity-based access control via Google OAuth 2.0
- Split-horizon DNS for intelligent routing
- Mesh VPN for secure administrative access

**Production Standards**
- Infrastructure-as-Code approach with Portainer
- Automated updates and health monitoring
- Real-time alerting via Gotify
- Comprehensive logging with Dozzle

---

## 🖥️ Hardware Architecture

### KryNet-Prime (Primary Server)
**Role:** Storage Hub, Media Processing, AI Workloads

| Component | Specification |
|-----------|---------------|
| **Chassis** | Fractal Design Node 804 (Dual-chamber, optimized for HDD cooling) |
| **CPU** | Intel i5-7600K (4C/4T @ 3.8GHz) |
| **RAM** | 32GB Crucial DDR4 |
| **GPU** | NVIDIA GTX 1060 6GB (Dedicated to Tdarr transcoding & Immich ML) |
| **OS** | TrueNAS SCALE (Dragonfish/Cobalt) |
| **Local IP** | 192.168.0.100 |

**Why this configuration:**
- Strong single-core performance for Go-based microservices
- Dedicated GPU for hardware-accelerated transcoding (NVENC) and facial recognition
- ECC-like data integrity via ZFS without ECC RAM requirement

---

### KryNet-Agni (Secondary Sentinel)
**Role:** High-Availability DNS, Configuration Backup, Failover Node

| Component | Specification |
|-----------|---------------|
| **Model** | SkullSaints Agni Mini-PC |
| **CPU** | Intel N150 (Twin Lake) |
| **RAM** | 16GB DDR4 |
| **Storage** | 512GB NVMe SSD |
| **OS** | Ubuntu Server 24.04 LTS |
| **Unique Feature** | Built-in LCD screen for real-time system monitoring |
| **Local IP** | 192.168.0.200 |

**Purpose:**
- Secondary DNS server (AdGuard Home) for 24/7 uptime
- Real-time configuration mirroring via Syncthing
- Lightweight, low-power consumption (< 15W)

---

### Retired: KryNet-Legion
**Former Role:** Secondary Ubuntu Server

**Reason for Retirement:**
- Excessive power consumption for limited use case
- Laptop form factor unsuitable for 24/7 operation
- Replaced by more efficient Agni node

---

## 💾 Storage Architecture (ZFS)

All storage is managed via **TrueNAS SCALE** with strict parity, health monitoring, and automatic snapshots.

### Storage Pools

| Pool Name | Hardware | Capacity | Purpose |
|-----------|----------|----------|---------|
| **orion** | 2x 4TB WD Red Plus (Mirror) | ~4TB usable | **The Vault** - Family photos (Immich), Documents (Paperless), Application configs |
| **comet** | 2x 1TB NVMe SSD (Mirror) | ~1TB usable | **The Ingest** - High-speed downloads, Tdarr processing cache, Database storage (PostgreSQL, Redis) |
| **andromeda** | 1x 8TB Seagate IronWolf | 8TB | **The Archive** - Movies, TV shows, long-term media storage |

### ZFS Benefits in Practice

**Data Integrity**
- Automatic checksum verification on every read
- Self-healing from mirror copies on detected corruption
- Protection against bit rot and silent data corruption

**Snapshot Strategy**
- Hourly snapshots of `orion` pool (24-hour retention)
- Daily snapshots of `comet` pool (7-day retention)
- Weekly snapshots of `andromeda` pool (30-day retention)

**Performance Optimization**
- L2ARC caching disabled (adequate RAM for ARC)
- Special metadata vdev consideration for future expansion
- Recordsize tuning per dataset (128K for databases, 1M for media)

---

## 🌐 Networking Stack

This is the "secret sauce" of KryNet — a multi-layered networking architecture that provides seamless access from anywhere while maintaining security.

### Network Topology Overview

```
Internet ──┬──> Cloudflare Tunnel (cloudflared) ──> Traefik ──> Services
           │
           ├──> Tailscale VPN Mesh ──────────────> Traefik ──> Services
           │
LAN ───────┴──> AdGuard Home (Split-Horizon) ───> Traefik ──> Services
```

---

### The Proxy Layer: Traefik

**Current Standard:** Traefik v3.x (Infrastructure-as-Code via Docker Labels)

**Evolution History:**
1. **Phase 1:** Nginx Proxy Manager (GUI-based, retired due to lack of automation)
2. **Phase 2:** Traefik (Current) - Chose for label-based config and native Docker integration
3. ~~**Phase 3:** Caddy (Considered but stayed with Traefik due to ecosystem maturity)~~

**Traefik Configuration:**
- **Automatic Service Discovery:** Monitors Docker socket for new containers
- **Wildcard SSL Certificates:** Via Cloudflare DNS-01 challenge
- **Entrypoints:** `websecure` (443) for all HTTPS traffic
- **Certificate Resolver:** `myresolver` using Let's Encrypt
- **Networks:** `traefik_proxy` (external) for all routed services

**Example Label Pattern:**
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=traefik_proxy"
  - "traefik.http.routers.myapp.rule=Host(`app.mydomain.com`) || Host(`app.local.mydomain2.com`) || Host(`app.tail.mydomain2.com`)"
  - "traefik.http.routers.myapp.entrypoints=websecure"
  - "traefik.http.routers.myapp.tls.certresolver=myresolver"
  - "traefik.http.services.myapp.loadbalancer.server.port=8080"
```

---

### DNS Strategy: Split-Horizon Intelligence

**Primary DNS:** AdGuard Home on Prime (192.168.0.100)  
**Secondary DNS:** AdGuard Home on Agni (192.168.0.200)

**Synchronization:** AdGuard Home Sync automatically mirrors:
- DNS rewrites (split-horizon rules)
- Blocklists and filtering rules
- Client settings and group configurations

#### Split-Horizon DNS Rules

| Request Location | Example URL | Resolved To | Network Path |
|------------------|-------------|-------------|--------------|
| **Home LAN** | `photos.mydomain.com` | `192.168.0.100` | Direct 1Gbps LAN connection |
| **Remote (Internet)** | `photos.mydomain.com` | Cloudflare Tunnel | Encrypted tunnel via Cloudflare |
| **Tailscale VPN** | `photos.tail.mydomain2.com` | `100.x.x.x` | Direct Tailscale mesh connection |

**Why This Matters:**
- **Performance:** Local traffic stays local (1Gbps vs internet upload speed)
- **Reliability:** Services remain accessible even if internet is down
- **Security:** External access requires authentication, internal doesn't

**DNS Configuration:**
- **Router DHCP:** Points all clients to 192.168.0.100 (Primary) and 192.168.0.200 (Secondary)
- **Upstream DNS:** Cloudflare (1.1.1.1) and Google (8.8.8.8)
- **DNS-over-HTTPS:** Enabled for upstream queries
- **Blocklist:** Standard AdGuard filters + custom rules

---

### Domain Strategy

**Two Domains in Use:**

**mydomain.com (Primary - Public Facing)**
- Used for: Services accessible via Cloudflare Tunnel
- Examples: `photos.mydomain.com`, `request.mydomain.com`, `media.mydomain.com`
- Managed via: Cloudflare Dashboard (DNS records point to tunnel)

**mydomain2.com (Secondary - Internal/VPN)**
- Used for: Local DNS rewrites and Tailscale subdomains
- Examples: `*.local.mydomain2.com` (LAN), `*.tail.mydomain2.com` (Tailscale)
- Managed via: AdGuard Home DNS rewrites

**Subdomain Pattern:**
```
app.mydomain.com        → Public (via Cloudflare Tunnel)
app.local.mydomain2.com → LAN Only (split-horizon DNS)
app.tail.mydomain2.com  → Tailscale VPN Only
```

---

### Cloudflare Tunnel (cloudflared)

**Purpose:** Secure, zero-configuration public access without port forwarding

**How It Works:**
1. `cloudflared` container runs on Prime
2. Establishes outbound encrypted tunnel to Cloudflare edge
3. Cloudflare DNS records point to tunnel UUID
4. All traffic flows: Internet → Cloudflare → Tunnel → Traefik → Service

**Security Layer: Cloudflare Zero Trust**
- **Google OAuth 2.0:** All public-facing services require Google authentication
- **Email Whitelist:** Only specific Gmail accounts can access
- **Session Duration:** 24-hour sessions with automatic re-authentication
- **Application Policies:** Per-service access control rules

**Services Exposed via Tunnel:**
- Immich (photos.mydomain.com)
- Jellyseerr (request.mydomain.com)
- Jellyfin (media.mydomain.com)
- Homepage Dashboard (home.mydomain.com)

**Services NOT Exposed:**
- Traefik Dashboard (admin only)
- AdGuard Home (admin only)
- Portainer (admin only)
- Dozzle Logs (admin only)

---

### Tailscale Mesh VPN

**Purpose:** Secure administrative access and "always-on" connectivity for power users

**Deployment:**
- **Prime Node:** Advertises subnet routes (192.168.0.0/24) and acts as exit node
- **Agni Node:** Standard mesh node
- **Mobile Devices:** Installed on phones/tablets for remote access
- **Laptop:** On-demand connection for administration

**Configuration:**
```bash
TS_AUTHKEY=tskey-auth-[REDACTED]
TS_ROUTES=192.168.0.0/24
TS_EXTRA_ARGS=--advertise-exit-node
```

**Use Cases:**
- Remote server administration via SSH
- Accessing non-public services (Traefik dashboard, logs)
- Secure access to media library while traveling
- Bypassing ISP throttling (via exit node)

**Tailscale Subdomain Pattern:**
- All services accessible via `*.tail.mydomain2.com`
- Traefik automatically routes based on Host header
- No additional authentication required (Tailscale = trusted network)

---

### Network Security & Isolation

**Docker Networks:**
- `traefik_proxy` (External): For all web-exposed services
- `kry_net` (External): Internal service communication
- `host` mode: Used only for Tailscale, Home Assistant, AdGuard Home (require host network access)

**Firewall Rules:**
- **TrueNAS:** Default deny, allow only ports 80/443 for Traefik
- **Router:** No port forwarding configured (Cloudflare Tunnel only)
- **Docker:** Inter-container communication restricted by network membership

**VPN Isolation (Gluetun):**
- All torrent traffic forced through Gluetun VPN container
- Kill switch enabled: If VPN drops, downloads stop
- DNS leak protection: Forced to VPN provider's DNS
- Services behind VPN: qBittorrent, Jellyseerr, Whisparr

---

## 🎬 Service Ecosystem

### Media Automation Pipeline (The *arr Stack)

**Request Flow:**
```
User Request (Jellyseerr) 
    → Indexer Search (Prowlarr) 
    → Download Manager (Radarr/Sonarr) 
    → Torrent Client (qBittorrent via Gluetun VPN) 
    → Optimization (Tdarr) 
    → Media Server (Jellyfin)
```

**Components:**

| Service | Purpose | Access URL |
|---------|---------|------------|
| **Jellyseerr** | User-friendly request interface | `request.mydomain.com` |
| **Prowlarr** | Centralized indexer management | `indexer.mydomain.com` |
| **Sonarr** | TV show and anime automation | `sonarr.local.mydomain2.com` |
| **Radarr** | Movie and documentary automation | `radarr.local.mydomain2.com` |
| **Whisparr** | Adult content automation (VPN-only) | `whisparr.local.mydomain2.com` |
| **Bazarr** | Subtitle management | `bazarr.local.mydomain2.com` |
| **qBittorrent** | Torrent client (behind Gluetun VPN) | `downloads.local.mydomain2.com` |
| **SABnzbd** | Usenet client (direct connection) | `sabnzbd.local.mydomain2.com` |
| **FlareSolverr** | Cloudflare bypass proxy | `flare.local.mydomain2.com` |

**Jellyfin Configuration:**
- Hardware acceleration: Intel QuickSync (CPU) + NVENC (GPU)
- 4K HDR tone-mapping enabled
- Libraries: Movies, TV Shows, Anime, Documentaries
- Mobile apps: Android, iOS (Finamp for music)

**Tdarr Optimization:**
- Monitors `andromeda` pool for new media
- Transcodes to H.265 (HEVC) using GTX 1060
- 10-bit color depth preserved
- Average 40% storage savings
- Automatic subtitle and audio track management

---

### Personal Data & Productivity

**Immich (Photo Management)**
- **Migration:** 500GB+ from Google Photos
- **Storage:** Database on `comet`, photos on `andromeda`
- **ML Features:** 
  - Facial recognition (GPU-accelerated)
  - Natural language search ("show me photos of a beach")
  - Smart albums and automatic tagging
- **Backup:** Primary source of truth for family photos
- **Access:** `photos.mydomain.com` (public) and `photos.local.mydomain2.com` (local)

**Paperless-ngx (Document Management)**
- **Storage:** Documents on `andromeda/apps/paperless`
- **OCR:** Tesseract with English language support
- **Workflow:**
  1. Physical mail scanned via mobile app
  2. Upload to consume folder (Syncthing monitored)
  3. Automatic OCR and metadata extraction
  4. Tagged and categorized (utility bills, health records, school documents)
- **Database:** Shared PostgreSQL on Prime
- **Access:** `docs.mydomain.com`

**FreshRSS (RSS Aggregator)**
- Centralized RSS feed management
- Mobile-friendly responsive design
- Fever API support for third-party apps
- Access: `rss.local.mydomain2.com`

**Syncthing (File Synchronization)**
- **Prime → Agni:** Real-time app config backup (read-only on Agni)
- **Agni → Prime:** Legion backup sync
- **Mobile → Prime:** Document scanning and photo upload
- **Conflict Resolution:** Latest modification wins
- **Access:** `sync.local.mydomain2.com`

---

### Private AI Playground

**LiteLLM (LLM Gateway)**
- Centralized proxy for multiple AI models
- Database: Shared PostgreSQL on Prime
- Metrics: Prometheus `/metrics` endpoint
- Cost tracking and usage analytics
- Access: `litellm.local.mydomain2.com`

**OpenWebUI (AI Interface)**
- Family-friendly ChatGPT-style interface
- Multi-user support with isolated conversations
- Model selection: GPT-4, Claude, Local models
- Document upload and RAG capabilities
- Access: `ow.mydomain.com`

---

### Dashboards & Interfaces

**Homepage (Primary Dashboard)**
- Real-time service status cards
- Docker container integration
- Weather, calendar, and bookmarks
- Customizable per-user layouts
- Access: `home.mydomain.com`

**Homarr (Alternative Dashboard)**
- Icon-based service launcher
- Integration with *arr stack for stats
- Custom CSS themes
- Access: `dash.mydomain.com`

---

## 🔄 Backup & Resilience Strategy

Following the **3-2-1 Backup Rule** strictly:

### 3 Copies of Data
1. **Primary:** Live data on ZFS pools (`orion`, `comet`, `andromeda`)
2. **Local Mirror:** Syncthing real-time sync to Agni node
3. **Offsite:** Encrypted S3-compatible cloud backup (Backblaze B2)

### 2 Different Media Types
- **HDD:** Spinning rust for bulk storage (orion, andromeda)
- **SSD:** Solid state for configs and databases (comet)

### 1 Offsite Copy
- **Critical Data:** Family photos (Immich) encrypted with age + rclone
- **Frequency:** Nightly incremental sync at 02:00 AM
- **Encryption:** AES-256, keys stored in password manager

### ZFS Snapshot Strategy

| Pool | Frequency | Retention |
|------|-----------|-----------|
| orion | Every 6 hours | 48 hours |
| comet | Daily | 7 days |
| andromeda | Weekly | 30 days |

**Snapshot Automation:** Built-in TrueNAS periodic snapshot tasks

### Application Config Backup

**Syncthing Mirroring:**
- Source: `/mnt/orion/apps-config` (Prime)
- Destination: `/home/legion/apps/syncthing/data/truenas-backup` (Agni)
- Mode: Send-only from Prime (read-only on Agni)
- Real-time sync with 60-second scan interval

**What's Backed Up:**
- All Portainer stack `.env` files
- Application configurations
- Database dumps (weekly automated via cron)
- SSL certificates from Traefik

---

## 🔒 Security Implementation

### Zero Trust Architecture

**Principle:** Never trust, always verify — even from internal network

**Implementation Layers:**

1. **Network Level (Tailscale + Cloudflare)**
   - No inbound ports open on router
   - All external access via encrypted tunnels
   - MagicDNS for internal service discovery

2. **Application Level (Cloudflare Access)**
   - Google OAuth 2.0 for public services
   - Email whitelist (only family members)
   - Session management with automatic timeout

3. **Service Level (Traefik + Docker)**
   - Network isolation via Docker networks
   - Least privilege container permissions
   - Read-only filesystem mounts where possible

### Docker Security Hardening

**Container Isolation:**
- Services on dedicated networks (`traefik_proxy`, `kry_net`)
- No `--privileged` flag except where absolutely necessary (Tailscale, Home Assistant)
- User namespacing via PUID/PGID

**Secrets Management:**
- Sensitive values in `.env` files (excluded from git)
- API keys rotated quarterly
- No secrets in container labels or logs

### mDNS Management

**Problem:** TrueNAS global mDNS conflicted with Home Assistant device discovery (UDP 5353)

**Solution:**
- Disabled TrueNAS global mDNS advertisement
- Home Assistant uses `host` network mode for discovery
- Local DNS resolution via AdGuard Home instead

### VPN Kill Switch (Gluetun)

**Configuration:**
```yaml
environment:
  - VPN_SERVICE_PROVIDER=surfshark
  - VPN_TYPE=wireguard
  - FIREWALL_OUTBOUND_SUBNETS=192.168.0.0/24,172.16.3.0/24
```

**Protection:**
- If VPN drops, firewall blocks all traffic
- Only allows traffic to VPN server and local networks
- DNS leak protection enforced

---

## 📊 Monitoring & Operations

### Health Monitoring (Uptime Kuma)

**Monitored Services:**
- All public-facing URLs (HTTP 200 checks)
- Docker container health status
- Disk space thresholds (80% warning, 90% critical)
- Certificate expiry (30-day warning)

**Notification Channels:**
- Gotify (instant push to mobile)
- Email (backup channel)

**Access:** `monitor.local.mydomain2.com`

### Metrics & Observability

**Prometheus:**
- Scrapes metrics from LiteLLM, Traefik, Docker
- 15-day retention policy
- Access: `prom.local.mydomain2.com`

**Grafana (Future):**
- Planned for visualizing Prometheus data
- Custom dashboards for bandwidth, CPU, GPU utilization

### Logging (Dozzle)

**Real-Time Log Streaming:**
- Web-based interface for all container logs
- No disk overhead (reads Docker socket directly)
- Search and filter across all services
- Access: `logs.local.mydomain2.com`

### Notifications (Gotify)

**Push Notification Server:**
- Self-hosted alternative to Pushover
- Mobile app for Android (iOS via web)
- Priority levels and custom sounds
- Access: `notify.local.mydomain2.com`

**Alert Types:**
- Service down (Uptime Kuma)
- Disk space warnings (TrueNAS)
- Backup failures (rclone)
- Certificate expiry warnings (Traefik)

### Automated Updates (Watchtower)

**Configuration:**
- Daily check at 04:00 AM
- Auto-update all containers with `latest` tag
- Email notification on updates
- Manual pin for critical services (database, Immich)

**Exclusions:**
- PostgreSQL (requires manual migration testing)
- Immich (breaking changes common)

### Network Testing

**Speedtest Tracker:**
- Automated hourly speed tests
- Historical data visualization
- ISP performance monitoring
- Access: `speed.local.mydomain2.com`

**OpenSpeedTest:**
- On-demand LAN speed testing
- Client-side JavaScript-based
- Access: `ospt.local.mydomain2.com`

---

## 🚀 Future Roadmap

### Planned Additions

**Infrastructure:**
- [ ] Grafana deployment with custom dashboards
- [ ] Vaultwarden for password management
- [ ] Nextcloud for collaborative document editing
- [ ] Home Assistant voice control expansion

**Storage:**
- [ ] Expand `orion` pool: Add 2x 8TB drives (mirror-vdev)
- [ ] Migrate `andromeda` to mirror configuration
- [ ] Add hot spare drive for automatic resilver

**Networking:**
- [ ] Transition from Traefik to Caddy for simpler config
- [ ] WireGuard as backup VPN (parallel to Tailscale)
- [ ] IPv6 support throughout stack

**Services:**
- [ ] Audiobookshelf for audiobook management
- [ ] Calibre-Web for ebook library
- [ ] Kavita for comics/manga
- [ ] Mealie for recipe management

---

## 📚 Lessons Learned

### What Went Right
- ZFS has saved data multiple times from drive errors
- Split-horizon DNS eliminates internet dependency for local access
- GPU transcoding reduces storage by 40% with no quality loss
- Cloudflare Tunnel is more reliable than dynamic DNS

### What I'd Do Differently
- Start with Caddy instead of migrating through 3 proxy solutions
- Use ECC RAM from day one (future build)
- Implement proper VLAN segmentation for IoT devices
- Choose a more modular UPS for easier expansion

### Key Takeaways
- **Backups are not optional** — Test restores quarterly
- **Documentation saves hours** — Future you will thank present you
- **KISS principle** — Complexity is the enemy of reliability
- **WAF is real** — If the family can't use it, it's failed

---

## 🙏 Acknowledgments

- **TrueNAS Community:** For excellent documentation and forum support
- **r/selfhosted:** Inspiration and troubleshooting assistance
- **LinuxServer.io:** Quality Docker images with consistent standards
- **Traefik Team:** Powerful reverse proxy with great Docker integration

---

## 📄 License

This documentation is shared under MIT License. Feel free to adapt for your own homelab.

---

**Last Updated:** January 2026  
**Current TrueNAS Version:** Dragonfish 24.10  
**Total Storage:** ~13TB usable  
**Services Running:** 40+ Docker containers  
**Uptime Target:** 99.9% (8.76 hours downtime/year allowed)

---

*Built with ❤️ and late nights for digital sovereignty and family convenience.*
