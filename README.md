# My Private Cloud & Homelab Setup ("Krynet")

Welcome to the documentation for my personal private cloud. This repository details the hardware, software, and networking architecture I use to self-host a wide array of services for my family. The goal is a reliable, secure, and low-maintenance system that handles everything from photo backups and media streaming to home automation and document archival.

This document is for my own reference and for anyone else interested in building a similar setup. All sensitive information (domains, IPs, API keys) has been replaced with generic `<PLACEHOLDERS>`.

## 1. Core Philosophy & Use Cases

This system is built on a "two-server" model: a primary, high-availability storage server and a secondary, high-performance compute server.

* **`Krynet-Prime` (TrueNAS):** The "data-first" server. Its primary job is to store data securely using ZFS, run core 24/7 services, and serve as the central brain of the network.
* **`Krynet-Legion` (Ubuntu):** The "compute-first" server. This is a powerful machine used for high-demand tasks like AI, transcoding, and for providing critical service redundancy (like secondary DNS).

This setup is designed to solve several key use cases:
1.  **📸 Photo & Video Management:** A complete, self-hosted Google Photos replacement via **Immich**.
2.  **🎬 Automated Media Stack:** A fully automated "request-and-watch" media server using the full **\*ARR stack**, **Jellyfin**, and **Gluetun** for privacy.
3.  **📄 Digital Document Archival:** A "scan-and-forget" digital file cabinet using **Paperless-NGX**.
4.  **🧠 AI & LLM Hub:** A private ChatGPT-like interface using **OpenWebUI** and **LiteLLM** to aggregate various AI models.
5.  **🏠 Home Automation:** A central hub for all smart devices, sensors, and automations via **Home Assistant**.
6.  **🌐 Network Security & Control:** Network-wide ad-blocking and local DNS resolution using a redundant **AdGuard Home** setup.
7.  **💾 Backup & Redundancy:** A multi-layered backup strategy involving ZFS, inter-server sync with **Syncthing**, and cloud backups.
8.  **Monitor & Aggregate:** Tools for monitoring uptime (**Uptime Kuma**), internet speed (**Speedtest Tracker**), internal network speed (**OpenSpeedTest**), and news feeds (**FreshRSS**).

---

## 2. Hardware Overview

### 2.1. Krynet-Prime (Primary Storage Server)

* **Host OS:** TrueNAS SCALE
* **CPU:** Intel i5-7600k
* **RAM:** 32GB (2x 16GB) Crucial 2400MHz DDR4
* **GPU:** Zotac GeForce GTX 1060 3GB (Used for Immich ML & Jellyfin transcoding)
* **Storage (OS):** 1x 500GB Crucial SATA SSD
* **Storage (Data):** See Storage Architecture below.
* **PSU:** Corsair VS550
* **Local IP:** `<TRUENAS_IP>` (e.g., 192.168.0.100)

### 2.2. Krynet-Legion (Secondary Compute Server)

* **Model:** Lenovo Legion Gaming Laptop
* **Host OS:** Ubuntu 22.04 LTS
* **CPU:** Intel i7-12700H
* **RAM:** 16GB
* **GPU:** NVIDIA GeForce GTX 3060 6GB (Used for high-intensity AI/transcoding)
* **Storage:** 1TB NVMe SSD
* **Local IP:** `<LEGION_IP>` (e.g., 192.168.0.200)

---

## 3. Storage Architecture (ZFS)

Data integrity is paramount. All data is stored on ZFS pools with built-in redundancy and health checks (daily scrubs, periodic S.M.A.R.T. tests).

### 3.1. Krynet-Prime Pools

* **Pool `andromeda` (Critical Data):**
    * **Disks:** 2x 4TB WD Red Plus (ZFS Mirror)
    * **Purpose:** Irreplaceable data. This pool holds all photos/videos (**Immich**) and scanned documents (**Paperless-NGX**).
* **Pool `orion` (App Data & Media):**
    * **Disks:** 2x 2TB WD Blue (ZFS Mirror)
    * **Purpose:** Resilient, but replaceable data. This pool holds all Docker app configurations, media libraries (**Jellyfin**), and download data.
