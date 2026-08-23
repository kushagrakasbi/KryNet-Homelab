# 🌌 KryNet Homelab: 3-Node Distributed Private Cloud & AI Supercluster

**Architected for Resilience | Powered by ZFS | Accelerated by CUDA | Managed by Agentic AI**

<p align="center">
  <img src="https://img.shields.io/badge/Architecture-3--Node_Distributed_Cluster-blue?style=for-the-badge&logo=server" alt="Cluster Architecture"/>
  <img src="https://img.shields.io/badge/TrueNAS_SCALE-Dragonfish_24.10-0078D7?style=for-the-badge&logo=truenas" alt="TrueNAS SCALE"/>
  <img src="https://img.shields.io/badge/AI_Compute-NVIDIA_RTX_3060_CUDA-76B900?style=for-the-badge&logo=nvidia" alt="NVIDIA GPU"/>
  <img src="https://img.shields.io/badge/Docker-45%2B_Containers-2496ED?style=for-the-badge&logo=docker" alt="Docker"/>
  <img src="https://img.shields.io/badge/Storage-12TB_Raw_ZFS_(Mirrored)-green?style=for-the-badge&logo=zfs" alt="Storage"/>
  <img src="https://img.shields.io/badge/Control_Plane-Agentic_AI_(OpenCode_/_Antigravity)-8A2BE2?style=for-the-badge&logo=robot" alt="Agentic AI"/>
</p>

A production-grade, distributed private cloud and local AI compute ecosystem serving a multi-user household. This repository documents the complete hardware, software, zero-trust networking, container architecture, and autonomous AI agent operations of a self-hosted infrastructure engineered to match commercial cloud reliability while ensuring 100% data sovereignty.

---

## 🗺️ Quick Navigation

| Document | Scope & Purpose |
| :--- | :--- |
| [**🔥 Agni Server Manual**](docs/AGNI-SERVER.md) | Ingress, Caddy Reverse Proxy, AdGuard DNS, Prometheus Master, Grafana, Vaultwarden |
| [**🌟 Prime Server Manual**](docs/PRIME-SERVER.md) | TrueNAS SCALE Storage, 12TB ZFS Pools, Immich Core, Media Pipeline (*Arr), Jellystat |
| [**⚡ Legion Server Manual**](docs/LEGION-SERVER.md) | AI & GPU Supernode, RTX 3060 CUDA, Ollama, LiteLLM Gateway, OpenWebUI, Tdarr Node |
| [**🤖 AI Stack Architecture**](docs/AI-STACK.md) | Local LLM inference, remote Immich ML acceleration, and LiteLLM agent proxy |
| [**🔒 Zero-Trust Networking**](docs/networking.md) | Tailscale mesh, Split-Horizon DNS, Cloudflare DNS-01 SSL, 0 open public ports |
| [**📦 Full Service Matrix**](docs/services.md) | Comprehensive 45+ container catalog, port mappings, and health checks |
| [**🚑 Operations Playbook**](docs/OPERATIONS-PLAYBOOK.md) | 3-2-1 backup verification, ZFS snapshots, and end-to-end database disaster recovery |
| [**🤖 Agent Operating Guide**](AGENTS.md) | AI agent directives, skills portfolio, Portainer API tooling, and branching lifecycle |
| [**🏗️ Redesign Blueprint**](docs/HOME-SERVER-REDESIGN.md) | Historical 3-node architectural overhaul and migration strategy |
| [**📈 Execution Progress**](docs/REDESIGN-PROGRESS.md) | Completed migration milestones, task checklists, and verification log |

---

## 🗺️ Fleet Topology & Node Specialization

