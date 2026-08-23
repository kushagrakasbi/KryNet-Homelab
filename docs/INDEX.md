# 📚 KryNet Documentation Index

**Central navigation for all KryNet Homelab documentation**

---

## 🗺️ Quick Navigation

### Primary Documentation

| Document | Description | Last Updated |
|----------|-------------|--------------|
| [**README.md**](../README.md) | Project overview, node topology, and architecture | Aug 2026 |
| [**AGENTS.md**](../AGENTS.md) | 🤖 Universal Fleet AI Agent Operating Guidelines | Aug 2026 |
| [**HOME-SERVER-REDESIGN.md**](HOME-SERVER-REDESIGN.md) | 🌌 3-Node Architecture Redesign & Agent Blueprint | Aug 2026 |
| [**REDESIGN-PROGRESS.md**](REDESIGN-PROGRESS.md) | 📊 Execution Progress & Live Service Status | Aug 2026 |
| [**AGNI-SERVER.md**](AGNI-SERVER.md) | 🔥 Network Core & Ingress documentation (`192.168.0.200`) | Aug 2026 |
| [**PRIME-SERVER.md**](PRIME-SERVER.md) | 🌟 Storage Vault & Media Hub documentation (`192.168.0.100`) | Aug 2026 |
| [**LEGION-SERVER.md**](LEGION-SERVER.md) | ⚡ AI, GPU & Compute Engine documentation (`192.168.0.150`) | Aug 2026 |
| [**AI-STACK.md**](AI-STACK.md) | 🤖 AI Supercomputing Stack (Ollama + LiteLLM + OpenWebUI) | Aug 2026 |
| [**OPERATIONS-PLAYBOOK.md**](OPERATIONS-PLAYBOOK.md) | 🛠️ Multi-Node Ops runbooks, FAQ & incident resolution | Aug 2026 |

### Technical Deep Dives, Upgrades & Plans

| Document | Description |
|----------|-------------|
| [**plans/README.md**](plans/README.md) | 📋 Fleet Strategic Plans & Architecture Transformations |
| [**plans/2026-08-FLEET-ROADMAP-AND-ENHANCEMENTS.md**](plans/2026-08-FLEET-ROADMAP-AND-ENHANCEMENTS.md) | 🗺️ Master Roadmap (3-2-1 Backups, Observability, Media Pipeline) |
| [**plans/2026-08-NETWORKING-ARCHITECTURE-PLAN.md**](plans/2026-08-NETWORKING-ARCHITECTURE-PLAN.md) | 🌐 Networking Review, Tailscale Remediation & Zero-Trust Plan |
| [**upgrades/README.md**](upgrades/README.md) | 🚀 Fleet Upgrades & Major Migrations Index |
| [**upgrades/2026-08-IMMICH-V3-UPGRADE.md**](upgrades/2026-08-IMMICH-V3-UPGRADE.md) | 📸 Immich v2 ➔ v3 & VectorChord Migration Guide |
| [**HOME-SERVER-REDESIGN.md**](HOME-SERVER-REDESIGN.md) | 🌌 3-Node distributed architecture & agentic fleet blueprint |
| [**networking.md**](networking.md) | Complete networking architecture & split-horizon DNS |
| [**services.md**](services.md) | Fleet service configuration guide |
| [**NETWORKING-QUICKREF.md**](NETWORKING-QUICKREF.md) | One-page networking and port reference |

---

## 📁 Documentation Structure

```
docs/
├── INDEX.md                    # This file
├── HOME-SERVER-REDESIGN.md     # 🌌 3-Node Architecture & Agent Blueprint
├── REDESIGN-PROGRESS.md        # 📊 Execution Progress & Verification Log
├── AGNI-SERVER.md             # 🔥 Network Core docs (192.168.0.200)
├── PRIME-SERVER.md            # 🌟 Storage Vault docs (192.168.0.100)
├── LEGION-SERVER.md           # ⚡ AI & GPU Compute docs (192.168.0.150)
├── AI-STACK.md                # 🤖 AI Stack Guide (Ollama + LiteLLM + OpenWebUI)
├── OPERATIONS-PLAYBOOK.md     # 🛠️ Ops Runbooks, Multi-Node FAQ & Troubleshooting
├── NETWORKING-QUICKREF.md     # Quick networking reference
├── networking.md              # Deep dive: networking
├── services.md                # Deep dive: services
├── plans/                     # 📋 Strategic Architecture Plans & Blueprints
│   ├── README.md              # Plans Directory Index
│   ├── 2026-08-FLEET-ROADMAP-AND-ENHANCEMENTS.md # Master Roadmap & Enhancements
│   └── 2026-08-NETWORKING-ARCHITECTURE-PLAN.md   # Networking Transformation Plan
└── upgrades/                  # 🚀 Fleet Upgrade Records & Migration History
    ├── README.md              # Upgrade SOP & History Index
    └── 2026-08-IMMICH-V3-UPGRADE.md # Immich v3 & VectorChord Migration
```

---

## 🎯 Find What You Need

### By Server

| Need | Document | Stack Directory |
|------|----------|-----------------|
| **Agni** (Ingress, DNS, Auth, Master Monitoring) | [AGNI-SERVER.md](AGNI-SERVER.md) | [`stacks/agni/`](../stacks/agni) |
| **Prime** (ZFS Storage, Media Suite, Immich Core) | [PRIME-SERVER.md](PRIME-SERVER.md) | [`stacks/prime/`](../stacks/prime) |
| **Legion** (RTX 3060 GPU, Ollama, Immich ML, Tdarr Node) | [LEGION-SERVER.md](LEGION-SERVER.md) | [`stacks/legion/`](../stacks/legion) |

### By Topic

| Topic | Document |
|-------|----------|
| Reverse Proxy (Caddy) & Ingress | [AGNI-SERVER.md](AGNI-SERVER.md) & [networking.md](networking.md) |
| Split-Horizon DNS & AdGuard Home | [networking.md](networking.md) |
| ZFS Storage Pools & TrueNAS | [PRIME-SERVER.md](PRIME-SERVER.md) |
| AI Models, LiteLLM & Ollama CUDA | [AI-STACK.md](AI-STACK.md) & [LEGION-SERVER.md](LEGION-SERVER.md) |
| Terminal Coding Agents & OpenCode | [AGENTS.md](../AGENTS.md) & [opencode.json](../opencode.json) |
| GPU Video Transcoding (Tdarr) | [LEGION-SERVER.md](LEGION-SERVER.md) |
| Prometheus, Grafana & Gatus | [AGNI-SERVER.md](AGNI-SERVER.md) & [OPERATIONS-PLAYBOOK.md](OPERATIONS-PLAYBOOK.md) |
| Troubleshooting & Docker Port Locks | [OPERATIONS-PLAYBOOK.md](OPERATIONS-PLAYBOOK.md) |

---

**Maintained by:** KryNet Homelab  
**Repository:** [home-server](https://github.com/kushagrakasbi/home-server)
