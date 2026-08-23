# 🗺️ KryNet Fleet Strategic Roadmap, Enhancements & Disaster Recovery Plan

**Target Infrastructure:** 🔥 Agni (`192.168.0.200`), 🌟 Prime (`192.168.0.100`), ⚡ Legion (`192.168.0.150`), 💻 Mac Workstation  
**Date:** August 23, 2026  
**Status:** 🟡 **ACTIVE STRATEGIC BLUEPRINT**  
**Author:** KryNet Fleet Engineering Agent  

---

## 📋 Executive Overview

Following the successful completion of the **Immich v3 VectorChord Migration** and the **Zero-Trust Private Networking Transformation**, this document defines the multi-phase roadmap for hardening the KryNet 3-node infrastructure across:

1. **💾 3-2-1 Backups & Disaster Recovery Audit** (Local ZFS Snapshots + Encrypted pCloud Cloud Sync + Database Dump Runbooks)
2. **📊 Observability & Multi-Platform Alerting Hardening** (Prometheus Multi-Node Metrics + Gatus Status Page + iOS/Android Push Notifications)
3. **🎬 Media Automation & Pipeline Optimization** (Gluetun VPN Kill-Switch Stability + *Arr Suite Hardening + Tdarr GPU Transcoding + Jellystat Setup)

---

## 🗺️ Master Fleet Roadmap Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          KRYNET ENHANCEMENT ROADMAP                         │
├───────────────────┬──────────────────────────────────┬──────────────────────┤
│ Phase / Pillar    │ Core Objectives                  │ Target Node(s)       │
├───────────────────┼──────────────────────────────────┼──────────────────────┤
│ **Pillar 1: 💾**  │ • Audit Rclone pCloud Backups    │ 🔥 Agni, 🌟 Prime    │
│ **Backups & DR**  │ • Audit TrueNAS ZFS Snapshots    │ 🌟 Prime             │
│                   │ • Database Restore Runbooks      │ 🌟 Prime, 🔥 Agni    │
│                   │ • 3-2-1 Compliance Verification  │ Entire Fleet         │
├───────────────────┼──────────────────────────────────┼──────────────────────┤
│ **Pillar 2: 📊**  │ • Prometheus 3-Node Scrapes      │ 🔥 Agni Master       │
│ **Observability** │ • Gatus Multi-Service Checks     │ 🔥 Agni (:3001)      │
│                   │ • iOS & Android Mobile Alerts    │ Gotify / Pushover    │
│                   │ • Dead Man's Switch Backup Pings │ Healthchecks (:8000) │
├───────────────────┼──────────────────────────────────┼──────────────────────┤
│ **Pillar 3: 🎬**  │ • Gluetun VPN & Kill-Switch Audit│ 🌟 Prime (media_net) │
│ **Media Pipeline**│ • *Arr Suite & Jellyseerr Audit  │ 🌟 Prime             │
│                   │ • Tdarr GPU Transcoding Node     │ ⚡ Legion (RTX 3060) │
│                   │ • Jellystat Analytics Deployment │ 🌟 Prime / ⚡ Legion │
└───────────────────┴──────────────────────────────────┴──────────────────────┘
```

---

## 💾 Pillar 1: 3-2-1 Backups & Disaster Recovery Audit

### 1. The 3-2-1 Backup Standard for KryNet
* **3 Copies of Data:**
  1. Live production storage (Local NVMe / ZFS pools `orion` & `andromeda`).
  2. Local atomic TrueNAS ZFS snapshots (Point-in-time recovery).
  3. Off-site encrypted cloud backup (pCloud via Rclone).
* **2 Different Media Types:**
  - High-performance local ZFS mirrored HDD/NVMe storage.
  - Remote encrypted cloud object storage.
* **1 Off-Site Copy:**
  - Automated Rclone sync to `pcloud:Backups/Krynet-*` every 12 hours.

### 2. Backup Audit Tasks
* [ ] **Agni Configuration Backup (`rclone-stack.yml`):**
  - Verify `/home/agni/apps/docker/` sync to `pcloud:Backups/Krynet-Agni`.
  - Validate exclusions (WAL, temp sockets, logs, cache).
  - Verify Healthchecks ping on completion (`https://hc.krynet.cc`).
* [ ] **Prime Configuration & Vault Backup (`rclone-stack.yml`):**
  - Verify `/mnt/orion/apps-config/` sync to `pcloud:Backups/Krynet-Prime`.
  - Verify paperless documents and audiobook metadata backups.
* [ ] **TrueNAS ZFS Automated Snapshot Schedule:**
  - Audit snapshot tasks on `orion/apps-config`, `andromeda/apps/immich`, and `andromeda/apps/paperless`.
  - Retention policy: 15-minute snapshots (keep 24h), Daily snapshots (keep 30d), Monthly snapshots (keep 6 months).
* [ ] **Database Dump Automation & Disaster Recovery Runbooks:**
  - Automated `pg_dump` for Immich PostgreSQL (VectorChord).
  - Automated SQLite backups for Vaultwarden and Home Assistant.
  - Step-by-step restoration playbook verified for zero-data-loss recovery.

---

