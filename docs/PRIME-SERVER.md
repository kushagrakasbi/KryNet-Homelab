# 🌟 Prime Server Documentation

**KryNet Storage & Media Hub | TrueNAS SCALE | 192.168.0.100**

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
│                 (Storage Vault & Media Hub)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│   │   ZFS Pools     │  │  Media Stack    │  │  Photo Stack    │ │
│   │                 │  │                 │  │                 │ │
│   │ • orion (2TB)   │  │ • Jellyfin      │  │ • Immich Core   │ │
│   │   mirror        │  │ • *Arr Suite    │  │ • PostgreSQL    │ │
│   │ • andromeda     │  │ • Tdarr Server  │  │ • Redis         │ │
│   │   (4TB) mirror  │  │ • Downloads     │  │ (ML on Legion)  │ │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│   │   DNS Stack     │  │   Monitoring    │  │    Backup       │ │
│   │                 │  │                 │  │                 │ │
│   │ • AdGuard Home  │  │ • Node Exporter │  │ • Rclone        │ │
│   │   (Secondary)   │  │ • cAdvisor      │  │ • pCloud Sync   │ │
│   │                 │  │ • Docker Proxy  │  │ • OpenCode CLI  │ │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Primary Functions

| Function | Description |
|----------|-------------|
| **Storage Vault** | ~6TB ZFS mirrored storage with bitrot protection & snapshots |
| **Media Server** | 4K Jellyfin streaming with hardware transcoding |
| **Photo Vault** | Immich core photo storage (AI offloaded to Legion on `:3003`) |
| **DNS Secondary** | Secondary AdGuard Home instance (synced from Agni) |
| **Download Pipeline** | VPN-protected torrent (qBittorrent) / Usenet (SABnzbd) |
| **Transcode Server** | Tdarr queue server (GPU worker offloaded to Legion over NFS) |

---

## 🖥️ Hardware Specifications

| Component | Specification |
|-----------|---------------|
| **Chassis** | Old MSI Cabinet |
| **CPU** | Intel i3 10th Gen F Series |
| **RAM** | 32GB DDR4 @ 2400 MHz (ZFS ARC + containers + ML) |
| **GPU** | NVIDIA GTX 1060 3GB (NVENC + Immich ML) |
| **OS** | TrueNAS SCALE (Dragonfish 24.10) |
| **Network** | 1Gbps Ethernet |
| **IP Address** | 192.168.0.100 (Static) |
| **Web UI** | https://server.krynet.cc or port 88 |

---

## 💾 Storage Architecture (ZFS)

### Storage Pools

| Pool | Hardware | Type | Capacity | Purpose |
|------|----------|------|----------|---------|
| **orion** | 2x 2TB WD Blue HDD | Mirror | ~2TB | App configs, media pipeline data (movies, TV, downloads) |
| **andromeda** | 2x 4TB WD Red Plus HDD | Mirror | ~4TB | Immich (photos/videos), audiobooks & podcasts |

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
├── data/                     # Media pipeline data
│   ├── media/                # Organized media library
│   │   ├── movies/
│   │   ├── series/
│   │   ├── anime/
│   │   └── documentaries/
│   ├── downloads/            # Active downloads
│   │   ├── torrents/
│   │   │   ├── tv/
│   │   │   ├── movies/
│   │   │   └── incomplete/
│   │   └── usenet/
│   │       ├── complete/
│   │       └── incomplete/
│   └── tdarr-cache/          # Transcode temporary files

/mnt/andromeda/
├── apps/
│   └── immich/               # Photo management
│       ├── uploads/          # Original photos (500GB+)
│       ├── ml/               # ML model cache
│       └── db/               # PostgreSQL data
└── media/
    ├── audiobooks/           # Audiobookshelf library
    └── podcasts/             # Audiobookshelf podcasts
```

### ZFS Configuration

**Automated Snapshot Strategy:**
| Dataset | Frequency | Retention | Purpose |
| :--- | :--- | :--- | :--- |
| `orion/apps-config` | Every hour (07:00–23:59) | 3 days | Rapid application config recovery |
| `orion/apps-config` | Daily at 00:00 | 14 days | Long-term config and database protection |
| `andromeda/apps` | Daily at 02:00 (Recursive)| 14 days | Immich DB, uploads, and Paperless protection |
| `andromeda/media` | Weekly Sun at 03:00 (Recursive)| 30 days | Audiobooks and Podcasts library protection |

**Data Integrity:**
- Checksums on every read
- Self-healing from mirror copies on both pools
- Weekly scrubs: Sundays at 23:00 for both orion and andromeda
- SMART tests:
  - **Long test (Orion):** 4:00 AM, 1st of every month
  - **Long test (Andromeda):** 3:00 AM, 1st of every month
  - **Short test (All disks):** Weekly at 12:00 AM

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
DOCKER_DATA_PATH=/mnt/orion/data

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

### Service Details

#### Jellyseerr (Request Interface)
**Port:** 5055 (via Gluetun)  
**Access:** `https://request.krynet.cc`