KryNet decouples compute, storage, and networking across three dedicated physical nodes connected over high-speed Gigabit LAN and an encrypted Tailscale WireGuard mesh:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    KRYNET 3-NODE CLUSTER TOPOLOGY                               │
├───────────────────────────────┬─────────────────────────────────┬───────────────────────────────┤
│ 🔥 AGNI (192.168.0.200)        │ 🌟 PRIME (192.168.0.100)        │ ⚡ LEGION (192.168.0.150)     │
│ Ingress & Core Orchestration  │ ZFS Storage & Application Vault │ AI & GPU Compute Supernode    │
├───────────────────────────────┼─────────────────────────────────┼───────────────────────────────┤
│ • Ubuntu Server 24.04 LTS     │ • TrueNAS SCALE (Dragonfish)    │ • Ubuntu Server 26.04 LTS     │
│ • Caddy Reverse Proxy (HTTPS) │ • ZFS Pools: orion & andromeda  │ • NVIDIA RTX 3060 6GB (CUDA)  │
│ • AdGuard Home (Primary DNS)  │ • Immich Core (v3.1 VectorChord)│ • Ollama Engine (Qwen/DeepSeek│
│ • Vaultwarden Password Vault  │ • Jellyfin Media Server         │ • LiteLLM Gateway (:4000)     │
│ • Home Assistant Automation   │ • *Arr Suite (Sonarr, Radarr)   │ • OpenWebUI Interface (:3999) │
│ • Prometheus Master DB        │ • Gluetun WireGuard VPN Gateway │ • Immich ML Remote Offload    │
│ • Grafana Fleet Dashboards    │ • Jellystat Analytics (:3005)   │ • Tdarr GPU Transcode Worker  │
│ • Gatus & Discord Alerting    │ • Paperless-ngx & Audiobookshelf│ • NVIDIA GPU Metrics Exporter │
│ • Portainer Server (Master)   │ • Portainer Instance (TrueNAS)  │ • Portainer Agent Endpoint    │
└───────────────────────────────┴─────────────────────────────────┴───────────────────────────────┘
```

---

## 🖥️ Hardware Infrastructure Matrix

| Node | Form Factor | CPU | RAM | Primary Storage | Secondary Storage | GPU / Accelerator |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **🔥 Agni** | Mini PC | Intel 12th Gen N100 (4C/4T) | 16GB DDR4 3200MHz | 512GB NVMe M.2 SSD | External NVMe Scratch | Intel UHD Graphics (QuickSync) |
| **🌟 Prime** | Custom Tower | Intel Core i5 (4C/4T @ 3.8GHz) | 32GB DDR4 Non-ECC | 512GB NVMe (Boot/Apps) | 2x 6TB WD Red Plus (ZFS Mirror) | Intel HD Graphics 630 |
| **⚡ Legion** | Laptop Server | Intel Core i7-12700H (14C/20T) | 16GB DDR5 4800MHz | 1TB Samsung 980 Pro NVMe | NFS Share from Prime (`/data`) | NVIDIA GeForce RTX 3060 6GB GDDR6 |

---

## 🤖 The Control Plane: Agentic AI Pair-Programming

The entire 3-node cluster is managed, provisioned, debugged, and monitored via **Autonomous Agentic AI** running from a central development machine (MacBook Pro) communicating across nodes via passwordless ED25519 SSH and REST APIs.

```
                  ┌──────────────────────────────────────────────────┐
                  │          👨‍💻 Central Developer Mac Control Plane   │
                  │   (Antigravity CLI / OpenCode / Claude Code)     │
                  └─────────┬───────────────────┬────────────────────┘
                            │                   │
               Passwordless │ SSH               │ Portainer REST API
               ED25519 Keys │                   │ (Token Authenticated)
                            ▼                   ▼
    ┌────────────────────────────────────────────────────────────────────────┐
    │                       KRYNET 3-NODE CLUSTER                            │
    │  🔥 Agni (192.168.0.200) ── 🌟 Prime (192.168.0.100) ── ⚡ Legion (.150)│
    └────────────────────────────────────────────────────────────────────────┘
```

### 🧠 Key AI Management Highlights:
1. **Zero Manual Compose Copy-Pasting:** AI agents interact directly with the cluster via [`scripts/portainer-helper.sh`](scripts/portainer-helper.sh) to query live environments, validate YAML syntax, and deploy/redeploy Portainer Stacks programmatically.
2. **Autonomous Tooling & Skills (`.agents/skills/`):**
   - 🏥 [**`fleet-health`**](.agents/skills/fleet-health/SKILL.md): 12-point automated diagnostic health checks (containers, ZFS pools, GPU thermals, Tailscale, DNS, Gatus, backups).
   - 🐳 [**`portainer-ops`**](.agents/skills/portainer-ops/SKILL.md): Multi-node stack deployment, rollback, and lifecycle management.
   - 💾 [**`backup-dr`**](.agents/skills/backup-dr/SKILL.md): Automated 3-2-1 backup verification and database disaster recovery execution.
   - 🔄 [**`caddy-proxy`**](.agents/skills/caddy-proxy/SKILL.md): Zero-downtime reverse proxy validation and hot reloading.
3. **Local Self-Hosted Agent Backends:** The local coding models driving terminal operations run directly on Legion's RTX 3060 (`qwen2.5-coder:7b` and `deepseek-r1:7b`) via the LiteLLM Gateway (`http://192.168.0.150:4000/v1`).
4. **Branch-Per-Task & Conventional Commits:** All modifications across stacks, scripts, and documentation follow strict Git branch isolation and Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`).

---

## 🔒 Zero-Trust Networking & Split-Horizon DNS

KryNet enforces a strict **Zero Open WAN Ports** security posture. No ports are forwarded on the router firewall.

```
                      ┌─────────────────────────────────────────┐
                      │    Zero Open Public WAN Ports (Router)  │
                      └────────────────────┬────────────────────┘
                                           │
                        ┌──────────────────┴──────────────────┐
                        │                                     │
           ┌────────────▼────────────┐           ┌────────────▼────────────┐
           │   Tailscale WireGuard   │           │    Local LAN Ingress    │
           │   Encrypted Mesh VPN    │           │  (Home WiFi / Ethernet) │
           └────────────┬────────────┘           └────────────┬────────────┘
                        │                                     │
                        └──────────────────┬──────────────────┘
                                           ▼
                      ┌─────────────────────────────────────────┐
                      │    Split-Horizon DNS (AdGuard Home)     │
                      │       *.krynet.cc ➔ 192.168.0.200       │
                      └────────────────────┬────────────────────┘
                                           ▼
                      ┌─────────────────────────────────────────┐
                      │  Agni Caddy Ingress (Wildcard SSL TLS)  │
                      └─────────────────────────────────────────┘
```

* **Tailscale MagicDNS Nameserver Integration:** Devices outside the home connect via Tailscale. MagicDNS directs `*.krynet.cc` queries directly to Agni (`100.89.216.106`), providing seamless remote access from mobile devices even through restrictive mobile carrier CGNAT.
* **Automated Cloudflare DNS-01 SSL:** Caddy on Agni acquires and renews wildcard Let's Encrypt SSL certificates (`*.krynet.cc`) via outbound Cloudflare DNS API challenges without requiring public HTTP ingress.

---

## 📦 Complete Categorized Service Catalog

| Category | Service | Node | Port | Ingress URL | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Ingress & DNS** | **Caddy** | Agni | 80/443 | `*.krynet.cc` | Ingress Reverse Proxy & Wildcard TLS |
| | **AdGuard Home (Primary)** | Agni | 53/7000 | `adguard2.krynet.cc` | DNS Filtering & Split-Horizon Rewrites |
| | **AdGuard Home (Replica)** | Prime | 53/7000 | `adguard.krynet.cc` | Secondary Redundant DNS Server |
| | **AdGuard Home Sync** | Agni | 8082 | `adsync.krynet.cc` | Automatic Bi-directional DNS Sync |
| **AI & Compute** | **Ollama (CUDA)** | Legion | 11434 | N/A (Internal) | Local LLM Engine (Qwen / DeepSeek) |
| | **LiteLLM Gateway** | Legion | 4000 | `litellm.krynet.cc` | Universal OpenAI-Compatible API Proxy |
| | **OpenWebUI** | Legion | 3999 | `ow.krynet.cc` | Feature-Rich AI Chat & Agent Canvas |
| | **Immich ML Node** | Legion | 3003 | N/A (Worker) | Remote CUDA Image Embedding & Facial Recognition |
| | **Tdarr Transcode Node** | Legion | N/A | N/A (Worker) | Hardware NVENC Video Transcoding Worker |
| **Media & Photos** | **Immich Server (v3.1)** | Prime | 2283 | `photos.krynet.cc` | High-Performance Self-Hosted Photo Management |
| | **PostgreSQL VectorChord** | Prime | 5432 | N/A (Internal) | 260K+ CLIP & Face Vector Index DB |
| | **Jellyfin** | Prime | 8096 | `media.krynet.cc` | 4K HDR Media Streaming Server |
| | **Jellystat** | Prime | 3005 | `jellystat.krynet.cc` | Jellyfin Viewing History & Analytics |
| | **Audiobookshelf** | Prime | 13378 | `abs.krynet.cc` | Audiobooks & Podcasts Streaming |
| **Automation** | **Sonarr** | Prime | 8989 | `sonarr.krynet.cc` | TV Series Management & Auto-Downloads |
| | **Radarr** | Prime | 7878 | `radarr.krynet.cc` | Movie Library Management & Auto-Downloads |
| | **Prowlarr** | Prime | 9696 | `indexer.krynet.cc` | Indexer Aggregator & Arr Sync |
| | **Bazarr** | Prime | 6767 | `bazarr.krynet.cc` | Automated Subtitle Downloader |
| | **Jellyseerr** | Prime | 5055 | `request.krynet.cc` | Media Discovery & Request Management |
| | **Gluetun VPN** | Prime | 8080/5055 | N/A (Gateway) | Surfshark WireGuard Kill-Switch Gateway |
| | **qBittorrent** | Prime | 8080 | `qbit.krynet.cc` | Torrent Client (Isolated through VPN) |
| | **SABnzbd** | Prime | 8085 | `nzb.krynet.cc` | Usenet Downloader |
| **Productivity** | **Vaultwarden** | Agni | 8222 | `vault.krynet.cc` | Bitwarden-Compatible Password Vault |
| | **Home Assistant** | Agni | 8123 | `ha.krynet.cc` | Smart Home IoT Automation Hub |
| | **Paperless-ngx** | Prime | 8089 | `paperless.krynet.cc` | Automated Document Archiving & OCR |
| | **FreshRSS** | Prime | 8086 | `rss.krynet.cc` | Self-Hosted RSS Feed Aggregator |
| | **Copyparty** | Agni | 3923 | `file.krynet.cc` | Resilient Web-Based File Server |
| **Observability** | **Prometheus Master** | Agni | 9090 | `prom.krynet.cc` | Central Time-Series Metrics Database |
| | **Grafana** | Agni | 3000 | `grafana.krynet.cc` | Production Fleet & GPU Dashboards |
| | **Gatus** | Agni | 3001 | `status.krynet.cc` | 38+ Service Probes & Discord Webhook Alerts |
| | **Healthchecks** | Agni | 8000 | `hc.krynet.cc` | 12-Hour Backup Cron Dead-Man's Switch |
| | **Gotify** | Agni | 8089 | `notify.krynet.cc` | Push Notifications for Android / iOS |
| | **NVIDIA GPU Exporter** | Legion | 9835 | N/A (Prometheus) | Real-time RTX 3060 Thermals & VRAM Metrics |
| | **Homepage** | Agni | 3075 | `home.krynet.cc` | Master Unified Dashboard |
| | **Homarr** | Prime | 7575 | `dash.krynet.cc` | Secondary Lightweight LAN Dashboard |

---

## 💾 3-2-1 Backup & Disaster Recovery Architecture

```
┌───────────────────┬───────────────────────────────┬────────────────────────────────────────┐
│ Node / Target     │ Layer 1: Local ZFS Snapshots  │ Layer 2: Encrypted pCloud Cloud Backup │
├───────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ **🔥 Agni**       │ Host Ext4 Local Data          │ 🟢 `pcloud:Backups/Krynet-Agni` (12h)   │
│ (`.200`)          │                               │ (Caddy, Vaultwarden, HA, Healthchecks) │
├───────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ **🌟 Prime**      │ 🟢 `orion/apps-config`        │ 🟢 `pcloud:Backups/Krynet-Prime` (12h)  │
│ (`.100`)          │ • Hourly (keep 3d)            │ • `/Configs` (Apps configs)            │
│                   │ • Daily (keep 14d)            │ • `/Apps` (Immich DB dumps, Paperless) │
│                   │ 🟢 `andromeda/apps`           │                                        │
│                   │ • Daily 02:00 (keep 14d)      │                                        │
│                   │ 🟢 `andromeda/media`          │                                        │
│                   │ • Weekly Sun 03:00 (keep 30d) │                                        │
├───────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ **⚡ Legion**      │ Host Ext4 NVMe Local Data     │ 🟢 `pcloud:Backups/Krynet-Legion` (12h) │
│ (`.150`)          │                               │ (OpenWebUI history, LiteLLM, Tdarr)    │
└───────────────────┴───────────────────────────────┴────────────────────────────────────────┘
```

---

## 🚀 Quickstart: Reproducing & Deploying This Cluster

### 1. Prerequisites
* **Operating Systems:** Ubuntu Server 24.04/26.04 LTS (Agni/Legion), TrueNAS SCALE Dragonfish (Prime).
* **Software:** Docker 26+, Docker Compose v2, NVIDIA Container Toolkit (for CUDA compute), Tailscale.
* **Network:** Static local LAN IPs (`192.168.0.x`) and Tailscale mesh network configured.

### 2. Setup Environment Files
```bash
# Clone the repository
git clone https://github.com/kushagrakasbi/KryNet-Homelab.git && cd KryNet-Homelab

# Configure environment variables from templates
cp stacks/agni/.env.example stacks/agni/.env
cp stacks/prime/.env.example stacks/prime/.env
cp stacks/legion/.env.example stacks/legion/.env
```

### 3. Deploy Stacks via Portainer API Tooling
```bash
# Save your Portainer API tokens
mkdir -p ~/.portainer
echo "your_agni_token" > ~/.portainer/agni_token
echo "your_prime_token" > ~/.portainer/prime_token

# Deploy Ingress on Agni
./scripts/portainer-helper.sh deploy agni caddy-stack stacks/agni/caddy-stack.yml

# Deploy Storage & Media on Prime
./scripts/portainer-helper.sh deploy prime immich stacks/prime/immich.yml
./scripts/portainer-helper.sh deploy prime media-stack stacks/prime/media-stack.yml

# Deploy AI Compute on Legion
./scripts/portainer-helper.sh deploy legion ai-stack stacks/legion/ai-stack.yml
```

---

## 📁 Repository Directory Structure

```
.
├── .agents/                    # Agentic AI capabilities & skills
│   └── skills/
│       ├── fleet-health/       # 12-point cluster diagnostic health checks
│       ├── portainer-ops/      # Programmatic stack deployment engine
│       ├── backup-dr/          # 3-2-1 backup verification & DR runbooks
│       └── caddy-proxy/        # Zero-downtime reverse proxy reload skill
├── config/                     # Configuration sources of truth
│   ├── caddy/                  # Caddyfile reverse proxy rules & wildcard routing
│   ├── gatus/                  # 38+ service health probe definitions & Discord webhook
│   ├── prometheus/             # Multi-node Prometheus scrape configuration
│   ├── grafana/                # Auto-provisioned datasources & dashboard JSONs
│   ├── homepage/               # Unified dashboard configuration (services.yaml)
│   └── litellm/                # AI model routing gateway rules
├── docs/                       # Comprehensive documentation suite
│   ├── AGNI-SERVER.md          # Agni node operations manual
│   ├── PRIME-SERVER.md         # Prime node & ZFS storage manual
│   ├── LEGION-SERVER.md        # Legion AI GPU node manual
│   ├── AI-STACK.md             # Local LLM & Immich ML architecture
│   ├── networking.md           # Zero-trust networking & DNS deep dive
│   ├── services.md             # Complete service catalog and port reference
│   ├── OPERATIONS-PLAYBOOK.md  # Disaster recovery runbooks & maintenance procedures
│   └── plans/                  # Architectural roadmap & enhancement documents
├── scripts/                    # Autonomous Agent API Tooling
│   ├── portainer-helper.sh     # Programmatic Portainer API CLI
│   ├── tailscale-helper.sh     # Tailnet status & auth key generator
│   └── cloudflare-helper.sh    # DNS records and tunnel querying
├── stacks/                     # Declarative Docker Compose Stacks
│   ├── agni/                   # Ingress, DNS, Vaultwarden, Monitoring stacks
│   ├── prime/                  # Storage, Immich, Media (*Arr), Jellystat stacks
│   └── legion/                 # CUDA AI, Immich ML, Tdarr, Sensors stacks
├── AGENTS.md                   # AI Agent operating directives & cluster safety rules
└── opencode.json               # OpenCode CLI autonomous agent configuration
```

---

## 📄 License & Attribution

This project is licensed under the **MIT License**. Created and maintained by [Kushagra Kasbi](https://github.com/kushagrakasbi).
