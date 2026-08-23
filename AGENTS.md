# 🤖 KryNet AI Agent Operating Guidelines & Fleet Context

**Repository:** `home-server`  
**Fleet Scope:** 🔥 Agni (`192.168.0.200`), 🌟 Prime (`192.168.0.100`), ⚡ Legion (`192.168.0.150`)  
**Target Agents:** OpenCode CLI, Antigravity CLI, Claude Code, Terminal Autonomous Agents  
**Last Updated:** August 2026

---

## 🎯 Agent Mission & Identity

You are the **KryNet Fleet Engineering Agent**. Your role is to assist the system administrator in managing, provisioning, debugging, monitoring, and maintaining a 3-node distributed home server infrastructure.

---

## 🗺️ Fleet Overview & Node Topology

| Node Name | IP Address | OS / Environment | Base Path | Core Workloads |
| :--- | :--- | :--- | :--- | :--- |
| **🔥 Agni** | `192.168.0.200` | Ubuntu Server 24.04 LTS | `/home/agni/apps/docker` | Caddy (Reverse Proxy Ingress), Cloudflared, AdGuard Home (Primary DNS), Vaultwarden, Home Assistant, Prometheus, Grafana, Gatus, Portainer Server |
| **🌟 Prime** | `192.168.0.100` | TrueNAS SCALE (Dragonfish) | `/mnt/orion/apps-config` | ZFS Storage Pools (`orion` & `andromeda`), Immich Core, Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, Gluetun, qBittorrent, SABnzbd, Paperless-ngx, Tdarr Server |
| **⚡ Legion** | `192.168.0.150` | Ubuntu Server 26.04 LTS (Headless) | `/home/legion/apps/docker` | Ollama (CUDA RTX 3060 6GB), LiteLLM Gateway (:4000), OpenWebUI (:3999), Immich ML Node (:3003), Tdarr Transcode Node, Portainer Agent |

---

## 🔒 Safety & Operational Rules

### 1. Data Protection (CRITICAL)
- **NEVER** run destructive disk commands (`mkfs`, `fdisk`, `zpool destroy`, `rm -rf /mnt/*`) on Prime.
- TrueNAS ZFS pools are named `orion` (configs/media pipeline) and `andromeda` (Immich photos, audiobooks, documents).
- **NEVER** commit `.env` or `stack.env` files containing raw API keys, passwords, or WireGuard credentials to Git.

### 2. Networking & Reverse Proxy
- All external and internal HTTP/HTTPS traffic terminates at **Agni** (`192.168.0.200`) on Caddy.
- Whenever you modify `config/caddy/Caddyfile`, **ALWAYS** validate the configuration before reloading:
  ```bash
  docker exec caddy caddy validate --config /etc/caddy/Caddyfile
  docker exec caddy caddy reload --config /etc/caddy/Caddyfile
  ```
- Split-horizon DNS rewrites in AdGuard Home ensure `*.krynet.cc` resolves locally to `192.168.0.200`.

### 3. Docker & Stack Management Conventions (CRITICAL)
- **Portainer Architecture & Ingress Endpoints**:
  - **Agni Master Portainer (`https://portainer2.krynet.cc` / `192.168.0.200:9443`)**: Manages **Agni (Local)** and **Legion (Portainer Agent at `192.168.0.150:9001`)**.
  - **Prime Portainer (`https://portainer.krynet.cc` / `192.168.0.100:9443`)**: Manages **Prime (TrueNAS applications)**.
- **Portainer Stacks Standard**:
  - **ALWAYS** deploy, update, and manage services via **Portainer Stacks** (Portainer Web UI or via `scripts/portainer-helper.sh`) rather than running manual `docker compose` commands directly on node hosts.
  - **Bootstrap Daemon Exception**: Only `portainer_agent` is started directly via Docker Compose on remote worker nodes (`stacks/legion/portainer-agent.yml`) to initialize communication with the master Portainer server.
  - Compose files located under `stacks/<node>/<stack-name>.yml` in this repository are the **Source of Truth** for Portainer stack definitions.
  - Use the Docker CLI on host nodes strictly for read-only / diagnostic actions: container status (`docker ps`), log streaming (`docker logs`), health checks, database dumps (`pg_dump`), and disaster recovery.
- **Autonomous Agent API Tooling (`scripts/`)**:
  - **Portainer API**: [`scripts/portainer-helper.sh`](scripts/portainer-helper.sh) ➔ Manage, deploy, redeploy, start, stop, and inspect stacks across Agni, Prime, and Legion programmatically.
  - **Tailscale API**: [`scripts/tailscale-helper.sh`](scripts/tailscale-helper.sh) ➔ Inspect active Tailnet devices and generate pre-authenticated keys.
  - **Cloudflare API**: [`scripts/cloudflare-helper.sh`](scripts/cloudflare-helper.sh) ➔ Query DNS records, zones, and tunnels.
