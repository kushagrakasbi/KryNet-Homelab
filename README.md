# 🌌 KryNet Homelab: Production-Grade Private Cloud

**Architected for Resilience | Powered by ZFS | Secured by Zero Trust**

<p align="center">
  <img src="https://img.shields.io/badge/TrueNAS_SCALE-Dragonfish_24.10-0078D7?style=for-the-badge" alt="TrueNAS SCALE"/>
  <img src="https://img.shields.io/badge/Ubuntu-24.04_LTS-E95420?style=for-the-badge" alt="Ubuntu"/>
  <img src="https://img.shields.io/badge/Docker-40%2B_Containers-2496ED?style=for-the-badge" alt="Docker"/>
  <img src="https://img.shields.io/badge/Storage-13TB_ZFS-green?style=for-the-badge" alt="Storage"/>
</p>

A production-grade private cloud ecosystem serving a family of four. This repository documents the complete hardware, software, and networking architecture of a self-hosted infrastructure that rivals commercial cloud services while maintaining complete data sovereignty.

---

## 🗺️ Quick Navigation

| Document | Description |
|----------|-------------|
| [**📖 README**](#-table-of-contents) | This file - Project overview |
| [**🔥 Agni Server**](docs/AGNI-SERVER.md) | Network Core documentation |
| [**🌟 Prime Server**](docs/PRIME-SERVER.md) | Storage & Media Hub documentation |
| [**🌐 Networking**](docs/NETWORKING-QUICKREF.md) | Quick networking reference |

---

## 📋 Table of Contents

1. [Philosophy & Design Principles](#-philosophy--design-principles)
2. [Architecture Overview](#-architecture-overview)
3. [Hardware Infrastructure](#-hardware-infrastructure)
4. [Storage Architecture](#-storage-architecture)
5. [Networking Stack](#-networking-stack)
6. [Service Ecosystem](#-service-ecosystem)
7. [Security Implementation](#-security-implementation)
8. [Backup & Resilience](#-backup--resilience)
9. [Monitoring & Operations](#-monitoring--operations)
10. [Getting Started](#-getting-started)
11. [Directory Structure](#-directory-structure)
12. [Future Roadmap](#-future-roadmap)

---

## 🎯 Philosophy & Design Principles

This homelab operates under the **"Home Utility"** model — when the system is down, the house is "broken."

### Core Pillars

| Principle | Implementation |
|-----------|----------------|
| **Digital Sovereignty** | 100% data ownership, no vendor lock-in, successful migration from Google Photos |
| **WAF (Wife Approval Factor)** | Services must match "Big Tech" reliability and UX |
| **Zero Trust Architecture** | No open ports, identity-based access via OAuth 2.0 |
| **Production Standards** | Infrastructure-as-Code, automated monitoring, quarterly backup tests |
| **Graceful Degradation** | Multiple redundant paths for all services |

---

## 🏗️ Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                     │
└─────────────────────────────────┬────────────────────────────────────────┘
                                  │
           ┌──────────────────────┼──────────────────────┐
           │                      │                      │
    ┌──────▼──────┐        ┌──────▼──────┐       ┌──────▼──────┐
    │ Cloudflare  │        │  Tailscale  │       │   Direct    │
    │   Tunnel    │        │  Mesh VPN   │       │    LAN      │
    │ (Public)    │        │ (Admin)     │       │ (Home)      │
    └──────┬──────┘        └──────┬──────┘       └──────┬──────┘
           │                      │                      │
           └──────────────────────┼──────────────────────┘
                                  │
                    ╔═════════════▼═════════════╗
                    ║     🔥 AGNI SERVER        ║
                    ║     (Network Core)        ║
                    ║                           ║
                    ║  • Caddy Reverse Proxy    ║
                    ║  • Cloudflared Tunnel     ║
                    ║  • AdGuard DNS (Secondary)║
                    ║  • Tailscale VPN          ║
                    ║  • Prometheus + Grafana   ║
                    ║  • Home Assistant         ║
                    ╚═════════════╦═════════════╝
                                  ║
                    ╔═════════════▼═════════════╗
                    ║     🌟 PRIME SERVER       ║
                    ║     (Storage Hub)         ║
                    ║                           ║
                    ║  • TrueNAS SCALE          ║
                    ║  • 13TB ZFS Storage       ║
                    ║  • Jellyfin + *Arr Stack  ║
                    ║  • Immich Photos          ║
                    ║  • AdGuard DNS (Primary)  ║
                    ║  • GPU Transcoding        ║
                    ╚═══════════════════════════╝
```

---

## 🖥️ Hardware Infrastructure

### Server Fleet

| Server | Hardware | OS | Role |
|--------|----------|----|----|
| **🌟 Prime** | i5-7600K, 32GB RAM, GTX 1060 | TrueNAS SCALE | Storage Hub |
| **🔥 Agni** | 16GB RAM, 512GB NVMe | Ubuntu 24.04 | Network Core |

### Prime Server Specs

| Component | Specification |
|-----------|---------------|
| **Chassis** | Fractal Design Node 804 |
| **CPU** | Intel i5-7600K (4C/4T @ 3.8GHz) |
| **RAM** | 32GB DDR4 (ZFS ARC + ML workloads) |
| **GPU** | NVIDIA GTX 1060 6GB (NVENC + Immich) |
| **Storage** | 13TB+ across 3 ZFS pools |

### Agni Server Specs

| Component | Specification |
|-----------|---------------|
| **Device** | Repurposed Ubuntu Laptop |
| **RAM** | 16GB DDR4 |
| **Storage** | 512GB NVMe SSD |
| **Power** | ~20W (clamshell mode) |

---

## 💾 Storage Architecture

All storage managed via **TrueNAS SCALE** with ZFS data integrity.

### Storage Pools

| Pool | Hardware | Type | Capacity | Purpose |
|------|----------|------|----------|---------|
| **orion** | 2x 4TB WD Red Plus | Mirror | ~4TB | App configs, databases |
| **comet** | 2x 1TB NVMe SSD | Mirror | ~1TB | Downloads, transcode cache |
| **andromeda** | 1x 8TB Seagate IronWolf | Single | 8TB | Media, photos, documents |

### ZFS Features

- ✅ **Automatic checksums** on every read
- ✅ **Self-healing** from mirror copies
- ✅ **Snapshots** for point-in-time recovery
- ✅ **LZ4 compression** (~15% space savings)
- ✅ **Weekly scrubs** for data integrity

---

## 🌐 Networking Stack

### Multi-Path Architecture

```
Same URL → Different Paths Based on Location
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 At Home (LAN)
   photos.example.com → AdGuard DNS → Local IP → Caddy → Immich
   Speed: 1Gbps | Latency: <1ms

🌍 Remote (Internet)
   photos.example.com → Cloudflare → Tunnel → Agni → Caddy → Immich
   Speed: Upload limited | Auth: OAuth

🔐 VPN (Tailscale)
   photos.internal.home → Tailscale → Direct P2P → Caddy → Immich
   Speed: P2P optimized | Encryption: WireGuard
```

### Key Components

| Component | Purpose | Server |
|-----------|---------|--------|
| **Caddy** | Reverse proxy with auto-HTTPS | Agni |
| **Cloudflared** | Secure tunnel to Cloudflare | Agni |
| **AdGuard Home** | DNS + ad blocking | Both (synced) |
| **Tailscale** | Mesh VPN | Both |

### Why Caddy Over Traefik?

1. **Nginx Proxy Manager** → Retired (lack of automation)
2. **Traefik v3** → Replaced (label complexity)
3. **Caddy v2** → Current (simplicity + power)

**Benefits:**
- Centralized Caddyfile (Infrastructure-as-Code)
- Native Cloudflare DNS-01 challenge
- 3 lines config vs 15+ Traefik labels
- Automatic HTTPS with zero configuration

---

## 🎬 Service Ecosystem

**40+ Docker containers** deployed via Portainer Stacks.

### Media Stack

```mermaid
graph TD
    subgraph "User Interaction"
        A[User] -->|Requests Media| B(Jellyseerr)
    end

    subgraph "Automation"
        B -->|Sends Request| C{Sonarr / Radarr}
        C -->|Searches via| D(Prowlarr)
        C -->|Imports Files| G[Media Library]
        H(Bazarr) -->|Downloads Subtitles| G
    end

    subgraph "VPN Protected"
        D -->|Sends to| E{qBittorrent / SABnzbd}
        E -->|Downloads| F[Temp Folder]
        subgraph "Gluetun VPN"
            E
        end
    end

    subgraph "Playback"
        I(Jellyfin) -->|Serves Media| G
        J[Client Devices] -->|Streams from| I
    end

    F -->|Imported by Arr| G
```

| Service | Purpose | Access |
|---------|---------|--------|
| **Jellyfin** | Media streaming (4K hardware accel) | Public |
| **Jellyseerr** | User media requests | Public |
| **Sonarr/Radarr** | TV/Movie automation | Admin only |
| **Prowlarr** | Indexer management | Admin only |
| **Bazarr** | Subtitle management | Admin only |
| **qBittorrent** | Torrent client (VPN protected) | Admin only |
| **Tdarr** | GPU transcoding to HEVC (~40% savings) | Admin only |

### Photo Management

| Service | Purpose | Access |
|---------|---------|--------|
| **Immich** | Google Photos replacement | Public (OAuth) |

**Features:**
- GPU facial recognition
- Natural language search ("beach photos")
- 500GB+ migrated from Google Photos

### Monitoring & Infrastructure

| Service | Purpose |
|---------|---------|
| **Prometheus** | Metrics collection |
| **Grafana** | Visualization dashboards |
| **Gatus** | Status page |
| **Gotify** | Push notifications |
| **Healthchecks** | Backup monitoring |
| **Dozzle** | Container logs |
| **Homepage** | Dashboard |
| **Home Assistant** | Smart home automation |

---

## 🔒 Security Implementation

### Zero Trust Layers

```
Layer 1: Network
└─ No open ports on router
└─ All traffic via encrypted tunnels

Layer 2: Authentication
└─ Cloudflare Access (Google OAuth)
└─ Only whitelisted family emails

Layer 3: Container Isolation
└─ Separate Docker networks
└─ Minimal privileged containers

Layer 4: VPN Kill Switch
└─ Gluetun blocks non-VPN traffic
└─ Download clients protected
```

### Network Isolation

| Network | Purpose | Containers |
|---------|---------|------------|
| `kry_net` | Internal communication | All backend |
| `traefik_proxy` | Web-exposed only | Caddy-facing |
| `host` | System access | Tailscale, HA, AdGuard |

---

## 🔄 Backup & Resilience

### 3-2-1 Backup Rule

```
3 Copies          2 Media Types       1 Offsite
─────────         ─────────────       ─────────
• Live (ZFS)      • HDD (orion)       • Cloud
• Syncthing       • SSD (comet)         encrypted
• Cloud                                 nightly
```

### Redundancy

| Component | Failure Mode | Fallback |
|-----------|--------------|----------|
| DNS | Prime down | Agni secondary |
| Reverse Proxy | Agni down | N/A (planned) |
| VPN | Prime down | Agni subnet routing |
| Monitoring | Agni down | N/A (single point) |

---

## 📊 Monitoring & Operations

### Health Monitoring

| Service | Purpose | Alerts |
|---------|---------|--------|
| **Gatus** | HTTP health checks | Service down |
| **Healthchecks** | Dead man's switch | Backup failures |
| **Prometheus** | Metrics collection | Threshold alerts |
| **Grafana** | Visualization | Dashboard |

### Automated Maintenance

- 🔄 **Backups:** Every 12 hours to cloud
- 🧹 **ZFS Scrubs:** Weekly (Sundays 02:00 AM)
- 📊 **Speedtest:** Hourly ISP monitoring
- ❤️ **Health Pings:** Every 5 minutes

---

## 🚀 Getting Started

### Prerequisites

- Docker & Docker Compose
- Domain with Cloudflare DNS
- Tailscale account
- Cloud storage account (for backups)

### Quick Setup

1. **Clone this repository:**
   ```bash
   git clone https://github.com/yourusername/homelab.git
   cd homelab
   ```

2. **Configure environment:**
   ```bash
   cp stacks/agni/.env.example stacks/agni/.env
   cp stacks/prime/.env.example stacks/prime/.env
   # Edit with your credentials
   ```

3. **Deploy stacks:**
   ```bash
   cd stacks/agni
   docker compose -f caddy-stack.yml up -d
   docker compose -f cloudflared-stack.yml up -d
   # ... continue with other stacks
   ```

4. **Configure Cloudflare Tunnel:**
   - Create tunnel in Zero Trust dashboard
   - Add token to `CF_TOKEN` env variable
   - Configure public hostnames

5. **Setup AdGuard DNS rewrites:**
   - Add split-horizon rules
   - Point router DHCP to AdGuard IPs

---

## 📁 Directory Structure

```
homelab/
├── README.md                   # This file
├── docs/
│   ├── AGNI-SERVER.md         # Agni documentation
│   ├── PRIME-SERVER.md        # Prime documentation
│   ├── NETWORKING-QUICKREF.md # Quick networking reference
│   └── INDEX.md               # Documentation index
├── stacks/
│   ├── agni/                  # Agni Docker stacks
│   │   ├── .env.example
│   │   ├── caddy-stack.yml
│   │   ├── cloudflared-stack.yml
│   │   ├── adguard-stack.yml
│   │   ├── tailscale.yml
│   │   ├── monitoring-stack.yml
│   │   ├── homeassistant.yml
│   │   ├── dashboard-stack.yml
│   │   ├── rclone-stack.yml
│   │   └── ...
│   └── prime/                 # Prime Docker stacks
│       ├── .env.example
│       ├── media-stack.yml
│       ├── immich.yml
│       ├── dns-stack.yml
│       ├── monitoring-sensors.yml
│       └── ...
└── LICENSE
```

---

## 🚀 Future Roadmap

### Infrastructure
- [ ] Deploy dedicated mini-PC (replacing laptop)
- [ ] Vaultwarden password manager
- [ ] Nextcloud collaborative editing

### Storage
- [ ] Expand orion pool (additional mirror vdev)
- [ ] Convert andromeda to mirror
- [ ] Hot spare drive

### Services
- [ ] Mealie recipe management
- [ ] Calibre-Web ebook library
- [ ] AI stack (LiteLLM + OpenWebUI)

---

## 📈 Stats

| Metric | Value |
|--------|-------|
| **Total Storage** | ~13TB usable |
| **Docker Containers** | 40+ |
| **Uptime Target** | 99.9% |
| **Power Usage** | ~150W average |
| **Family Photos** | 500GB+ (migrated from Google Photos) |

---

## 🙏 Acknowledgments

- **TrueNAS Community** - Documentation & support
- **r/selfhosted** - Inspiration & troubleshooting
- **LinuxServer.io** - Quality Docker images
- **Caddy Team** - Simple, powerful reverse proxy

---

<p align="center">
  <b>Last Updated:</b> February 2026 | 
  <b>TrueNAS:</b> Dragonfish 24.10 | 
  <b>Total Services:</b> 40+
</p>

<p align="center">
  <i>Built with ❤️ for digital sovereignty and family convenience</i>
</p>
