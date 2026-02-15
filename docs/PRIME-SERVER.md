# 🌟 Prime Server Documentation

**KryNet Storage & Media Hub | TrueNAS SCALE | 192.168.1.100**

Prime is the **powerhouse** of the KryNet Homelab, serving as the primary storage server, media processing center, photo management hub, and data archive. It hosts both ZFS pools (andromeda and orion) and runs all storage-intensive workloads.

---

## 📋 Table of Contents

1. [Server Overview](#server-overview)
2. [Hardware Specifications](#hardware-specifications)
3. [Storage Architecture (ZFS)](#storage-architecture-zfs)
4. [Data Integrity & Maintenance](#data-integrity--maintenance)
5. [Service Architecture](#service-architecture)
6. [Media Automation Stack](#media-automation-stack)
7. [Photo Management (Immich)](#photo-management-immich)
8. [Audiobookshelf](#audiobookshelf)
9. [Monitoring Sensors](#monitoring-sensors)
10. [Backup Configuration](#backup-configuration)
11. [Network Configuration](#network-configuration)
12. [Maintenance & Operations](#maintenance--operations)

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
│   │ • andromeda     │  │ • Jellyfin      │  │ • Immich        │ │
│   │   (2×4TB,Mirror)│  │ • *Arr Suite    │  │ • ML Processing │ │
│   │ • orion         │  │ • Tdarr         │  │ • Facial Recog  │ │
│   │   (2×2TB,Mirror)│  │ • Downloads     │  │                 │ │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                  │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│   │   DNS Stack     │  │   Monitoring    │  │    Backup       │ │
│   │                 │  │                 │  │                 │ │
│   │ • AdGuard Home  │  │ • Node Exporter │  │ • Rclone        │ │
│   │   (Secondary)   │  │ • cAdvisor      │  │ • pCloud Sync   │ │
│   │                 │  │ • Docker Proxy  │  │                 │ │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                  │
│   ┌─────────────────┐                                            │
│   │  Audio Stack    │                                            │
│   │                 │                                            │
│   │ • Audiobookshelf│                                            │
│   │  (Podcasts +    │                                            │
│   │   Audiobooks)   │                                            │
│   └─────────────────┘                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Primary Functions

| Function | Description |
|----------|-------------|
| **Storage Hub** | 12TB raw ZFS storage (mirrored) across 2 pools |
| **Media Server** | Streaming with hardware transcoding (GTX 1060) |
| **Photo Backup** | Google Photos replacement with ML features (Immich) |
| **Audio Library** | Podcasts & audiobooks via Audiobookshelf |
| **DNS Secondary** | Backup AdGuard Home instance (synced from Agni) |
| **Download Server** | VPN-protected torrent/usenet |
| **Transcode Engine** | GPU-powered H.265 conversion |

---

## 🖥️ Hardware Specifications

| Component | Specification |
|-----------|---------------|
| **Chassis** | Old MSI Cabinet (repurposed) |
| **CPU** | Intel Core i3-10th Gen F Series |
| **RAM** | 32GB DDR4 @ 2400 MHz (ZFS ARC + containers + ML) |
| **GPU** | NVIDIA GTX 1060 3GB (NVENC transcoding + Immich ML) |
| **OS** | TrueNAS SCALE (Dragonfish 24.10) |
| **Network** | 1Gbps Ethernet |
| **IP Address** | 192.168.1.100 (Static) |
| **Web UI** | https://server.example.com or port 88 |

---

## 💾 Storage Architecture (ZFS)

### Storage Pools

Both ZFS pools reside on Prime and are configured in **mirror** mode for redundancy.

| Pool | Hardware | Type | Raw Capacity | Usable Capacity | Purpose |
|------|----------|------|-------------|-----------------|---------|
| **andromeda** | 2× 4TB WD Red Plus | Mirror | 8TB | ~4TB | Immich photos/videos, podcasts, audiobooks |
| **orion** | 2× 2TB WD Blue HDD | Mirror | 4TB | ~2TB | App configs, databases, media library |

### Dataset Structure

```
/mnt/orion/
├── apps-config/               # All Docker container configurations
│   ├── adguardhome/           # AdGuard Home (Secondary DNS)
│   ├── jellyfin/              # Media server config
│   ├── jellyseerr/            # Request interface config
│   ├── sonarr/                # TV automation config
│   ├── radarr/                # Movie automation config
│   ├── prowlarr/              # Indexer manager config
│   ├── bazarr/                # Subtitle manager config
│   ├── qbittorrent/           # Torrent client config
│   ├── sabnzbd/               # Usenet client config
│   ├── tdarr/                 # Transcode engine config
│   ├── gluetun/               # VPN gateway config
│   ├── homarr/                # Dashboard config
│   ├── tailscale/             # VPN state
│   ├── rclone/                # Cloud backup config
│   ├── audiobookshelf/        # Audiobook server config
│   └── ... (30+ services)
│
└── data/
    └── media/                 # Media pipeline library
        ├── movies/            # Movie files (managed by Radarr)
        ├── series/            # TV series (managed by Sonarr)
        ├── anime/             # Anime series
        └── documentaries/     # Documentary collection

/mnt/andromeda/
├── apps/
│   └── immich/                # Photo management platform
│       ├── uploads/           # Original photos & videos (500GB+)
│       │   ├── library/       # Per-user photo libraries
│       │   │   └── admin/     # Admin user
│       │   │       └── 2024/  # Organized by year
│       │   │           └── 01/ # By month
│       │   ├── thumbs/        # Generated thumbnails
│       │   └── encoded-video/ # Transcoded videos
│       ├── ml/                # ML model cache (~10GB)
│       │   ├── facial-recognition/
│       │   └── clip/          # CLIP model for smart search
│       └── db/                # PostgreSQL data (~5GB)
│
└── media/
    ├── podcasts/              # Podcast library (served by Audiobookshelf)
    └── audiobooks/            # Audiobook library (served by Audiobookshelf)
```

### ZFS Configuration

**Performance Tuning:**
- ARC: ~20GB RAM allocated (from 32GB total)
- Compression: LZ4 (~15% savings)
- Recordsize: 128K (databases), 1M (media)

---

## 🔍 Data Integrity & Maintenance

### ZFS Scrub Schedule

Scrubs are configured in TrueNAS to run weekly on both pools, verifying every data block against its checksum and repairing any corruption from mirror copies.

| Pool | Day | Time | Frequency |
|------|-----|------|-----------|
| **orion** | Sunday | 23:00 | Weekly |
| **andromeda** | Sunday | 23:00 | Weekly |

### ZFS Snapshot Strategy

Periodic snapshots are configured for `orion/apps-config` to protect all Docker container configuration data. Two snapshot tasks are set up:

| Task | Frequency | Schedule | Retention | Purpose |
|------|-----------|----------|-----------|---------|
| Hourly snapshots | Every hour | Each day | 3 days | Quick rollback for config issues |
| Daily snapshots | Daily | 12:00 AM | 2 weeks | Longer-term config protection |

> **Note:** Snapshots are currently only configured for `orion/apps-config` as it contains all critical container configurations. Immich data on andromeda is protected through mirroring + cloud backups.

### SMART Disk Health Tests

Automated SMART tests are configured in TrueNAS for early detection of disk failures:

| Test Type | Pool/Disks | Schedule | Time |
|-----------|-----------|----------|------|
| **Long Test** | Orion (2× 2TB WD Blue) | 1st day of every month | 04:00 AM |
| **Long Test** | Andromeda (2× 4TB WD Red Plus) | 1st day of every month | 03:00 AM |
| **Short Test** | All disks (Orion + Andromeda) | Weekly | 12:00 AM |

**What these tests do:**
- **Short test:** Quick ~2 minute scan checking electrical/mechanical health, read/write performance, and SMART attributes
- **Long test:** Full surface scan of every sector on the disk, typically takes several hours. Catches developing bad sectors before data loss occurs

---

## 🏗️ Service Architecture

### Docker Configuration

**Environment Variables (stack.env):**
```bash
PUID=568
PGID=568
TZ=Asia/Kolkata
DOCKER_CONFIG_PATH=/mnt/orion/apps-config
DOCKER_DATA_PATH=/mnt/orion/data
DOCKER_ANDROMEDA_PATH=/mnt/andromeda

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
| `dns-stack.yml` | AdGuard Home (Secondary) |
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

**Media files** are stored on `orion` pool at `/mnt/orion/data/media/` and organized into folders for movies, series, anime, and documentaries.

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
- ~40% space savings
- GPU-accelerated (GTX 1060 3GB NVENC)
- Quality: CRF 23 (visually lossless)
- Speed: 2-3x realtime

#### Jellyfin (Media Server)
**Port:** 8096  
**Access:** `https://media.example.com`

Streaming platform:
- Hardware transcoding (NVIDIA GTX 1060)
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

### Storage

All Immich data is stored on the **andromeda** pool at `/mnt/andromeda/apps/immich/`:

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

## 🎧 Audiobookshelf

**Port:** 13378  
**Access:** `https://audiobooks.example.com`

Audiobookshelf serves podcasts and audiobooks stored on the **andromeda** pool:

| Content Type | Storage Path |
|-------------|--------------|
| Podcasts | `/mnt/andromeda/media/podcasts/` |
| Audiobooks | `/mnt/andromeda/media/audiobooks/` |

Features:
- Progress tracking across devices
- Chapter navigation
- Sleep timer
- Podcast auto-download

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

**Healthcheck:** `hc.example.com` ping on completion

**Backup Targets:**

| Source | Destination | Purpose |
|--------|-------------|---------|
| `/mnt/orion/apps-config` | `pcloud:Backups/Krynet-Prime/Configs` | All Docker container configs |
| Immich DB backup (from andromeda) | `pcloud:Backups/Krynet-Prime/ImmichDB` | Immich PostgreSQL database backup |

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

### AdGuard Home (Secondary DNS)

> **Note:** The **primary** AdGuard Home instance runs on Agni (192.168.1.200). This is the **secondary** instance, kept in sync via AdGuard Home Sync running on Agni.

**Port:** 53 (DNS), 7000 (Web UI)  
**Access:** `https://adguard.example.com`

Secondary DNS server with:
- Split-horizon DNS rewrites (synced from Agni)
- Ad blocking (OISD Big List)
- Query logging
- Automatic config sync from primary (Agni) via AdGuard Home Sync

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

# Check snapshots (orion/apps-config)
zfs list -t snapshot -r orion/apps-config

# Create manual snapshot
zfs snapshot orion/apps-config@manual-$(date +%Y%m%d-%H%M)

# Check scrub status
zpool status | grep scrub

# Check disk usage
zfs list

# Check SMART status for a disk
smartctl -a /dev/sdX
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

# Audiobookshelf: Check logs
docker logs audiobookshelf --tail 20
```

### Troubleshooting

#### Media Not Playing
```bash
# Check Jellyfin transcoding logs
docker logs jellyfin | grep -i transcode

# Verify GPU passthrough
docker exec jellyfin nvidia-smi

# Check file permissions
ls -la /mnt/orion/data/media/movies/
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
| 53 | AdGuard DNS (Secondary) | TCP/UDP |
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
**Storage:** ~6TB usable (12TB raw, ZFS mirror)  
**Services:** 25+ containers  
**Role:** Storage Hub + Media Center
