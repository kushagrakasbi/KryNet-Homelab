# 🏠 Home Server Documentation (Detailed)

This document provides a comprehensive overview of the home server setup, including hardware, software, networking, and application configurations. It serves as a detailed reference for maintenance and troubleshooting.

## 🖥️ Hardware Specifications

Your primary TrueNAS Scale server is built on older PC hardware, repurposed for home server duties. A secondary Windows Server (Lenovo Legion laptop) augments the setup with additional resources, especially for GPU-intensive tasks.

### TrueNAS Scale Server

- **CPU:** Intel i5 7600k
- **Motherboard:** Gigabyte GA-B250M D2V
- **RAM:** 32GB DDR4 (2x Crucial 2400mhz 16GB)
- **Storage:**
    - **OS Drive:** 1x Crucial SATA SSD 500GB (TrueNAS Scale OS)
    - **ZFS Pool `andromeda`:** 2x WD Red Plus 4TB HDD (Mirrored) - Primarily for Immich.
    - **ZFS Pool `orion`:** 2x WD Blue 2TB HDD (Mirrored) - For media, app-configs, etc.
    - **ZFS Pool `comet`:** 1x WD Blue 1TB HDD (Stripe Mode) - For general storage.
- **GPU:** Zotac Geforce GTX 1060 3GB (Used for Immich ML)
- **PSU:** Corsair VS550
- **Cabinet Fan:** Cooler Master 103
- **Cabinet:** Zebronix Bijli
- **IP Address:** `192.168.0.100`

### Secondary Windows Server (Lenovo Legion Laptop)

- **CPU:** Intel 12th Gen i7 12700H
- **RAM:** 16 GB
- **Storage:** 1 TB SSD
- **GPU:** Nvidia GTX 3060 6GB
- **Operating System:** Windows (with Docker Desktop and WSL2 Backend)
- **IP Address:** `192.168.0.212`

---
### Key Installation Videos Referenced

