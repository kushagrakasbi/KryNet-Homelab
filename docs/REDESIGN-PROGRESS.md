# 📊 KryNet 3-Node Redesign — Execution Progress & Fleet Status

**Status:** 🟢 **100% COMPLETE & PRODUCTION LIVE**  
**Active Branch:** `main` (All Redesign PRs Merged)  
**Nodes:** 🔥 Agni (`192.168.0.200`) | 🌟 Prime (`192.168.0.100`) | ⚡ Legion (`192.168.0.150`)  
**Last Updated:** August 23, 2026 (14:30 IST)

---

## 🗺️ Fleet Overview & Live State

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                FLEET HEALTH SNAPSHOT                             │
├──────────────────────────┬──────────────────────────┬────────────────────────────┤
│  🔥 AGNI (192.168.0.200) │  🌟 PRIME (192.168.0.100)│  ⚡ LEGION (192.168.0.150) │
│  • OS: Ubuntu 24.04 LTS  │  • OS: TrueNAS SCALE     │  • OS: Ubuntu 26.04 LTS    │
│  • Role: Ingress & Auth  │  • Role: Storage Vault   │  • Role: AI & GPU Compute  │
│  • Ingress: Caddy Live   │  • ZFS: 6TB Mirrored     │  • GPU: RTX 3060 6GB CUDA  │
│  • Portainer Master: Live│  • Immich Server: Live   │  • Ollama: Qwen/DeepSeek   │
│  • Prometheus: 3-Node    │  • Old AI Stack: Stopped │  • Ingress: ow.krynet.cc   │
│  • Gatus: status.krynet  │  • 4GB+ RAM Reclaimed!   │  • Tdarr Worker: Live      │
└──────────────────────────┴──────────────────────────┴────────────────────────────┘
```

---

## ✅ Completed & Verified Milestones

### 1. Legion OS Installation & Hardware Hardening
- [x] **Ubuntu Server 26.04 LTS (Headless, 64-bit)** cleanly installed on Legion's 1TB NVMe.
- [x] **NVIDIA Drivers & CUDA Runtime:** Installed `nvidia-driver-595-server-open` + `nvidia-utils-595-server` (Driver 595.71.05, CUDA 13.2).
- [x] **Battery Conservation Mode:** Capped battery charging at ~60% via `battery-conservation.service` (systemd unit enabled on boot) to prevent battery swelling.
- [x] **Lid-Closed Operation:** Configured `/etc/systemd/logind.conf` with `HandleLidSwitch=ignore` and `HandleLidSwitchExternalPower=ignore`.
- [x] **Docker & NVIDIA Container Toolkit:** Docker installed, NVIDIA runtime configured (`nvidia-ctk runtime configure`), and verified working.

### 2. Fleet Git Synchronization & Universal Agent Baseline
- [x] Cloned and synchronized `home-server` repo across all nodes (`/home/legion/home-server`, `/home/agni/home-server`, `/mnt/orion/apps-config/home-server`).
- [x] Root **[`AGENTS.md`](../AGENTS.md)** established as universal operating instructions for all terminal agents across the fleet.
- [x] **[`opencode.json`](../opencode.json)** configured for autonomous agent execution.

### 3. Portainer Management & Central Ingress
- [x] **Portainer Agent** deployed on Legion (`stacks/legion/monitoring-sensors.yml`) on port `9001`.
- [x] Connected Legion environment into Agni's central Portainer Server (`https://portainer.krynet.cc`).
- [x] **Caddy Ingress Updated:** Agni's `/etc/caddy/Caddyfile` updated and reloaded with reverse proxy routes for `ow.krynet.cc`, `litellm.krynet.cc`, `ollama.krynet.cc`, and `logs3.krynet.cc`.

### 4. AI Supercomputing Stack on Legion
- [x] **AI Stack Deployed:** `stacks/legion/ai-stack.yml` active with Ollama on GPU, LiteLLM Gateway, and OpenWebUI.
- [x] **GPU Models Pulled into RTX 3060 VRAM:**
  - `qwen2.5-coder:7b` (Primary coding and sysadmin model for OpenCode).
  - `deepseek-r1:7b` (Deep reasoning and troubleshooting model).
  - `nomic-embed-text` (Fast document and knowledge search embedding model).
- [x] **Web Interface Active:** `https://ow.krynet.cc` tested and generating responses.