* **Pool `comet` (Scratch):**
    * **Disks:** 1x 1TB WD Blue (ZFS Stripe)
    * **Purpose:** Non-critical, general storage.

### 3.2. Krynet-Legion Storage

* **Pool `legion-store` (Compute & Backup):**
    * **Disks:** 1x 1TB NVMe SSD
    * **Purpose:** Hosts the Ubuntu OS, local Docker containers, and serves as a **Syncthing** backup target for `Krynet-Prime`'s app configurations.

---

## 4. Networking Architecture

The network is designed for seamless, secure access from anywhere without exposing services directly to the internet. This is achieved via a **Split-Horizon DNS** model.

### 4.1. Core Components

* **Reverse Proxy:** **Traefik** (running on `Krynet-Prime`) is the single gateway for all web traffic. It handles SSL certificates and routes requests to the correct Docker container.
* **DNS:** A high-availability DNS setup using two **AdGuard Home** instances (Primary on `Krynet-Prime`, Secondary on `Krynet-Legion`). **AdGuardHome-Sync** keeps them synchronized.
* **VPN:** **Tailscale** is installed on both servers and all client devices (phones, laptops) for a secure overlay mesh network.
* **Public Access:** A few select services are exposed publicly (and securely) using a **Cloudflare Tunnel** (`cloudflared` container).

### 4.2. Access Strategy & Domain Placeholders

I use three domain types for different access methods. All are managed by Traefik.

* **`*.my-main.domain` (e.g., `krynet.cc`):** The primary, "magic" domain.
* **`*.my-local.domain` (e.g., `local.kkasbi.site`):** A legacy/backup domain for local-only access.
* **`*.my-vpn.domain` (e.g., `tail.kkasbi.site`):** A legacy/backup domain for Tailscale-only access.
* **`*.my-public.domain` (e.g., `kkasbi.site`):** The public-facing domain, protected by Cloudflare Access.

### 4.3. Request Flow: The Split-Horizon Model

This model lets me use the **exact same address** (e.g., `photos.my-main.domain`) whether I'm at home or on the go.

* **Flow 1: At Home (on LAN)**
    1.  My laptop requests `photos.my-main.domain`.
    2.  My router's DNS is set to `Krynet-Prime`'s AdGuard instance (`<TRUENAS_IP>`).
    3.  AdGuard sees the request and a **DNS Rewrite** rule matches `*.my-main.domain`.
    4.  AdGuard returns the *local* IP of the Traefik server: `<TRUENAS_IP>`.
    5.  My laptop connects directly to `<TRUENAS_IP>`, and Traefik serves the Immich website.

* **Flow 2: Remote (on Tailscale VPN)**
    1.  My phone (on 5G) connects to Tailscale.
    2.  Tailscale's DNS is configured to use my AdGuard instance (`<TRUENAS_IP>`).
    3.  I request `photos.my-main.domain`.
    4.  The request goes over the secure Tailscale tunnel to AdGuard.
    5.  AdGuard's DNS Rewrite returns `<TRUENAS_IP>`.
    6.  My phone connects to `<TRUENAS_IP>` *over the VPN tunnel*. Traefik serves the website.

* **Flow 3: Remote (Public Access via Cloudflare)**
    1.  A family member (with permission) requests `photos.my-public.domain`.
    2.  The request hits Cloudflare.
    3.  **Cloudflare Access** (with Google OAuth) challenges them for a login.
    4.  Upon success, the request is sent down the secure **Cloudflare Tunnel** to the `cloudflared` container on `Krynet-Prime`.
    5.  `cloudflared` forwards the request to Traefik, which serves the Immich website.



---

## 5. Software & Service Stack

