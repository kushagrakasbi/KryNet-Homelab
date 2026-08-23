---
name: portainer-ops
description: Programmatic Portainer stack management and deployment engine for KryNet fleet (Agni, Prime, Legion). Use to deploy, update, redeploy, start, stop, or inspect stacks without web UI manual intervention.
---

# 🐳 KryNet Portainer Operations Skill

This skill provides procedures and CLI conventions for managing Docker Stacks across the KryNet 3-node homelab infrastructure programmatically via Portainer REST API.

---

## 🗺️ Portainer Cluster Architecture

| Portainer Instance | Ingress URL | Node / Environment | Endpoint ID | Target Scope |
| :--- | :--- | :--- | :--- | :--- |
| **🔥 Agni Master** | `https://portainer2.krynet.cc` | `agni-server` (Local) | `4` | Ingress (Caddy), DNS, Vaultwarden, Monitoring |
| **🔥 Agni Master** | `https://portainer2.krynet.cc` | `Legion` (Agent) | `6` | AI Compute, Ollama CUDA, LiteLLM, Immich ML |
| **🌟 Prime Portainer** | `https://portainer.krynet.cc` | `krynet-server` (Local) | `2` | TrueNAS Applications, Immich, Media (*Arr) |

---

## 🛠️ CLI Automation Engine: `scripts/portainer-helper.sh`

The [`scripts/portainer-helper.sh`](../../../scripts/portainer-helper.sh) script automatically resolves tokens from `~/.portainer/agni_token` and `~/.portainer/prime_token`.

### 1. Inspect Environments & Stacks
```bash
# List all environments on Agni and Prime:
./scripts/portainer-helper.sh environments

# List all running stacks across the fleet:
./scripts/portainer-helper.sh stacks all

# List stacks on a specific node:
./scripts/portainer-helper.sh stacks agni
./scripts/portainer-helper.sh stacks prime
./scripts/portainer-helper.sh stacks legion
```

### 2. Deploy or Update Stacks from Repository YAML
```bash
# Deploy / Update on Agni:
./scripts/portainer-helper.sh deploy agni caddy-stack stacks/agni/caddy-stack.yml

# Deploy / Update on Prime:
./scripts/portainer-helper.sh deploy prime immich stacks/prime/immich.yml

# Deploy / Update on Legion:
./scripts/portainer-helper.sh deploy legion ai-stack stacks/legion/ai-stack.yml
```

### 3. Trigger Instant Image Re-pull & Redeploy
```bash
./scripts/portainer-helper.sh redeploy prime immich
./scripts/portainer-helper.sh redeploy legion ai-stack
```

### 4. Stack Lifecycle Control
```bash
# Stop a stack:
./scripts/portainer-helper.sh stop prime syncthing-stack

# Start a stack:
./scripts/portainer-helper.sh start prime syncthing-stack

# Retrieve live compose YAML from Portainer:
./scripts/portainer-helper.sh get-stack prime immich
```

### 5. Inspect Running Containers
```bash
./scripts/portainer-helper.sh containers agni
./scripts/portainer-helper.sh containers prime
./scripts/portainer-helper.sh containers legion
```

---

## 🔒 Operational Guidelines for AI Agents

1. **Source of Truth:** Compose definitions under `stacks/<node>/<stack-name>.yml` are the source of truth.
2. **Never Run Direct `docker compose up` on Nodes:** Always deploy via `./scripts/portainer-helper.sh deploy` to preserve UI visibility, environment variable mapping, and Portainer stack tracking.
3. **Bootstrap Exception:** Only `stacks/legion/portainer-agent.yml` is started via host Compose to initialize communication with the Agni master server.
