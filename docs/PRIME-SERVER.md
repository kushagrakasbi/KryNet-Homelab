# 🌟 Prime Server Documentation

**KryNet Storage & Media Hub | TrueNAS SCALE | 192.168.1.100**

Prime is the **powerhouse** of the KryNet Homelab, serving as the primary storage server, media processing center, photo management hub, and data archive.

---

## 📋 Table of Contents

1. [Server Overview](#server-overview)
2. [Hardware Specifications](#hardware-specifications)
3. [Storage Architecture (ZFS)](#storage-architecture-zfs)
4. [Service Architecture](#service-architecture)
5. [Media Automation Stack](#media-automation-stack)
6. [Photo Management (Immich)](#photo-management-immich)
7. [Monitoring Sensors](#monitoring-sensors)
8. [Backup Configuration](#backup-configuration)
9. [Network Configuration](#network-configuration)
10. [Maintenance & Operations](#maintenance--operations)

---

## 🎯 Server Overview

### Role in KryNet Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     🌟 PRIME SERVER                              │
│                    (Storage & Media Hub)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│   │   ZFS Pools     │  │  Media Stack    │  │  Photo Stack    │ │
│   │                 │  │                 │  │                 │ │
│   │ • orion (4TB)   │  │ • Jellyfin      │  │ • Immich        │ │
│   │ • comet (1TB)   │  │ • *Arr Suite    │  │ • ML Processing │ │
│   │ • andromeda     │  │ • Tdarr         │  │ • Facial Recog  │ │
│   │   (8TB)         │  │ • Downloads     │  │                 │ │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                  │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│   │   DNS Stack     │  │   Monitoring    │  │    Backup       │ │
│   │                 │  │                 │  │                 │ │
│   │ • AdGuard Home  │  │ • Node Exporter │  │ • Rclone        │ │
│   │   (Primary)     │  │ • cAdvisor      │  │ • pCloud Sync   │ │
│   │                 │  │ • Docker Proxy  │  │                 │ │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Primary Functions

| Function | Description |
|----------|-------------|
| **Storage Hub** | 13TB+ ZFS storage with data integrity |
| **Media Server** | 4K streaming with hardware transcoding |
| **Photo Backup** | Google Photos replacement with ML features |
| **DNS Primary** | Main AdGuard Home instance |
| **Download Server** | VPN-protected torrent/usenet |
| **Transcode Engine** | GPU-powered H.265 conversion |

---

## 🖥️ Hardware Specifications

| Component | Specification |
|-----------|---------------|
| **Chassis** | Fractal Design Node 804 (Dual-chamber, HDD cooling) |
| **CPU** | Intel i5-7600K (4C/4T @ 3.8GHz) |
| **RAM** | 32GB Crucial DDR4 (ZFS ARC + containers + ML) |
| **GPU** | NVIDIA GTX 1060 6GB (NVENC + Immich ML) |
| **OS** | TrueNAS SCALE (Dragonfish 24.10) |
| **Network** | 1Gbps Ethernet (Intel I219-V) |
| **IP Address** | 192.168.1.100 (Static) |
| **Web UI** | https://server.example.com or port 88 |

---

## 💾 Storage Architecture (ZFS)

### Storage Pools

| Pool | Hardware | Type | Capacity | Purpose |
|------|----------|------|----------|---------|
| **orion** | 2x 4TB WD Red Plus | Mirror | ~4TB | App configs, databases |
| **comet** | 2x 1TB NVMe SSD | Mirror | ~1TB | Downloads, transcode cache |
| **andromeda** | 1x 8TB Seagate IronWolf | Single | 8TB | Media, photos, documents |

### Dataset Structure

```
/mnt/orion/
├── apps-config/              # All Docker container configs
│   ├── adguardhome/
│   ├── jellyfin/
│   ├── jellyseerr/
│   ├── sonarr/
│   ├── radarr/
│   ├── prowlarr/
│   ├── bazarr/
│   ├── qbittorrent/
│   ├── sabnzbd/
│   ├── tdarr/
│   ├── gluetun/
│   ├── homarr/
│   ├── tailscale/
│   ├── rclone/
│   └── ... (30+ services)
│
/mnt/comet/
├── downloads/                # Active downloads
│   ├── torrents/
│   │   ├── tv/
│   │   ├── movies/
│   │   └── incomplete/
│   └── usenet/
│       ├── complete/
│       └── incomplete/
└── tdarr-cache/              # Transcode temporary files

/mnt/andromeda/
├── apps/
│   └── immich/               # Photo management
│       ├── uploads/          # Original photos (500GB+)
│       ├── ml/               # ML model cache
│       └── db/               # PostgreSQL data
├── data/
│   └── media/                # Organized media library
│       ├── movies/
│       ├── series/
│       ├── anime/
│       ├── documentaries/
│       ├── audiobooks/
│       └── podcasts/
└── share/                    # General file sharing
```

### ZFS Configuration

**Snapshot Strategy:**
| Pool | Frequency | Retention | Purpose |
|------|-----------|-----------|---------|
| orion | Every 6 hours | 48 hours | Config protection |
| comet | Daily | 7 days | Download protection |
| andromeda | Weekly | 4 weeks | Media protection |

**Data Integrity:**
- Checksums on every read
- Self-healing from mirror copies
- Weekly scrubs (Sundays 02:00 AM)
- SMART tests: Long monthly, short weekly

**Performance Tuning:**
- ARC: ~20GB RAM allocated
- Compression: LZ4 (~15% savings)
- Recordsize: 128K (databases), 1M (media)

---

## 🏗️ Service Architecture

### Docker Configuration

**Environment Variables (stack.env):**
```bash
PUID=568
PGID=568
TZ=Asia/Kolkata
DOCKER_CONFIG_PATH=/mnt/orion/apps-config
DOCKER_DATA_PATH=/mnt/andromeda/data
DOCKER_TRANSCODE_CACHE=/mnt/comet/tdarr-cache

# VPN Configuration
WIREGUARD_PRIVATE_KEY=your_key
WIREGUARD_ADDRESSES=10.x.x.x/32
SERVER_COUNTRIES=Netherlands

# Database Credentials
POSTGRES_PASS=your_password
DB_PASSWORD=your_password
DB_USERNAME=postgres
DB_DATABASE_NAME=immich

# Service Keys
SPEEDTEST_APP_KEY=base64:...
```

### Docker Networks

| Network | Purpose |
|---------|---------|
| `kry_net` | Internal service communication |
| `traefik_proxy` | Web-exposed containers |

### Stack Files

| Stack File | Services |
|------------|----------|
| `media-stack.yml` | Gluetun, qBittorrent, SABnzbd, FlareSolverr, Prowlarr, Sonarr, Radarr, Bazarr, Jellyfin, Jellyseerr, Whisparr, Tdarr |
| `immich.yml` | Immich Server, ML, Redis, PostgreSQL, Power Tools |
| `dns-stack.yml` | AdGuard Home (Primary) |
| `monitoring-sensors.yml` | Dozzle, Node Exporter, cAdvisor, Docker Socket Proxy, Portainer Agent |
| `audiobookshelf.yml` | Audiobookshelf |
| `speedtest.yml` | OpenSpeedTest, Speedtest Tracker |
| `homarr.yml` | Homarr Dashboard |
| `rclone-stack.yml` | Rclone Backup |
| `tailscale.yml` | Tailscale VPN |

---

## 🎬 Media Automation Stack

### Workflow Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Jellyseerr │───▶│   Prowlarr  │───▶│   Indexers  │
│  (Requests) │    │  (Search)   │    │  (Sources)  │
└──────┬──────┘    └──────┬──────┘    └─────────────┘
       │                  │
       │           ┌──────▼──────┐
       │           │   Sonarr    │◄──┐
       │           │   (TV)      │   │
       │           └──────┬──────┘   │
       │                  │          │
       │           ┌──────▼──────┐   │
       │           │   Radarr    │   │
       │           │  (Movies)   │   │
       │           └──────┬──────┘   │
       │                  │          │
       │           ┌──────▼──────┐   │
       └──────────▶│   Bazarr    │───┘
                   │ (Subtitles) │
                   └──────┬──────┘
                          │
┌─────────────────────────▼─────────────────────────┐
│                     GLUETUN VPN                    │
│  ┌─────────────┐              ┌─────────────┐     │
│  │ qBittorrent │              │   SABnzbd   │     │
│  │  (Torrents) │              │  (Usenet)   │     │
│  └──────┬──────┘              └──────┬──────┘     │
└─────────┼────────────────────────────┼────────────┘
          │                            │
          └────────────┬───────────────┘
                       │
                ┌──────▼──────┐
                │    Tdarr    │
                │ (Transcode) │
                │ GPU: NVENC  │
                └──────┬──────┘
                       │
                ┌──────▼──────┐
                │  Jellyfin   │
                │  (Stream)   │
                └─────────────┘
```

### Service Details

#### Jellyseerr (Request Interface)
**Port:** 5055 (via Gluetun)  
**Access:** `https://request.example.com`

User-friendly media request portal:
- Family members request content
- Auto-routes to Sonarr/Radarr
- Request limits per user
- Auto-approval rules

#### Prowlarr (Indexer Manager)
**Port:** 9696  
**Access:** `https://indexer.example.com` (Admin only)

Centralized indexer management:
- FlareSolverr integration for Cloudflare bypass
- Syncs indexers to all *arr apps
- Public and private trackers

#### Sonarr (TV Automation)
**Port:** 8989  
**Access:** `https://sonarr.example.com` (Admin only)

TV show management:
- Automatic downloads
- Quality upgrades
- Season pack handling
- Naming: `{Series} - S{season:00}E{episode:00} - {Title}`

#### Radarr (Movie Automation)
**Port:** 7878  
**Access:** `https://radarr.example.com` (Admin only)

Movie management:
- Automatic downloads
- Quality profiles
- Naming: `{Movie} ({Year}) [{Quality}]`

#### Bazarr (Subtitles)
**Port:** 6767  
**Access:** `https://bazarr.example.com` (Admin only)

Automatic subtitle downloads:
- OpenSubtitles integration
- Multi-language support
- Hearing impaired filtering

#### Gluetun (VPN Gateway)
**Network Mode:** Container gateway  
**VPN Provider:** Surfshark (WireGuard)  
**Server:** Netherlands

Kill switch protection:
- All torrent traffic through VPN
- Blocks if VPN drops
- Container sharing: `network_mode: service:gluetun`

#### qBittorrent (Torrent Client)
**Port:** 8080 (via Gluetun)  
**Access:** `https://qb.example.com` (Admin only)

Configuration:
- Download path: `/data/downloads/torrents`
- Categories: tv, movies
- Speed limits configurable

#### SABnzbd (Usenet Client)
**Port:** 8085  
**Access:** `https://nzb.example.com` (Admin only)

Usenet downloading:
- Provider: Your Usenet provider
- SSL connections
- Categories synced with *arr apps

#### Tdarr (GPU Transcoding)
**Port:** 8265  
**Access:** `https://tdarr.example.com` (Admin only)

H.265/HEVC conversion:
- 40% space savings
- GPU-accelerated (GTX 1060 NVENC)
- Quality: CRF 23 (visually lossless)
- Speed: 2-3x realtime

#### Jellyfin (Media Server)
**Port:** 8096  
**Access:** `https://media.example.com`

Streaming platform:
- Hardware transcoding (Intel QSV + NVIDIA)
- Multi-user support
- Mobile apps available
- External access via Cloudflare

---

## 📸 Photo Management (Immich)

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        IMMICH STACK                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────────┐    ┌─────────────────────────────┐    │
│   │  Immich Server  │◄──▶│  Immich Machine Learning   │    │
│   │     :2283       │    │  (CUDA GPU Accelerated)    │    │
│   └────────┬────────┘    └─────────────────────────────┘    │
│            │                                                 │
│   ┌────────▼────────┐    ┌─────────────────────────────┐    │
│   │  PostgreSQL     │    │         Redis               │    │
│   │  (pgvecto-rs)   │    │       (Valkey)              │    │
│   │     :5432       │    │                             │    │
│   └─────────────────┘    └─────────────────────────────┘    │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              Immich Power Tools                      │   │
│   │                    :8001                             │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Storage Structure

```
/mnt/andromeda/apps/immich/
├── uploads/              # Original photos (500GB+)
│   ├── library/
│   │   └── admin/        # Per-user folders
│   │       └── 2024/
│   │           ├── 01/   # Organized by date
│   │           └── 02/
│   ├── thumbs/           # Generated thumbnails
│   └── encoded-video/    # Transcoded videos
├── ml/                   # ML model cache (10GB)
│   ├── facial-recognition/
│   └── clip/
└── db/                   # PostgreSQL data (5GB)
```

### ML Features

**Facial Recognition:**
- Automatic face detection
- Group similar faces
- Name assignment
- Search by person

**Smart Search (CLIP):**
- Natural language: "beach sunset"
- Object recognition: "dog", "car"
- Scene detection: "mountain", "city"
- No manual tagging needed

**Configuration:**
```yaml
environment:
  - MACHINE_LEARNING__FACE_RECOGNITION_MODEL=mobile_face
  - MACHINE_LEARNING__FACE_DETECTION_MODEL=yunet
  - MACHINE_LEARNING__CLIP_MODEL=ViT-B-16__laion2b_s34b_b88k
```

### Access

| URL | Purpose |
|-----|---------|
| `https://photos.example.com` | Public access (OAuth) |
| `https://photos.internal.home` | LAN access |
| `https://ipt.example.com` | Power Tools (bulk edits) |

---

## 📊 Monitoring Sensors

Prime exports metrics to Agni's Prometheus:

### Node Exporter
**Port:** 9100

Host system metrics:
- CPU usage
- Memory usage
- Disk I/O
- Network throughput

### cAdvisor
**Port:** 8087

Container metrics:
- Per-container CPU/memory
- Network per container
- Disk usage per container

### Docker Socket Proxy
**Port:** 2375

Secure Docker API proxy:
- Read-only access
- For Homepage widgets
- Blocks dangerous commands

### Portainer Agent
**Port:** 9001

Remote container management:
- Controlled from Agni's Portainer
- Stack deployment
- Container operations

### Dozzle (Log Viewer)
**Port:** 8088  
**Access:** `https://logs.example.com`

Real-time log streaming for Prime containers.

---

## 💾 Backup Configuration

### Rclone to pCloud

**Schedule:** Every 12 hours  
**Healthcheck:** `hc.example.com` ping on completion

**Backup Targets:**

| Source | Destination | Purpose |
|--------|-------------|---------|
| `/mnt/orion/apps-config` | `pcloud:Backups/Krynet-Prime/Configs` | All container configs |
| `/mnt/andromeda/apps` | `pcloud:Backups/Krynet-Prime/Apps` | App data (excluding media) |

**Exclusions:**
- Git directories
- Log files, cache files
- Database WAL/shm files
- Jellyfin cache/metadata
- Immich ML cache
- Transcode temporary files
- Portainer snapshots

---

## 🌐 Network Configuration

### AdGuard Home (Primary DNS)
**Port:** 53 (DNS), 7000 (Web UI)  
**Access:** `https://adguard.example.com`

Primary DNS server with:
- Split-horizon DNS rewrites
- Ad blocking (OISD Big List)
- Query logging

### Tailscale VPN
**Network Mode:** Host  
**Configuration:**
```yaml
environment:
  - TS_AUTHKEY=${TS_AUTHKEY}
  - TS_STATE_DIR=/var/lib/tailscale
  - TS_EXTRA_ARGS=--reset
  - TS_USERSPACE=false
```

---

## 🔧 Maintenance & Operations

### Common Commands

```bash
# TrueNAS Shell access
ssh admin@192.168.1.100

# Check ZFS pool status
zpool status
zpool list

# Check container status
docker ps --format "table {{.Names}}\t{{.Status}}"

# View container logs
docker logs -f jellyfin
docker logs -f immich_server

# Restart media stack
cd /mnt/orion/apps-config
docker compose -f media-stack.yml restart

# Check GPU status
nvidia-smi

# Check Gluetun VPN status
docker exec gluetun wget -qO- ifconfig.me
```

### ZFS Commands

```bash
# Check pool health
zpool status -v

# Check snapshots
zfs list -t snapshot

# Create manual snapshot
zfs snapshot andromeda/apps@manual-backup-$(date +%Y%m%d)

# Check scrub status
zpool status | grep scrub

# Check disk usage
zfs list
```

### Service-Specific

```bash
# Jellyfin: Scan library
curl -X POST "http://localhost:8096/Library/Refresh?api_key=YOUR_KEY"

# Immich: Check ML status
docker logs immich_machine_learning --tail 50

# qBittorrent: Check VPN IP
docker exec -it qbittorrent curl ifconfig.me

# Tdarr: Check node status
docker logs tdarr-node --tail 20
```

### Troubleshooting

#### Media Not Playing
```bash
# Check Jellyfin transcoding logs
docker logs jellyfin | grep -i transcode

# Verify GPU passthrough
docker exec jellyfin nvidia-smi

# Check file permissions
ls -la /mnt/andromeda/data/media/movies/
```

#### Downloads Not Starting
```bash
# Check Gluetun VPN
docker logs gluetun | tail -20

# Verify qBittorrent connectivity
docker exec qbittorrent cat /config/qBittorrent/logs/qbittorrent.log | tail -20

# Check Prowlarr indexer status
docker logs prowlarr | grep -i error
```

#### Photos Not Syncing
```bash
# Check Immich server logs
docker logs immich_server | tail -50

# Check ML processing
docker logs immich_machine_learning | tail -50

# Verify database connection
docker exec immich_postgres pg_isready
```

---

## 📊 Port Reference

| Port | Service | Protocol |
|------|---------|----------|
| 53 | AdGuard DNS | TCP/UDP |
| 88 | TrueNAS Web UI | TCP |
| 2283 | Immich | TCP |
| 2375 | Docker Socket Proxy | TCP |
| 5055 | Jellyseerr (via Gluetun) | TCP |
| 5432 | PostgreSQL (Immich) | TCP |
| 6767 | Bazarr | TCP |
| 6881 | qBittorrent Peers | TCP/UDP |
| 6969 | Whisparr | TCP |
| 7000 | AdGuard Web UI | TCP |
| 7575 | Homarr | TCP |
| 7878 | Radarr | TCP |
| 8001 | Immich Power Tools | TCP |
| 8080 | qBittorrent (via Gluetun) | TCP |
| 8085 | SABnzbd | TCP |
| 8087 | cAdvisor | TCP |
| 8088 | Dozzle | TCP |
| 8093 | Speedtest Tracker | TCP |
| 8096 | Jellyfin | TCP |
| 8191 | FlareSolverr | TCP |
| 8265 | Tdarr WebUI | TCP |
| 8266 | Tdarr Server | TCP |
| 8989 | Sonarr | TCP |
| 8992 | OpenSpeedTest | TCP |
| 9001 | Portainer Agent | TCP |
| 9100 | Node Exporter | TCP |
| 9443 | Portainer HTTPS | TCP |
| 9696 | Prowlarr | TCP |
| 13378 | Audiobookshelf | TCP |

---

**Last Updated:** February 2026  
**Server IP:** 192.168.1.100  
**OS:** TrueNAS SCALE Dragonfish 24.10  
**Storage:** ~13TB (ZFS)  
**Services:** 25+ containers  
**Role:** Storage Hub + Media Center