### 5. Immich Machine Learning Offload & Prime Resource Reclaim
- [x] **Immich ML Node Deployed:** `stacks/legion/immich-ml.yml` active on Legion port `3003` with CUDA acceleration.
- [x] **Prime Reconfiguration:** `stack.env` on Prime updated with `IMMICH_MACHINE_LEARNING_URL=http://192.168.0.150:3003`.
- [x] **Resource Reclaim:** Stopped local `immich-machine-learning` and the old `ai-stack` on Prime, saving ~4GB+ RAM and freeing up Prime's CPU.

### 6. Multi-Node Prometheus & Gatus Observability
- [x] `/home/agni/apps/docker/prometheus/config/prometheus.yml` updated with scrape targets for `agni`, `prime`, and `legion`.
- [x] `/home/agni/apps/docker/gatus/config/config.yaml` updated with 3-node core health, AI stack endpoints, and Dozzle log monitors.

### 7. Distributed Tdarr GPU Video Transcoding
- [x] NFS share created on Prime for `/mnt/orion/data`.
- [x] Mounted on Legion at `/mnt/prime-media` with fstab persistent entry.
- [x] `stacks/legion/tdarr-node.yml` deployed on Legion with RTX 3060 NVENC GPU passthrough.
- [x] Transcode pipeline configured: Migz image removal → Audio cleaning → Stream reordering → NVENC HEVC transcoding → Size check.

### 8. Cross-Fleet OpenCode CLI Agent Configuration
- [x] OpenCode CLI installed and configured on Legion, Agni, and Prime.
- [x] Configured via **[`opencode.json`](../opencode.json)** pointing to LiteLLM Gateway (`http://192.168.0.150:4000/v1`) using `qwen2.5-coder` on RTX 3060.
- [x] Added **`.agents/skills/`** (`fleet-health` and `caddy-proxy`).

### 9. Homepage Dashboard 3-Node Alignment
- [x] Updated `config/homepage/services.yaml` with clean, matching groups.
- [x] Added **Dozzle (Legion)** under Network Tools (`https://logs3.krynet.cc`).
- [x] Updated **Smart Home & AI** group with Legion OpenWebUI, LiteLLM, and Ollama.

### 10. Complete Documentation & PR Merges
- [x] Dedicated Server Manuals: [`AGNI-SERVER.md`](AGNI-SERVER.md), [`PRIME-SERVER.md`](PRIME-SERVER.md), [`LEGION-SERVER.md`](LEGION-SERVER.md).
- [x] Master Blueprint & Progress Tracker: [`HOME-SERVER-REDESIGN.md`](HOME-SERVER-REDESIGN.md), [`REDESIGN-PROGRESS.md`](REDESIGN-PROGRESS.md).
- [x] All Pull Requests reviewed, approved, and merged into `main`.

### 11. Immich v2 to v3 VectorChord Database Migration
- [x] Pre-flight redundant backups: Application SQL dump (`704MB`), TrueNAS ZFS atomic snapshots (`andromeda/apps/immich/db`, `uploads`, `ml`, `orion/apps-config`), and Portainer stack backups.
- [x] Migrated PostgreSQL vector engine from `pgvecto.rs` to **VectorChord** (`ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0`).
- [x] Upgraded `immich_server` to **v3.1.0** and Redis to **ValKey 8**.
- [x] Rebuilt VectorChord vector indexes: 87,706 CLIP vectors and 173,656 Face vectors successfully indexed on Prime.
- [x] Verified remote CUDA ML acceleration on Legion (`http://192.168.0.150:3003`).
- [x] Documented in [**`docs/upgrades/2026-08-IMMICH-V3-UPGRADE.md`**](upgrades/2026-08-IMMICH-V3-UPGRADE.md).

### 12. Zero-Trust Private Mesh & Tailscale Split DNS Transformation
- [x] Remediated Legion Tailscale node (`100.117.26.106`) into permanent Portainer stack [`stacks/legion/tailscale.yml`](../stacks/legion/tailscale.yml).
- [x] Decommissioned public Cloudflared tunnel (`cloudflared-stack-cloudflared-1`) on Agni to achieve **0 open public ports** and eliminate public attack surface.
- [x] Configured Tailscale MagicDNS Split DNS nameserver (`100.89.216.106`) to bypass mobile carrier CGNAT filtering for seamless remote access.
- [x] Retained outbound Cloudflare DNS-01 API challenges in Caddy for automated wildcard SSL (`*.krynet.cc`).
- [x] Documented in [**`docs/plans/2026-08-NETWORKING-ARCHITECTURE-PLAN.md`**](plans/2026-08-NETWORKING-ARCHITECTURE-PLAN.md).