| Category | Service | Host | Purpose |
| :--- | :--- | :--- | :--- |
| **Infrastructure** | Portainer | Prime & Legion | Docker GUI Management |
| | Traefik | Prime | Reverse Proxy & SSL |
| | AdGuard Home | Prime & Legion | Redundant DNS & Ad-Blocking |
| | AdGuardHome-Sync | Prime | Syncs AdGuard instances |
| | Cloudflared | Prime | Secure Public Access Tunnel |
| | Tailscale | Prime & Legion | VPN Mesh Network |
| | Watchtower | Prime | Automatic Container Updates |
| **Media (ARR Stack)** | Gluetun | Prime | VPN Client (Surfshark) for downloaders |
| | QBittorrent | Prime | Torrent Downloader (behind Gluetun) |
| | Sabnzbd | Prime | Usenet Downloader (behind Gluetun) |
| | Prowlarr | Prime | Indexer Manager for \*ARRs |
| | Sonarr | Prime | TV Show Automation |
| | Radarr | Prime | Movie Automation |
| | Bazarr | Prime | Subtitle Automation |
| | Whisparr | Prime | Adult Media Automation (behind Gluetun) |
| **Media (Consume)** | Jellyfin | Prime | Media Server & Streaming |
| | Jellyseers | Prime | Media Request Portal (behind Gluetun) |
| **Productivity** | Immich | Prime | Photo & Video Management |
| | **Paperless-NGX** | Prime | Document Archival & OCR |
| | **FreshRSS** | Prime | RSS Feed Aggregator |
| | Vaultwarden | Prime | Password Manager |
| | **Syncthing** | Prime & Legion | Inter-Server File Sync |
| **Home & AI** | Home Assistant | Prime | Home Automation Hub |
| | OpenWebUI | Prime | WebUI for LLM (ChatGPT-like) |
| | LiteLLM | Prime | LLM Proxy/Aggregator |
| **Monitoring** | Uptime Kuma | Prime | Service Uptime Monitoring |
| | Prometheus | Prime | Metrics Collection |
| | Dozzle | Prime | Real-time Log Viewer |
| | **OpenSpeedTest** | Prime | **Internal** LAN Speed Test |
| | **Speedtest Tracker** | Prime | **External** Internet Speed Test Logger |

---

## 6. Backup & Resiliency Strategy

This system is designed to survive hardware failures and data loss through multiple layers of defense.

1.  **Hardware Redundancy (ZFS):** All primary data pools (`andromeda`, `orion`) are ZFS mirrors, meaning one disk in each pool can fail completely with zero data loss.
2.  **Data Integrity (ZFS):** Daily ZFS scrubs and S.M.A.R.T. tests run to detect and correct "bit rot" or silent data corruption before it becomes a problem.
3.  **Application Backup (ZFS):** The entire `orion/apps-config` dataset is automatically captured in a ZFS snapshot on a regular schedule.
4.  **Inter-Server Backup (Syncthing):** A **one-way, read-only** sync is set up:
    * `Krynet-Prime`'s `/apps-config` (read-only) ➡️ **Syncthing** ➡️ `Krynet-Legion`'s backup folder.
    * `Krynet-Legion`'s `/apps` (read-only) ➡️ **Syncthing** ➡️ `Krynet-Prime`'s backup folder.
    * This provides a near-real-time backup of all application configs to a separate physical machine.
5.  **Off-Site Backup (Cloud):** A TrueNAS Cloud Sync task regularly backs up critical database dumps (e.g., Immich, Vaultwarden) to a pCloud account.

---

## 7. Docker Stack Configuration (Sanitized Examples)

All applications are deployed as Docker containers via Portainer Stacks.

### Key Environment Variables

I use a central `.env` file for all stacks on each server. Key variables include:

```bash
# === General ===
# Set to 'Asia/Kolkata'
TZ=

# User/Group IDs for permissions
# On TrueNAS, 568 (apps)
PUID=568
PGID=568

# === Paths (TrueNAS) ===
# Path to app-config ZFS dataset (e.g., /mnt/orion/apps-config)
DOCKER_CONFIG_PATH=/path/to/your/configs

# Path to media ZFS dataset (e.g., /mnt/orion/media)
MEDIA_DATA_PATH=/path/to/your/media

# Path to critical data ZFS dataset (e.g., /mnt/andromeda)
ANDROMEDA_DATA_PATH=/path/to/your/critical-data

# === Secrets ===
# Your main Postgres 'postgres' user password
POSTGRES_PASS=<YOUR_DB_PASSWORD>

# Generated key for Speedtest Tracker
SPEEDTEST_APP_KEY=<YOUR_APP_KEY>

# Other secrets...
CLOUDFLARE_API_TOKEN=...
GOTIFY_ADMIN_PASS=...
VAULTWARDEN_ADMIN_TOKEN=...
