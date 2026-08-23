# 🌐 KryNet Networking Deep Dive

**Comprehensive Technical Documentation**

This document provides an in-depth analysis of KryNet's networking architecture, explaining the technical decisions, configurations, and troubleshooting approaches that make the "works everywhere" experience possible.

---

## Table of Contents

1. [Network Philosophy & Design Goals](#network-philosophy--design-goals)
2. [The Reverse Proxy Layer (Caddy)](#the-reverse-proxy-layer-caddy)
3. [Split-Horizon DNS Architecture](#split-horizon-dns-architecture)
4. [Cloudflare Tunnel Deep Dive](#cloudflare-tunnel-deep-dive)
5. [Tailscale Mesh VPN](#tailscale-mesh-vpn)
6. [Domain Management Strategy](#domain-management-strategy)
7. [Network Security & Isolation](#network-security--isolation)
8. [Traffic Flow Examples](#traffic-flow-examples)
9. [Troubleshooting Guide](#troubleshooting-guide)

---

## 🎯 Network Philosophy & Design Goals

### The Core Problem We're Solving

**Traditional Homelab Access:**
```
Problem 1: Port Forwarding
- Exposes home IP address
- Opens security holes
- Requires dynamic DNS
- ISP can block ports
- CGNAT makes it impossible

Problem 2: VPN-Only Access
- Family must install VPN clients
- Poor mobile experience
- Complicated for non-technical users
- Battery drain on phones

Problem 3: Performance at Home
- Traffic hairpins through internet
- Wastes upload bandwidth
- Adds latency
- Fails when internet is down
```

**KryNet's Solution: Hybrid Multi-Path Architecture**
```
✅ Cloudflare Tunnel: Family-friendly public access (no VPN needed)
✅ Split-Horizon DNS: Local traffic stays local (1Gbps LAN speed)
✅ Tailscale VPN: Secure admin access + subnet routing
✅ Zero Open Ports: No attack surface on home router
```

### Design Principles

1. **Transparent to Users:** Same URL works everywhere
2. **Optimal Routing:** Traffic takes the fastest available path
3. **Defense in Depth:** Multiple security layers
4. **Graceful Degradation:** Services work even if one path fails
5. **Infrastructure as Code:** All configs in git-trackable files

---

## 🔄 The Reverse Proxy Layer (Caddy)

### Why We Migrated to Caddy

#### The Journey Through Three Proxies

**Phase 1: Nginx Proxy Manager (2023-2024)**

*Why We Chose It:*
- GUI-based configuration (beginner-friendly)
- Built-in Let's Encrypt support
- Access lists for basic auth

*Why We Left:*
- Database bloat (SQLite grows indefinitely)
- No Infrastructure-as-Code support
- Manual certificate management
- GUI becomes limiting at scale
- Difficult to version control

**Phase 2: Traefik v3 (2024-2025)**

*Why We Chose It:*
- Label-based Docker integration
- Automatic service discovery
- Powerful middleware system
- Excellent for Kubernetes (future-proofing)

*Why We Left:*
```yaml
# Traefik requires this per container:
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=traefik_proxy"
  - "traefik.http.routers.myapp.rule=Host(`app.mydomain.com`) || Host(`app.lan.mydomain2.com`)"
  - "traefik.http.routers.myapp.entrypoints=websecure"
  - "traefik.http.routers.myapp.tls=true"
  - "traefik.http.routers.myapp.tls.certresolver=myresolver"
  - "traefik.http.routers.myapp.tls.domains[0].main=app.mydomain.com"
  - "traefik.http.routers.myapp.tls.domains[0].sans=app.lan.mydomain2.com"
  - "traefik.http.services.myapp.loadbalancer.server.port=8080"

# That's 9-15 labels per container × 40 containers = Label Hell
```

**Phase 3: Caddy v2 (2025-Current)**

*Why We Chose It:*
```caddyfile
# Caddy requires this for the same container:
@myapp host app.mydomain.com app.lan.mydomain2.com
handle @myapp {
    reverse_proxy myapp:8080
}

# That's 3 lines. For the same functionality.
```

### Caddy Architecture

#### Container Setup

**Docker Compose Configuration:**
```yaml
services:
  caddy:
    image: caddy-cloudflare:custom  # Custom build with Cloudflare module
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"      # HTTP (auto-redirects to HTTPS)
      - "443:443"    # HTTPS
      - "443:443/udp" # HTTP/3 (QUIC)
    volumes:
      - ${DOCKER_CONFIG_PATH}/caddy/Caddyfile:/etc/caddy/Caddyfile
      - ${DOCKER_CONFIG_PATH}/caddy/data:/data       # Certificates
      - ${DOCKER_CONFIG_PATH}/caddy/config:/config   # Runtime config
    environment:
      - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
      - ACME_AGREE=true
    networks:
      - traefik_proxy  # Note: Network name kept for compatibility
```

**Why Custom Image?**
Caddy doesn't include the Cloudflare DNS module by default. Built with:
```dockerfile
FROM caddy:builder AS builder
RUN xcaddy build --with github.com/caddy-dns/cloudflare

FROM caddy:latest
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
```

#### Caddyfile Structure

**Global Configuration Block:**
```caddyfile
{
    email your-email@gmail.com
    # Optional: Enable debug logging
    # debug
    
    # Optional: Admin API endpoint
    # admin off  # Disable for security in production
}
```

**Reusable Snippet (DRY Principle):**
```caddyfile
(cloudflare) {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        resolvers 1.1.1.1
    }
}
```

This snippet enables:
- DNS-01 ACME challenge (works behind CGNAT)
- Wildcard certificates (`*.mydomain.com`)
- Cloudflare API integration
- Custom DNS resolver for challenges

**Wildcard Site Block:**
```caddyfile
*.mydomain.com, *.lan.mydomain2.com {
    import cloudflare  # Apply TLS settings
    
    # Service 1: Immich Photos
    @immich host photos.mydomain.com photos.lan.mydomain2.com
    handle @immich {
        reverse_proxy immich-server:2283
    }
    
    # Service 2: Jellyfin Media
    @jellyfin host media.mydomain.com media.lan.mydomain2.com
    handle @jellyfin {
        reverse_proxy jellyfin:8096
    }
    
    # Service 3: TrueNAS (HTTPS backend)
    @truenas host server.mydomain.com server.lan.mydomain2.com
    handle @truenas {
        reverse_proxy https://192.168.0.100:88 {
            transport http {
                tls_insecure_skip_verify  # Self-signed cert
            }
        }
    }
    
    # Service 4: Portainer (HTTPS backend)
    @portainer host portainer.mydomain.com portainer.lan.mydomain2.com
    handle @portainer {
        reverse_proxy https://192.168.0.100:9443 {
            transport http {
                tls_insecure_skip_verify
            }
        }
    }
    
    # Fallback: Reject unmatched hosts
    handle {
        abort
    }
}
```

#### Advanced Caddy Features Used

**1. Named Matchers for Complex Logic**
```caddyfile
@adminServices {
    host portainer.lan.mydomain2.com logs.lan.mydomain2.com
    not remote_ip 192.168.0.0/24 100.64.0.0/10
}
handle @adminServices {
    respond "Access Denied: Admin services require LAN or VPN" 403
}
```

**2. Header Manipulation**
```caddyfile
@immich host photos.mydomain.com photos.lan.mydomain2.com
handle @immich {
    # Add security headers
    header {
        Strict-Transport-Security "max-age=31536000;"
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
    }
    reverse_proxy immich-server:2283
}
```

**3. Request Buffering for Large Uploads**
```caddyfile
@immich host photos.mydomain.com photos.lan.mydomain2.com
handle @immich {
    request_body {
        max_size 10GB  # Allow large photo uploads
    }
    reverse_proxy immich-server:2283
}
```

**4. Health Checks**
```caddyfile
reverse_proxy immich-server:2283 {
    health_uri /api/server-info/ping
    health_interval 30s
    health_timeout 5s
}
```

### Certificate Management

**Automatic Certificate Issuance:**
1. Caddy detects new hostname in Caddyfile
2. Requests DNS-01 challenge from Let's Encrypt
3. Creates TXT record via Cloudflare API: `_acme-challenge.mydomain.com`
4. Let's Encrypt verifies DNS record
5. Certificate issued and stored in `/data/caddy/certificates`
6. Auto-renewal 30 days before expiry

**Certificate Storage:**
```
/mnt/orion/apps-config/caddy/data/caddy/certificates/
├── acme-v02.api.letsencrypt.org-directory/
│   ├── mydomain.com/
│   │   ├── mydomain.com.crt
│   │   └── mydomain.com.key
│   └── wildcard_.mydomain.com/
│       ├── wildcard_.mydomain.com.crt
│       └── wildcard_.mydomain.com.key
```

**Certificate Lifespan:**
- Issued: 90 days
- Auto-renewal: 60 days
- Grace period: 30 days
- Monitoring: Uptime Kuma checks expiry dates

### Performance Optimization

**HTTP/3 (QUIC) Benefits:**
- 0-RTT connection resumption
- Improved mobile performance
- Better handling of packet loss
- Multiplexing without head-of-line blocking

**Enabled Automatically:**
```
Port 443/udp open for QUIC
Caddy serves HTTP/1.1, HTTP/2, and HTTP/3 simultaneously
Clients negotiate best protocol
```

**Connection Pooling:**
```caddyfile
reverse_proxy immich-server:2283 {
    transport http {
        keepalive 30s
        keepalive_idle_conns 10
    }
}
```

---

## 🔀 Split-Horizon DNS Architecture

### The Problem Split-Horizon Solves

**Scenario Without Split-Horizon:**
```
User at home requests: photos.mydomain.com
→ DNS resolves to Cloudflare Tunnel IP
→ Traffic: Home PC → Router → ISP → Internet → Cloudflare → Tunnel → Back Home
→ Speed: Limited by upload bandwidth (~50 Mbps)
→ Latency: 50-100ms
→ Bandwidth: Consumes ISP quota twice (upload + download)
```

**Scenario With Split-Horizon:**
```
User at home requests: photos.mydomain.com
→ AdGuard DNS rewrites to 192.168.0.100
→ Traffic: Home PC → LAN Switch → Server
→ Speed: Full 1 Gbps LAN
→ Latency: <1ms
→ Bandwidth: Zero internet consumption
```

### AdGuard Home Configuration

#### Primary Instance (KryNet-Agni)

**Installation Path:** `/home/agni/apps/docker/adguard/`

**Docker Configuration:**
```yaml
services:
  adguardhome:
    image: adguard/adguardhome:latest
    container_name: adguardhome
    ports:
      - "53:53/tcp"      # DNS
      - "53:53/udp"      # DNS
      - "7000:80/tcp"    # Web UI
      - "8444:443/tcp"   # DNS-over-HTTPS
      - "854:853/tcp"    # DNS-over-TLS
      - "785:784/udp"    # DNS-over-QUIC
      - "8854:8853/udp"  # DNS-over-QUIC Alt
    volumes:
      - /home/agni/apps/docker/adguard/work:/opt/adguardhome/work
      - /home/agni/apps/docker/adguard/conf:/opt/adguardhome/conf
    environment:
      - TZ=Asia/Kolkata
    restart: unless-stopped
    network_mode: host
```

**DNS Settings:**

*Upstream DNS Servers:*
```
# Primary (Encrypted)
https://dns.cloudflare.com/dns-query
https://dns.google/dns-query

# Fallback (Standard)
1.1.1.1
8.8.8.8
9.9.9.9
```

*DNS Rewrites (Split-Horizon Rules):*
```
Domain                          → IP Address
────────────────────────────────────────────────
*.krynet.cc                     → 192.168.0.200 (Agni / Caddy)
*.lan.kkasbi.in                 → 192.168.0.200 (Agni / Caddy)
```

*Blocklists:*
```
1. OISD Big List (~1.5M domains)
2. AdGuard DNS Filter
3. Phishing Army
4. Custom whitelist for false positives
```

#### Secondary Instance (KryNet-Prime)

**Purpose:** High-availability DNS failover

**Configuration Differences:**
```yaml
ports:
  - "53:53/tcp"
  - "53:53/udp"
  - "7000:80/tcp"    # Web UI
```

**Sync Setup:** AdGuard Home Sync container runs on **Agni** and syncs config to Prime.

```yaml
# Runs on Agni (origin)
services:
  adguardhome-sync:
    image: lscr.io/linuxserver/adguardhome-sync:latest
    container_name: adguardhome-sync
    environment:
      - CONFIGFILE=/config/adguardhome-sync.yaml
    volumes:
      - /home/agni/apps/docker/adguard-sync:/config
    ports:
      - "8082:8080"  # Monitoring UI
```

**Sync Configuration File:**
```yaml
# /config/adguardhome-sync.yaml
origin:
  url: http://192.168.0.200:7000  # Agni (Primary)
  username: admin
  password: ${ADGUARD_PASSWORD}

replicas:
  - url: http://192.168.0.100:7000  # Prime (Secondary)
    username: admin
    password: ${ADGUARD_PASSWORD}

# What to sync
sync:
  dns_rewrites: true
  filters: true
  clients: true
  settings: true
  
# Sync interval
interval: 5m
```

#### Router DHCP Configuration

**DNS Servers Advertised to Clients:**
```
Primary DNS:   192.168.0.200 (Agni)
Secondary DNS: 192.168.0.100 (Prime)
```

**Failover Behavior:**
1. Client tries primary (Agni)
2. If no response in 2 seconds, tries secondary (Prime)
3. Clients cache successful server for ~5 minutes
4. Automatic return to primary when available

### DNS Query Flow

**Example: User requests photos.mydomain.com from home**

```
1. Client sends DNS query to 192.168.0.200 (AdGuard on Agni)
2. AdGuard checks DNS Rewrites
3. Match found: photos.mydomain.com → 192.168.0.200
4. AdGuard returns 192.168.0.200 to client
5. Client connects directly to Agni on LAN
6. Request hits Caddy on Agni
7. Caddy proxies to 192.168.0.100:2283 (Immich on Prime)
```

**Example: Remote user requests photos.krynet.cc away from home (via Tailscale)**

```
1. Client device (Mac / iPhone / Android) is connected to Tailscale Mesh VPN.
2. Tailscale MagicDNS intercepts query for photos.krynet.cc.
3. Query routes over WireGuard to Agni Tailscale Nameserver (100.89.216.106).
4. Agni resolves to 100.89.216.106 (Agni Caddy Ingress).
5. Request enters Caddy on Agni over encrypted WireGuard tunnel.
6. Caddy presents valid Let's Encrypt wildcard certificate (*.krynet.cc).
7. Caddy proxies to Prime (192.168.0.100:2283) over private LAN.
8. Speed: Full WireGuard P2P bandwidth (no 100MB chunk limit, no ToS video limits).
```

### Troubleshooting DNS

**Check Local LAN DNS Resolution:**
```bash
# Query Agni Primary DNS
dig @192.168.0.200 photos.krynet.cc +short
# Query Prime Secondary DNS
dig @192.168.0.100 photos.krynet.cc +short
# Both return: 192.168.0.200
```

**Check Remote Tailscale DNS Resolution:**
```bash
# Query via Tailscale interface
dig @100.89.216.106 photos.krynet.cc +short
# Returns: 100.89.216.106
```

---

## 🌍 Zero-Trust Ingress & Remote Access Architecture

### Evolution: Why We Decommissioned Public Cloudflare Ingress

In August 2026, KryNet transitioned from public Cloudflare Tunnels to a **Zero-Trust Private Mesh (Tailscale + Split-Horizon LAN)**:

```
┌─────────────────────────────────────────────────────────────┐
│                 KRYNET ZERO-TRUST INGRESS                   │
├─────────────────────────────────────────────────────────────┤
│ 1. Home Wi-Fi / LAN:                                        │
│    AdGuard Home (192.168.0.200 / .100)                      │
│    └── Rewrites *.krynet.cc ──▶ 192.168.0.200 (Agni Caddy)  │
│        └── 1Gbps line rate, zero internet bandwidth         │
│                                                             │
│ 2. Remote / Cellular (Away from Home):                      │
│    Tailscale Mesh VPN (MagicDNS Split DNS)                  │
│    └── Routes *.krynet.cc ──▶ 100.89.216.106 (Agni Caddy)   │
│        └── Direct P2P WireGuard, zero public attack surface │
│                                                             │
│ 3. Automated SSL Certificates:                              │
│    Caddy DNS-01 Challenge via Cloudflare API Token          │
│    └── Outbound API call ──▶ Valid *.krynet.cc Wildcard TLS │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Benefits

1. **Zero Public Attack Surface:** No public IP exposure, no open ports, and no public HTTP proxies exposed to bots or automated scanners.
2. **Unlimited Body Size for Photos & Videos:** Immich mobile app uploads 4K videos at full network speed without hitting Cloudflare's 100MB body size limit or proxy timeouts.
3. **No Video Streaming Violations:** Jellyfin streams high-bitrate media over WireGuard without violating Cloudflare Terms of Service Section 2.8.
4. **Automated Wildcard TLS:** Let's Encrypt certificates are renewed outbound via Cloudflare DNS-01 API challenges. No inbound HTTP port 80 or public tunnel is required.

---

### Tailscale MagicDNS / Split DNS Configuration (Path A - Active)

To ensure mobile devices (Android / iOS) bypass cellular carrier CGNAT filtering:

1. In **Tailscale Admin Console** ➔ **DNS Settings**:
   * Toggle **MagicDNS** = `ON`.
2. Under **Nameservers** ➔ Click **Add nameserver** ➔ **Custom**:
   * Nameserver IP: `100.89.216.106` (Agni Tailscale IP)
   * Restrict to search domains: `krynet.cc`, `lan.kkasbi.in`, `kkasbi.in`
3. Click **Save**.

---

### Preserved Cloudflare Tunnel Blueprint (Path B - Archived Runbook)

If public access or clientless sharing is ever required for temporary guest access:

1. Deploy `stacks/agni/cloudflared-stack.yml` in Agni Master Portainer (`https://portainer2.krynet.cc`).
2. Ensure `CF_TOKEN` is present in `/home/agni/apps/docker/stack.env`.
3. In [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) ➔ **Access** ➔ **Applications**:
   * Add Access Application for target subdomain (e.g. `share.krynet.cc`).
   * Add Policy requiring One-Time PIN / Google OAuth.
```
Name: KryNet Family Services
Session Duration: 24 hours
Application Domain: 
  - photos.mydomain.com
  - media.mydomain.com
  - request.mydomain.com
  - home.mydomain.com
```

#### Create Access Policy

**Policy Name:** Family Members Only

**Include Rules:**
```
Selector: Emails
Value:    user1@gmail.com
          user2@gmail.com
          user3@gmail.com
          user4@gmail.com
```

**Or use Email Domain:**
```
Selector: Emails ending in
Value:    @gmail.com

+ Additional rule:
Selector: Email
Value:    [specific family emails]
```

**Authentication Method:** Google OAuth 2.0

#### User Experience

**First Access:**
```
1. User visits photos.mydomain.com
2. Cloudflare intercepts request
3. Redirects to Cloudflare login page
4. User clicks "Sign in with Google"
5. Google OAuth consent screen
6. User approves
7. Cloudflare validates email against policy
8. If approved, sets 24-hour session cookie
9. Redirects to photos.mydomain.com
10. Service loads normally
```

**Subsequent Access (within 24 hours):**
```
1. User visits photos.mydomain.com
2. Cloudflare checks session cookie
3. Valid → passes through immediately
4. Service loads with no login prompt
```

### Performance Considerations

**Tunnel Overhead:**
- Latency: +10-30ms (Cloudflare edge routing)
- Bandwidth: Dependent on home upload speed
- Reliability: 99.99% uptime (Cloudflare SLA)

**Bandwidth Usage:**
```
Scenario: Streaming 4K movie (20 Mbps)
Without Split-Horizon: 20 Mbps upload consumed (limited to ISP upload)
With Split-Horizon: 0 Mbps (local LAN, no tunnel used)
```

**When Tunnel is Used:**
- User outside home network
- User explicitly uses `photos.mydomain.com` (not `.lan`)
- Mobile devices on cellular data

**When Tunnel is NOT Used:**
- User on home LAN (split-horizon DNS)
- User connected to Tailscale VPN
- Direct IP access from LAN

### Monitoring & Troubleshooting

**Check Tunnel Status:**
```bash
# From Prime
docker logs cloudflared

# Should show:
# "Connection established"
# "Registered tunnel connection"
```

**Cloudflare Dashboard:**
- Navigate: Zero Trust → Access → Tunnels → krynet-prime
- Should show: "Healthy" status
- Shows: Last heartbeat timestamp
- Metrics: Requests/second, bandwidth

**Common Issues:**

*Tunnel shows "Down"*
```bash
# Restart container
docker restart cloudflared

# Check token validity
echo $CF_TOKEN  # Should not be expired

# Check network connectivity
ping 1.1.1.1
```

*"403 Forbidden" after OAuth*
- Email not in Access Policy
- Policy not applied to application
- Session cookie expired (past 24 hours)
- Browser incognito mode (cookies disabled)

*Slow Performance*
- Check home upload bandwidth: `speedtest-cli`
- Verify Cloudflare tunnel metrics
- Consider Tailscale for large transfers

---

## 🔐 Tailscale Mesh VPN

### Architecture

**Traditional VPN (Hub-and-Spoke):**
```
Phone → VPN Server → Home Network
        ↓
    Bottleneck
```

**Tailscale (Mesh):**
```
Phone ←→ Home Server (Direct P2P)
Phone ←→ Laptop (Direct P2P)
Laptop ←→ Home Server (Direct P2P)
```

### KryNet-Prime Configuration

**Container Setup:**
```yaml
services:
  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    restart: unless-stopped
    network_mode: host  # Required for subnet routing
    cap_add:
      - NET_ADMIN  # Required for network manipulation
      - NET_RAW    # Required for packet crafting
    volumes:
      - /mnt/orion/apps-config/tailscale:/var/lib
      - /dev/net/tun:/dev/net/tun  # TUN device for VPN
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_ROUTES=192.168.0.0/24
      - TS_EXTRA_ARGS=--advertise-exit-node
      - TS_STATE_DIR=/var/lib/tailscale
```

**Environment Breakdown:**

`TS_AUTHKEY`: Reusable authentication key from Tailscale admin console
- Generate: Settings → Keys → Auth Keys
- Enable: "Reusable" and "Ephemeral" options
- Expires: 90 days (regenerate as needed)

`TS_ROUTES=192.168.0.0/24`: Subnet routing
- Advertises entire home network
- Allows Tailscale clients to access 192.168.0.x devices
- Must be approved in Tailscale admin console

`TS_EXTRA_ARGS=--advertise-exit-node`: Exit node functionality
- Routes ALL internet traffic through home connection
- Useful for: Public Wi-Fi security, geo-unblocking
- Must be approved in Tailscale admin console

### KryNet-Agni Configuration

**Container Setup:**
```yaml
services:
  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale-agni
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - /home/agni/apps/docker/tailscale:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_HOSTNAME=agni-server
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_EXTRA_ARGS=--advertise-exit-node --advertise-routes=192.168.0.0/24
```

**Key Differences from Prime:**
- Advertises subnet routes (192.168.0.0/24)
- Advertises exit node
- Custom hostname for identification

### Tailscale Admin Console Setup

**Step 1: Approve Subnet Routes**
```
Navigate: Machines → krynet-prime → Edit route settings
Enable: 192.168.0.0/24
```

**Step 2: Approve Exit Node**
```
Navigate: Machines → krynet-prime → Edit route settings
Enable: Use as exit node
```

**Step 3: Enable MagicDNS**
```
Navigate: DNS → Enable MagicDNS
Effect: Can access machines via hostname (e.g., krynet-prime)
```

**Step 4: Disable Key Expiry (Optional)**
```
Navigate: Machines → krynet-prime → Disable key expiry
Effect: Node won't disconnect after 180 days
```

### Use Cases

#### 1. Administrative SSH Access

```bash
# From laptop (anywhere in the world)
ssh admin@krynet-prime  # MagicDNS hostname
# Or
ssh admin@100.x.x.1  # Tailscale IP

# No password needed (SSH keys)
# Encrypted end-to-end
# NAT traversal automatic
```

#### 2. Web Interface Access

**Access internal services:**
```
https://portainer.lan.mydomain2.com  # Container management
https://logs.lan.mydomain2.com       # Dozzle logs
https://server.lan.mydomain2.com     # TrueNAS UI
```

**How it works:**
1. Tailscale client resolves hostname
2. Connects to Prime's Tailscale IP (100.x.x.1)
3. Request hits Caddy
4. Caddy matches `*.lan.mydomain2.com`
5. Proxies to appropriate service

#### 3. Subnet Access

**Access any home device:**
```bash
# Access router admin (192.168.0.1)
https://192.168.0.1

# Access IoT device (192.168.0.50)
http://192.168.0.50

# Access Agni directly (192.168.0.200)
ssh admin@192.168.0.200
```

**Traffic flow:**
```
Your Device → Tailscale Mesh → Prime (subnet router) → LAN Device
```

#### 4. Exit Node (Secure Public Wi-Fi)

**Enable on mobile:**
```
Tailscale App → [Three dots] → Use exit node → krynet-prime
```

**Effect:**
```
ALL internet traffic routes through home connection
Phone → Tailscale → Prime → Internet
```

**Benefits:**
- Coffee shop Wi-Fi can't see your traffic
- Appear as if browsing from home IP
- Bypass hotel/airport network restrictions

#### 5. High-Speed Media Access

**Scenario:** Streaming 4K movie while traveling

```
Option 1: Cloudflare Tunnel
- Limited by home upload (~50 Mbps)
- Buffering likely for 4K (needs 25-40 Mbps)

Option 2: Tailscale Direct Connection
- P2P connection (no relay if possible)
- Can achieve 100+ Mbps on good connections
- Adaptive: Falls back to relay if P2P fails
```

**Access via:**
```
https://media.lan.mydomain2.com  # Tailscale-routed Jellyfin
```

### Tailscale Network Topology

**Mesh Visualization:**
```
                    ┌──────────────┐
                    │  Tailscale   │
                    │ Control Plane│
                    │ (Coordination)
                    └───────┬──────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼────┐         ┌────▼────┐        ┌────▼────┐
   │  Prime  │◄────────►│  Agni   │        │  Phone  │
   │100.x.x.1│   P2P    │100.x.x.2│        │100.x.x.10
   └────┬────┘         └─────────┘        └─────────┘
        │                                       │
        │ Subnet Route (192.168.0.0/24)       │ 
        │                                       │
   ┌────▼────────────────────────────────┐    │
   │     Home LAN (192.168.0.0/24)       │◄───┘
   └─────────────────────────────────────┘
```

---

## 🔐 Domain Management Strategy

### Public vs. Private Domains

**Public Domain (`krynet.cc` / `kkasbi.in`):**
- **Managed by:** Cloudflare
- **Resolution:** Public DNS (1.1.1.1) resolves to Cloudflare Tunnel
- **Access:** Zero Trust Authentication required (Google OAuth)
- **Use Case:** Family access from anywhere, sharing links

**Private Domain (`lan.kkasbi.in`):**
- **Managed by:** AdGuard Home (Local)
- **Resolution:**
  - On LAN: 192.168.0.200 (Agni) or 192.168.0.100 (Prime)
  - On VPN: 100.x.x.1 (Tailscale MagicDNS)
- **Access:** Direct IP connection (no auth proxy overhead)
- **Use Case:** Admin interfaces, high-bandwidth streaming at home, service-to-service communication

---

## 🛡️ Network Security & Isolation

### Zero Trust Implementation

1.  **Identity Awareness:**
    *   No service is exposed to the open internet without authentication.
    *   Even "public" services like Jellyfin are behind Cloudflare Access.
    *   Only specific Google Accounts (family members) effectively "exist" to the network.

2.  **No Open Ports:**
    *   Router firewall blocks ALL incoming connections.
    *   `cloudflared` makes *outbound* connections to Cloudflare edge.
    *   Tailscale uses NAT traversal (STUN/DERP) to punch specific P2P holes only when authenticated.

3.  **Container Isolation:**
    *   `traefik_proxy` network: Only for containers that *need* to be seen by Caddy.
    *   `kry_net` network: For backend communication (e.g., Sonarr talking to Prowlarr).
    *   Database containers (Postgres/Redis) are often NOT exposed on `traefik_proxy`.

### VPN Kill Switch (Gluetun)

For privacy-sensitive applications (Torrents/Usenet), we use **Gluetun** as a gateway.

*   **Mechanism:** Docker container networking (`network_mode: service:gluetun`)
*   **Leak Protection:** Gluetun configures `iptables` to strictly allow traffic ONLY through the `tun0` interface.
*   **Result:** If the VPN tunnel drops, the network interface effectively "dies" for attached containers. No traffic leaks to the ISP.

---

## 🚥 Traffic Flow Examples

### Scenario A: Family Member Watching Movie on Vacation
*Device: iPad on Hotel Wi-Fi*

1.  **Request:** User opens `media.krynet.cc`.
2.  **DNS:** Resolves to Cloudflare's Anycast IP.
3.  **Auth:** Cloudflare checks for valid session cookie. If missing, prompts Google Login.
4.  **Transport:** Cloudflare routes traffic through the encrypted tunnel to `cloudflared` on Prime.
5.  **Proxy:** `cloudflared` forwards to Caddy (localhost:443) on Agni.
6.  **Service:** Caddy proxies to `192.168.0.100:8096` (Jellyfin on Prime).
7.  **Stream:** Video stream flows back through the tunnel. *Note: Latency is slightly higher, bitrate limited by home upload speed.*

### Scenario B: Admin Managing Server from Coffee Shop
*Device: Laptop on Public Wi-Fi + Tailscale*

1.  **Connection:** User enables Tailscale. Laptop gets IP `100.x.x.5`.
2.  **Request:** User opens `https://portainer.lan.kkasbi.in`.
3.  **DNS:** Tailscale MagicDNS resolves to Prime's Tailscale IP `100.x.x.1`.
4.  **Transport:** Traffic flows P2P (UDP) encrypted via WireGuard directly to Prime.
5.  **Proxy:** Caddy receives request on the Tailscale interface.
6.  **Service:** Caddy proxies to `portainer:9443`.
7.  **Result:** Secure management without exposing Portainer to the public internet.

### Scenario C: Home Automation Trigger
*Device: IoT Sensor on LAN*

1.  **Event:** Motion detected.
2.  **Action:** Sensor sends HTTP POST to `http://192.168.0.200:8123` (Home Assistant on Agni).
3.  **Transport:** Direct LAN traffic. No encryption needed inside trusted LAN VLAN.
4.  **Latency:** <1ms. Instant response.

---

## 🔧 Troubleshooting Guide

### 1. "Service Not Reachable" (Public URL)
*   **Check Cloudflare Tunnel:**
    ```bash
    docker logs cloudflared
    ```
    Look for "ERR" or "Connection lost".
*   **Check Caddy:**
    ```bash
    docker logs caddy
    ```
    Ensure Caddy is running and has valid certificates.
*   **Check Auth:** ensure your email is in the Cloudflare Access policy.

### 2. "Service Not Reachable" (LAN URL)
*   **Check DNS:**
    ```bash
    nslookup photos.lan.kkasbi.in
    ```
    Should return `192.168.0.100`. If it fails, check AdGuard Home.
*   **Check Caddy:** Ensure Caddy is connected to the `traefik_proxy` network.

### 3. Slow Speeds on Downloads
*   **Check Gluetun:**
    ```bash
    docker logs gluetun
    ```
    Check for "Unhealthy" status or VPN disconnects.
*   **Check qBittorrent:** Ensure "Connection Status" is green (online).

### 4. Certificate Errors
Caddy manages certs automatically, but issues can arise.
*   **Reset Certs:**
    ```bash
    # Caution: This clears all certs
    rm -rf config/caddy/data/caddy/certificates
    docker restart caddy
    ```
    Caddy will re-negotiate with Let's Encrypt.