### 13. Portainer REST API Automation & Fleet Tooling
- [x] Built [`scripts/portainer-helper.sh`](../scripts/portainer-helper.sh) for programmatic stack management across Agni, Prime, and Legion.
- [x] Integrated permanent Portainer Access Tokens (`~/.portainer/agni_token` & `~/.portainer/prime_token`).
- [x] Created [`.agents/skills/portainer-ops/SKILL.md`](../.agents/skills/portainer-ops/SKILL.md) equipping AI agents with automated stack deploy and inspection capabilities.

### 14. 3-2-1 Backups & Disaster Recovery Hardening
- [x] Fixed Prime Rclone exclusion rule to prevent 32 GB Tdarr transcode cache files from uploading to pCloud.
- [x] Enabled TrueNAS automated recursive ZFS snapshots on `andromeda/apps` (Daily 02:00, keep 14d) and `andromeda/media` (Weekly Sun 03:00, keep 30d).
- [x] Deployed automated 12-hour off-site cloud backup stack on Legion ([`stacks/legion/rclone-stack.yml`](../stacks/legion/rclone-stack.yml)) to `pcloud:Backups/Krynet-Legion`.
- [x] Documented complete database and snapshot disaster recovery runbooks in [**`docs/OPERATIONS-PLAYBOOK.md`**](OPERATIONS-PLAYBOOK.md) and [`.agents/skills/backup-dr/SKILL.md`](../.agents/skills/backup-dr/SKILL.md).

### 15. Observability, Grafana Provisioning & Discord Alerting
- [x] Deployed `nvidia-gpu-exporter` on Legion (`stacks/legion/monitoring-sensors.yml`) exposing RTX 3060 metrics on `:9835`.
- [x] Updated Prometheus master on Agni to scrape all 3 nodes + GPU exporter with 100% UP health.
- [x] Automated Grafana provisioning with pre-built production dashboards (`KryNet 3-Node Fleet Overview` and `Legion RTX 3060 GPU Metrics`).
- [x] Connected Gatus health checks to Discord webhook (`#fleet-alerts`) for instant multi-platform push notifications.

### 16. Media Pipeline Hardening & Jellystat Deployment
- [x] Verified Gluetun WireGuard VPN gateway (`138.199.60.173` Singapore) and kill-switch isolation for qBittorrent and Jellyseerr.
- [x] Verified Legion RTX 3060 Tdarr Transcode Node (`tdarr-node-legion`) hardware acceleration (`h264_nvenc`, `hevc_nvenc`, `libsvtav1`).
- [x] Deployed **Jellystat** analytics stack on Prime ([`stacks/prime/jellystat.yml`](../stacks/prime/jellystat.yml)) on port `3005`.
- [x] Configured Caddy ingress (`https://jellystat.krynet.cc`) and integrated Jellystat card into Homepage (`https://home.krynet.cc`).

---

## 📋 Critical Path Summary Table

| Service | Node | Port | Public URL / Access | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Caddy Ingress** | Agni | 80/443 | `*.krynet.cc` | 🟢 Operational |
| **AdGuard Primary** | Agni | 53/7000 | `adguard2.krynet.cc` | 🟢 Operational |
| **Portainer Server** | Agni | 9443 | `portainer.krynet.cc` | 🟢 Operational |
| **Prometheus Master**| Agni | 9090 | `prom.krynet.cc` | 🟢 Operational |
| **Gatus Status** | Agni | 3001 | `status.krynet.cc` | 🟢 Operational |
| **Homepage** | Agni | 3075 | `home.krynet.cc` | 🟢 Operational |
| **Immich Core** | Prime | 2283 | `photos.krynet.cc` | 🟢 Operational |
| **Jellyfin** | Prime | 8096 | `media.krynet.cc` | 🟢 Operational |
| **ZFS Pools** | Prime | - | `/mnt/orion`, `/mnt/andromeda` | 🟢 Healthy |
| **OpenWebUI** | Legion | 3999 | `ow.krynet.cc` | 🟢 Operational |
| **LiteLLM Gateway** | Legion | 4000 | `litellm.krynet.cc` | 🟢 Operational |
| **Ollama (CUDA)** | Legion | 11434 | `ollama.krynet.cc` | 🟢 Operational |
| **Immich ML (CUDA)**| Legion | 3003 | Internal API (`:3003`) | 🟢 Operational |
| **Tdarr Node** | Legion | - | Node in `tdarr.krynet.cc` | 🟢 Operational |
| **Portainer Agent** | Legion | 9001 | Internal (`192.168.0.150:9001`)| 🟢 Operational |
| **Dozzle Logs** | Legion | 8088 | `logs3.krynet.cc` | 🟢 Operational |
