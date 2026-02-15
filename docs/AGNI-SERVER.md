# 🔥 Agni Server Documentation

**KryNet Network Core | Ubuntu Server | 192.168.1.200**

Agni serves as the **network backbone** of the KryNet Homelab, handling all traffic routing, DNS resolution (primary), VPN connectivity, monitoring, and home automation. It is a SkullSaints Agni Mini PC running Ubuntu Server 24.04 LTS.

---

## 📋 Table of Contents

1. [Server Overview](#server-overview)
2. [Hardware Specifications](#hardware-specifications)
3. [Service Architecture](#service-architecture)
4. [Network Stack](#network-stack)
5. [Monitoring Stack](#monitoring-stack)
6. [Home Automation](#home-automation)
7. [Backup Configuration](#backup-configuration)
8. [Configuration Files](#configuration-files)
9. [Maintenance & Operations](#maintenance--operations)

---

## 🎯 Server Overview

### Role in KryNet Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
    ┌────────────▼────────────┐
    │    Cloudflare Edge      │
    │   (Zero Trust Access)   │
    └────────────┬────────────┘
                 │ Encrypted Tunnel
    ╔════════════▼════════════╗
    ║     🔥 AGNI SERVER      ║
    ║  (Network Core - Mini PC)║
    ║                         ║
    ║  • Caddy Reverse Proxy  ║
    ║  • Cloudflared Tunnel   ║
    ║  • AdGuard DNS (Primary)║
    ║  • AdGuard Home Sync    ║
    ║  • Tailscale VPN        ║
    ║  • Monitoring Hub       ║
    ╚═══════════╦═════════════╝
                ║
    ┌───────────▼───────────┐
    │   Home LAN (0.0/24)   │
    │     192.168.0.x       │
    └───────────┬───────────┘
                │
    ┌───────────▼───────────┐
    │     PRIME SERVER      │
    │   (192.168.1.100)     │
    │  TrueNAS + Services   │
    └───────────────────────┘
```

### Why Agni Exists

**Problem Solved:** Single point of failure if Prime goes down for maintenance.

| Scenario | Without Agni | With Agni |
|----------|--------------|-----------| 
| Prime reboot | All services offline | DNS + VPN + Monitoring continues |
| DNS resolution | Fails completely | Primary DNS on Agni remains active |
| External access | Tunnel offline | Tunnel remains active |
| Alerting | No notifications | Gotify sends alerts |

---

## 🖥️ Hardware Specifications

| Component | Specification |
|-----------|---------------|
| **Device** | SkullSaints Agni Mini PC |
| **OS** | Ubuntu Server 24.04 LTS |
| **RAM** | 16GB DDR5 |
| **Storage** | 512GB NVMe SSD |
| **Network** | 1Gbps Ethernet |
| **IP Address** | 192.168.1.200 (Static) |
| **Power Draw** | ~20W |
| **Location** | Near router for network reliability |

---

## 🏗️ Service Architecture

### Docker Configuration

**Base Path:** `/home/agni/apps/docker/`  
**Network:** `agni_net` (external Docker network)  
**Environment:** `stack.env` with variables

### Stack Files

| Stack File | Services | Purpose |
|------------|----------|---------|
| `caddy-stack.yml` | Caddy | Reverse proxy with Cloudflare DNS |
| `cloudflared-stack.yml` | cloudflared | Cloudflare tunnel connector |
| `adguard-stack.yml` | AdGuard Home, AdGuard Home Sync | Primary DNS + ad blocking + config sync to Prime |
| `tailscale.yml` | Tailscale | Mesh VPN with subnet routing |
| `monitoring-stack.yml` | Prometheus, Grafana, Gotify, Gatus, Healthchecks, Node-exporter, cAdvisor, Dozzle | Full monitoring suite |
| `homeassistant.yml` | Home Assistant | Smart home automation |
| `dashboard-stack.yml` | Homepage | Dashboard interface |
| `rclone-stack.yml` | Rclone | Cloud backup to pCloud |
| `copyparty-stack.yml` | CopyParty | File server |
| `openspeedtest.yml` | OpenSpeedTest | Network speed testing |

---

## 🌐 Network Stack

### Caddy Reverse Proxy

**Image:** `caddy-cloudflare:local` (custom build with Cloudflare DNS module)  
**Network Mode:** Host  
**Port:** 80, 443 (HTTP/HTTPS)

**Caddyfile Location:** `/home/agni/apps/docker/caddy/Caddyfile`

**Domains Served:**
- `*.example.com` - Public access via Cloudflare Tunnel
- `*.internal.home` - Internal LAN access

**Local Services Proxied:**

| Subdomain | Service | Port |
|-----------|---------|------|
| `home.example.com` | Homepage Dashboard | 3075 |
| `status.example.com` | Gatus Status Page | 3001 |
| `grafana.example.com` | Grafana Dashboards | 3000 |
| `notify.example.com` | Gotify Notifications | 8089 |
| `hc.example.com` | Healthchecks | 8000 |
| `prom.example.com` | Prometheus | 9090 |
| `ha.example.com` | Home Assistant | 8123 |
| `adguard2.example.com` | AdGuard Home (Agni - Primary) | 7000 |
| `adsync.example.com` | AdGuard Home Sync | 8082 |
| `portainer2.example.com` | Portainer (Agni) | 9443 |
| `logs2.example.com` | Dozzle Logs | 8088 |
| `ospt2.example.com` | OpenSpeedTest | 8092 |
| `file.example.com` | CopyParty | 3923 |

**Remote Services (Prime) Proxied:**

| Subdomain | Service | Target |
|-----------|---------|--------|
| `server.example.com` | TrueNAS UI | 192.168.1.100:88 |
| `photos.example.com` | Immich | 192.168.1.100:2283 |
| `media.example.com` | Jellyfin | 192.168.1.100:8096 |
| `request.example.com` | Jellyseerr | 192.168.1.100:5055 |
| And 15+ more... | | |

---

### Cloudflared Tunnel

**Purpose:** Secure tunnel from Cloudflare edge to home network without port forwarding.

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    command: tunnel --no-autoupdate run --token ${CF_TOKEN}
    network_mode: host
    restart: unless-stopped
```

**Configuration:**
- Token stored in `stack.env` as `CF_TOKEN`
- No authentication headers needed (tunnel handles it)
- Host network mode for optimal performance

---

### AdGuard Home (Primary DNS)

> **This is the primary DNS server for the entire network.** AdGuard Home Sync also runs on Agni and synchronizes configuration to the secondary instance on Prime (192.168.1.100).

**Primary:** Agni (192.168.1.200) ← This instance  
**Secondary:** Prime (192.168.1.100)

**Ports:**
| Port | Protocol | Purpose |
|------|----------|---------|
| 53 | TCP/UDP | DNS |
| 7000 | TCP | Web UI |
| 7001 | TCP | Initial Setup |
| 8444 | TCP/UDP | DNS-over-HTTPS |
| 854 | TCP | DNS-over-TLS |
| 785, 8854 | UDP | DNS-over-QUIC |

**DNS Rewrites (Split-Horizon):**
All `*.example.com` and `*.internal.home` domains rewrite to local IPs when on LAN.

**AdGuard Home Sync:**
```yaml
# Syncs configuration FROM Agni (primary) TO Prime (secondary)
services:
  adguardhome-sync:
    image: lscr.io/linuxserver/adguardhome-sync:latest
    ports:
      - "8082:8080"
    volumes:
      - /home/agni/apps/docker/adguard-sync:/config
```

The sync service ensures that DNS rewrites, filtering rules, and upstream DNS settings are consistent between both AdGuard instances. If Agni goes down, Prime's secondary DNS continues serving cached configuration.

---

### Tailscale VPN

**Hostname:** `network-server`  
**Network Mode:** Host
**Capabilities:** NET_ADMIN, NET_RAW

```yaml
services:
  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale-agni
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - /home/agni/apps/docker/tailscale:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_HOSTNAME=network-server
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_EXTRA_ARGS=--advertise-exit-node --advertise-routes=192.168.1.0/24
```

**Features Enabled:**
- Exit node (route all traffic through home)
- Subnet routing (192.168.1.0/24)
- Backup VPN access if Prime is down

---

## 📊 Monitoring Stack

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AGNI MONITORING HUB                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│   │   Gatus     │    │  Grafana    │    │   Gotify    │    │
│   │ Status Page │    │ Dashboards  │    │Notifications│    │
│   │   :3001     │    │   :3000     │    │   :8089     │    │
│   └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    │
│          │                  │                   │           │
│          └──────────────────┼───────────────────┘           │
│                             │                               │
│                    ┌────────▼────────┐                      │
│                    │   Prometheus    │                      │
│                    │  Metrics Store  │                      │
│                    │     :9090       │                      │
│                    └────────┬────────┘                      │
│                             │                               │
│          ┌──────────────────┼──────────────────┐            │
│          │                  │                  │            │
│   ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐    │
│   │Node Exporter│    │  cAdvisor   │    │Prime Sensors│    │
│   │Host Metrics │    │Docker Stats │    │  (Remote)   │    │
│   │   :9100     │    │   :8087     │    │   :9100     │    │
│   └─────────────┘    └─────────────┘    └─────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Service Details

#### Gatus (Status Page)
**Port:** 3001  
**Access:** `https://status.example.com`

Monitors all services with health checks:
- HTTP/HTTPS endpoint checks
- Response time tracking
- Uptime percentages
- Alert integration

#### Grafana (Dashboards)
**Port:** 3000  
**Access:** `https://grafana.example.com`
**Default Credentials:** admin/admin (change on first login)

Dashboards:
- Node overview (CPU, RAM, Disk)
- Docker container metrics
- Network throughput
- ZFS pool statistics (from Prime)

#### Gotify (Push Notifications)
**Port:** 8089  
**Access:** `https://notify.example.com`

Sends push notifications for:
- Service down alerts
- Backup completion/failure
- Security events
- System warnings

#### Prometheus (Metrics Database)
**Port:** 9090  
**Access:** `https://prom.example.com`
**Retention:** 30 days

Scrape targets:
- Agni node-exporter (localhost:9100)
- Agni cAdvisor (localhost:8087)
- Prime node-exporter (192.168.1.100:9100)
- Prime cAdvisor (192.168.1.100:8087)

#### Healthchecks ("Dead Man's Switch")
**Port:** 8000  
**Access:** `https://hc.example.com`

Monitors scheduled tasks:
- Backup jobs ping on completion
- If no ping received, alert triggered
- Prevents silent failures
- Monitors RClone backup jobs from both Agni and Prime

#### Dozzle (Log Viewer)
**Port:** 8088  
**Access:** `https://logs2.example.com`

Real-time container log streaming for Agni containers.

---

## 🏠 Home Automation

### Home Assistant

**Port:** 8123  
**Access:** `https://ha.example.com`  
**Network Mode:** Host (for mDNS device discovery)

```yaml
services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    network_mode: host
    privileged: true
    volumes:
      - ${DOCKER_CONFIG_PATH}/ha/config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
```

**Integration Points:**
- Smart lights
- Thermostats
- Security cameras
- Presence detection
- Automation rules

---

## 💾 Backup Configuration

### Rclone to pCloud

**Target:** `pcloud:Backups/Krynet-Agni`  
**Healthcheck:** Pings `hc.example.com` on success/failure

**What's Backed Up:**
- All Docker container configs (`/home/agni/apps/docker/`)

This includes configs for Caddy, AdGuard Home, AdGuard Home Sync, Grafana, Prometheus, Home Assistant, Gatus, Gotify, Healthchecks, and all other services running on Agni.

**Exclusions:**
- Git directories
- Log files
- Temporary files
- Socket files
- Database WAL files
- Cache directories

```bash
# Manual backup trigger
docker exec backup-agni rclone sync /data pcloud:Backups/Krynet-Agni --verbose
```

---

## 📁 Configuration Files

### Directory Structure

```
/home/agni/
└── apps/
    └── docker/
        ├── .env                    # Environment variables
        ├── stack.env               # Stack-specific env
        ├── adguard/
        │   ├── work/               # Runtime data
        │   └── conf/               # Configuration (PRIMARY DNS)
        ├── adguard-sync/
        │   └── adguardhome-sync.yaml  # Sync config (Agni→Prime)
        ├── caddy/
        │   ├── Caddyfile           # Reverse proxy config
        │   ├── data/               # Certificates
        │   └── config/             # Runtime config
        ├── cloudflared/
        │   └── [token stored in env]
        ├── gatus/
        │   └── config/
        │       └── config.yaml     # Health check definitions
        ├── gotify/
        │   └── data/               # Notification database
        ├── grafana/
        │   └── data/               # Dashboards, plugins
        ├── ha/
        │   └── config/             # Home Assistant config
        ├── healthchecks/
        │   ├── config/
        │   └── data/
        ├── homepage/
        │   ├── services.yaml
        │   ├── settings.yaml
        │   └── images/
        ├── prometheus/
        │   ├── config/
        │   │   └── prometheus.yml  # Scrape config
        │   └── data/               # Metrics database
        ├── rclone/
        │   └── config/
        │       └── rclone.conf     # Remote config
        └── tailscale/              # VPN state
```

### Environment Variables (.env.example)

```bash
# Cloudflare API Token (for DNS-01 challenge)
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token_here

# Tailscale Auth Key (ephemeral or reusable)
TS_AUTHKEY=your_tailscale_auth_key_here

# AdGuard Home Passwords (for sync)
ADGUARD_PRIME_PASSWORD=your_prime_adguard_password
ADGUARD_AGNI_PASSWORD=your_agni_adguard_password

# User/Group IDs
PUID=1000
PGID=1000
TZ=Asia/Kolkata

# Cloudflare Tunnel Token
CF_TOKEN=your_cloudflare_tunnel_token

# Docker config path
DOCKER_CONFIG_PATH=/home/agni/apps/docker

# Admin passwords
GOTIFY_ADMIN_PASS=your_admin_password
```

---

## 🔧 Maintenance & Operations

### Common Commands

```bash
# Check all container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View container logs
docker logs -f caddy
docker logs -f cloudflared
docker logs -f adguardhome

# Restart a service
docker restart caddy

# Update all containers
docker compose -f /home/agni/apps/docker/[stack].yml pull
docker compose -f /home/agni/apps/docker/[stack].yml up -d

# Check Tailscale status
docker exec tailscale-agni tailscale status

# Test DNS resolution
nslookup photos.example.com 192.168.1.200

# Check Caddy certificates
docker exec caddy caddy list-certificates
```

### Troubleshooting

#### Tunnel Not Connecting
```bash
docker logs cloudflared
# Look for authentication errors
# Verify CF_TOKEN in stack.env
docker restart cloudflared
```

#### DNS Not Resolving
```bash
# Check AdGuard is running (this is the PRIMARY DNS)
docker ps | grep adguard
# Check upstream DNS in AdGuard UI
# Verify DNS rewrites are configured
# Check AdGuard Sync is running and syncing to Prime
docker logs adguardhome-sync --tail 20
```

#### Services Unreachable
```bash
# Check Caddy is running
docker logs caddy --tail 50
# Verify Caddyfile syntax
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
# Reload config
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

#### Tailscale Not Connecting
```bash
docker exec tailscale-agni tailscale status
# If expired, regenerate auth key in Tailscale admin
# Update TS_AUTHKEY in stack.env
docker restart tailscale-agni
```

### Backup Verification

```bash
# Check last backup status
docker logs backup-agni --tail 20

# Manual backup test
docker exec backup-agni rclone ls pcloud:Backups/Krynet-Agni --max-depth 1

# Verify healthcheck received
# Check hc.example.com for backup job status
```

---

## 📊 Port Reference

| Port | Service | Protocol |
|------|---------|----------|
| 53 | AdGuard DNS (Primary) | TCP/UDP |
| 80 | Caddy HTTP | TCP |
| 443 | Caddy HTTPS | TCP |
| 854 | AdGuard DoT | TCP |
| 785 | AdGuard DoQ | UDP |
| 3000 | Grafana | TCP |
| 3001 | Gatus | TCP |
| 3075 | Homepage | TCP |
| 3923 | CopyParty | TCP |
| 7000 | AdGuard Web UI | TCP |
| 7001 | AdGuard Setup | TCP |
| 8000 | Healthchecks | TCP |
| 8082 | AdGuard Home Sync | TCP |
| 8087 | cAdvisor | TCP |
| 8088 | Dozzle | TCP |
| 8089 | Gotify | TCP |
| 8092 | OpenSpeedTest HTTP | TCP |
| 8093 | OpenSpeedTest HTTPS | TCP |
| 8123 | Home Assistant | TCP |
| 8444 | AdGuard DoH | TCP/UDP |
| 8854 | AdGuard DoQ Alt | UDP |
| 9090 | Prometheus | TCP |
| 9100 | Node Exporter | TCP |
| 9443 | Portainer HTTPS | TCP |

---

**Last Updated:** February 2026  
**Server IP:** 192.168.1.200  
**Hostname:** network-server  
**Device:** SkullSaints Agni Mini PC  
**Services:** 15+ containers  
**Role:** Network Core + Monitoring Hub + Primary DNS