- **Autonomous Agent Skills (`.agents/skills/`)**:
  - [**`fleet-health`**](.agents/skills/fleet-health/SKILL.md) ➔ Automated 12-point health checks (containers, ZFS pools, GPU thermals, Tailscale, DNS, Gatus).
  - [**`portainer-ops`**](.agents/skills/portainer-ops/SKILL.md) ➔ Programmatic multi-node stack deployment, redeployment, and inspection.
  - [**`backup-dr`**](.agents/skills/backup-dr/SKILL.md) ➔ 3-2-1 backup verification, TrueNAS snapshots, and database disaster recovery execution.
  - [**`caddy-proxy`**](.agents/skills/caddy-proxy/SKILL.md) ➔ Zero-downtime reverse proxy configuration and validation.
- Base Docker networks:
  - `agni_net` on Agni
  - `kry_net` and `traefik_proxy` on Prime
  - `legion_net` on Legion (Pre-existing networks must use `external: true` in Compose)
- Standard UID/GID:
  - Agni: `PUID=1000`, `PGID=1000`
  - Prime (TrueNAS): `PUID=568`, `PGID=568` (`apps` user)
  - Legion: `PUID=1000`, `PGID=1000`
- Timezone: `TZ=Asia/Kolkata`

### 4. Fleet SSH Key & Access Standards
- Passwordless ED25519 SSH keys (`~/.ssh/id_ed25519`) are standard across all nodes.
- Direct host alias shortcuts: `ssh agni` (`192.168.0.200`), `ssh prime` (`192.168.0.100`), `ssh legion` (`192.168.0.150`).
- Tailscale IP mapping:
  - `agni-server`: `100.89.216.106`
  - `prime-server`: `100.102.169.42`
  - `legion-server`: `100.117.26.106`
  - `mac`: `100.91.182.70`

### 5. Git Branching, PR Lifecycle & Conventional Commits (CRITICAL)
- **Branch-Per-Task / PR Lifecycle**:
  - Whenever starting a new work item, phase, or roadmap pillar after the previous branch was merged to `main`:
    1. Switch to `main` branch: `git checkout main && git pull --rebase`.
    2. Create a **NEW dedicated feature/fix branch** from `main`: `git checkout -b <type>/<task-name>`.
    3. **NEVER** reuse an existing branch or mix unrelated features/pillars into a previously used PR branch.
    4. Upon task completion, push the new branch to GitHub and present the new PR link.
- **Conventional Commits Standard**:
  - **ALL** commit messages, PR titles, and pull request descriptions **MUST** strictly adhere to the Conventional Commits specification:
    - `feat(<scope>): <description>` ➔ New functionality, stack additions, scripts
    - `fix(<scope>): <description>` ➔ Bug fixes, configuration corrections
    - `docs(<scope>): <description>` ➔ Documentation, manuals, plans, runbooks
    - `refactor(<scope>): <description>` ➔ Code/stack restructuring without functional changes
    - `perf(<scope>): <description>` ➔ Performance improvements (e.g. cache exclusions, CUDA tuning)
    - `chore(<scope>): <description>` ➔ Maintenance, minor tooling, housekeeping
  - Examples:
    - `feat(portainer): add programmatic stack helper script for fleet agents`
    - `fix(backups): exclude tdarr transcode cache files from prime rclone sync`
    - `docs(dr): add immich and vaultwarden disaster recovery runbooks`


---

## 🤖 LiteLLM Gateway & Agent Connections

All coding agents in the fleet connect to the **LiteLLM Gateway** hosted on Legion:

* **Base URL:** `http://192.168.0.150:4000/v1`
* **Health Check:** `curl http://192.168.0.150:4000/health/liveliness`
* **Available Models via Gateway:**
  - `qwen2.5-coder` (Local GPU model on Legion RTX 3060 - primary coding/sysadmin driver)
  - `deepseek-r1:7b` (Local GPU reasoning model on Legion - root-cause debugging)
  - `llama3.1:8b` (Local GPU general chat model on Legion)
  - `gemini-3-flash` (Cloud Google AI - fast tool use)
  - `claude-sonnet-4.5` / `claude-opus-4.6` (Cloud Anthropic - high intelligence)
  - `gpt-5.3` / `gpt-5.2` (Cloud OpenAI)

---

## 🛠️ Common Fleet Operations Playbook

### 1. Check Status of Containers Across Nodes
```bash
# On Agni:
ssh agni "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# On Prime:
ssh prime "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# On Legion:
ssh legion "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

### 2. Check GPU Utilization & Thermals on Legion
```bash
nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu --format=csv
```

### 3. Verify Immich ML Remote Offload
```bash
# Health check from Prime:
curl http://192.168.0.150:3003/ping
```

### 4. Git Repository Synchronization
```bash
cd ~/home-server && git pull --rebase
```

---

## 📂 Key Documentation References
- [**3-Node Redesign Blueprint**](docs/HOME-SERVER-REDESIGN.md)
- [**Redesign Execution Progress**](docs/REDESIGN-PROGRESS.md)
- [**Fleet Upgrades & Migrations**](docs/upgrades/README.md)
- [**Fleet Strategic Plans**](docs/plans/README.md)
- [**Agni Server Manual**](docs/AGNI-SERVER.md)
- [**Prime Server Manual**](docs/PRIME-SERVER.md)
- [**Legion Server Manual**](docs/LEGION-SERVER.md)
- [**AI Stack Guide**](docs/AI-STACK.md)
- [**Networking Deep Dive**](docs/networking.md)
- [**Operations Playbook & FAQ**](docs/OPERATIONS-PLAYBOOK.md)
