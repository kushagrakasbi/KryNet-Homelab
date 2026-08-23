# 📦 KryNet Service Configuration Guide

**Comprehensive Service Documentation**

This document provides detailed configuration, deployment, and troubleshooting information for all services running in the KryNet ecosystem.

---

## Table of Contents

1. [Service Overview](#service-overview)
2. [Media Automation Stack](#media-automation-stack)
3. [Personal Data Services](#personal-data-services)
4. [Monitoring & Operations](#monitoring--operations)
5. [Infrastructure Services](#infrastructure-services)
6. [Network Services](#network-services)
7. [Common Patterns](#common-patterns)
8. [Troubleshooting](#troubleshooting)

---

## 📊 Service Overview

### Service Matrix

| Service | Node | Purpose | Port | Ingress URL | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Caddy** | 🔥 Agni | Ingress Reverse Proxy & Wildcard SSL | 80/443 | `*.krynet.cc` | 🟢 Active |
| **AdGuard Home** | 🔥 Agni / 🌟 Prime | Split-Horizon DNS & Ad Blocking | 53 / 7000 | `adguard2.krynet.cc` | 🟢 Active |
| **Tailscale** | Fleet Mesh | Zero-Trust WireGuard Mesh VPN | N/A | `100.x.x.x` | 🟢 Active |
| **Immich Core (v3.1)** | 🌟 Prime | Self-hosted Photo & Video Backup | 2283 | `photos.krynet.cc` | 🟢 Active |
| **Jellyfin** | 🌟 Prime | Media Server & Streaming | 8096 | `media.krynet.cc` | 🟢 Active |
| **Jellystat** | 🌟 Prime | Jellyfin Watch Analytics & History | 3005 | `jellystat.krynet.cc` | 🟢 Active |
| **Jellyseerr** | 🌟 Prime | Media Request Manager (Gluetun) | 5055 | `request.krynet.cc` | 🟢 Active |
| **Sonarr** | 🌟 Prime | TV Show PVR Automation | 8989 | `sonarr.krynet.cc` | 🟢 Active |
| **Radarr** | 🌟 Prime | Movie PVR Automation | 7878 | `radarr.krynet.cc` | 🟢 Active |
| **Prowlarr** | 🌟 Prime | Torrent & Usenet Indexer Sync | 9696 | `indexer.krynet.cc` | 🟢 Active |
| **Bazarr** | 🌟 Prime | Subtitle Downloader | 6767 | `bazarr.krynet.cc` | 🟢 Active |
| **qBittorrent** | 🌟 Prime | BitTorrent Client (Gluetun VPN) | 8080 | `qbit.krynet.cc` | 🟢 Active |
| **SABnzbd** | 🌟 Prime | Usenet Client | 8085 | `nzb.krynet.cc` | 🟢 Active |
| **Gluetun** | 🌟 Prime | Surfshark WireGuard VPN Gateway | 8080/5055 | N/A (Internal) | 🟢 Active |
| **Tdarr Server** | 🌟 Prime | Video Transcoding Coordinator | 8265 | `tdarr.krynet.cc` | 🟢 Active |
| **Tdarr Node (GPU)**| ⚡ Legion | RTX 3060 NVENC Hardware Transcoder| N/A | N/A (Worker) | 🟢 Active |
| **Ollama (CUDA)** | ⚡ Legion | Local LLM Engine (Qwen / DeepSeek)| 11434 | N/A (Internal) | 🟢 Active |
| **LiteLLM Gateway**| ⚡ Legion | Universal AI Model API Proxy | 4000 | `litellm.krynet.cc` | 🟢 Active |
| **OpenWebUI** | ⚡ Legion | AI Chat & Workflow Interface | 3999 | `ow.krynet.cc` | 🟢 Active |
| **Immich ML Node** | ⚡ Legion | Remote Machine Learning Acceleration | 3003 | N/A (Worker) | 🟢 Active |
| **NVIDIA GPU Exporter**|⚡ Legion| RTX 3060 Prometheus Exporter | 9835 | N/A (Prometheus) | 🟢 Active |
| **Vaultwarden** | 🔥 Agni | Encrypted Password Vault | 8222 | `vault.krynet.cc` | 🟢 Active |
| **Home Assistant** | 🔥 Agni | Smart Home Automation Hub | 8123 | `ha.krynet.cc` | 🟢 Active |
| **Homepage** | 🔥 Agni | Unified Fleet Dashboard | 3075 | `home.krynet.cc` | 🟢 Active |
| **Prometheus** | 🔥 Agni | Multi-Node Time-Series Metrics DB | 9090 | `prom.krynet.cc` | 🟢 Active |
| **Grafana** | 🔥 Agni | Fleet & GPU Metrics Visualization | 3000 | `grafana.krynet.cc` | 🟢 Active |
| **Gatus** | 🔥 Agni | Multi-Node Service Health Probing | 3001 | `status.krynet.cc` | 🟢 Active |
| **Gotify** | 🔥 Agni | Mobile Push Notifications | 8089 | `notify.krynet.cc` | 🟢 Active |
| **Healthchecks** | 🔥 Agni | Backup Cron Dead-Man's Switch | 8000 | `hc.krynet.cc` | 🟢 Active |
| **Paperless-ngx** | 🌟 Prime | Document Indexing & OCR Archiving | 8089 | `paperless.krynet.cc`| 🟢 Active |
| **FreshRSS** | 🌟 Prime | Self-hosted RSS Reader | 8086 | `rss.krynet.cc` | 🟢 Active |
| **Audiobookshelf** | 🌟 Prime | Audiobook & Podcast Streaming | 13378| `abs.krynet.cc` | 🟢 Active |

### Docker Network Assignment

**kry_net (Internal Communication):**
- All backend services
- Database connections
- Service-to-service communication

**traefik_proxy (Web-Exposed):**
- Caddy reverse proxy
- All services with web interfaces
- Health check monitoring

**host (Host Network Mode):**
- Tailscale (VPN requires host network)
- Home Assistant (mDNS discovery)
- AdGuard Home (port 53 binding)
- cloudflared (optimal performance)

---

## 🎬 Media Automation Stack

### Architecture Overview

```
User Request → Jellyseerr → Prowlarr → Sonarr/Radarr
    ↓                           ↓
Notification              Download Client (qBit/SAB)
                                ↓
                          File Organization
                                ↓
                          Tdarr Optimization
                                ↓
                          Bazarr Subtitles
                                ↓
                          Jellyfin Streaming
```

---

### Jellyseerr (Media Request Interface)

**Purpose:** User-friendly interface for media requests without exposing *arr stack complexity

**Docker Configuration:**
```yaml
services:
  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    network_mode: service:gluetun  # Routes through VPN
    depends_on:
      - gluetun
    volumes:
      - ${DOCKER_CONFIG_PATH}/jellyseerr:/app/config
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - LOG_LEVEL=info
      - PORT=5055
    restart: unless-stopped
```

**Initial Setup:**

1. **First Access:** `http://192.168.0.100:5055` (or via Gluetun proxy)
2. **Sign in with Jellyfin:**
   - Jellyfin URL: `http://jellyfin:8096`
   - Use Jellyfin admin credentials
3. **Configure Radarr:**
   - Server: `http://radarr:7878`
   - API Key: (from Radarr → Settings → General)
   - Root Folder: `/data/media/movies`
   - Quality Profile: HD-1080p
4. **Configure Sonarr:**
   - Server: `http://sonarr:8989`
   - API Key: (from Sonarr → Settings → General)
   - Root Folder: `/data/media/series`
   - Quality Profile: HD-1080p
5. **Permissions:**
   - Create user accounts for family members
   - Set request limits (e.g., 10 requests/week)
   - Configure auto-approval for certain users

**Public Access:**
- URL: `https://request.mydomain.com`
- Cloudflare Access: OAuth required
- Purpose: Family can request content from anywhere

**Why Behind VPN:**
- Prevents ISP from seeing media request patterns
- Additional privacy layer
- Consistent with download client isolation

---

### Prowlarr (Indexer Manager)

**Purpose:** Centralized indexer management for all *arr applications

**Docker Configuration:**
```yaml
services:
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    ports:
      - "9696:9696"
    volumes:
      - ${DOCKER_CONFIG_PATH}/prowlarr:/config
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy
```

**Initial Setup:**

1. **Add Indexers:**
   - Navigate: Indexers → Add Indexer
   - Public: 1337x, RARBG, The Pirate Bay
   - Private: (If you have accounts)

2. **Configure FlareSolverr** (Cloudflare bypass):
   - Settings → Indexers → FlareSolverr
   - URL: `http://flaresolverr:8191`
   - Required for Cloudflare-protected indexers

3. **Connect to *arr Apps:**
   - Settings → Apps → Add Application
   - Type: Sonarr
   - Server: `http://sonarr:8989`
   - API Key: (from Sonarr)
   - Sync Level: Full Sync
   - Repeat for Radarr

**Sync Behavior:**
- Prowlarr pushes indexers to Sonarr/Radarr automatically
- Any indexer added in Prowlarr appears in all *arr apps
- Centralized stats and monitoring

**Access:** `https://indexer.lan.mydomain2.com` (Admin only)

---

### Sonarr (TV Show Automation)

**Purpose:** Automate TV show downloads, organization, and upgrading

**Docker Configuration:**
```yaml
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    ports:
      - "8989:8989"
    volumes:
      - ${DOCKER_CONFIG_PATH}/sonarr:/config
      - ${DOCKER_DATA_PATH}:/data  # Unified data structure
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy
```

**Unified Data Structure:**
```
/data/
├── torrents/        # qBittorrent downloads
│   ├── tv/
│   └── movies/
├── usenet/          # SABnzbd downloads
│   ├── tv/
│   └── movies/
└── media/           # Final organized media
    ├── series/      # TV shows
    ├── anime/       # Anime
    ├── movies/      # Movies
    └── documentaries/
```

**Key Configuration:**

1. **Root Folders:**
   - Series: `/data/media/series`
   - Anime: `/data/media/anime`

2. **Quality Profiles:**
   - HD-1080p: Preferred quality
   - Upgrades: Enabled (will replace 720p with 1080p)
   - Cutoff: WEBDL-1080p or Bluray-1080p

3. **Download Clients:**
   - qBittorrent: `http://gluetun:8080` (via VPN)
   - Category: tv
   - Priority: 1

   - SABnzbd: `http://sabnzbd:8085` (direct)
   - Category: tv
   - Priority: 2 (fallback)

4. **Connect to Jellyfin:**
   - Settings → Connect → Jellyfin
   - Host: `http://jellyfin:8096`
   - API Key: (from Jellyfin)
   - Action: Update Library on Import/Upgrade

**Series Organization:**
```
/data/media/series/
├── Breaking Bad (2008)/
│   ├── Season 01/
│   │   ├── Breaking Bad - S01E01 - Pilot.mkv
│   │   └── Breaking Bad - S01E02 - Cat's in the Bag....mkv
│   └── Season 02/
└── Game of Thrones (2011)/
```

**Naming Scheme:**
```
{Series Title} - S{season:00}E{episode:00} - {Episode Title}
```

**Access:** `https://sonarr.lan.mydomain2.com` (Admin only)

---

### Radarr (Movie Automation)

**Purpose:** Automate movie downloads, organization, and upgrading

**Docker Configuration:**
```yaml
services:
  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    ports:
      - "7878:7878"
    volumes:
      - ${DOCKER_CONFIG_PATH}/radarr:/config
      - ${DOCKER_DATA_PATH}:/data
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy
```

**Key Configuration:**

1. **Root Folders:**
   - Movies: `/data/media/movies`
   - Documentaries: `/data/media/documentaries`

2. **Quality Profiles:**
   - HD-1080p: Primary profile
   - 4K: Future profile (when 4K capable displays added)

3. **Download Clients:** Same as Sonarr

**Movie Organization:**
```
/data/media/movies/
├── The Matrix (1999)/
│   └── The Matrix (1999) [1080p].mkv
└── Inception (2010)/
    └── Inception (2010) [1080p].mkv
```

**Naming Scheme:**
```
{Movie Title} ({Release Year}) [{Quality Full}]
```

**Access:** `https://radarr.lan.mydomain2.com` (Admin only)

---

### Bazarr (Subtitle Management)

**Purpose:** Automatic subtitle download for movies and TV shows

**Docker Configuration:**
```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    ports:
      - "6767:6767"
    volumes:
      - ${DOCKER_CONFIG_PATH}/bazarr:/config
      - ${DOCKER_DATA_PATH}:/data
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy
```

**Initial Setup:**

1. **Languages:**
   - Languages Filter: English
   - Also download: Hindi (for Bollywood content)

2. **Providers:**
   - OpenSubtitles.com (requires account)
   - Subscene
   - Addic7ed

3. **Connect to Sonarr:**
   - Settings → Sonarr
   - Address: `http://sonarr:8989`
   - API Key: (from Sonarr)

4. **Connect to Radarr:**
   - Settings → Radarr
   - Address: `http://radarr:7878`
   - API Key: (from Radarr)

**Subtitle Preferences:**
- Format: SRT (best compatibility)
- Encoding: UTF-8
- Hearing Impaired: Exclude
- Foreign Parts Only: Include when available

**Access:** `https://bazarr.lan.mydomain2.com` (Admin only)

---

### qBittorrent (Torrent Client)

**Purpose:** Download torrents via VPN with kill switch

**Docker Configuration:**
```yaml
services:
  # VPN Container
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    ports:
      - "8080:8080"  # qBittorrent WebUI
      - "6881:6881"  # Torrent TCP
      - "6881:6881/udp"  # Torrent UDP
      - "5055:5055"  # Jellyseerr
    volumes:
      - ${DOCKER_CONFIG_PATH}/gluetun:/gluetun
    environment:
      - VPN_SERVICE_PROVIDER=surfshark
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
      - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES}
      - SERVER_COUNTRIES=Netherlands  # Fast EU server
      - FIREWALL_OUTBOUND_SUBNETS=192.168.0.0/24,172.16.3.0/24
      - FIREWALL_INPUT_PORTS=8080,6881,5055
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy

  # qBittorrent behind VPN
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    network_mode: service:gluetun  # Shares Gluetun's network
    depends_on:
      - gluetun
    volumes:
      - ${DOCKER_CONFIG_PATH}/qbittorrent:/config
      - ${DOCKER_DATA_PATH}:/data
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - WEBUI_PORT=8080
    restart: unless-stopped
```

**Initial Setup:**

1. **First Login:**
   - URL: `http://192.168.0.100:8080` or via Caddy
   - Default: admin / adminadmin
   - Change immediately!

2. **Downloads:**
   - Default Save Path: `/data/torrents`
   - Keep incomplete in: `/data/torrents/incomplete`
   - Automatically add: `.torrent` files from `/data/torrents/watch`

3. **Connection:**
   - Port: 6881 (both TCP/UDP)
   - UPnP/NAT-PMP: Disabled (VPN handles it)
   - Max connections: 500
   - Max uploads: 10

4. **Speed Limits:**
   - Global upload: 10 MB/s (or unlimited if good upload)
   - Global download: Unlimited
   - Alt speed: 1 MB/s (daytime throttle)
   - Schedule: Alt speed 9 AM - 11 PM

5. **Categories:**
   - tv: `/data/torrents/tv`
   - movies: `/data/torrents/movies`
   - (Sonarr/Radarr will auto-assign)

**VPN Verification:**

Test kill switch:
```bash
# Stop Gluetun
docker stop gluetun

# Check qBittorrent connectivity
# Should fail - no downloads happening
# No IP leak outside VPN
```

**Access:** `https://qb.lan.mydomain2.com` (Admin only, via Gluetun proxy)

---

### SABnzbd (Usenet Client)

**Purpose:** Download from Usenet (faster, more reliable than torrents for some content)

**Docker Configuration:**
```yaml
services:
  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    ports:
      - "8085:8085"
    volumes:
      - ${DOCKER_CONFIG_PATH}/sabnzbd:/config
      - ${DOCKER_DATA_PATH}:/data
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy
```

**Initial Setup:**

1. **Usenet Provider:**
   - Provider: (Your Usenet service, e.g., Newshosting)
   - Server: news.example.com
   - Port: 563 (SSL)
   - Connections: 20
   - Username/Password: (from provider)

2. **Folders:**
   - Temporary: `/data/usenet/incomplete`
   - Completed: `/data/usenet/complete`
   - Watched: `/data/usenet/watch`

3. **Categories:**
   - tv: `/data/usenet/complete/tv`
   - movies: `/data/usenet/complete/movies`

4. **Switches:**
   - Enable HTTPS: Yes
   - Port: 8085
   - API Key: (auto-generated, needed for *arr apps)

**Access:** `https://nzb.lan.mydomain2.com` (Admin only)

---

### Tdarr (GPU Transcoding)

**Purpose:** Automatically transcode media to H.265 (HEVC) for ~40% space savings

**Docker Configuration:**
```yaml
services:
  # Server
  tdarr-server:
    image: ghcr.io/haveagitgat/tdarr:latest
    container_name: tdarr-server
    ports:
      - "8265:8265"  # WebUI
      - "8266:8266"  # Server port
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - serverIP=0.0.0.0
      - serverPort=8266
      - webUIPort=8265
    volumes:
      - ${DOCKER_CONFIG_PATH}/tdarr/server:/app/server
      - ${DOCKER_CONFIG_PATH}/tdarr/configs:/app/configs
      - ${DOCKER_CONFIG_PATH}/tdarr/logs:/app/logs
      - ${DOCKER_DATA_PATH}:/data
      - ${DOCKER_TRANSCODE_CACHE}:/temp  # Transcode cache
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy

  # Worker Node (GPU-accelerated)
  tdarr-node:
    image: ghcr.io/haveagitgat/tdarr_node:latest
    container_name: tdarr-node
    depends_on:
      - tdarr-server
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - nodeID=KrynetPrimeNode
      - nodeName=KrynetPrimeNode
      - serverIP=tdarr-server
      - serverPort=8266
      - NVIDIA_DRIVER_CAPABILITIES=all
      - NVIDIA_VISIBLE_DEVICES=all
    volumes:
      - ${DOCKER_CONFIG_PATH}/tdarr/configs:/app/configs
      - ${DOCKER_CONFIG_PATH}/tdarr/logs-node:/app/logs
      - ${DOCKER_DATA_PATH}:/data
      - ${DOCKER_TRANSCODE_CACHE}:/temp
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped
    networks:
      - kry_net
```

**Initial Setup:**

1. **Libraries:**
   - Add Library: Movies
   - Source: `/data/media/movies`
   - Scan: Recursive
   - File health checks: Enabled

   - Add Library: TV Shows
   - Source: `/data/media/series`
   - Scan: Recursive

2. **Transcode Flow:**
   ```
   Input Plugin: Check File
   ↓
   Filter: Video Codec = H.264 (skip if already H.265)
   ↓
   Transcode Plugin: NVIDIA NVENC H.265
   ↓
   Output: Replace Original
   ```

3. **Worker Settings:**
   - Transcode: GPU (GTX 1060 NVENC)
   - Health Check: CPU
   - Simultaneous: 1 (GPU limited)

**Transcode Settings:**
```
Codec: HEVC (H.265)
Preset: Slow (better quality)
CRF: 23 (visually lossless)
Audio: Copy (no re-encoding)
Subtitles: Copy all tracks
10-bit: Enabled (smaller files)
```

**Performance:**
- Speed: 2-3x realtime (90-min movie = 30-45 mins)
- GPU Load: 95-100% during transcode
- Space Savings: 35-45% average
- Quality Loss: Imperceptible (CRF 23)

**Access:** `https://tdarr.lan.mydomain2.com` (Admin only)

---

### Jellyfin (Media Server)

**Purpose:** Stream movies, TV shows, and music to all devices

**Docker Configuration:**
```yaml
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    ports:
      - "8096:8096"
    volumes:
      - ${DOCKER_CONFIG_PATH}/jellyfin:/config
      - ${DOCKER_DATA_PATH}/media/movies:/data/movies
      - ${DOCKER_DATA_PATH}/media/series:/data/tvshows
      - ${DOCKER_DATA_PATH}/media/anime:/data/anime
      - ${DOCKER_DATA_PATH}/media/documentaries:/data/documentaries
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - JELLYFIN_PublishedServerUrl=media.mydomain.com
    devices:
      - /dev/dri:/dev/dri  # Intel QuickSync + VAAPI
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy
```

**Initial Setup:**

1. **Libraries:**
   - Movies: `/data/movies` (Movie library)
   - TV Shows: `/data/tvshows` (Show library)
   - Anime: `/data/anime` (Show library)
   - Documentaries: `/data/documentaries` (Movie library)

2. **Hardware Acceleration:**
   - Playback → Transcoding
   - Hardware acceleration: Intel QuickSync (QSV)
   - Enable: H.264, HEVC, VP9
   - Fallback: NVIDIA NVENC (H.264 only on GTX 1060)

3. **Networking:**
   - Enable automatic port mapping: No (Caddy handles it)
   - Public HTTPS port: 443
   - Public HTTP port: 80
   - Local network: 192.168.0.0/24

4. **Users:**
   - Admin: Full access
   - Family Member 1: Access to all libraries
   - Family Member 2: Access to all libraries
   - Kids: Access to age-appropriate only (parental controls)

**Playback Settings:**
- Max streaming bitrate: 120 Mbps (home LAN)
- Remote streaming: 20 Mbps (internet limited)
- Allow subtitle extraction: Yes
- Subtitle burn-in: Auto (only when needed)

**Public Access:**
- URL: `https://media.mydomain.com`
- Cloudflare Access: OAuth required
- Mobile apps: Jellyfin (Android/iOS)

**Access:** `https://media.lan.mydomain2.com` (Direct LAN, fastest)

---

## 📸 Personal Data Services

### Immich (Photo Management)

**Purpose:** Self-hosted Google Photos alternative with ML features

**Docker Configuration:**
```yaml
services:
  # Main Server
  immich-server:
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    container_name: immich_server
    ports:
      - "2283:2283"
    volumes:
      - /mnt/andromeda/apps/immich/uploads:/data
      - /etc/localtime:/etc/localtime:ro
    depends_on:
      - redis
      - database
    restart: unless-stopped
    networks:
      - kry_net
      - traefik_proxy

  # ML Service (GPU-accelerated)
  immich-machine-learning:
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-cuda
    container_name: immich_machine_learning
    volumes:
      - /mnt/andromeda/apps/immich/ml:/cache
    environment:
      - MACHINE_LEARNING__FACE_RECOGNITION_MODEL=mobile_face
      - MACHINE_LEARNING__FACE_DETECTION_MODEL=yunet
      - MACHINE_LEARNING__CLIP_MODEL=ViT-B-16__laion2b_s34b_b88k
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped
    networks:
      - kry_net

  # Redis Cache
  redis:
    image: docker.io/valkey/valkey:8-bookworm
    container_name: immich_redis
    healthcheck:
      test: redis-cli ping || exit 1
    restart: unless-stopped
    networks:
      - kry_net

  # PostgreSQL Database
  database:
    image: docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:739cdd626151ff1f796dc95a6591b55a714f341c737e27f045019ceabf8e8c52
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
      POSTGRES_INITDB_ARGS: --data-checksums
    ports:
      - "5432:5432"
    env_file:
      - stack.env
    volumes:
      - /mnt/andromeda/apps/immich/db:/var/lib/postgresql/data
    command: postgres -c shared_preload_libraries=vectors.so -c
      'search_path="$$user", public, vectors' -c logging_collector=on -c
      max_wal_size=2GB -c shared_buffers=512MB -c wal_compression=on
    restart: unless-stopped
    networks:
      - kry_net
```

**Access:** `https://photos.mydomain.com` (Public) or `https://photos.lan.mydomain2.com` (Internal)

---

### Paperless-ngx (Document Management)
*(Currently Disabled - Pending Migration)*

**Purpose:** OCR and organize physical documents.
**Configuration:** Uses Redis and a dedicated Postgres database.
**Critical Path:** `/mnt/andromeda/apps/paperless/documents/consume` (Scanner upload target).

---

## 🔍 Monitoring & Operations

### Uptime Kuma (Status Page)

**Purpose:** Health checks for all services.
**Config:** `stacks/prime/monitoring.yml`
**Access:** `https://status.lan.mydomain2.com`

**Monitored Endpoints:**
- HTTP(s) Keywords: Checks for "Dashboard" or specific text on service pages.
- Certificate Expiry: Warns 14 days before expiration.
- Container Health: Docker socket integration.

### Prometheus & Grafana (Metrics)

**Purpose:** Visualizing server performance (CPU, RAM, ZFS ARC, Network).
**Config:** `stacks/prime/monitoring.yml`
**Access:** `https://grafana.lan.mydomain2.com`

**Data Sources:**
- Node Exporter (Host metrics)
- cAdvisor (Container metrics)
- TrueNAS API (ZFS stats)

### Dozzle (Log Viewer)

**Purpose:** Real-time stream of container logs via web UI.
**Config:** `stacks/prime/monitoring.yml`
**Port:** 8088
**Security Note:** Exposed only on LAN. Logs can contain sensitive info.

---

## 🏗️ Infrastructure Services

### Homepage (Dashboard)

**Purpose:** The start page for the homelab.
**Config:** `stacks/prime/homepage.yml`
**Features:**
- Real-time service status indicators (green/red dots).
- Interactive widgets (Calendar, Weather, System Stats).
- Bookmark groups for external links.

### Syncthing (Backup & Sync)

**Purpose:** Continuous file synchronization between Prime (TrueNAS) and Agni (Ubuntu).
**Config:** `stacks/prime/syncthing.yml`
**Sync Folder:** `/data/sync`
**Topology:**
- Prime (Master): "Send Only" for app configs.
- Agni (Slave): "Receive Only" with simple versioning.

---

## 🌐 Network Services

### Cloudflared (Tunnel)
**Config:** `stacks/prime/cloudflared.yml`
**Role:** Creates the outbound tunnel to Cloudflare Edge.
**Token:** `CF_TOKEN` in `stack.env` (ROTATED QUARTERLY).

### AdGuard Home (DNS)
**Config:** `stacks/prime/adguard.yml`
**Role:** Secondary DNS (synced from Agni primary via AdGuard Home Sync on Agni).

---

## 🧩 Common Patterns

### Database Management
Most services use the centralized PostgreSQL instance on port `5432` if possible, otherwise they use their own bundled SQLite/DB containers.
**Credentials:** Managed via `stack.env` (`POSTGRES_PASS`).

### Volume Mapping Standards
- `/config`: Always maps to `/mnt/orion/apps-config/<app_name>`
- `/data`: Maps to the shared data directory on orion (e.g., `/mnt/orion/data`) or andromeda for Immich/Audiobookshelf
- `/etc/localtime`: Ro-mounted for correct timezone logging.

---

## 🛠️ Troubleshooting

### "Container Healthy but Unreachable"
1. **Check Networks:**
   ```bash
   docker inspect <container_name> | grep Network
   ```
   Must be attached to `traefik_proxy` (even though we use Caddy now, the network name persists).

2. **Check Caddy Logs:**
   ```bash
   docker logs caddy --tail 100
   ```
   Look for `upstream connect error` (means Caddy can't talk to the container).

### "Files Not Found in *arr Apps"
1. **Check PUID/PGID:**
   Ensure `PUID=1000` and `PGID=1000` (or appropriate user ID) matches file ownership on ZFS.
2. **Check Mount Paths:**
   Verify `/data` inside the container maps to the correct ZFS dataset path.

### "Slow Trascode"
1. **Check GPU Passthrough:**
   ```bash
   docker exec -it jellyfin nvidia-smi
   ```
   If this command fails, the container doesn't see the GPU. Check `deploy.resources` block in `media-stack.yml`.
    container_name: immich_postgres
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
      POSTGRES_INITDB_ARGS: --data-checksums
    volumes:
      - /mnt/andromeda/apps/immich/db:/var/lib/postgresql/data
    command: postgres -c shared_preload_libraries=vectors.so
    restart: unless-stopped
    networks:
      - kry_net
```

**Storage Structure:**
```
/mnt/andromeda/apps/immich/
├── uploads/              # Original photos (500GB+)
│   ├── library/
│   │   └── admin/       # Per-user folders
│   │       └── 2024/
│   │           ├── 01/  # Organized by upload date
│   │           └── 02/
│   └── thumbs/          # Generated thumbnails
├── ml/                  # ML model cache (10GB)
│   ├── facial-recognition/
│   └── clip/
└── db/                  # PostgreSQL data (5GB)
```

**Initial Setup:**

1. **First Access:** `https://photos.mydomain.com`
2. **Create Admin User:** (First user becomes admin)
3. **Mobile Upload:**
   - Install Immich app (Android/iOS)
   - Add server: `https://photos.mydomain.com`
   - Enable background upload
   - Select albums to backup

**ML Features:**

*Facial Recognition:*
- Automatic face detection in photos
- Group similar faces (asks for name assignment)
- Search: "Show me photos of [Person Name]"
- GPU accelerated (GTX 1060)

*Smart Search (CLIP):*
- Natural language: "beach sunset"
- Object recognition: "dog", "car", "food"
- Scene detection: "mountain", "city", "indoor"
- Works without manual tagging

**Migration from Google Photos:**
- Use Google Takeout to download library
- Upload via Immich CLI or web bulk upload
- Preserves EXIF data (date, location, camera)
- Detects duplicates automatically

**Public Access:**
- URL: `https://photos.mydomain.com`
- Cloudflare Access: OAuth (family only)
- Shared Albums: Can create public links

**Backup:**
- Photos stored on `andromeda` pool
- Weekly ZFS snapshots
- Encrypted cloud backup via rclone (Backblaze B2)

---

### Paperless-ngx (Document Management) - DISABLED

**Purpose:** OCR and archive scanned documents

*Currently disabled - plan to re-enable after storage expansion*

**When Re-enabled:**
- Scan physical mail via mobile app
- Automatic OCR (Tesseract)
- Tag and categorize documents
- Search full text content