1. [TrueNAS Scale via Pendrive](https://youtu.be/9O3E9U0DFWo?si=F4lXICvo6wHfy86z)
2. [Tailscale via Portainer](https://youtu.be/lajmJtNycgQ?si=ijGmnjDE3orXkshz)
3. [NPM + Cloudflare + Tailscale Setup](https://youtu.be/Y7Z-RnM77tA?si=O_ksxbD4fXHtLG8g)
4. [OpenWebUI + LiteLLM](https://www.youtube.com/watch?v=JJ_0-pAOIEk)
5. [Immich on TrueNAS](https://www.youtube.com/watch?v=TqjlUocu6ZI)
6. [ARR Stack Setup](https://www.youtube.com/watch?v=twJDyoj0tDc)
---

## 💾 TrueNAS Scale Configuration

### Operating System

- **TrueNAS Scale:** Installed on the 500GB Crucial SATA SSD.
- **GUI Ports:** HTTPS on `444`, HTTP on `88` (changed from default 80/443 to allow Nginx Proxy Manager to use standard web ports).

### ZFS Storage Pools

1. **`andromeda` Pool**
    - **Disks:** 2x 4TB WD Red Plus HDDs
    - **Configuration:** ZFS Mirror
    - **Primary Use:** Dedicated storage for Immich (photos and videos).
    - **Mount Path Example:** `/mnt/andromeda/apps/immich/uploads`
2. **`orion` Pool**
    - **Disks:** 2x 2TB WD Blue HDDs
    - **Configuration:** ZFS Mirror
    - **Primary Use:** General media storage, application configurations, downloads, usenet. Each app typically has a dedicated folder within `apps-config` under this pool.
    - **Mount Path Example:** `/mnt/orion/apps-config/portainer`
3. **`comet` Pool**
    - **Disks:** 1x 1TB WD Blue HDD
    - **Configuration:** ZFS Stripe (single disk)
    - **Primary Use:** General storage (likely for temporary data or less critical files).

## 🗂️ Storage Structure

### Pool: Andromeda (2x4TB Mirror)

`/mnt/andromeda/
├── apps/
│   └── immich/
│       ├── uploads/      # Photo/video storage
│       ├── ml/          # ML model cache
│       └── db/          # PostgreSQL data`

### Pool: Orion (2x2TB Mirror)

`/mnt/orion/
├── apps-config/         # All Docker configs
│   ├── npm/
│   ├── homarr/
│   ├── jellyfin/
│   ├── radarr/
│   ├── sonarr/
│   ├── prowlarr/
│   ├── bazarr/
│   ├── qbittorrent/
│   ├── sabnzbd/
│   ├── jellyseerr/
│   ├── whisparr/
│   ├── openwebui/
│   ├── uptime-kuma/
│   ├── prometheus/
│   ├── gluetun/
│   ├── tailscale/
│   ├── adguardhome/
│   ├── adguardhome-sync/
│   └── homeassistant/
├── downloads/           # Torrent downloads
├── usenet/
│   ├── complete/       # Completed usenet downloads
│   └── incomplete/     # In-progress downloads
└── media/
    ├── Movies/
    ├── TVShows/
    ├── Anime/
    ├── Documentaries/
    └── Books/`

### Pool: Comet (1TB Stripe)

`/mnt/comet/
└── general/            # General storage`

---

## 🌐 Networking Architecture

The networking setup is designed for flexible, secure, and unified access to services, catering to local network, remote VPN (Tailscale), and public internet access.

### Key Components & Roles

1. **TrueNAS Scale Server (`192.168.0.100`):** Hosts most core services.
2. **Windows Server (`192.168.0.212`):** Hosts secondary services like a backup AdGuard Home and Portainer instance.
3. **Router:** Configured to use AdGuard Home instances as primary/secondary DNS.
4. **Nginx Proxy Manager (NPM):**
    - **Role:** Acts as a reverse proxy, handling SSL termination (using Let's Encrypt certificates via Cloudflare DNS challenge), routing traffic to internal services based on domain names, and providing a centralized access point for all web services.
    - **Ports:** `80`, `443` (for proxying), `81` (for NPM UI).
    - **Location:** Installed via Portainer on the TrueNAS server, using `network_mode: host` to bind directly to ports 80/443.
5. **Cloudflare:**
    - **Domain:** `kkasbi.site`
    - **Role:** DNS management, wildcard SSL certificate issuance (through NPM), Cloudflare Access for security, and Cloudflare Tunnels for secure public exposure of specific services.
    - **Google OAuth for Cloudflare Access:** Configured for enhanced security on publicly exposed services.
6. **Cloudflared:**
    - **Role:** Creates secure tunnels from the TrueNAS server to Cloudflare, enabling public access to selected services without exposing the server's IP address directly.
    - **Installation:** Via Portainer on the TrueNAS server, using `network_mode: host`.
7. **Tailscale:**
    - **Role:** A zero-config VPN that creates a secure mesh network for all your devices (clients and servers). It provides secure access to your home server services from anywhere, bypassing firewall complexities.
    - **Installation:** Via Portainer on the TrueNAS server, using `network_mode: host` and `cap_add: NET_ADMIN, NET_RAW`.
    - **Configuration:** Advertises a subnet route (`192.168.0.0/24`) and acts as an exit node (`TS_EXTRA_ARGS=--advertise-exit-node`).
8. **AdGuard Home:**
    - **Role:** Network-wide ad-blocking and DNS server. Crucial for implementing Split Horizon DNS.
    - **Instances:** Primary on TrueNAS (`192.168.0.100:7000`), Secondary on Windows Server (`192.168.0.212:7002`).
    - **Sync:** `adguardhome-sync` keeps configurations synchronized between instances.

### Domain Naming Conventions

You utilize a structured domain naming convention to differentiate access methods:

- **`.local.kkasbi.site` (Deprecated/Backup):** For local network access. Previously used `Nginx Proxy Manager` to route these requests.
- **`.tail.kkasbi.site` (Deprecated/Backup):** For Tailscale-driven access. Requires Tailscale VPN to be active on the client device.
- **`.kkasbi.site` (Public Access):** Direct Cloudflare Tunnel access for specific services. These services are publicly exposed via Cloudflare.
- **`.krynet.cc` (Primary Split Horizon DNS):** The main domain for unified access, regardless of whether you're on the local network or accessing remotely via Tailscale. This is achieved through Split Horizon DNS.

### Split Horizon DNS (`krynet.cc`) Configuration

This setup allows you to use a single URL (e.g., `photos.krynet.cc`) for both internal and external access to your services.

1. **External Resolution (via Tailscale):**
    - For clients *outside* your home network, DNS queries for `.krynet.cc` are resolved to the **Tailscale public IP** of your TrueNAS server.
    - When a request is made (e.g., `photos.krynet.cc`), it first goes through Tailscale, then is routed internally to the TrueNAS server. NPM on the TrueNAS server then proxies it to the correct application.
2. **Internal Resolution (via AdGuard Home):**
    - For clients *inside* your home network, your router points to your **AdGuard Home instances** (`192.168.0.100` and `192.168.0.212`) as DNS servers.
    - AdGuard Home has **DNS Rewrite rules** configured: `.krynet.cc` is rewritten to `192.168.0.100` (the LAN IP of your TrueNAS server).
    - When a request is made (e.g., `photos.krynet.cc`), it's resolved directly to `192.168.0.100` by AdGuard Home. NPM then proxies it to the correct application.

This setup ensures that all `*.krynet.cc` domains resolve to the correct internal IP (`192.168.0.100`) when on the local network and leverage Tailscale for external access, simplifying access patterns.

### Request Flow for `.krynet.cc` Services

- **Client (Local Network) -> `photos.krynet.cc`:**
    1. Client makes DNS query for `photos.krynet.cc`.
    2. Router forwards query to **AdGuard Home** (`192.168.0.100`).
    3. AdGuard Home's DNS Rewrite resolves `photos.krynet.cc` to `192.168.0.100`.
    4. Client connects directly to `192.168.0.100` (TrueNAS server) on port `443` (HTTPS).
    5. **Nginx Proxy Manager (NPM)** on TrueNAS (`network_mode: host`) receives the request on port `443`.
    6. NPM proxies the request to the internal port of Immich (`2283`).
    7. Immich responds.
- **Client (External/Tailscale VPN active) -> `photos.krynet.cc`:**
    1. Client (with Tailscale VPN on) makes DNS query for `photos.krynet.cc`.
    2. DNS resolution (could be public DNS or Tailscale's MagicDNS depending on configuration) resolves `photos.krynet.cc` to the **Tailscale IP** of the TrueNAS server.
    3. Client connects via the Tailscale VPN tunnel to the TrueNAS server's Tailscale IP on port `443` (HTTPS).
    4. **Nginx Proxy Manager (NPM)** on TrueNAS (`network_mode: host`) receives the request on port `443`.
    5. NPM proxies the request to the internal port of Immich (`2283`).
    6. Immich responds.
- **Client (External/Public Cloudflare Tunnel) -> `media.kkasbi.site`:**
    1. Client makes DNS query for `media.kkasbi.site`.
    2. Cloudflare DNS resolves `media.kkasbi.site` to a **Cloudflare IP**.
    3. Client connects to Cloudflare.
    4. Cloudflare routes the request through the **Cloudflare Tunnel** (established by the `cloudflared` container) to the TrueNAS server.
    5. The `cloudflared` container, typically on the host network, directs the traffic to the appropriate internal service (e.g., Jellyfin on port `8096`).
    6. Jellyfin responds.

### Domain Configuration

### Primary Domain: kkasbi.site

**Registrar/DNS:** Cloudflare

**Access Patterns:**

1. **Direct Access (*.kkasbi.site)** - Public internet via Cloudflare Tunnel
2. **Local Network (*.local.kkasbi.site)** - LAN access via NPM
3. **Tailscale VPN (*.tail.kkasbi.site)** - Secure remote access via Tailnet

### Secondary Domain: krynet.cc

**Configuration:** Split-Horizon DNS

- **External:** Points to Tailscale public IP → Tailscale → Server
- **Internal:** DNS Rewrite in AdGuard → 192.168.0.100 → NPM → Service
- **Purpose:** Single URL for both internal and external access

### SSL/TLS Configuration

**Certificates:** Let's Encrypt via Cloudflare DNS Challenge
**Managed by:** Nginx Proxy Manager

**Wildcard Certificates:**

- .local.kkasbi.site
- .tail.kkasbi.site
- .kkasbi.site
- .krynet.cc

### DNS Configuration

**Primary DNS:** AdGuard Home (192.168.0.100:53) - Port 7000 for UI
**Secondary DNS:** AdGuard Home on Windows Server (192.168.0.212:53) - Port 7002 for UI
**Sync:** AdGuard Home Sync (Port 8082) - Keeps configurations synchronized

**Router DNS Settings:**

- Primary: 192.168.0.100
- Secondary: 192.168.0.212

**Split-Horizon DNS Rules (AdGuard):**

`DNS Rewrite Rules:
*.krynet.cc → 192.168.0.100
(External DNS has *.krynet.cc → Tailscale Public IP)`

---

📦 Service Inventory
Core Infrastructure
ServicePortDomainsPurposeTrueNAS ScaleHTTP: 88, HTTPS: 444server.kkasbi.site, server.local.kkasbi.site, server.tail.kkasbi.site, server.krynet.ccNAS ManagementPortainer (TrueNAS)9443portainer.kkasbi.site, portainer.local.kkasbi.site, portainer.tail.kkasbi.site, portainer.krynet.ccDocker ManagementPortainer (Windows)9444portainer2.krynet.ccWindows Docker ManagementNginx Proxy Manager80, 443, UI: 81npm.kkasbi.site, npm.local.kkasbi.site, npm.tail.kkasbi.site, npm.krynet.ccReverse Proxy & SSLCloudflaredN/A (host network)N/ACloudflare TunnelTailscaleN/A (host network)N/AVPN & Subnet Router
Monitoring & Logs
ServicePortDomainsPurposeUptime Kuma3001monitor.kkasbi.site, monitor.local.kkasbi.site, monitor.tail.kkasbi.site, monitor.krynet.ccService MonitoringPrometheus9090prometheus.local.kkasbi.site, prometheus.tail.kkasbi.site, prometheus.krynet.ccMetrics CollectionDozzle8088logs.kkasbi.site, logs.local.kkasbi.site, logs.tail.kkasbi.site, logs.krynet.ccDocker LogsGoAccess7880npmlogs.local.kkasbi.site, npmlogs.tail.kkasbi.site, npmlogs.krynet.ccNPM Log AnalyticsHomarr7575dash.kkasbi.site, dash.local.kkasbi.site, dash.tail.kkasbi.site, dash.krynet.ccDashboardWatchtowerN/AN/AContainer Auto-Update
Media Stack
ServicePortDomainsNetwork ModePurposeJellyfin8096media.kkasbi.site, media.local.kkasbi.site, media.tail.kkasbi.site, media.krynet.ccBridge (kry_net)Media ServerJellyseerr5055request.kkasbi.site, request.local.kkasbi.site, request.tail.kkasbi.site, request.krynet.ccservice:gluetun (VPN)Media RequestsRadarr7878radarr.local.kkasbi.site, radarr.tail.kkasbi.site, radarr.krynet.ccBridge (kry_net)Movie ManagementSonarr8989sonarr.local.kkasbi.site, sonarr.tail.kkasbi.site, sonarr.krynet.ccBridge (kry_net)TV Show ManagementWhisparr6969whisparr.local.kkasbi.site, whisparr.tail.kkasbi.site, whisparr.krynet.ccservice:gluetun (VPN)Adult Content ManagementBazarr6767bazarr.local.kkasbi.site, bazarr.tail.kkasbi.site, bazarr.krynet.ccBridge (kry_net)Subtitle ManagementProwlarr9696indexer.local.kkasbi.site, indexer.tail.kkasbi.site, indexer.krynet.ccBridge (kry_net)Indexer ManagerqBittorrent8080downloads.local.kkasbi.site, downloads.tail.kkasbi.site, downloads.krynet.ccservice:gluetun (VPN)Torrent ClientSABnzbd8085sabnzbd.local.kkasbi.site, sabnzbd.tail.kkasbi.site, sabnzbd.krynet.ccservice:gluetun (VPN)Usenet ClientFlareSolverr8191N/ABridge (kry_net)Cloudflare BypassGluetunN/AN/ABridge (kry_net)VPN Gateway
Photo Management
ServicePortDomainsPurposeImmich2283photos.kkasbi.site, photos.local.kkasbi.site, photos.tail.kkasbi.site, photos.krynet.ccPhoto ManagementImmich MLN/A (internal)N/AAI/ML Processing (CUDA)Immich RedisN/A (internal)N/ACachingImmich PostgreSQL5432 (exposed)N/ADatabaseImmich Power Tools8001N/AAdmin Tools
AI Stack
ServicePortDomainsPurposeOpenWebUI3999owui.kkasbi.site, owui.local.kkasbi.site, owui.tail.kkasbi.site, owui.krynet.ccAI Chat InterfaceLiteLLM4000litellm.local.kkasbi.site, litellm.tail.kkasbi.site, litellm.krynet.ccLLM Proxy/Gateway
Connected Models:

Claude (Anthropic)
ChatGPT (OpenAI)
Gemini (Google)

Database: Uses Immich PostgreSQL (separate DB: litellm)
Master Key: ${LITELLM_MASTER_KEY} (in stack.env)
Home Automation
ServicePortDomainsPurposeHome Assistant8123ha.kkasbi.site, ha.local.kkasbi.site, ha.tail.kkasbi.site, ha.krynet.ccHome Automation Hub
Integrated Devices:

SmartLife devices
TP-Link Tapo
Wiz bulbs
Amazon Alexa
Various smart plugs

Mobile App: NZB360 configured with Radarr, Sonarr, Jellyseerr
DNS & Network Services
ServicePortDomainsLocationPurposeAdGuard Home (Primary)DNS: 53, UI: 7000adguard.kkasbi.site, adguard.krynet.ccTrueNASPrimary DNS/Ad BlockingAdGuard Home (Secondary)DNS: 53, UI: 7002adguard2.krynet.ccWindows ServerSecondary DNS/Ad BlockingAdGuard Home Sync8082N/ATrueNASConfig Synchronization

---
## 🛠️ Applications & Services

This section lists all installed applications, their functionality, networking details, and associated domains.

### Docker Environment

- **TrueNAS Scale:** Docker containers are managed via `k3s` (Kubernetes) and exposed through **Portainer**.
- **Windows Server:** Docker containers are managed via Docker Desktop with WSL2 backend.
- **Portainer:**
    - **Primary Instance (TrueNAS):**
        - **Port:** `9443`
        - **Installation:** Via TrueNAS Apps catalog.
        - **Domains:** `portainer.local.kkasbi.site`, `portainer.tail.kkasbi.site`, `portainer.kkasbi.site`, `portainer.krynet.cc`
        - **Functionality:** Centralized management UI for Docker containers, stacks, volumes, and networks on the TrueNAS server.
    - **Secondary Instance (Windows Server):**
        - **Port:** `9444`
        - **Installation:** Docker Desktop on Windows.
        - **Domain:** `portainer2.krynet.cc`
        - **Functionality:** Manages Docker containers on the Windows server.
- **`kry_net` Docker Network:** An external Docker network used by most services for inter-container communication on the TrueNAS server.

---
## 🎯 Primary Use Cases

### 1. Photo & Video Management (Immich)

- **Storage:** Andromeda pool (8TB usable in mirror)
- **AI Features:** Face recognition, object detection (CUDA accelerated)
- **Access:** Mobile app, web interface
- **Backup:** Mirrored across 2x4TB drives

### 2. Media Automation Pipeline

**Workflow:**

1. Browse/request media via Jellyseerr
2. Jellyseerr notifies Radarr/Sonarr
3. Radarr/Sonarr searches via Prowlarr
4. Downloads via qBittorrent (torrents) or SABnzbd (usenet)
5. All downloads protected by Gluetun VPN
6. Automatic organization and renaming
7. Bazarr fetches subtitles
8. Media appears in Jellyfin
9. Stream via Jellyfin on any device

### 3. DNS Ad-Blocking & Split-Horizon

- Network-wide ad blocking via AdGuard
- Single URLs work everywhere (krynet.cc)
- Automatic failover with secondary DNS
- Custom DNS rules for local services

### 4. AI/LLM Aggregation

- Single interface (OpenWebUI) for multiple AI models
- Cost tracking and usage monitoring via LiteLLM
- Privacy: Self-hosted, data stays local
- Access from anywhere via VPN
---

### Core Use Cases & Associated Apps

### 1. Photos & Videos Management

- **Immich:**
    - **Functionality:** Self-hosted photo and video backup and management solution, similar to Google Photos. Leverages the GTX 1060 GPU for machine learning tasks like face recognition and object detection.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `2283`
        - **Host Port:** `2283`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/andromeda/apps/immich/uploads` for media, `/mnt/andromeda/apps/immich/db` for PostgreSQL database, `/mnt/andromeda/apps/immich/ml` for ML cache.
    - **Domains:** `photos.local.kkasbi.site`, `photos.tail.kkasbi.site`, `photos.kkasbi.site`, `photos.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          immich-server:
            image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
            volumes:
              - /mnt/andromeda/apps/immich/uploads:/data
            ports:
              - 2283:2283
            depends_on:
              - redis
              - database
            networks:
              - kry_net
          immich-machine-learning:
            image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-cuda
            volumes:
              - /mnt/andromeda/apps/immich/ml:/cache
            networks:
              - kry_net
            deploy:
              resources:
                reservations:
                  devices:
                    - driver: nvidia
                      count: 1
                      capabilities:
                        - gpu
          redis:
            image: docker.io/valkey/valkey:8-bookworm
            networks:
              - kry_net
          database:
            image: docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0
            ports:
              - "5432:5432"
            volumes:
              - /mnt/andromeda/apps/immich/db:/var/lib/postgresql/data
            networks:
              - kry_net
          power-tools: # Immich Power Tools
            image: ghcr.io/varun-raj/immich-power-tools:latest
            ports:
              - "8001:3000"
            networks:
              - kry_net
        ```
        

### 2. Media Request, Downloads & Streaming (ARR Stack with Jellyfin)

This stack automates the entire process of discovering, requesting, downloading, and organizing movies, TV shows, and music.

- **Jellyfin:**
    - **Functionality:** Free and open-source media system that lets you control the management and streaming of your media.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `8096`
        - **Host Port:** `8096`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/jellyfin:/config`, `/mnt/orion/media/Movies:/data/movies`, etc.
    - **Domains:** `media.local.kkasbi.site`, `media.tail.kkasbi.site`, `media.kkasbi.site`, `media.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          jellyfin:
            image: lscr.io/linuxserver/jellyfin:latest
            container_name: jellyfin
            ports:
              - "8096:8096"
            volumes:
              - ${DOCKER_CONFIG_PATH}/jellyfin:/config
              - ${DOCKER_MEDIA_PATH}/Movies:/data/movies
              # ... other media paths
            environment:
              - JELLYFIN_PublishedServerUrl=jellyfin.local.kkasbi.site # Example
            devices:
              - /dev/dri:/dev/dri # For hardware transcoding
            networks:
              - kry_net
        ```
        
- **Jellyseerr:**
    - **Functionality:** Media request management system for Jellyfin (and Plex), allowing users to request movies and TV shows. Routes through Gluetun due to TMDB connection issues in India.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `5055`
        - **Network Mode:** `service:gluetun` (host port `5055` mapped on Gluetun)
    - **Storage:** `/mnt/orion/apps-config/jellyseerr:/app/config`
    - **Domains:** `request.local.kkasbi.site`, `request.tail.kkasbi.site`, `request.kkasbi.site`, `request.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          jellyseerr:
            image: fallenbagel/jellyseerr:latest
            container_name: jellyseerr
            network_mode: service:gluetun # Crucial for VPN routing
            depends_on:
              - gluetun
            volumes:
              - ${DOCKER_CONFIG_PATH}/jellyseerr:/app/config
            environment:
              - PORT=5055
        ```
        
- **Gluetun (VPN Gateway):**
    - **Functionality:** Routes specified container traffic through a VPN (Surfshark Wireguard in this case), ensuring privacy for downloads and other services.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Ports:** `8080`, `6881`, `6881/udp`, `8085`, `5055`, `6969` (mapped for qBittorrent, torrent, SABnzbd, Jellyseerr, Whisparr).
        - **Host Ports:** Same as container ports, but traffic is routed *through* the VPN.
    - **Configuration:** Uses Surfshark VPN with Wireguard protocol. Configured with `FIREWALL_OUTBOUND_SUBNETS=192.168.0.0/24` to allow internal network access for services behind the VPN.
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          gluetun:
            image: qmcgaw/gluetun:latest
            container_name: gluetun
            cap_add:
              - NET_ADMIN
            devices:
              - /dev/net/tun:/dev/net/tun
            ports:
              - "8080:8080" # qBittorrent WebUI
              - "6881:6881" # TCP for torrents
              - "6881:6881/udp" # UDP for torrents
              - "8085:8085" # SABnzbd WebUI
              - "5055:5055" # jellyseers
              - "6969:6969" # Whisparr
            volumes:
              - ${DOCKER_CONFIG_PATH}/gluetun:/gluetun
            environment:
              - VPN_SERVICE_PROVIDER=surfshark
              - VPN_TYPE=wireguard
              - FIREWALL_OUTBOUND_SUBNETS=192.168.0.0/24
              - FIREWALL_INPUT_PORTS=8080,6881,8081,8191,5055,6969 # Includes Jellyseerr and Whisparr
        ```
        
- **qBittorrent:**
    - **Functionality:** Torrent client for downloading media. Runs behind Gluetun.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `8080` (for WebUI)
        - **Network Mode:** `service:gluetun` (Host port `8080` mapped on Gluetun)
    - **Storage:** `/mnt/orion/apps-config/qbittorrent:/config`, `/mnt/orion/downloads:/downloads`
    - **Domains:** `downloads.local.kkasbi.site`, `downloads.tail.kkasbi.site`, `downloads.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          qbittorrent:
            image: lscr.io/linuxserver/qbittorrent:latest
            container_name: qbittorrent
            network_mode: service:gluetun
            depends_on:
              - gluetun
            volumes:
              - ${DOCKER_CONFIG_PATH}/qbittorrent:/config
              - ${DOCKER_DOWNLOADS_PATH}:/downloads
            environment:
              - WEBUI_PORT=8080
        ```
        
- **SABnzbd:**
    - **Functionality:** Usenet client for downloading media. Runs behind Gluetun.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `8085` (for WebUI)
        - **Network Mode:** `service:gluetun` (Host port `8085` mapped on Gluetun)
    - **Storage:** `/mnt/orion/apps-config/sabnzbd:/config`, `/mnt/orion/usenet/complete:/downloads`, `/mnt/orion/usenet/incomplete:/incomplete-downloads`
    - **Domains:** `sabnzbd.local.kkasbi.site`, `sabnzbd.tail.kkasbi.site`, `sabnzbd.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          sabnzbd:
            image: lscr.io/linuxserver/sabnzbd:latest
            container_name: sabnzbd
            network_mode: service:gluetun
            depends_on:
              - gluetun
            volumes:
              - ${DOCKER_CONFIG_PATH}/sabnzbd:/config
              - ${DOCKER_USENET_PATH}/complete:/downloads
              - ${DOCKER_USENET_PATH}/incomplete:/incomplete-downloads
        ```
        
- **FlareSolverr:**
    - **Functionality:** Proxy server to bypass Cloudflare and DDoS-Guard protection for torrent/usenet indexers.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `8191`
        - **Host Port:** `8191`
        - **Docker Network:** `kry_net`
    - **Domains:** `flaresolverr.local.kkasbi.site`, `flaresolverr.tail.kkasbi.site`, `flaresolverr.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          flaresolverr:
            image: ghcr.io/flaresolverr/flaresolverr:latest
            container_name: flaresolverr
            ports:
              - "8191:8191"
            networks:
              - kry_net
        ```
        
- **Prowlarr:**
    - **Functionality:** Indexer manager for Sonarr, Radarr, and Lidarr, allowing easy management and querying of both torrent trackers and Usenet indexers.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `9696`
        - **Host Port:** `9696`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/prowlarr:/config`
    - **Domains:** `indexer.local.kkasbi.site`, `indexer.tail.kkasbi.site`, `indexer.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          prowlarr:
            image: lscr.io/linuxserver/prowlarr:latest
            container_name: prowlarr
            ports:
              - "9696:9696"
            volumes:
              - ${DOCKER_CONFIG_PATH}/prowlarr:/config
            networks:
              - kry_net
        ```
        
- **Sonarr:**
    - **Functionality:** Automated TV show downloading and management.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `8989`
        - **Host Port:** `8989`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/sonarr:/config`, `/mnt/orion/downloads:/downloads`, `/mnt/orion/usenet/complete:/usenet`, `/mnt/orion/media/TVShows:/tv`, `/mnt/orion/media/Anime:/anime`
    - **Domains:** `sonarr.local.kkasbi.site`, `sonarr.tail.kkasbi.site`, `sonarr.krynet.cc`
    - **NZB360 Integration:** Configured on Android phone.
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          sonarr:
            image: lscr.io/linuxserver/sonarr:latest
            container_name: sonarr
            ports:
              - "8989:8989"
            volumes:
              - ${DOCKER_CONFIG_PATH}/sonarr:/config
              - ${DOCKER_DOWNLOADS_PATH}:/downloads
              - ${DOCKER_USENET_PATH}/complete:/usenet
              - ${DOCKER_MEDIA_PATH}/TVShows:/tv
              - ${DOCKER_MEDIA_PATH}/Anime:/anime
            networks:
              - kry_net
        ```
        
- **Radarr:**
    - **Functionality:** Automated movie downloading and management.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `7878`
        - **Host Port:** `7878`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/radarr:/config`, `/mnt/orion/downloads:/downloads`, `/mnt/orion/usenet/complete:/usenet`, `/mnt/orion/media/Movies:/movies`, `/mnt/orion/media/Documentaries:/documentaries`
    - **Domains:** `radarr.local.kkasbi.site`, `radarr.tail.kkasbi.site`, `radarr.krynet.cc`
    - **NZB360 Integration:** Configured on Android phone.
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          radarr:
            image: lscr.io/linuxserver/radarr:latest
            container_name: radarr
            ports:
              - "7878:7878"
            volumes:
              - ${DOCKER_CONFIG_PATH}/radarr:/config
              - ${DOCKER_DOWNLOADS_PATH}:/downloads
              - ${DOCKER_USENET_PATH}/complete:/usenet
              - ${DOCKER_MEDIA_PATH}/Movies:/movies
              - ${DOCKER_MEDIA_PATH}/Documentaries:/documentaries
            networks:
              - kry_net
        ```
        
- **Bazarr:**
    - **Functionality:** Companion application for Sonarr and Radarr to manage and download subtitles.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `6767`
        - **Host Port:** `6767`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/bazarr:/config`, and mounts to all media folders (`/mnt/orion/media/Movies`, `/mnt/orion/media/TVShows`, etc.)
    - **Domains:** `bazarr.local.kkasbi.site`, `bazarr.tail.kkasbi.site`, `bazarr.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          bazarr:
            image: lscr.io/linuxserver/bazarr:latest
            container_name: bazarr
            ports:
              - "6767:6767"
            volumes:
              - ${DOCKER_CONFIG_PATH}/bazarr:/config
              - ${DOCKER_MEDIA_PATH}/Movies:/movies
              - ${DOCKER_MEDIA_PATH}/TVShows:/tv
              # ... other media paths
            networks:
              - kry_net
        ```
        
- **Whisparr:**
    - **Functionality:** Automated music downloading and management (likely for artists, albums). Runs behind Gluetun.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `6969`
        - **Network Mode:** `service:gluetun` (Host port `6969` mapped on Gluetun)
    - **Storage:** `/mnt/orion/apps-config/whisparr:/config`, `/mnt/orion/media:/media`
    - **Domains:** `whisparr.local.kkasbi.site`, `whisparr.tail.kkasbi.site`, `whisparr.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          whisparr:
            image: ghcr.io/hotio/whisparr:latest
            container_name: whisparr
            volumes:
              - ${DOCKER_CONFIG_PATH}/whisparr:/config
              - ${DOCKER_MEDIA_PATH}:/media
            network_mode: service:gluetun
            depends_on:
              gluetun:
                condition: service_healthy
        ```
        

### 3. DNS Ad-Blocking & Split Horizon DNS

- **AdGuard Home:**
    - **Functionality:** Network-wide ad, tracker, and malware blocking. Provides DNS services and supports Split Horizon DNS configuration.
    - **Primary Instance (TrueNAS):**
        - **Installation:** Portainer Stack.
        - **Networking:**
            - **DNS Ports:** `53/tcp`, `53/udp` (host mode for DNS)
            - **Admin UI Port:** `7000` (mapped to container port `80`)
            - **Initial Setup Port:** `7001` (mapped to container port `3000`)
            - **DoH/DoT/DoQ Ports:** `8443` (DoH/HTTPS), `853` (DoT), `784`/`8853` (DoQ)
        - **Storage:** `/mnt/orion/apps-config/adguardhome/work`, `/mnt/orion/apps-config/adguardhome/conf`
        - **Domains:** `adguard.kkasbi.site`, `adguard.local.kkasbi.site`, `adguard.tail.kkasbi.site`, `adguard.krynet.cc`
    - **Secondary Instance (Windows Server):**
        - **Installation:** Portainer Stack on Docker Desktop.
        - **Networking:**
            - **Admin UI Port:** `7002` (mapped to container port `80`)
            - **Domains:** `adguard2.krynet.cc`
    - **Router Configuration:** Router DNS settings point to `192.168.0.100` (primary) and `192.168.0.212` (secondary).
    - **Split Horizon DNS:** Configured within AdGuard Home using DNS Rewrite rules for `.krynet.cc` to resolve to `192.168.0.100`.
    - **Docker Compose Snippet Highlights (TrueNAS):**YAML
        
        ```yaml
        services:
          adguardhome:
            image: adguard/adguardhome:latest
            container_name: adguardhome
            ports:
              - "53:53/tcp"
              - "53:53/udp"
              - "7000:80/tcp" # Admin panel
              - "7001:3000/tcp" # Setup wizard
              - "8443:443/tcp" # DoH
              # ... other ports
            volumes:
              - ${DOCKER_CONFIG_PATH}/adguardhome/work:/opt/adguardhome/work
              - ${DOCKER_CONFIG_PATH}/adguardhome/conf:/opt/adguardhome/conf
            cap_add:
              - NET_ADMIN # Required for DHCP
            networks:
              - kry_net
        ```
        
- **AdGuard Home Sync:**
    - **Functionality:** Keeps configurations (filter lists, DNS rewrites, custom rules) synchronized between the primary and secondary AdGuard Home instances.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `8080` (for WebUI)
        - **Host Port:** `8082`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/adguardhome-sync:/config` (for `adguardhome-sync.yaml`)
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          adguardhome-sync:
            image: lscr.io/linuxserver/adguardhome-sync:latest
            container_name: adguardhome-sync
            environment:
              - CONFIGFILE=/config/adguardhome-sync.yaml
            volumes:
              - ${DOCKER_CONFIG_PATH}/adguardhome-sync:/config
            ports:
              - "8082:8080"
            networks:
              - kry_net
        ```
        

### 4. AI LLM Aggregation

- **OpenWebUI:**
    - **Functionality:** A self-hosted, open-source AI chatbot UI, providing a unified interface for interacting with various LLMs.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `8080`
        - **Host Port:** `3999`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/openwebui:/app/backend/data`
    - **Domains:** `owui.local.kkasbi.site`, `owui.tail.kkasbi.site`, `owui.kkasbi.site`, `owui.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          openwebui:
            image: ghcr.io/open-webui/open-webui:main
            container_name: openwebui
            ports:
              - "3999:8080"
            volumes:
              - ${DOCKER_CONFIG_PATH}/openwebui:/app/backend/data
            networks:
              - kry_net
        ```
        
- **LiteLLM:**
    - **Functionality:** A lightweight library/proxy to simplify calling various LLMs (Claude, ChatGPT, Gemini, etc.) via a unified API. OpenWebUI connects to LiteLLM.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `4000`
        - **Host Port:** `4000`
        - **Docker Network:** `kry_net`
    - **Configuration:** Connects to a PostgreSQL database on the TrueNAS server (`192.168.0.100:5432/litellm`).
    - **Domains:** `litellm.local.kkasbi.site`, `litellm.tail.kkasbi.site`, `litellm.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          litellm:
            image: ghcr.io/berriai/litellm:main-stable
            container_name: litellm
            ports:
              - "4000:4000"
            environment:
              - DATABASE_URL=postgresql://postgres:SonyIphone27!@192.168.0.100:5432/litellm
              - STORE_MODEL_IN_DB=True
            networks:
              - kry_net
        ```
        

### 5. Home Automation

- **Home Assistant:**
    - **Functionality:** Open-source home automation platform to integrate and manage smart devices. Integrates with SmartLife, TP-Link Tapo, Wiz, and Amazon Alexa/Plugs.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `8123`
        - **Network Mode:** `host` (for auto-discovery)
    - **Storage:** `/mnt/orion/apps-config/homeassistant:/config`, `/etc/localtime:/etc/localtime:ro`, `/run/dbus:/run/dbus:ro`
    - **Domains:** `ha.local.kkasbi.site`, `ha.tail.kkasbi.site`, `ha.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          homeassistant:
            image: ghcr.io/home-assistant/home-assistant:stable
            container_name: homeassistant
            network_mode: host # For auto-discovery
            volumes:
              - ${DOCKER_CONFIG_PATH}/homeassistant:/config
              - /etc/localtime:/etc/localtime:ro
              - /run/dbus:/run/dbus:ro
            privileged: true # May be needed for some integrations
        ```
        

### 6. Monitoring & Utilities

- **Uptime Kuma:**
    - **Functionality:** Self-hosted monitoring tool for HTTP(s) / TCP / HTTP(s) Keyword / Ping / DNS Record / Push / Steam Game Server / Docker containers. Provides real-time status updates.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `3001`
        - **Host Port:** `3001`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/uptime-kuma:/app/data`
    - **Domains:** `monitor.local.kkasbi.site`, `monitor.tail.kkasbi.site`, `monitor.kkasbi.site`, `monitor.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          uptime-kuma:
            image: louislam/uptime-kuma:1
            container_name: uptime-kuma
            volumes:
              - ${DOCKER_CONFIG_PATH}/uptime-kuma:/app/data
            ports:
              - "3001:3001"
            networks:
              - kry_net
        ```
        
- **Prometheus:**
    - **Functionality:** Open-source monitoring system with a time series database. Collects metrics from configured targets at given intervals.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `9090`
        - **Host Port:** `9090`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/prometheus/data:/prometheus`, `/mnt/orion/apps-config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml`
    - **Domains:** `prometheus.local.kkasbi.site`, `prometheus.tail.kkasbi.site`, `prometheus.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          prometheus:
            image: prom/prometheus:latest
            container_name: prometheus
            ports:
              - "9090:9090"
            volumes:
              - ${DOCKER_CONFIG_PATH}/prometheus/data:/prometheus
              - ${DOCKER_CONFIG_PATH}/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
            networks:
              - kry_net
        ```
        
- **Dozzle:**
    - **Functionality:** Real-time Docker log viewer for multiple containers. Simplifies monitoring container output.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `8080`
        - **Host Port:** `8088`
        - **Docker Network:** `kry_net`
    - **Storage:** `/var/run/docker.sock:/var/run/docker.sock:ro` (read-only access to Docker socket)
    - **Domains:** `logs.local.kkasbi.site`, `logs.tail.kkasbi.site`, `logs.kkasbi.site`, `logs.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          dozzle:
            image: amir20/dozzle:latest
            container_name: dozzle
            volumes:
              - /var/run/docker.sock:/var/run/docker.sock:ro
            ports:
              - "8088:8080"
            networks:
              - kry_net
        ```
        
- **GoAccess:**
    - **Functionality:** Real-time web log analyzer for Nginx Proxy Manager logs, providing statistics and insights into website traffic.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `7880`
        - **Host Port:** `7880`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/npm/data/logs:/opt/log` (mounts NPM logs)
    - **Domains:** `npmlogs.local.kkasbi.site`, `npmlogs.tail.kkasbi.site`, `npmlogs.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          goaccess:
            image: justsky/goaccess-for-nginxproxymanager:latest
            container_name: goaccess
            ports:
              - '7880:7880'
            volumes:
              - /mnt/orion/apps-config/npm/data/logs:/opt/log
            networks:
              - kry_net
        ```
        
- **Homarr:**
    - **Functionality:** A dashboard for your home server, providing a centralized place to access all your services.
    - **Installation:** Portainer Stack.
    - **Networking:**
        - **Container Port:** `7575`
        - **Host Port:** `7575`
        - **Docker Network:** `kry_net`
    - **Storage:** `/mnt/orion/apps-config/homarr:/appdata`, `/var/run/docker.sock:/var/run/docker.sock` (optional, for Docker integration)
    - **Domains:** `dash.local.kkasbi.site`, `dash.tail.kkasbi.site`, `dash.kkasbi.site`, `dash.krynet.cc`
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          homarr:
            container_name: homarr
            image: ghcr.io/homarr-labs/homarr:latest
            volumes:
              - /var/run/docker.sock:/var/run/docker.sock
              - /mnt/orion/apps-config/homarr:/appdata
            ports:
              - '7575:7575'
            networks:
              - kry_net
        ```
        
- **Watchtower:**
    - **Functionality:** Automatically updates running Docker containers to their latest images. Scheduled to run daily.
    - **Installation:** Portainer Stack.
    - **Networking:** No exposed ports.
    - **Storage:** `/var/run/docker.sock:/var/run/docker.sock` (access to Docker daemon for updates)
    - **Docker Compose Snippet Highlights:**YAML
        
        ```yaml
        services:
          watchtower:
            image: containrrr/watchtower:latest
            container_name: watchtower
            volumes:
              - /var/run/docker.sock:/var/run/docker.sock
            environment:
              - WATCHTOWER_SCHEDULE=0 0 4 * * * # Daily at 4 AM
        ```
        

---

## 🔒 Security Measures

- **Cloudflare Access with Google OAuth:** Secures public access to `.kkasbi.site` domains, requiring Google authentication.
- **Tailscale:** Provides a secure, encrypted VPN tunnel for remote access to services, reducing the attack surface.
- **VPN for Downloads (Gluetun/Surfshark):** Ensures privacy and anonymity for torrent and Usenet traffic.
- **Nginx Proxy Manager:** Centralizes SSL certificate management, providing HTTPS for all web services.
- **Read-only Docker Socket for Dozzle:** Limits potential harm by preventing Dozzle from modifying Docker daemon.

---

## 📈 Monitoring and Maintenance

- **Uptime Kuma:** For real-time service status monitoring.
- **Prometheus:** For collecting system and application metrics.
- **Dozzle:** For live Docker container log viewing.
- **GoAccess:** For Nginx Proxy Manager web log analytics.
- **Watchtower:** For automated Docker container updates.

---

## ⚙️ Common Environment Variables

These variables are defined in a `stack.env` file and used across various Docker Compose stacks.

Code snippet

```yaml
PUID=568
PGID=568
TZ=Asia/Kolkata
DOCKER_CONFIG_PATH=/mnt/orion/apps-config
DOCKER_DOWNLOADS_PATH=/mnt/orion/downloads
DOCKER_USENET_PATH=/mnt/orion/usenet
DOCKER_MEDIA_PATH=/mnt/orion/media

# Database Credentials
DB_PASSWORD=SonyIphone27!
DB_USERNAME=postgres
DB_DATABASE_NAME=immich

# LiteLLM
LITELLM_MASTER_KEY=[Your Master Key]
LITELLM_SALT_KEY=[Your Salt Key]
DATABASE_URL=postgresql://postgres:SonyIphone27!@192.168.0.100:5432/litellm

# Surfshark VPN
WIREGUARD_PRIVATE_KEY=[Your Private Key]
WIREGUARD_ADDRESSES=[Your VPN Address]
SERVER_COUNTRIES=[Your Preferred Countries]

# Tailscale
TS_AUTHKEY=[Your Auth Key]

# Cloudflare
CLOUDFLARE_TUNNEL_TOKEN=[Your Tunnel Token]
```