User-friendly media request portal:
- Family members request content
- Auto-routes to Sonarr/Radarr
- Request limits per user
- Auto-approval rules

#### Prowlarr (Indexer Manager)
**Port:** 9696  
**Access:** `https://indexer.krynet.cc` (Admin only)

Centralized indexer management:
- FlareSolverr integration for Cloudflare bypass
- Syncs indexers to all *arr apps
- Public and private trackers

#### Sonarr (TV Automation)
**Port:** 8989  
**Access:** `https://sonarr.krynet.cc` (Admin only)

TV show management:
- Automatic downloads
- Quality upgrades
- Season pack handling
- Naming: `{Series} - S{season:00}E{episode:00} - {Title}`

#### Radarr (Movie Automation)
**Port:** 7878  
**Access:** `https://radarr.krynet.cc` (Admin only)

Movie management:
- Automatic downloads
- Quality profiles
- Naming: `{Movie} ({Year}) [{Quality}]`

#### Bazarr (Subtitles)
**Port:** 6767  
**Access:** `https://bazarr.krynet.cc` (Admin only)

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
**Access:** `https://qb.krynet.cc` (Admin only)

Configuration:
- Download path: `/data/downloads/torrents`
- Categories: tv, movies
- Speed limits configurable

#### SABnzbd (Usenet Client)
**Port:** 8085  
**Access:** `https://nzb.krynet.cc` (Admin only)

Usenet downloading:
- Provider: Your Usenet provider
- SSL connections
- Categories synced with *arr apps

#### Tdarr (GPU Transcoding)
**Port:** 8265  
**Access:** `https://tdarr.krynet.cc` (Admin only)

H.265/HEVC conversion:
- 40% space savings
- GPU-accelerated (GTX 1060 NVENC)
- Quality: CRF 23 (visually lossless)
- Speed: 2-3x realtime

#### Jellyfin (Media Server)
**Port:** 8096  
**Access:** `https://media.krynet.cc`

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
│                        IMMICH STACK (v3)                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────────┐    ┌─────────────────────────────┐    │
│   │  Immich Server  │◄──▶│  Immich Machine Learning   │    │
│   │     :2283       │    │  (CUDA GPU on Legion :3003) │    │
│   └────────┬────────┘    └─────────────────────────────┘    │
│            │                                                 │
│   ┌────────▼────────┐    ┌─────────────────────────────┐    │
│   │  PostgreSQL     │    │         Redis               │    │
│   │  (VectorChord)  │    │       (Valkey)              │    │
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
| `https://photos.krynet.cc` | Public access (OAuth) |
| `https://photos.lan.kkasbi.in` | LAN access |
| `https://ipt.krynet.cc` | Power Tools (bulk edits) |

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
**Access:** `https://logs.krynet.cc`

Real-time log streaming for Prime containers.

---

## 💾 Backup Configuration

### Rclone to pCloud

**Healthcheck:** `hc.krynet.cc` ping on completion

**Backup Targets:**

| Source | Destination | Purpose |
|--------|-------------|---------|
| `/mnt/orion/apps-config` | `pcloud:Backups/Krynet-Prime/Configs` | All container configs |
| `/mnt/andromeda/apps/immich/db` | `pcloud:Backups/Krynet-Prime/ImmichDB` | Immich database backup |

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
**Port:** 53 (DNS), 7000 (Web UI)  
**Access:** `https://adguard.krynet.cc`

Secondary DNS server (synced from Agni primary via AdGuard Home Sync):
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
> **Note on Stack Management:** Deploy, update, and manage services via **Portainer Stacks** (`https://portainer.krynet.cc` or Agni Master) using `stacks/prime/`. Use terminal access for diagnostics, ZFS management, backups, and log inspections.

```bash
# TrueNAS Shell access (Passwordless ED25519)
ssh prime  # or ssh truenas_admin@192.168.0.100

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

**Last Updated:** August 2026  
**Server IP:** 192.168.0.100  
**OS:** TrueNAS SCALE Dragonfish 24.10  
**Storage:** ~6TB (2x ZFS mirrored pools)  
**Services:** 25+ containers  
**Role:** Storage Hub + Media Center
