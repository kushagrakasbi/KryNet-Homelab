# 🌌 Project KryNet  
### A Production-Grade Private Cloud & Home Infrastructure (2025–2026)

Project **KryNet** is a multi-node, production-grade private cloud built at home.  
What started as a small experiment on repurposed hardware has evolved into a **high-availability digital utility** serving a family of four.

This repository acts as the **architectural memory** of the system — documenting *why* decisions were made, not just *what* is running.

---

## 1. Philosophy & Design Principles

KryNet follows a simple rule:

> **If the system is down, the house is “broken.”**

### Core Pillars

#### 🔐 Digital Sovereignty
- 100% ownership of family photos, documents, and media  
- No dependency on proprietary storage platforms  
- Cloud is used selectively, not blindly  

#### ⚖️ The Wife Approval Factor (WAF)
- UX and reliability come first  
- If photos don’t back up or media doesn’t play instantly, the system is considered down  
- “I’ll fix it in 5 minutes” is not acceptable downtime  

#### 🛡️ Zero Trust by Default
- No open inbound ports  
- Identity-based access over network-based trust  
- Every access path is authenticated and scoped  

#### 🧱 Boring Reliability
- Predictability over cleverness  
- Recoverability over optimization  
- Observability before features  

---

## 2. Hardware Architecture

### 🚀 KryNet-Prime (Primary Node — The Heavy Lifter)

**Role:**  
Primary storage, media processing, databases, and AI workloads.

- **OS:** TrueNAS SCALE (Dragonfish)
- **Chassis:** Fractal Design Node 804  
- **CPU:** Intel i5-7600K (4C @ 3.8GHz)  
- **RAM:** 32GB DDR4  
- **GPU:** NVIDIA GTX 1060 (6GB)  
  - NVENC for Tdarr transcoding  
  - CUDA for Immich ML workloads  

#### Storage (ZFS – Non-Negotiable)

| Pool | Type | Purpose |
|-----|-----|--------|
| `orion` | HDD Mirror | Photos, documents, app configs |
| `comet` | NVMe Mirror | Databases, high-IO workloads |
| `andromeda` | HDD | Media archive & documents |

ZFS snapshots, scrubbing, and parity protection form the backbone of data integrity.

---

### 🛰️ KryNet-Agni (Secondary Node — Network Sentinel)

**Role:**  
High-availability DNS, config backup, and failover.

- **Hardware:** SkullSaints Agni Mini-PC  
- **OS:** Ubuntu Server 24.04 LTS  
- **CPU:** Intel N150 (Twin Lake)  
- **RAM:** 16GB DDR4  
- **Storage:** 512GB NVMe  

**Unique Feature:**  
Integrated LCD screen showing DNS health and system status without needing a dashboard.

---

### 🪦 Retired Node — KryNet-Legion
- Ubuntu laptop previously used as a secondary server  
- Retired due to power inefficiency and limited expandability  

---

## 3. Networking & Access Architecture

KryNet uses a **triple-layered access model** with **Split-Horizon DNS** to ensure the *same hostname works everywhere*.

---

## 4. DNS & Name Resolution

### Primary DNS Stack
- **Primary:** AdGuard Home on KryNet-Prime  
- **Secondary:** AdGuard Home on KryNet-Agni  
- Configuration is automatically synced  

### Split-Horizon DNS

| Access Location | Resolution Target |
|---------------|------------------|
| Home LAN | Local IP (1Gbps LAN) |
| Remote (Trusted) | Tailscale IP |
| Public | Cloudflare Tunnel |

---

## 5. Domain Strategy (Sanitized)

### Public Domains
- `*.mydomain.com`  
- Routed via **Cloudflare Tunnel**  
- Protected using **Cloudflare Access (Google OAuth 2.0)**  

### Local-Only Domains
- `*.local.mydomain.com`  
- Resolved by AdGuard Home  
- Never leaves the LAN  

### VPN-Only Domains
- `*.tail.mydomain.com`  
- Accessible only over Tailscale mesh  
- Used for admin and sensitive services  

---

## 6. External Access & Zero Trust

### ☁️ Cloudflare Tunnel
- No inbound ports exposed on the router  
- `cloudflared` runs as a service  
- Used for family-facing services (Photos, Media, Docs)  

### 🕸️ Tailscale (Mesh VPN)
- Always-on secure access for administration  
- KryNet-Prime advertises LAN routes  
- Used for:
  - Remote maintenance  
  - Non-public services  
  - Emergency access  

---

## 7. Reverse Proxy Layer

### Proxy Evolution
1. **Nginx Proxy Manager** – GUI-driven, limited automation  
2. **Traefik** – Powerful but resulted in label sprawl  
3. **Caddy** – Current standard  

### Why Caddy?
- Minimal configuration  
- Native Cloudflare DNS-01 support  
- Clean Infrastructure-as-Code model  
- Lower cognitive overhead  

---

## 8. Service Stack Overview

### 🎬 Media Automation (*Arr Stack)
- Jellyseerr → Prowlarr → Sonarr / Radarr  
- qBittorrent & SABnzbd routed through **Gluetun VPN**  
- Tdarr transcodes media to **H.265 (HEVC)** using GPU  
- Jellyfin serves media with hardware acceleration  

### 📸 Personal Data
- **Immich:** Google Photos replacement with GPU-backed ML  
- **Paperless-ngx:** OCR-powered document archive  
- **Syncthing:** Real-time config and data replication  

### 🧠 Private AI
- **LiteLLM:** Centralized LLM gateway with PostgreSQL backend  
- **OpenWebUI:** Family-friendly AI interface  
- **Prometheus + Grafana:** Metrics and observability  

### 🛠️ Operations & SRE
- Uptime Kuma for health checks  
- Gotify for instant alerts  
- Dozzle for real-time logs  
- Watchtower for controlled image updates  

---

## 9. Backup & Resiliency (3-2-1 Rule)

### Backup Strategy
- **Local:** ZFS snapshots (hourly / 6-hourly)  
- **Secondary Node:** Syncthing mirrors configs to Agni  
- **Cloud:** Encrypted backups of critical photos to S3-compatible storage  

### Failure Philosophy
- Assume disks will fail  
- Assume updates will break things  
- Design recovery paths *before* incidents happen  

---

## 10. Final Thoughts

KryNet is not a “homelab” in the traditional sense.

It is:
- A practical application of **Zero Trust**
- A family-scale implementation of **SRE principles**
- A living system designed to evolve without fragility  

Most importantly, it works quietly — which is the highest compliment infrastructure can receive.