## 📊 Pillar 2: Observability & Alerting Hardening

### 1. Multi-Node Prometheus Scrape Target Audit
* [x] **Agni Master Prometheus (`prom.krynet.cc` / `:9090`):**
  - Verified scraping Agni: `node-exporter:9100` (Host OS) and `cadvisor:8080` (Containers) ➔ **100% UP**.
  - Verified scraping Prime: `192.168.0.100:9100` and `192.168.0.100:8087` ➔ **100% UP**.
  - Verified scraping Legion: `192.168.0.150:9100` and `192.168.0.150:8087` ➔ **100% UP**.
  - Added NVIDIA GPU Prometheus exporter (`utkuozdemir/nvidia_gpu_exporter`) on Legion (`192.168.0.150:9835`) for RTX 3060 temperature, power, and VRAM metrics ➔ **100% UP**.

### 2. Grafana Provisioning & Pre-Built Fleet Dashboards (`grafana.krynet.cc`)
* [x] **Automated Provisioning Configured:**
  - Prometheus datasource provisioned at `http://prometheus:9090`.
  - **`KryNet 3-Node Fleet Overview`** (`fleet-overview.json`): Side-by-side real-time CPU, RAM, Disk, and Network bandwidth for Agni, Prime, and Legion.
  - **`Legion RTX 3060 GPU & AI Metrics`** (`legion-gpu.json`): GPU thermals, VRAM in-use (6GB limit), compute load, and power draw (Watts).

### 3. Gatus Status Page & Multi-Platform Push Notifications
* [x] **Gatus (`status.krynet.cc` / `:3001`):**
  - 38 active health checks across 10 functional groups with 100% healthy status.
* [x] **Discord Push Alerting (`#fleet-alerts`):**
  - Webhook: `https://discordapp.com/api/webhooks/...` integrated into Gatus alerting engine for instant incident notifications.
* [x] **Android (Gotify) Push Alerting (`notify.krynet.cc`):**
  - Integrated with Gatus for persistent background alerts on Android (S26 Ultra).
* [x] **Healthchecks Dead-Man's Switch Integration (`hc.krynet.cc` / `:8000`):**
  - Actively tracking 12-hour automated Rclone backup pings from Agni, Prime, and Legion.

---

## 🎬 Pillar 3: Media Automation & Download Pipeline Optimization

### 1. Gluetun VPN Stability & Kill-Switch Audit
* [x] **Gluetun WireGuard Gateway Verified:**
  - Connected to Surfshark WireGuard endpoint (`138.199.60.172:51820`), assigned public IP `138.199.60.173` (Singapore).
  - DNS leak protection active with DOT upstream resolvers.
  - Inbound subnet access preserved for LAN (`192.168.0.0/24`).
* [x] **VPN Routing & Kill-Switch Isolation:**
  - `qbittorrent` and `jellyseerr` run in `network_mode: service:gluetun` ➔ 100% of torrent peer traffic and external requests route through the VPN tunnel.
  - Kill-switch verified: If Gluetun drops, container networking immediately severs with zero host IP leak.

### 2. Complete *Arr Suite & Pipeline Alignment
* [x] **Unified Storage & Path Mapping:**
  - Standardized unified data path `/mnt/orion/data:/data` across Sonarr, Radarr, Prowlarr, Bazarr, and SABnzbd enabling hardlinks and instant atomic file moves without disk I/O penalties.
* [x] **Service Integration:**
  - Prowlarr (`:9696`) syncing indexers to Sonarr (`:8989`) and Radarr (`:7878`).
  - FlareSolverr (`:8191`) bypassing anti-bot challenges.
  - Jellyseerr (`:5055`) handling user media requests and webhook dispatch.

### 3. Legion GPU Video Transcoding (Tdarr)
* [x] **Legion Transcode Worker Verified:**
  - `tdarr-node-legion` connected to Prime Tdarr Server (`192.168.0.100:8266`).
  - Hardware accelerated encoders verified: `h264_nvenc`, `hevc_nvenc`, `libsvtav1` on RTX 3060.
  - Active transcoding cache configured on local high-speed NVMe (`/home/legion/apps/docker/tdarr/temp`).

### 4. Jellystat Analytics Deployment
* [x] **Jellystat Live on Prime (`stacks/prime/jellystat.yml`):**
  - PostgreSQL database and web frontend deployed via Portainer API (`:3005`).
  - Ingress configured in Caddy (`https://jellystat.krynet.cc` / `https://stats.krynet.cc`).
  - Automated health check probe active in Gatus with Discord `#fleet-alerts` routing.

---

## 🤖 Agent Execution Standards for This Roadmap

All steps in this roadmap will be executed autonomously via:
1. **Portainer API Tooling:** Stacks deployed/updated via [`scripts/portainer-helper.sh`](../../scripts/portainer-helper.sh).
2. **Tailscale & Cloudflare API Tooling:** Inspected via [`scripts/tailscale-helper.sh`](../../scripts/tailscale-helper.sh) and [`scripts/cloudflare-helper.sh`](../../scripts/cloudflare-helper.sh).
3. **Zero-Data-Loss Safety Standard:** Atomic snapshots before modifying database or storage containers.
